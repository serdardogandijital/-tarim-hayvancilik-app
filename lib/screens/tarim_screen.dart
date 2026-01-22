import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../widgets/weather_card.dart';
import '../widgets/planting_calendar_card.dart';
import '../widgets/location_card.dart';
import '../widgets/recommendations_card.dart';
import '../widgets/today_planting_card.dart';
import '../widgets/fields_carousel_card.dart';
import '../models/city.dart';
import '../models/field.dart';
import '../services/field_storage_service.dart';
import '../services/notification_service.dart';
import '../providers/location_notifier.dart';
import 'add_edit_field_screen.dart';
import 'all_fields_map_screen.dart';
import 'city_selector_screen.dart';

class TarimScreen extends StatefulWidget {
  const TarimScreen({super.key});

  @override
  State<TarimScreen> createState() => _TarimScreenState();
}

class _TarimScreenState extends State<TarimScreen> {
  // Tarla verileri
  List<Field> _fields = [];

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    final loadedFields = await FieldStorageService.loadFields();
    for (final field in loadedFields) {
      await NotificationService.instance.scheduleFieldNotifications(field);
    }
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
      await NotificationService.instance.scheduleFieldNotifications(result);
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

  Future<void> _openAllFieldsMap() async {
    final latestFields = await FieldStorageService.loadFields();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllFieldsMapScreen(fields: latestFields),
      ),
    );
  }

  Future<void> _updateField(Field updatedField) async {
    await FieldStorageService.updateField(updatedField);
    await NotificationService.instance.scheduleFieldNotifications(updatedField);
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
    await NotificationService.instance
        .cancelNotificationsForEntity(field.id, scopes: NotificationService.fieldScopes);
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

  Position? _positionFromLocation(LocationNotifier location) {
    if (location.latitude == null || location.longitude == null) return null;
    return Position(
      latitude: location.latitude!,
      longitude: location.longitude!,
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

  Future<void> _getCurrentLocation() async {
    final locationNotifier = context.read<LocationNotifier>();
    locationNotifier.setLoading(true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum servisi kapalı - Manuel seçim yapın.')),
        );
        locationNotifier.setLoading(false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum izni reddedildi - Manuel seçim yapın.')),
          );
          locationNotifier.setLoading(false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum izni kalıcı reddedildi - Manuel seçim yapın.')),
        );
        locationNotifier.setLoading(false);
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
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Simülatör konumu - Manuel seçim yapın.')),
          );
        } else {
          await locationNotifier.updateLocation(
            city: cityName,
            address: cityName.isNotEmpty ? cityName : 'Konum tespit edildi',
            latitude: position.latitude,
            longitude: position.longitude,
            isManual: false,
            notifyLoading: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konum alınamadı - Manuel seçim yapın.')),
        );
      }
    }
    if (mounted) {
      locationNotifier.setLoading(false);
    }
  }

  Future<void> _selectCityManually() async {
    final selectedCity = await Navigator.push<City>(
      context,
      MaterialPageRoute(builder: (context) => const CitySelectorScreen()),
    );

    if (selectedCity != null && mounted) {
      await context.read<LocationNotifier>().updateLocation(
            city: selectedCity.name,
            address: selectedCity.name,
            isManual: true,
            notifyLoading: false,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationNotifier>();
    final position = _positionFromLocation(location);
    final selectedCity = location.city;

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
                address: location.address,
                isLoading: location.isLoading,
                onRefresh: _getCurrentLocation,
                onManualSelect: _selectCityManually,
                isManualSelection: location.isManualSelection,
              ),
              const SizedBox(height: 16),
              TodayPlantingCard(selectedCity: selectedCity),
              const SizedBox(height: 16),
              FieldsCarouselCard(
                fields: _fields,
                onAddField: _addNewField,
                onFieldUpdated: _updateField,
                onFieldDeleted: _deleteField,
                onViewAllFields: _openAllFieldsMap,
              ),
              const SizedBox(height: 16),
              WeatherCard(
                position: position,
                selectedCity: selectedCity,
              ),
              const SizedBox(height: 16),
              PlantingCalendarCard(
                position: position,
                selectedCity: selectedCity,
              ),
              const SizedBox(height: 16),
              RecommendationsCard(
                position: position,
                selectedCity: selectedCity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
