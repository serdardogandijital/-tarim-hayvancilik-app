import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../widgets/animal_card.dart';
import 'add_animal_screen.dart';
import 'animal_detail_screen.dart';

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

  void _loadAnimals() {
    setState(() {
      _animals = [
        Animal(
          id: '1',
          name: 'Sarıkız',
          type: 'İnek',
          breed: 'Montofon',
          birthDate: DateTime(2020, 3, 15),
          lastBirthDate: DateTime(2023, 5, 20),
          nextHeatDate: DateTime.now().add(const Duration(days: 45)),
          notes: 'Sağlıklı, düzenli süt veriyor',
        ),
        Animal(
          id: '2',
          name: 'Pamuk',
          type: 'Koyun',
          breed: 'Merinos',
          birthDate: DateTime(2021, 2, 10),
          lastBirthDate: DateTime(2024, 1, 5),
          nextHeatDate: DateTime.now().add(const Duration(days: 30)),
          notes: 'İkiz doğurdu',
        ),
      ];
    });
  }

  void _addAnimal(Animal animal) {
    setState(() {
      _animals.add(animal);
    });
  }

  void _deleteAnimal(String id) {
    setState(() {
      _animals.removeWhere((animal) => animal.id == id);
    });
  }

  void _updateAnimal(Animal updatedAnimal) {
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Hayvancılık'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddAnimalScreen(),
                ),
              );
              if (result != null && result is Animal) {
                _addAnimal(result);
              }
            },
          ),
        ],
      ),
      body: _animals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz hayvan kaydı yok',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sağ üstteki + butonuna tıklayarak\nhayvan ekleyebilirsiniz',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _animals.length,
              itemBuilder: (context, index) {
                final animal = _animals[index];
                return AnimalCard(
                  animal: animal,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimalDetailScreen(
                          animal: animal,
                        ),
                      ),
                    );
                    if (result != null) {
                      if (result == 'delete') {
                        _deleteAnimal(animal.id);
                      } else if (result is Animal) {
                        _updateAnimal(result);
                      }
                    }
                  },
                );
              },
            ),
    );
  }
}
