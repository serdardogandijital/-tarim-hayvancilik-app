import 'package:shared_preferences/shared_preferences.dart';

class LocationStorageService {
  static const String _cityKey = 'selected_city';
  static const String _addressKey = 'current_address';
  static const String _latitudeKey = 'latitude';
  static const String _longitudeKey = 'longitude';
  static const String _isManualKey = 'is_manual_selection';

  // Konum bilgilerini kaydet
  static Future<void> saveLocation({
    required String? city,
    required String address,
    double? latitude,
    double? longitude,
    required bool isManual,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (city != null) {
      await prefs.setString(_cityKey, city);
    } else {
      await prefs.remove(_cityKey);
    }
    
    await prefs.setString(_addressKey, address);
    await prefs.setBool(_isManualKey, isManual);
    
    if (latitude != null && longitude != null) {
      await prefs.setDouble(_latitudeKey, latitude);
      await prefs.setDouble(_longitudeKey, longitude);
    } else {
      await prefs.remove(_latitudeKey);
      await prefs.remove(_longitudeKey);
    }
  }

  // Konum bilgilerini yükle
  static Future<Map<String, dynamic>> loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'city': prefs.getString(_cityKey),
      'address': prefs.getString(_addressKey) ?? 'Konum alınıyor...',
      'latitude': prefs.getDouble(_latitudeKey),
      'longitude': prefs.getDouble(_longitudeKey),
      'isManual': prefs.getBool(_isManualKey) ?? false,
    };
  }

  // Şehir bilgisini al
  static Future<String?> getSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cityKey);
  }

  // Konum bilgilerini temizle
  static Future<void> clearLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cityKey);
    await prefs.remove(_addressKey);
    await prefs.remove(_latitudeKey);
    await prefs.remove(_longitudeKey);
    await prefs.remove(_isManualKey);
  }
}
