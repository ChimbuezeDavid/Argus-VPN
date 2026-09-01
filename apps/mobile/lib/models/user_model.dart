import 'shield_settings.dart';

class UserModel {
  final String id;
  final String email;
  final String tier;
  final int activeDevicesCount;
  final int maxAllowedDevices;
  final ArgusShieldSettings shieldSettings;

  const UserModel({
    required this.id,
    required this.email,
    required this.tier,
    required this.activeDevicesCount,
    required this.maxAllowedDevices,
    required this.shieldSettings,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      tier: json['tier'] as String? ?? 'FREE',
      activeDevicesCount: json['activeDevicesCount'] as int? ?? 1,
      maxAllowedDevices: json['maxAllowedDevices'] as int? ?? 5,
      shieldSettings: json['shieldSettings'] != null
          ? ArgusShieldSettings.fromJson(json['shieldSettings'] as Map<String, dynamic>)
          : const ArgusShieldSettings(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'tier': tier,
      'activeDevicesCount': activeDevicesCount,
      'maxAllowedDevices': maxAllowedDevices,
      'shieldSettings': shieldSettings.toJson(),
    };
  }
}
