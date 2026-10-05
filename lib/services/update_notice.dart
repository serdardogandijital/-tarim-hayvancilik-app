import 'package:shared_preferences/shared_preferences.dart';

class UpdateNotice {
  static const version = '1.1.1';
  static const _seenKey = 'update_notice_seen_version';
  static const _legacyKeys = {
    'fields_data',
    'animals_data',
    'plant_analyses',
    'fields_initialized',
    'animals_initialized',
    'selected_city',
    'current_address',
    'openai_api_key',
    'notification_schema',
  };

  static Future<bool> shouldShowAutomatically() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_seenKey) == version) return false;
      final hasPreviousUse =
          prefs.getString(_seenKey) != null ||
          prefs.getKeys().any(_legacyKeys.contains);
      if (!hasPreviousUse) await prefs.setString(_seenKey, version);
      return hasPreviousUse;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seenKey, version);
    } catch (_) {
      // A notice must never prevent the app from opening.
    }
  }
}
