import 'package:flutter/material.dart';

import '../services/location_storage_service.dart';

class LocationNotifier extends ChangeNotifier {
  String? _city;
  String _address = 'Konum alınıyor...';
  double? _latitude;
  double? _longitude;
  bool _isManual = false;
  bool _isLoading = true;

  LocationNotifier() {
    loadSavedLocation();
  }

  String? get city => _city;
  String get address => _address;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isManualSelection => _isManual;
  bool get isLoading => _isLoading;

  Future<void> loadSavedLocation() async {
    _setLoading(true);
    final savedLocation = await LocationStorageService.loadLocation();
    _city = savedLocation['city'];
    _address = savedLocation['address'];
    _latitude = savedLocation['latitude'];
    _longitude = savedLocation['longitude'];
    _isManual = savedLocation['isManual'] ?? false;
    _setLoading(false);
  }

  Future<void> updateLocation({
    required String? city,
    required String address,
    double? latitude,
    double? longitude,
    required bool isManual,
    bool notifyLoading = true,
    bool persist = true,
  }) async {
    if (notifyLoading) {
      _setLoading(true);
    }

    if (persist) {
      await LocationStorageService.saveLocation(
        city: city,
        address: address,
        latitude: latitude,
        longitude: longitude,
        isManual: isManual,
      );
    }

    _city = city;
    _address = address;
    _latitude = latitude;
    _longitude = longitude;
    _isManual = isManual;

    if (notifyLoading) {
      _setLoading(false);
    } else {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void setLoading(bool value) => _setLoading(value);
}
