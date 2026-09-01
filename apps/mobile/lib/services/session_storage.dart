import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/shield_settings.dart';

/// Persists user session data using SharedPreferences, which is backed by
/// Android's SharedPreferences (XML in /data/data/<pkg>/shared_prefs/).
/// This survives app restarts, unlike the old Directory.systemTemp approach
/// which was cleared on many Android devices between launches.
class SessionStorage {
  static final SessionStorage _instance = SessionStorage._internal();
  factory SessionStorage() => _instance;
  SessionStorage._internal();

  static const String _sessionKey = 'argus_vpn_session';

  Future<void> saveSession({
    required String token,
    required UserModel user,
    required ArgusShieldSettings shieldSettings,
    List<String> bypassedPackages = const [],
    String selectedDnsId = 'cloudflare',
    String customPrimaryDns = '1.1.1.1',
    String customSecondaryDns = '1.0.0.1',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'token': token,
        'user': user.toJson(),
        'shieldSettings': shieldSettings.toJson(),
        'bypassedPackages': bypassedPackages,
        'selectedDnsId': selectedDnsId,
        'customPrimaryDns': customPrimaryDns,
        'customSecondaryDns': customSecondaryDns,
        'savedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_sessionKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_sessionKey);
      if (content == null || content.trim().isEmpty) return null;

      final map = jsonDecode(content) as Map<String, dynamic>;
      return map;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (_) {}
  }
}
