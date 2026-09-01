import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/app_info.dart';

class NativeVpnBridge {
  static const MethodChannel _vpnChannel = MethodChannel('com.argusvpn.app/vpn');
  static const MethodChannel _appsChannel = MethodChannel('com.argusvpn.app/installed_apps');

  /// Requests the Android OS VPN Permission consent dialog
  static Future<bool> prepareVpn() async {
    try {
      final bool? result = await _vpnChannel.invokeMethod<bool>('prepareVpn');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      // In web / desktop simulation
      return true;
    }
  }

  /// Starts the native Android VpnService tunnel with DNS Shield and Split Tunneling
  static Future<bool> startTunnel({
    required String serverIp,
    required int serverPort,
    required String assignedIp,
    required List<String> dnsList,
    required String clientPrivateKey,
    required String serverPublicKey,
    required List<String> disallowedPackages,
    required bool killSwitch,
    String serverCity = 'Frankfurt',
    String serverCountry = 'Germany',
    String serverFlag = '🇩🇪',
    bool localLanAccess = true,
    int packetMtu = 1420,
    bool stealthMode = false,
  }) async {
    try {
      final bool? result = await _vpnChannel.invokeMethod<bool>('connectVpn', {
        'serverIp': serverIp,
        'serverPort': serverPort,
        'assignedIp': assignedIp,
        'dnsList': dnsList,
        'clientPrivateKey': clientPrivateKey,
        'serverPublicKey': serverPublicKey,
        'disallowedPackages': disallowedPackages,
        'killSwitch': killSwitch,
        'serverCity': serverCity,
        'serverCountry': serverCountry,
        'serverFlag': serverFlag,
        'localLanAccess': localLanAccess,
        'packetMtu': packetMtu,
        'stealthMode': stealthMode,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      // In web / desktop simulation
      return true;
    }
  }

  /// Reloads the native WireGuard tunnel with updated DNS servers and app bypass list seamlessly without full service teardown
  static Future<bool> reloadTunnel({
    required List<String> dnsList,
    List<String> disallowedPackages = const [],
    String? serverCity,
    String? serverCountry,
    String? serverFlag,
    bool localLanAccess = true,
    int packetMtu = 1420,
    bool stealthMode = false,
  }) async {
    try {
      final bool? result = await _vpnChannel.invokeMethod<bool>('reloadTunnel', {
        'dnsList': dnsList,
        'disallowedPackages': disallowedPackages,
        'serverCity': ?serverCity,
        'serverCountry': ?serverCountry,
        'serverFlag': ?serverFlag,
        'localLanAccess': localLanAccess,
        'packetMtu': packetMtu,
        'stealthMode': stealthMode,
      });
      return result ?? true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return true;
    }
  }

  /// Queries current connected Wi-Fi SSID
  static Future<String> getCurrentWifiSsid() async {
    try {
      final String? ssid = await _vpnChannel.invokeMethod<String>('getCurrentWifiSsid');
      return ssid ?? 'Wi-Fi (Protected)';
    } catch (_) {
      return 'Wi-Fi (Protected)';
    }
  }

  /// Queries real-time WireGuard RX and TX byte counters directly from GoBackend
  static Future<Map<String, int>> getTunnelStats() async {
    try {
      final Map<dynamic, dynamic>? result = await _vpnChannel.invokeMethod<Map<dynamic, dynamic>>('getTunnelStats');
      if (result != null) {
        return {
          'bytesRx': (result['bytesRx'] as num?)?.toInt() ?? 0,
          'bytesTx': (result['bytesTx'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (_) {}
    return const {'bytesRx': 0, 'bytesTx': 0};
  }

  /// Stops the native VpnService tunnel
  static Future<bool> stopTunnel() async {
    try {
      final bool? result = await _vpnChannel.invokeMethod<bool>('disconnectVpn');
      return result ?? true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return true;
    }
  }

  /// Checks if the native Android VPN service is currently active
  static Future<bool> isRunning() async {
    try {
      final bool? result = await _vpnChannel.invokeMethod<bool>('isVpnRunning');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static void Function()? onDisconnectedFromNotification;
  static void Function(bool isWifi, bool isCellular)? onNetworkAvailable;

  /// Registers MethodChannel listeners from native Android (e.g. Disconnect from Notification, Wi-Fi joined)
  static void initializeCallbacks({
    void Function()? onDisconnect,
    void Function(bool isWifi, bool isCellular)? onNetworkChange,
  }) {
    onDisconnectedFromNotification = onDisconnect;
    onNetworkAvailable = onNetworkChange;

    _vpnChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onVpnStateChanged':
          if (call.arguments == 'disconnected') {
            onDisconnectedFromNotification?.call();
          }
          break;
        case 'onNetworkAvailable':
          if (call.arguments is Map) {
            final map = call.arguments as Map<dynamic, dynamic>;
            final isWifi = map['isWifi'] as bool? ?? false;
            final isCellular = map['isCellular'] as bool? ?? false;
            onNetworkAvailable?.call(isWifi, isCellular);
          }
          break;
      }
    });
  }

  /// Measures real-time TCP socket latency (in milliseconds) to a server node
  static Future<int> pingServer(String host, {int port = 4001, Duration timeout = const Duration(seconds: 2)}) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds < timeout.inMilliseconds ? stopwatch.elapsedMilliseconds : 999;
    }
  }

  /// Retrieves list of installed applications on the Android device for Split Tunneling
  static Future<List<AppInfo>> getInstalledApps(Set<String> bypassedPackages) async {
    try {
      final List<dynamic>? apps = await _appsChannel.invokeMethod<List<dynamic>>('getInstalledApps');
      if (apps == null) return [];

      return apps.map((item) {
        final map = item as Map<dynamic, dynamic>;
        final pkg = map['packageName'] as String? ?? '';
        return AppInfo.fromMap(map, isBypassed: bypassedPackages.contains(pkg));
      }).toList();
    } catch (_) {
      // Fallback mock installed apps for web/desktop testing
      return [
        AppInfo(name: 'WhatsApp', packageName: 'com.whatsapp', isSystemApp: false, isBypassed: bypassedPackages.contains('com.whatsapp')),
        AppInfo(name: 'Telegram', packageName: 'org.telegram.messenger', isSystemApp: false, isBypassed: bypassedPackages.contains('org.telegram.messenger')),
        AppInfo(name: 'Bank Mobile App', packageName: 'com.bank.mobile', isSystemApp: false, isBypassed: bypassedPackages.contains('com.bank.mobile')),
        AppInfo(name: 'YouTube', packageName: 'com.google.android.youtube', isSystemApp: false, isBypassed: bypassedPackages.contains('com.google.android.youtube')),
        AppInfo(name: 'Spotify', packageName: 'com.spotify.music', isSystemApp: false, isBypassed: bypassedPackages.contains('com.spotify.music')),
      ];
    }
  }
}
