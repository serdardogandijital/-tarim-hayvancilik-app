import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_key_store.dart';

enum AnalysisProvider { openAi, gemini }

class AnalysisCredential {
  const AnalysisCredential(this.provider, this.key);
  final AnalysisProvider provider;
  final String key;
}

class AnalysisProviderStore {
  static const _providerKey = 'analysis_provider_v1';
  static const _geminiKey = 'gemini_api_key';
  static const _secure = FlutterSecureStorage();

  static Future<String?> readGeminiKey() async {
    final key = await _secure.read(key: _geminiKey);
    return key == null || key.trim().isEmpty ? null : key.trim();
  }

  static Future<void> saveGeminiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) throw ArgumentError('Gemini anahtarı boş olamaz');
    await _secure.write(key: _geminiKey, value: trimmed);
    if (!await select(AnalysisProvider.gemini)) {
      throw StateError('Gemini sağlayıcısı seçilemedi');
    }
  }

  static Future<void> deleteGeminiKey() async {
    await _secure.delete(key: _geminiKey);
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_providerKey) == AnalysisProvider.gemini.name) {
      await prefs.remove(_providerKey);
    }
  }

  static Future<AnalysisProvider> selected() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_providerKey);
    if (saved == AnalysisProvider.gemini.name) return AnalysisProvider.gemini;
    return AnalysisProvider.openAi;
  }

  static Future<bool> select(AnalysisProvider provider) async {
    final key = provider == AnalysisProvider.gemini
        ? await readGeminiKey()
        : await ApiKeyStore.read();
    if (key == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_providerKey, provider.name);
  }

  static Future<AnalysisCredential?> resolve() async {
    final provider = await selected();
    final key = provider == AnalysisProvider.gemini
        ? await readGeminiKey()
        : await ApiKeyStore.read();
    return key == null ? null : AnalysisCredential(provider, key);
  }
}
