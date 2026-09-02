import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/server_model.dart';
import '../models/shield_settings.dart';
import '../models/vpn_profile.dart';
import '../models/app_info.dart';
import '../models/dns_option.dart';
import '../services/api_service.dart';
import '../services/wireguard_tunnel_service.dart';
import '../services/native_vpn_bridge.dart';
import '../services/session_storage.dart';

class VpnProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SessionStorage _sessionStorage = SessionStorage();
  late final WireGuardTunnelService _tunnelService;

  UserModel? _currentUser;
  String? _token;

  List<ServerNode> _servers = [];
  ServerNode? _selectedServer;
  bool _isLoadingServers = false;

  ArgusShieldSettings _shieldSettings = const ArgusShieldSettings();
  bool _killSwitchEnabled = true;
  bool _autoConnectOnWifiEnabled = false;
  bool _isReloadingShield = false;
  bool _isPingingServers = false;
  ThemeMode _themeMode = ThemeMode.dark;

  // DNS Selector State
  String _selectedDnsId = 'argus_shield';
  String _customPrimaryDns = '1.1.1.1';
  String _customSecondaryDns = '1.0.0.1';

  // Split tunneling bypassed packages
  Set<String> _bypassedPackages = {};
  List<AppInfo> _installedApps = [];
  bool _isLoadingApps = false;

  VpnState _vpnState = VpnState.disconnected;
  TrafficStats _trafficStats = const TrafficStats();

  StreamSubscription? _stateSub;
  StreamSubscription? _statsSub;

  VpnProvider() {
    _tunnelService = WireGuardTunnelService();

    _stateSub = _tunnelService.stateStream.listen((state) {
      _vpnState = state;
      notifyListeners();
    });

    _statsSub = _tunnelService.statsStream.listen((stats) {
      _trafficStats = stats;
      notifyListeners();
    });

    NativeVpnBridge.initializeCallbacks(
      onDisconnect: () {
        _tunnelService.disconnect();
      },
      onNetworkChange: (isWifi, isCellular) async {
        if (isWifi) {
          await fetchCurrentWifiSsid();
          final isTrusted = _shieldSettings.trustedWifiNetworks.contains(_currentWifiSsid);
          if (!isTrusted && (_autoConnectOnWifiEnabled || _shieldSettings.autoSecureUntrustedWifi) && _vpnState == VpnState.disconnected) {
            debugPrint('[ArgusVPN] Auto-securing untrusted Wi-Fi: $_currentWifiSsid');
            connect();
          } else if (isTrusted && _vpnState == VpnState.connected) {
            debugPrint('[ArgusVPN] Connected to trusted Wi-Fi ($_currentWifiSsid)');
          }
        }
      },
    );

    loadInitialData();
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;
  ThemeMode get themeMode => _themeMode;
  List<ServerNode> get servers => _servers;
  ServerNode? get selectedServer => _selectedServer;
  bool get isLoadingServers => _isLoadingServers;
  ArgusShieldSettings get shieldSettings => _shieldSettings;
  bool get killSwitchEnabled => _killSwitchEnabled;
  bool get autoConnectOnWifiEnabled => _autoConnectOnWifiEnabled;
  bool get isReloadingShield => _isReloadingShield;
  bool get isPingingServers => _isPingingServers;

  double get shieldScore {
    int activeCount = 0;
    if (_shieldSettings.blockAdultContent) activeCount++;
    if (_shieldSettings.blockGambling) activeCount++;
    if (_shieldSettings.blockSocialMedia) activeCount++;
    if (_shieldSettings.blockAdsAndTrackers) activeCount++;
    if (_shieldSettings.blockMalware) activeCount++;
    return (activeCount / 5.0).clamp(0.0, 1.0);
  }

  String get shieldGradeTitle {
    final score = shieldScore;
    if (score >= 0.8) return 'MAXIMUM DEFENSE';
    if (score >= 0.5) return 'ENHANCED SHIELD';
    if (score > 0.0) return 'BASIC PROTECTION';
    return 'SHIELD INACTIVE';
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> applyShieldPreset(String preset) async {
    switch (preset) {
      case 'family':
        await updateShieldSetting(
          blockAdultContent: true,
          blockGambling: true,
          blockAdsAndTrackers: true,
          blockMalware: true,
          blockSocialMedia: false,
        );
        break;
      case 'max_privacy':
        await updateShieldSetting(
          blockAdultContent: false,
          blockGambling: false,
          blockAdsAndTrackers: true,
          blockMalware: true,
          blockSocialMedia: false,
        );
        break;
      case 'focus':
        await updateShieldSetting(
          blockAdultContent: true,
          blockGambling: true,
          blockAdsAndTrackers: true,
          blockMalware: true,
          blockSocialMedia: true,
        );
        break;
      case 'performance':
        await updateShieldSetting(
          blockAdultContent: false,
          blockGambling: false,
          blockAdsAndTrackers: false,
          blockMalware: false,
          blockSocialMedia: false,
        );
        break;
    }
  }
  String get selectedDnsId => _selectedDnsId;
  String get customPrimaryDns => _customPrimaryDns;
  String get customSecondaryDns => _customSecondaryDns;
  Set<String> get bypassedPackages => _bypassedPackages;
  List<AppInfo> get installedApps => _installedApps;
  bool get isLoadingApps => _isLoadingApps;
  VpnState get vpnState => _vpnState;
  TrafficStats get trafficStats => _trafficStats;
  VpnProfile? get activeProfile => _tunnelService.activeProfile;

  List<String> get activeDnsServers {
    if (_selectedDnsId == 'custom') {
      final list = <String>[];
      if (_customPrimaryDns.trim().isNotEmpty) list.add(_customPrimaryDns.trim());
      if (_customSecondaryDns.trim().isNotEmpty) list.add(_customSecondaryDns.trim());
      return list.isNotEmpty ? list : ['1.1.1.1', '1.0.0.1'];
    }

    if (_selectedDnsId == 'argus_shield') {
      return _resolveShieldDnsServers(_shieldSettings);
    }

    final option = DnsOption.presetOptions.firstWhere(
      (opt) => opt.id == _selectedDnsId,
      orElse: () => DnsOption.presetOptions.first,
    );
    return option.servers.isNotEmpty ? option.servers : ['1.1.1.1', '1.0.0.1'];
  }

  List<String> _resolveShieldDnsServers(ArgusShieldSettings shield) {
    // 1. Adult + Gambling + Ads & Trackers (All-in-one Strict Guard)
    if (shield.blockAdultContent && shield.blockGambling && shield.blockAdsAndTrackers) {
      return const ['185.228.168.10', '185.228.169.11']; // CleanBrowsing Adult + Gambling
    }

    // 2. Adult + Ads & Trackers
    if (shield.blockAdultContent && shield.blockAdsAndTrackers) {
      return const ['94.140.14.15', '94.140.15.16']; // AdGuard Family (Adult + Ads + Trackers)
    }

    // 3. Adult + Gambling
    if (shield.blockAdultContent && shield.blockGambling) {
      return const ['185.228.168.10', '185.228.169.11']; // CleanBrowsing Adult + Gambling
    }

    // 4. Adult / Explicit Content only
    if (shield.blockAdultContent) {
      return const ['1.1.1.3', '1.0.0.3']; // Cloudflare Family (Adult + Malware)
    }

    // 5. Gambling & Betting only
    if (shield.blockGambling) {
      return const ['185.228.168.10', '185.228.169.11']; // CleanBrowsing Adult + Gambling
    }

    // 6. Social Media block
    if (shield.blockSocialMedia) {
      return const ['185.228.168.168', '185.228.169.168']; // CleanBrowsing Family
    }

    // 7. Ads & Trackers
    if (shield.blockAdsAndTrackers) {
      return const ['94.140.14.14', '94.140.15.15']; // AdGuard DNS (Ads + Trackers)
    }

    // 8. Malware & Phishing only
    if (shield.blockMalware) {
      return const ['9.9.9.9', '149.112.112.112', '1.1.1.2']; // Quad9 + Cloudflare Malware
    }

    // 9. No filtering active - Fast standard DNS
    return const ['1.1.1.1', '1.0.0.1'];
  }

  String get activeShieldProfileSummary {
    if (_selectedDnsId == 'custom') {
      return 'Custom DNS ($_customPrimaryDns)';
    }
    if (_selectedDnsId != 'argus_shield') {
      final opt = DnsOption.presetOptions.firstWhere(
        (o) => o.id == _selectedDnsId,
        orElse: () => DnsOption.presetOptions.first,
      );
      return opt.name;
    }
    if (_shieldSettings.blockAdultContent && _shieldSettings.blockGambling && _shieldSettings.blockAdsAndTrackers) {
      return 'Strict Family, Gambling & Ad Guard';
    }
    if (_shieldSettings.blockAdultContent && _shieldSettings.blockAdsAndTrackers) {
      return 'AdGuard Family (Adult + Ad Blocker)';
    }
    if (_shieldSettings.blockAdultContent && _shieldSettings.blockGambling) {
      return 'Strict Family & Anti-Gambling Filter';
    }
    if (_shieldSettings.blockAdultContent) {
      return 'Cloudflare Family Safe-Search Filter';
    }
    if (_shieldSettings.blockGambling) {
      return 'CleanBrowsing Anti-Gambling Guard';
    }
    if (_shieldSettings.blockSocialMedia) {
      return 'Family Focus & Social Shield Active';
    }
    if (_shieldSettings.blockAdsAndTrackers && _shieldSettings.blockMalware) {
      return 'AdGuard & Malware Shield Active';
    }
    if (_shieldSettings.blockAdsAndTrackers) {
      return 'AdGuard Ad & Tracker Blocker';
    }
    if (_shieldSettings.blockMalware) {
      return 'Quad9 Threat Guard Active';
    }
    return 'Standard DNS (No Filters)';
  }

  Future<void> loadInitialData() async {
    await _restoreSavedSession();
    await fetchServers();
  }

  Future<void> _restoreSavedSession() async {
    final session = await _sessionStorage.loadSession();
    if (session != null && session['token'] != null) {
      _token = session['token'] as String;
      _apiService.setAuthToken(_token);
      if (session['user'] != null) {
        _currentUser = UserModel.fromJson(session['user'] as Map<String, dynamic>);
      }
      if (session['shieldSettings'] != null) {
        _shieldSettings = ArgusShieldSettings.fromJson(session['shieldSettings'] as Map<String, dynamic>);
      }
      if (session['bypassedPackages'] != null) {
        _bypassedPackages = (session['bypassedPackages'] as List<dynamic>).map((e) => e.toString()).toSet();
      }
      if (session['selectedDnsId'] != null) {
        _selectedDnsId = session['selectedDnsId'] as String;
      }
      if (session['customPrimaryDns'] != null) {
        _customPrimaryDns = session['customPrimaryDns'] as String;
      }
      if (session['customSecondaryDns'] != null) {
        _customSecondaryDns = session['customSecondaryDns'] as String;
      }
      notifyListeners();
    }
  }

  Future<void> loginWithSocial(String provider) async {
    final email = '${provider.toLowerCase()}_user_${DateTime.now().millisecondsSinceEpoch % 10000}@argusmail.com';
    final user = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      tier: 'PRO',
      activeDevicesCount: 1,
      maxAllowedDevices: 5,
      shieldSettings: const ArgusShieldSettings(),
    );
    _token = 'token_${DateTime.now().millisecondsSinceEpoch}';
    _currentUser = user;
    _shieldSettings = user.shieldSettings;
    _apiService.setAuthToken(_token);

    await _sessionStorage.saveSession(
      token: _token!,
      user: _currentUser!,
      shieldSettings: _shieldSettings,
      bypassedPackages: _bypassedPackages.toList(),
      selectedDnsId: _selectedDnsId,
      customPrimaryDns: _customPrimaryDns,
      customSecondaryDns: _customSecondaryDns,
    );
    notifyListeners();
  }

  Future<void> fetchServers() async {
    _isLoadingServers = true;
    notifyListeners();

    try {
      _servers = await _apiService.getServers();
      if (_servers.isNotEmpty && _selectedServer == null) {
        _selectedServer = _servers.first;
      }
    } catch (_) {}

    _isLoadingServers = false;
    notifyListeners();
  }

  void selectServer(ServerNode server) {
    _selectedServer = server;
    notifyListeners();
  }

  Future<void> selectDnsOption(String dnsId) async {
    _selectedDnsId = dnsId;
    _persistCurrentSession();
    notifyListeners();
    await _reloadIfActive();
  }

  Future<void> setCustomDns({required String primary, required String secondary}) async {
    _customPrimaryDns = primary;
    _customSecondaryDns = secondary;
    _persistCurrentSession();
    notifyListeners();
    await _reloadIfActive();
  }

  void toggleKillSwitch(bool value) {
    _killSwitchEnabled = value;
    notifyListeners();
  }

  Future<void> loadInstalledApps() async {
    _isLoadingApps = true;
    notifyListeners();

    try {
      _installedApps = await NativeVpnBridge.getInstalledApps(_bypassedPackages);
    } catch (_) {}

    _isLoadingApps = false;
    notifyListeners();
  }

  Future<void> toggleAppBypass(String packageName, bool bypass) async {
    if (bypass) {
      _bypassedPackages.add(packageName);
    } else {
      _bypassedPackages.remove(packageName);
    }

    _installedApps = _installedApps.map((app) {
      if (app.packageName == packageName) {
        return app.copyWith(isBypassed: bypass);
      }
      return app;
    }).toList();

    _persistCurrentSession();
    notifyListeners();

    // Hot-reload tunnel with updated split tunneling rules if connected
    await _reloadIfActive();
  }

  Future<void> clearAllBypasses() async {
    _bypassedPackages.clear();
    _installedApps = _installedApps.map((app) => app.copyWith(isBypassed: false)).toList();
    _persistCurrentSession();
    notifyListeners();

    // Hot-reload tunnel with cleared bypass list if connected
    await _reloadIfActive();
  }

  String _currentWifiSsid = 'Wi-Fi (Protected)';
  String get currentWifiSsid => _currentWifiSsid;

  int? _activePortForward;
  DateTime? _portForwardExpiresAt;
  int? get activePortForward => _activePortForward;
  DateTime? get portForwardExpiresAt => _portForwardExpiresAt;

  Timer? _decoyTrafficTimer;

  Future<void> fetchCurrentWifiSsid() async {
    try {
      _currentWifiSsid = await NativeVpnBridge.getCurrentWifiSsid();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleDecoyTraffic(bool val) async {
    _shieldSettings = _shieldSettings.copyWith(decoyTraffic: val);
    _persistCurrentSession();
    _handleDecoyTrafficLifecycle();
    notifyListeners();
    await _reloadIfActive();
  }

  void _handleDecoyTrafficLifecycle() {
    _decoyTrafficTimer?.cancel();
    _decoyTrafficTimer = null;

    if (_shieldSettings.decoyTraffic && _vpnState == VpnState.connected) {
      _decoyTrafficTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_vpnState != VpnState.connected || !_shieldSettings.decoyTraffic) {
          timer.cancel();
          return;
        }
        // Send lightweight synthetic decoy packet burst
        NativeVpnBridge.pingServer('1.1.1.1', port: 53, timeout: const Duration(milliseconds: 800));
      });
    }
  }

  Future<void> toggleStealthMode(bool val) async {
    _shieldSettings = _shieldSettings.copyWith(stealthMode: val);
    _persistCurrentSession();
    notifyListeners();
    await _reloadIfActive();
  }

  Future<void> toggleLocalLanAccess(bool val) async {
    _shieldSettings = _shieldSettings.copyWith(localLanAccess: val);
    _persistCurrentSession();
    notifyListeners();
    await _reloadIfActive();
  }

  Future<void> setPacketMtu(int mtu) async {
    final clamped = mtu.clamp(1280, 1500);
    _shieldSettings = _shieldSettings.copyWith(packetMtu: clamped);
    _persistCurrentSession();
    notifyListeners();
    await _reloadIfActive();
  }

  Future<void> toggleAutoSecureUntrustedWifi(bool val) async {
    _shieldSettings = _shieldSettings.copyWith(autoSecureUntrustedWifi: val);
    _persistCurrentSession();
    notifyListeners();
  }

  Future<void> addTrustedWifi(String ssid) async {
    if (ssid.isEmpty || _shieldSettings.trustedWifiNetworks.contains(ssid)) return;
    final updated = List<String>.from(_shieldSettings.trustedWifiNetworks)..add(ssid);
    _shieldSettings = _shieldSettings.copyWith(trustedWifiNetworks: updated);
    _persistCurrentSession();
    notifyListeners();
  }

  Future<void> removeTrustedWifi(String ssid) async {
    final updated = List<String>.from(_shieldSettings.trustedWifiNetworks)..remove(ssid);
    _shieldSettings = _shieldSettings.copyWith(trustedWifiNetworks: updated);
    _persistCurrentSession();
    notifyListeners();
  }

  Future<int> requestEphemeralPort({int hours = 24}) async {
    final randomPort = 49152 + (DateTime.now().millisecondsSinceEpoch % 16000);
    _activePortForward = randomPort;
    _portForwardExpiresAt = DateTime.now().add(Duration(hours: hours));
    notifyListeners();
    return randomPort;
  }

  void cancelEphemeralPort() {
    _activePortForward = null;
    _portForwardExpiresAt = null;
    notifyListeners();
  }

  Future<void> updateShieldSetting({
    bool? blockMalware,
    bool? blockAdsAndTrackers,
    bool? blockAdultContent,
    bool? blockGambling,
    bool? blockSocialMedia,
    bool? macAddressMasking,
    bool? decoyTraffic,
    bool? stealthMode,
    bool? localLanAccess,
    int? packetMtu,
    bool? autoSecureUntrustedWifi,
    List<String>? trustedWifiNetworks,
  }) async {
    _selectedDnsId = 'argus_shield'; // Explicitly switch to Argus Shield mode
    _shieldSettings = _shieldSettings.copyWith(
      blockMalware: blockMalware,
      blockAdsAndTrackers: blockAdsAndTrackers,
      blockAdultContent: blockAdultContent,
      blockGambling: blockGambling,
      blockSocialMedia: blockSocialMedia,
      macAddressMasking: macAddressMasking,
      decoyTraffic: decoyTraffic,
      stealthMode: stealthMode,
      localLanAccess: localLanAccess,
      packetMtu: packetMtu,
      autoSecureUntrustedWifi: autoSecureUntrustedWifi,
      trustedWifiNetworks: trustedWifiNetworks,
    );
    _persistCurrentSession();
    _handleDecoyTrafficLifecycle();
    notifyListeners();

    // Hot-reload active WireGuard tunnel immediately with new DNS
    await _reloadIfActive();

    // Non-blocking async sync with backend (with short timeout)
    if (isAuthenticated) {
      unawaited(
        _apiService
            .updateShieldSettings(_shieldSettings)
            .timeout(const Duration(seconds: 2))
            .then((_) => _persistCurrentSession())
            .catchError((_) => _shieldSettings),
      );
    }
  }

  void setKillSwitch(bool val) {
    _killSwitchEnabled = val;
    _persistCurrentSession();
    notifyListeners();
  }

  void setAutoConnectOnWifi(bool val) {
    _autoConnectOnWifiEnabled = val;
    _persistCurrentSession();
    notifyListeners();
  }

  Future<void> pingAllServers() async {
    if (_servers.isEmpty || _isPingingServers) return;
    _isPingingServers = true;
    notifyListeners();

    try {
      final updated = await Future.wait(_servers.map((s) async {
        final ping = await NativeVpnBridge.pingServer(
          s.publicIp,
          port: s.wireguardPort == 51820 ? 4001 : s.wireguardPort,
        );
        return s.copyWith(pingMs: ping);
      }));

      // Sort by lowest latency
      updated.sort((a, b) => a.pingMs.compareTo(b.pingMs));
      _servers = updated;
    } catch (_) {}

    _isPingingServers = false;
    notifyListeners();
  }

  Future<void> quickConnectFastestServer() async {
    await pingAllServers();
    if (_servers.isNotEmpty) {
      _selectedServer = _servers.first;
      notifyListeners();
      await connect(server: _servers.first);
    }
  }

  Future<bool> connect({ServerNode? server}) async {
    if (server != null) _selectedServer = server;
    if (!isAuthenticated) {
      return false;
    }
    await _tunnelService.connect(
      server: _selectedServer,
      shieldSettings: _shieldSettings,
      customDnsServers: activeDnsServers,
      disallowedPackages: _bypassedPackages.toList(),
      killSwitch: _killSwitchEnabled,
    );
    return true;
  }

  Future<void> toggleVpnConnection() async {
    if (_vpnState == VpnState.connected || _vpnState == VpnState.connecting) {
      await _tunnelService.disconnect();
    } else {
      await connect();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final result = await _apiService.login(email, password);
      _token = result['token'] as String;
      _currentUser = UserModel.fromJson(result['user'] as Map<String, dynamic>);
      _shieldSettings = _currentUser!.shieldSettings;
      _apiService.setAuthToken(_token);
      await _sessionStorage.saveUserCredentials(email, password, _currentUser!);
    } catch (e) {
      // Check if user exists in local offline storage
      final localUser = await _sessionStorage.validateLocalCredentials(email, password);
      if (localUser != null) {
        _currentUser = localUser;
        _token = 'local_token_${DateTime.now().millisecondsSinceEpoch}';
        _shieldSettings = _currentUser!.shieldSettings;
        _apiService.setAuthToken(_token);
      } else {
        // If neither remote nor local matched, but remote was a network error, grant access with a new user profile
        if (e.toString().contains('SocketException') ||
            e.toString().contains('TimeoutException') ||
            e.toString().contains('Connection refused') ||
            e.toString().contains('ClientException') ||
            e.toString().contains('Failed host lookup')) {
          _currentUser = UserModel(
            id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
            email: email,
            tier: 'FREE',
            activeDevicesCount: 1,
            maxAllowedDevices: 5,
            shieldSettings: _shieldSettings,
          );
          _token = 'local_token_${DateTime.now().millisecondsSinceEpoch}';
          _apiService.setAuthToken(_token);
          await _sessionStorage.saveUserCredentials(email, password, _currentUser!);
        } else {
          rethrow;
        }
      }
    }

    await _sessionStorage.saveSession(
      token: _token!,
      user: _currentUser!,
      shieldSettings: _shieldSettings,
      bypassedPackages: _bypassedPackages.toList(),
      selectedDnsId: _selectedDnsId,
      customPrimaryDns: _customPrimaryDns,
      customSecondaryDns: _customSecondaryDns,
    );
    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    try {
      final result = await _apiService.register(email, password);
      _token = result['token'] as String;
      _currentUser = UserModel.fromJson(result['user'] as Map<String, dynamic>);
      _shieldSettings = _currentUser!.shieldSettings;
      _apiService.setAuthToken(_token);
      await _sessionStorage.saveUserCredentials(email, password, _currentUser!);
    } catch (e) {
      // If remote backend is temporarily unreachable, create user locally so onboarding is never blocked
      _currentUser = UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        tier: 'FREE',
        activeDevicesCount: 1,
        maxAllowedDevices: 5,
        shieldSettings: _shieldSettings,
      );
      _token = 'local_token_${DateTime.now().millisecondsSinceEpoch}';
      _apiService.setAuthToken(_token);
      await _sessionStorage.saveUserCredentials(email, password, _currentUser!);
    }

    await _sessionStorage.saveSession(
      token: _token!,
      user: _currentUser!,
      shieldSettings: _shieldSettings,
      bypassedPackages: _bypassedPackages.toList(),
      selectedDnsId: _selectedDnsId,
      customPrimaryDns: _customPrimaryDns,
      customSecondaryDns: _customSecondaryDns,
    );
    notifyListeners();
  }

  void logout() {
    _token = null;
    _currentUser = null;
    _apiService.setAuthToken(null);
    _sessionStorage.clearSession();
    notifyListeners();
  }

  /// Hot-reloads the active WireGuard tunnel seamlessly with the updated DNS and split tunneling bypass rules
  Future<void> _reloadIfActive() async {
    if (_vpnState == VpnState.connected) {
      _isReloadingShield = true;
      notifyListeners();
      try {
        debugPrint('[ArgusVPN] Hot-reloading tunnel with DNS: $activeDnsServers, bypassed: ${_bypassedPackages.length} apps');
        await _tunnelService.reloadTunnel(
          dnsServers: activeDnsServers,
          disallowedPackages: _bypassedPackages.toList(),
          shieldSettings: _shieldSettings,
        );
      } finally {
        await Future.delayed(const Duration(milliseconds: 300));
        _isReloadingShield = false;
        notifyListeners();
      }
    }
  }

  void _persistCurrentSession() {
    if (_token != null && _currentUser != null) {
      _sessionStorage.saveSession(
        token: _token!,
        user: _currentUser!,
        shieldSettings: _shieldSettings,
        bypassedPackages: _bypassedPackages.toList(),
        selectedDnsId: _selectedDnsId,
        customPrimaryDns: _customPrimaryDns,
        customSecondaryDns: _customSecondaryDns,
      );
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _statsSub?.cancel();
    _tunnelService.dispose();
    super.dispose();
  }
}
