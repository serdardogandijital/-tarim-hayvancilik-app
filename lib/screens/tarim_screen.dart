import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../widgets/weather_card.dart';
import '../widgets/planting_calendar_card.dart';
import '../widgets/location_card.dart';
import '../widgets/recommendations_card.dart';
import '../widgets/today_planting_card.dart';
import '../widgets/fields_carousel_card.dart';
import '../models/city.dart';
import '../models/field.dart';
import '../services/field_storage_service.dart';
import '../services/location_storage_service.dart';
import 'city_selector_screen.dart';
import 'add_edit_field_screen.dart';

class TarimScreen extends StatefulWidget {
  const TarimScreen({super.key});

  @override
  State<TarimScreen> createState() => _TarimScreenState();
}

class _TarimScreenState extends State<TarimScreen> {
  Position? _currentPosition;
  String _currentAddress = 'Konum alınıyor...';
  String? _selectedCity;
  bool _isLoading = true;
  bool _isManualSelection = false;
  
  // Tarla verileri
  List<Field> _fields = [];

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
    _loadFields();
  }

  Future<void> _loadSavedLocation() async {
    final savedLocation = await LocationStorageService.loadLocation();
    
    if (savedLocation['city'] != null) {
      // Kayıtlı konum var, onu kullan
      setState(() {
        _selectedCity = savedLocation['city'];
        _currentAddress = savedLocation['address'];
        _isManualSelection = savedLocation['isManual'];
        _isLoading = false;
        
        if (savedLocation['latitude'] != null && savedLocation['longitude'] != null) {
          _currentPosition = Position(
            latitude: savedLocation['latitude'],
            longitude: savedLocation['longitude'],
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
      });
    } else {
      // Kayıtlı konum yok, otomatik al
      _getCurrentLocation();
    }
  }

  Future<void> _loadFields() async {
    final loadedFields = await FieldStorageService.loadFields();
    setState(() {
      _fields = loadedFields;
    });
  }

  Future<void> _addNewField() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditFieldScreen(),
      ),
    );
    
    if (result != null && result is Field) {
      await FieldStorageService.addField(result);
      setState(() {
        _fields.add(result);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.name} eklendi!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateField(Field updatedField) async {
    await FieldStorageService.updateField(updatedField);
    setState(() {
      final index = _fields.indexWhere((f) => f.id == updatedField.id);
      if (index != -1) {
        _fields[index] = updatedField;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${updatedField.name} güncellendi!'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteField(Field field) async {
    await FieldStorageService.deleteField(field.id);
    setState(() {
      _fields.removeWhere((f) => f.id == field.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${field.name} silindi!'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _isManualSelection = false;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = 'Konum servisi kapalı - Manuel seçim yapın';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = 'Konum izni reddedildi - Manuel seçim yapın';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentAddress = 'Konum izni kalıcı olarak reddedildi - Manuel seçim yapın';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String cityName = place.administrativeArea ?? place.locality ?? '';
        String country = place.country ?? '';
        
        if (country != 'Turkey' && country != 'Türkiye' && cityName.length <= 3) {
          setState(() {
            _currentAddress = 'Simülatör konumu - Manuel seçim yapın';
            _isLoading = false;
          });
        } else {
          // Konumu kaydet
          await LocationStorageService.saveLocation(
            city: cityName,
            address: cityName.isNotEmpty ? cityName : 'Konum tespit edildi',
            latitude: position.latitude,
            longitude: position.longitude,
            isManual: false,
          );
          
          setState(() {
            _currentPosition = position;
            _selectedCity = cityName;
            _currentAddress = cityName.isNotEmpty ? cityName : 'Konum tespit edildi';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Konum alınamadı - Manuel seçim yapın';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCityManually() async {
    final selectedCity = await Navigator.push<City>(
      context,
      MaterialPageRoute(builder: (context) => const CitySelectorScreen()),
    );

    if (selectedCity != null) {
      // Manuel seçimi kaydet
      await LocationStorageService.saveLocation(
        city: selectedCity.name,
        address: selectedCity.name,
        isManual: true,
      );
      
      setState(() {
        _selectedCity = selectedCity.name;
        _currentAddress = selectedCity.name;
        _isManualSelection = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      appBar: AppBar(
        title: const Text(
          'Tarım Takvimi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Color(0xFF8B8B8B),
          ),
        ),
        backgroundColor: const Color(0xFFF5F1E8),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: const Color(0xFF8B8B8B),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _getCurrentLocation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocationCard(
                address: _currentAddress,
                isLoading: _isLoading,
                onRefresh: _getCurrentLocation,
                onManualSelect: _selectCityManually,
                isManualSelection: _isManualSelection,
              ),
              const SizedBox(height: 16),
              TodayPlantingCard(selectedCity: _selectedCity),
              const SizedBox(height: 16),
              FieldsCarouselCard(
                fields: _fields,
                onAddField: _addNewField,
                onFieldUpdated: _updateField,
                onFieldDeleted: _deleteField,
              ),
              const SizedBox(height: 16),
              WeatherCard(
                position: _currentPosition,
                selectedCity: _selectedCity,
              ),
              const SizedBox(height: 16),
              PlantingCalendarCard(
                position: _currentPosition,
                selectedCity: _selectedCity,
              ),
              const SizedBox(height: 16),
              RecommendationsCard(
                position: _currentPosition,
                selectedCity: _selectedCity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
