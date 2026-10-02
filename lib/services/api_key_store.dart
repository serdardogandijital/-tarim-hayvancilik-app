import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Personal keys belong in the OS keychain, never in the application bundle.
class ApiKeyStore {
  static const _key = 'openai_api_key';
  static const _storage = FlutterSecureStorage();

  static Future<String?> read() async {
    final stored = await _storage.read(key: _key);
    final prefs = await SharedPreferences.getInstance();
    if (stored != null && stored.isNotEmpty) {
      await prefs.remove(_key);
      return stored;
    }
    final legacy = prefs.getString(_key)?.trim();
    if (legacy == null || legacy.isEmpty) return null;
    // Remove the legacy copy only after a successful keychain write.
    await _storage.write(key: _key, value: legacy);
    await prefs.remove(_key);
    return legacy;
  }

  static Future<void> write(String value) async {
    if (value.trim().isEmpty) return clear();
    await _storage.write(key: _key, value: value.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await _storage.delete(key: _key);
  }
}
