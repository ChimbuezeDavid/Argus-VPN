class ApiConfig {
  // PC Local Wi-Fi Network Address (Active)
  static const String lanHostUrl = 'http://10.251.69.205:4000';
  // ADB Reverse / Localhost
  static const String localDesktopUrl = 'http://127.0.0.1:4000';
  // Android Emulator default
  static const String emulatorUrl = 'http://10.0.2.2:4000';

  // Active default Base URL (Primary LAN Wi-Fi with auto-fallback)
  static String defaultBaseUrl = lanHostUrl;

  // Auth endpoints
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String guest = '/api/auth/guest';

  // Server discovery
  static const String servers = '/api/servers';

  // Shield content filtering
  static const String shieldSettings = '/api/shield/settings';

  // VPN Connection Orchestration
  static const String vpnConnect = '/api/vpn/connect';
  static const String vpnDisconnect = '/api/vpn/disconnect';
}
