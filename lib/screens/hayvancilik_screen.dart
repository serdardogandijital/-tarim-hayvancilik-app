import 'dart:async';

import '../services/safe_list_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/animal.dart';
import '../widgets/location_card.dart';
import '../widgets/livestock_stats_row.dart';
import '../widgets/livestock_animals_card.dart';
import '../services/animal_storage_service.dart';
import '../services/notification_service.dart';
import '../models/city.dart';
import '../widgets/livestock_weather_alert.dart';
import '../providers/location_notifier.dart';
import 'city_selector_screen.dart';

class HayvancilikScreen extends StatefulWidget {
  const HayvancilikScreen({super.key});

  @override
  State<HayvancilikScreen> createState() => _HayvancilikScreenState();
}

class _HayvancilikScreenState extends State<HayvancilikScreen> {
  List<Animal> _animals = [];

  @override
  void initState() {
    super.initState();
    _loadAnimals();
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

  Future<void> _loadAnimals() async {
    final loadedAnimals = await AnimalStorageService.loadAnimals();
    if (!mounted) return;
    setState(() {
      _animals = loadedAnimals;
    });
    unawaited(_scheduleAnimalNotifications(loadedAnimals));
  }

  Future<void> _scheduleAnimalNotifications(List<Animal> animals) async {
    for (final animal in animals) {
      await NotificationService.instance.scheduleAnimalNotifications(animal);
    }
  }

  Future<void> _addAnimal(Animal animal) async {
    try {
      await AnimalStorageService.addAnimal(animal);
      await NotificationService.instance.scheduleAnimalNotifications(animal);
      if (!mounted) return;
      setState(() {
        _animals.add(animal);
      });
    } on StorageFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _deleteAnimal(String id) async {
    try {
      await AnimalStorageService.deleteAnimal(id);
      await NotificationService.instance.cancelNotificationsForEntity(
        id,
        scopes: NotificationService.animalScopes,
      );
      if (!mounted) return;
      setState(() {
        _animals.removeWhere((animal) => animal.id == id);
      });
    } on StorageFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _updateAnimal(Animal updatedAnimal) async {
    try {
      await AnimalStorageService.updateAnimal(updatedAnimal);
      await NotificationService.instance.scheduleAnimalNotifications(
        updatedAnimal,
      );
      if (!mounted) return;
      setState(() {
        final index = _animals.indexWhere((a) => a.id == updatedAnimal.id);
        if (index != -1) {
          _animals[index] = updatedAnimal;
        }
      });
    } on StorageFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationNotifier>();
    final selectedCity = location.city;

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LocationCard(
              address: location.address,
              isLoading: location.isLoading,
              onRefresh: () {}, // Hayvancılıkta GPS yok, sadece manuel
              onManualSelect: _selectCityManually,
              isManualSelection: location.isManualSelection,
            ),
            const SizedBox(height: 16),
            LivestockStatsRow(animals: _animals),
            const SizedBox(height: 16),
            LivestockAnimalsCard(
              animals: _animals,
              onAnimalAdded: _addAnimal,
              onRecordsChanged: _loadAnimals,
              onAnimalUpdated: _updateAnimal,
              onAnimalDeleted: _deleteAnimal,
            ),
            const SizedBox(height: 16),
            LivestockWeatherAlert(city: selectedCity),
          ],
        ),
      ),
    );
  }
}
