import 'dart:async';
import '../models/vpn_profile.dart';
import '../models/server_model.dart';
import '../models/shield_settings.dart';
import 'native_vpn_bridge.dart';

class TrafficStats {
  final int bytesReceived;
  final int bytesSent;
  final double downloadSpeedKbps;
  final double uploadSpeedKbps;
  final Duration duration;

  const TrafficStats({
    this.bytesReceived = 0,
    this.bytesSent = 0,
    this.downloadSpeedKbps = 0.0,
    this.uploadSpeedKbps = 0.0,
    this.duration = Duration.zero,
  });
}

class WireGuardTunnelService {
  VpnState _state = VpnState.disconnected;
  VpnProfile? _activeProfile;
  Timer? _metricsTimer;
  DateTime? _connectedAt;

  int _bytesRx = 0;
  int _bytesTx = 0;
  double _downSpeed = 0.0;
  double _upSpeed = 0.0;

  final _statsController = StreamController<TrafficStats>.broadcast();
  final _stateController = StreamController<VpnState>.broadcast();

  WireGuardTunnelService();

  VpnState get state => _state;
  VpnProfile? get activeProfile => _activeProfile;
  Stream<TrafficStats> get statsStream => _statsController.stream;
  Stream<VpnState> get stateStream => _stateController.stream;

  Future<void> connect({
    ServerNode? server,
    ArgusShieldSettings? shieldSettings,
    List<String>? customDnsServers,
    List<String> disallowedPackages = const [],
    bool killSwitch = false,
  }) async {
    try {
      _setState(VpnState.connecting);

      // 1. Prepare Android OS VPN Permission
      await NativeVpnBridge.prepareVpn();

      // 2. Resolve server and DNS configuration
      // NOTE: Client keypair generation is handled ENTIRELY by the native
      // Kotlin GoBackend (real Curve25519 via WireGuard SDK). The native
      // service also registers the peer with the node daemon dynamically.
      // We do NOT generate keys in Dart — the old KeyGenService produced
      // invalid random bytes that caused handshake failures.
      final serverNode = server ?? const ServerNode(
        id: 'node-de-frankfurt-1',
        hostname: 'de-fra-1.argusvpn.com',
        location: ServerLocation(
          city: 'Frankfurt',
          country: 'Germany',
          countryCode: 'DE',
          latitude: 50.1109,
          longitude: 8.6821,
        ),
        publicIp: '158.180.31.224',
        wireguardPort: 51820,
        publicKey: 'lrKW+2hSOCZ8XlQoTRJwQ5I73wORkVodEgdsTKQwuAQ=',
        currentLoadPercentage: 12,
        tierRequired: 'FREE',
        pingMs: 38,
      );

      // Determine virtual IP based on selected country/city to route through correct exit proxy
      final countryCode = serverNode.location.countryCode.toUpperCase();
      final cityName = serverNode.location.city.toLowerCase();
      String clientVirtualIp = '10.8.1.2'; // Default US NY

      if (countryCode == 'US' && cityName.contains('los angeles')) {
        clientVirtualIp = '10.8.2.2'; // US Los Angeles
      } else if (countryCode == 'US') {
        clientVirtualIp = '10.8.1.2'; // US New York (and other US cities)
      } else if (countryCode == 'GB' || countryCode == 'UK') {
        clientVirtualIp = '10.8.3.2'; // UK London
      } else if (countryCode == 'ES') {
        clientVirtualIp = '10.8.4.2'; // Spain Madrid
      } else if (countryCode == 'JP') {
        clientVirtualIp = '10.8.5.2'; // Japan Tokyo
      } else if (countryCode == 'DE') {
        clientVirtualIp = '10.8.0.2'; // Germany Frankfurt Direct
      }

      _activeProfile = VpnProfile(
        sessionId: 'session-${DateTime.now().millisecondsSinceEpoch}',
        server: serverNode,
        assignedVirtualIp: clientVirtualIp,
        dnsServers: customDnsServers ?? const ['1.1.1.1', '1.0.0.1'],
        serverPublicKey: serverNode.publicKey,
        endpoint: '${serverNode.publicIp}:${serverNode.wireguardPort}',
        shieldSettings: shieldSettings ?? const ArgusShieldSettings(),
      );

      _connectedAt = DateTime.now();
      _bytesRx = 0;
      _bytesTx = 0;

      final dnsToUse = (customDnsServers != null && customDnsServers.isNotEmpty)
          ? customDnsServers
          : const ['1.1.1.1', '1.0.0.1'];

      // 3. Start Native Android WireGuard TUN Interface
      final settings = shieldSettings ?? _activeProfile?.shieldSettings ?? const ArgusShieldSettings();

      await NativeVpnBridge.startTunnel(
        serverIp: serverNode.publicIp,
        serverPort: serverNode.wireguardPort,
        assignedIp: clientVirtualIp,
        dnsList: dnsToUse,
        clientPrivateKey: '',  // Empty = let native side generate real keys
        serverPublicKey: serverNode.publicKey,
        disallowedPackages: disallowedPackages,
        killSwitch: killSwitch,
        serverCity: serverNode.location.city,
        serverCountry: serverNode.location.country,
        serverFlag: serverNode.flagEmoji,
        localLanAccess: settings.localLanAccess,
        packetMtu: settings.packetMtu,
        stealthMode: settings.stealthMode,
      );

      // 4. Start telemetry timer
      _startMetricsTimer();

      _setState(VpnState.connected);
    } catch (e) {
      _setState(VpnState.error);
      rethrow;
    }
  }

  int _lastBytesRx = 0;
  int _lastBytesTx = 0;
  DateTime? _lastStatsTime;

  /// Hot-reloads the active WireGuard tunnel with updated DNS servers and split tunneling bypass list
  Future<void> reloadTunnel({
    required List<String> dnsServers,
    List<String> disallowedPackages = const [],
    ArgusShieldSettings? shieldSettings,
    ServerNode? newServer,
  }) async {
    try {
      final dnsToUse = dnsServers.isNotEmpty ? dnsServers : const ['1.1.1.1', '1.0.0.1'];
      final serverToUse = newServer ?? _activeProfile?.server;
      final settings = shieldSettings ?? _activeProfile?.shieldSettings ?? const ArgusShieldSettings();

      if (_activeProfile != null) {
        _activeProfile = VpnProfile(
          sessionId: _activeProfile!.sessionId,
          server: serverToUse ?? _activeProfile!.server,
          assignedVirtualIp: _activeProfile!.assignedVirtualIp,
          dnsServers: dnsToUse,
          serverPublicKey: serverToUse?.publicKey ?? _activeProfile!.serverPublicKey,
          endpoint: serverToUse != null ? '${serverToUse.publicIp}:${serverToUse.wireguardPort}' : _activeProfile!.endpoint,
          shieldSettings: settings,
        );
      }
      await NativeVpnBridge.reloadTunnel(
        dnsList: dnsToUse,
        disallowedPackages: disallowedPackages,
        serverCity: serverToUse?.location.city,
        serverCountry: serverToUse?.location.country,
        serverFlag: serverToUse?.flagEmoji,
        localLanAccess: settings.localLanAccess,
        packetMtu: settings.packetMtu,
        stealthMode: settings.stealthMode,
      );
    } catch (e) {
      // If reload fails, fallback to full connect
      await connect(
        server: newServer ?? _activeProfile?.server,
        shieldSettings: shieldSettings,
        customDnsServers: dnsServers,
        disallowedPackages: disallowedPackages,
      );
    }
  }

  Future<void> disconnect() async {
    if (_state == VpnState.disconnected) return;

    _setState(VpnState.disconnecting);
    _metricsTimer?.cancel();

    // Stop Android VpnService
    await NativeVpnBridge.stopTunnel();

    _activeProfile = null;
    _connectedAt = null;
    _downSpeed = 0.0;
    _upSpeed = 0.0;
    _bytesRx = 0;
    _bytesTx = 0;
    _lastBytesRx = 0;
    _lastBytesTx = 0;

    _setState(VpnState.disconnected);
    _statsController.add(const TrafficStats());
  }

  void _setState(VpnState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  void _startMetricsTimer() {
    _metricsTimer?.cancel();
    _lastBytesRx = 0;
    _lastBytesTx = 0;
    _lastStatsTime = DateTime.now();

    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_state != VpnState.connected || _connectedAt == null) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      final duration = now.difference(_connectedAt!);

      try {
        final rawStats = await NativeVpnBridge.getTunnelStats();
        final currentRx = rawStats['bytesRx'] ?? 0;
        final currentTx = rawStats['bytesTx'] ?? 0;

        if (_lastStatsTime != null) {
          final elapsedSeconds = now.difference(_lastStatsTime!).inMilliseconds / 1000.0;
          if (elapsedSeconds > 0.1) {
            final deltaRx = (currentRx >= _lastBytesRx && _lastBytesRx > 0) ? (currentRx - _lastBytesRx) : 0;
            final deltaTx = (currentTx >= _lastBytesTx && _lastBytesTx > 0) ? (currentTx - _lastBytesTx) : 0;

            // Convert bytes/sec to Kbps (kilobits per second)
            _downSpeed = (deltaRx * 8.0) / (elapsedSeconds * 1024.0);
            _upSpeed = (deltaTx * 8.0) / (elapsedSeconds * 1024.0);
          }
        }

        _bytesRx = currentRx;
        _bytesTx = currentTx;
        _lastBytesRx = currentRx;
        _lastBytesTx = currentTx;
        _lastStatsTime = now;
      } catch (_) {}

      _statsController.add(TrafficStats(
        bytesReceived: _bytesRx,
        bytesSent: _bytesTx,
        downloadSpeedKbps: _downSpeed,
        uploadSpeedKbps: _upSpeed,
        duration: duration,
      ));
    });
  }

  void dispose() {
    _metricsTimer?.cancel();
    _statsController.close();
    _stateController.close();
  }
}
