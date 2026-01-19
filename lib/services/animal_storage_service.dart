import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animal.dart';

class AnimalStorageService {
  static const String _animalsKey = 'animals_data';
  static const String _isInitializedKey = 'animals_initialized';

  // Hayvanları kaydet
  static Future<void> saveAnimals(List<Animal> animals) async {
    final prefs = await SharedPreferences.getInstance();
    final animalsJson = animals.map((animal) => animal.toJson()).toList();
    await prefs.setString(_animalsKey, jsonEncode(animalsJson));
  }

  // Hayvanları yükle
  static Future<List<Animal>> loadAnimals() async {
    final prefs = await SharedPreferences.getInstance();
    final animalsString = prefs.getString(_animalsKey);
    final isInitialized = prefs.getBool(_isInitializedKey) ?? false;
    
    // İlk açılışta initialized olarak işaretle
    if (!isInitialized) {
      await prefs.setBool(_isInitializedKey, true);
    }
    
    if (animalsString == null || animalsString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> animalsJson = jsonDecode(animalsString);
      return animalsJson.map((json) => Animal.fromJson(json)).toList();
    } catch (e) {
      print('Hayvan verileri yüklenirken hata: $e');
      return [];
    }
  }

  // Tek bir hayvanı güncelle
  static Future<void> updateAnimal(Animal updatedAnimal) async {
    final animals = await loadAnimals();
    final index = animals.indexWhere((a) => a.id == updatedAnimal.id);
    if (index != -1) {
      animals[index] = updatedAnimal;
      await saveAnimals(animals);
    }
  }

  // Hayvan ekle
  static Future<void> addAnimal(Animal animal) async {
    final animals = await loadAnimals();
    animals.add(animal);
    await saveAnimals(animals);
  }

  // Hayvan sil
  static Future<void> deleteAnimal(String animalId) async {
    final animals = await loadAnimals();
    animals.removeWhere((a) => a.id == animalId);
    await saveAnimals(animals);
  }

  // Tüm verileri temizle
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_animalsKey);
  }
}
