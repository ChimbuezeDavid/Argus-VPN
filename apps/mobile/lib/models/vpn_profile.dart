import 'server_model.dart';
import 'shield_settings.dart';

enum VpnState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class VpnProfile {
  final String sessionId;
  final ServerNode server;
  final String assignedVirtualIp;
  final List<String> dnsServers;
  final String serverPublicKey;
  final String endpoint;
  final ArgusShieldSettings shieldSettings;

  const VpnProfile({
    required this.sessionId,
    required this.server,
    required this.assignedVirtualIp,
    required this.dnsServers,
    required this.serverPublicKey,
    required this.endpoint,
    required this.shieldSettings,
  });

  factory VpnProfile.fromJson(Map<String, dynamic> json) {
    final config = json['config'] as Map<String, dynamic>;
    final interfaceConfig = config['interface'] as Map<String, dynamic>;
    final peerConfig = config['peer'] as Map<String, dynamic>;

    return VpnProfile(
      sessionId: json['sessionId'] as String,
      server: ServerNode.fromJson(json['server'] as Map<String, dynamic>),
      assignedVirtualIp: json['assignedVirtualIp'] as String,
      dnsServers: (interfaceConfig['dns'] as List<dynamic>).map((e) => e.toString()).toList(),
      serverPublicKey: peerConfig['publicKey'] as String,
      endpoint: peerConfig['endpoint'] as String,
      shieldSettings: json['shieldSettings'] != null
          ? ArgusShieldSettings.fromJson(json['shieldSettings'] as Map<String, dynamic>)
          : const ArgusShieldSettings(),
    );
  }
}
