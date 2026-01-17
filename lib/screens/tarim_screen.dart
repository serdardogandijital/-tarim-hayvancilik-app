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
  
  // Demo tarla verileri
  late List<Field> _fields;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initializeDemoFields();
  }

  void _initializeDemoFields() {
    _fields = [
      Field(
        id: '1',
        name: 'Tarla 1',
        area: 2.5,
        currentCrop: 'Buğday',
        plantingDate: DateTime(2025, 10, 15),
        harvestDate: DateTime(2026, 6, 25),
        tasks: [
          Task(
            id: '1',
            title: 'Toprak hazırlığı',
            isCompleted: true,
            category: TaskCategory.beforePlanting,
          ),
          Task(
            id: '2',
            title: 'Gübreleme',
            isCompleted: true,
            category: TaskCategory.beforePlanting,
          ),
          Task(
            id: '3',
            title: 'Ekim',
            isCompleted: true,
            category: TaskCategory.planting,
          ),
          Task(
            id: '4',
            title: 'İlaçlama',
            dueDate: DateTime(2026, 3, 15),
            isCompleted: false,
            category: TaskCategory.afterPlanting,
          ),
          Task(
            id: '5',
            title: 'Hasat',
            dueDate: DateTime(2026, 6, 25),
            isCompleted: false,
            category: TaskCategory.harvest,
          ),
        ],
      ),
      Field(
        id: '2',
        name: 'Tarla 2',
        area: 1.8,
        currentCrop: 'Mısır',
        plantingDate: DateTime(2025, 5, 10),
        harvestDate: DateTime(2025, 9, 20),
        tasks: [
          Task(
            id: '6',
            title: 'Toprak analizi',
            isCompleted: true,
            category: TaskCategory.beforePlanting,
          ),
          Task(
            id: '7',
            title: 'Ekim',
            isCompleted: true,
            category: TaskCategory.planting,
          ),
          Task(
            id: '8',
            title: 'Sulama sistemi kurulumu',
            dueDate: DateTime(2025, 6, 1),
            isCompleted: false,
            category: TaskCategory.afterPlanting,
          ),
          Task(
            id: '9',
            title: 'Yabani ot temizliği',
            dueDate: DateTime(2025, 7, 15),
            isCompleted: false,
            category: TaskCategory.maintenance,
          ),
          Task(
            id: '10',
            title: 'Hasat',
            dueDate: DateTime(2025, 9, 20),
            isCompleted: false,
            category: TaskCategory.harvest,
          ),
        ],
      ),
      Field(
        id: '3',
        name: 'Tarla 3',
        area: 3.0,
      ),
    ];
  }

  Future<void> _addNewField() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditFieldScreen(),
      ),
    );
    
    if (result != null && result is Field) {
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

  void _updateField(Field updatedField) {
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

  void _deleteField(Field field) {
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
    final City? selectedCity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CitySelectorScreen(),
      ),
    );

    if (selectedCity != null) {
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
