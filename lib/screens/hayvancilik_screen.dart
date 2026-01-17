import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../widgets/location_card.dart';
import '../widgets/livestock_stats_row.dart';
import '../widgets/livestock_animals_card.dart';
import '../services/location_storage_service.dart';
import '../services/animal_storage_service.dart';
import '../models/city.dart';
import 'city_selector_screen.dart';

class HayvancilikScreen extends StatefulWidget {
  const HayvancilikScreen({super.key});

  @override
  State<HayvancilikScreen> createState() => _HayvancilikScreenState();
}

class _HayvancilikScreenState extends State<HayvancilikScreen> {
  List<Animal> _animals = [];
  String? _selectedCity;
  String _currentAddress = 'Konum yükleniyor...';
  bool _isLoading = false;
  bool _isManualSelection = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
    _loadAnimals();
  }

  Future<void> _loadSavedLocation() async {
    final savedLocation = await LocationStorageService.loadLocation();
    
    if (savedLocation['city'] != null) {
      setState(() {
        _selectedCity = savedLocation['city'];
        _currentAddress = savedLocation['address'];
        _isManualSelection = savedLocation['isManual'];
      });
    }
  }

  Future<void> _selectCityManually() async {
    final selectedCity = await Navigator.push<City>(
      context,
      MaterialPageRoute(builder: (context) => const CitySelectorScreen()),
    );

    if (selectedCity != null) {
      await LocationStorageService.saveLocation(
        city: selectedCity.name,
        address: selectedCity.name,
        isManual: true,
      );
      
      setState(() {
        _selectedCity = selectedCity.name;
        _currentAddress = selectedCity.name;
        _isManualSelection = true;
      });
    }
  }

  Future<void> _loadAnimals() async {
    final loadedAnimals = await AnimalStorageService.loadAnimals();
    setState(() {
      _animals = loadedAnimals;
    });
  }

  Future<void> _addAnimal(Animal animal) async {
    await AnimalStorageService.addAnimal(animal);
    setState(() {
      _animals.add(animal);
    });
  }

  Future<void> _deleteAnimal(String id) async {
    await AnimalStorageService.deleteAnimal(id);
    setState(() {
      _animals.removeWhere((animal) => animal.id == id);
    });
  }

  Future<void> _updateAnimal(Animal updatedAnimal) async {
    await AnimalStorageService.updateAnimal(updatedAnimal);
    setState(() {
      final index = _animals.indexWhere((a) => a.id == updatedAnimal.id);
      if (index != -1) {
        _animals[index] = updatedAnimal;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      appBar: AppBar(
        title: const Text(
          'Hayvancılık',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LocationCard(
              address: _currentAddress,
              isLoading: _isLoading,
              onRefresh: () {}, // Hayvancılıkta GPS yok, sadece manuel
              onManualSelect: _selectCityManually,
              isManualSelection: _isManualSelection,
            ),
            const SizedBox(height: 16),
            LivestockStatsRow(animals: _animals),
            const SizedBox(height: 16),
            LivestockAnimalsCard(
              animals: _animals,
              onAnimalAdded: _addAnimal,
              onAnimalUpdated: _updateAnimal,
              onAnimalDeleted: _deleteAnimal,
            ),
          ],
        ),
      ),
    );
  }
}
