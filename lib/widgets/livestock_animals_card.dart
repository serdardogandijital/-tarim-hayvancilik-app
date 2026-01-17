import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../screens/animal_detail_screen.dart';
import '../screens/add_animal_screen.dart';

class LivestockAnimalsCard extends StatelessWidget {
  final List<Animal> animals;
  final Function(Animal) onAnimalAdded;
  final Function(Animal) onAnimalUpdated;
  final Function(String) onAnimalDeleted;

  const LivestockAnimalsCard({
    super.key,
    required this.animals,
    required this.onAnimalAdded,
    required this.onAnimalUpdated,
    required this.onAnimalDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.pets,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hayvanlarım',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${animals.length} hayvan kayıtlı',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _addAnimal(context),
                color: Theme.of(context).colorScheme.primary,
                tooltip: 'Hayvan Ekle',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (animals.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.pets_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz hayvan kaydı yok',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _addAnimal(context),
                      icon: const Icon(Icons.add),
                      label: const Text('İlk Hayvanı Ekle'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Column(
              children: animals
                  .take(3)
                  .map((animal) => _buildAnimalItem(context, animal))
                  .toList(),
            ),
            if (animals.length > 3) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showAllAnimals(context),
                  child: const Text('Tümünü Gör'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAnimalItem(BuildContext context, Animal animal) {
    return GestureDetector(
      onTap: () => _openAnimalDetail(context, animal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _buildAnimalEmoji(
                  animal.type,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${animal.type} • ${animal.breed}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (animal.nextHeatDate != null)
                    Text(
                      '${animal.daysUntilNextHeat} gün sonra kızgınlık',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[700],
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalEmoji(String type, Color color) {
    final lowerType = type.toLowerCase();

    String emoji = '🐾';
    if (lowerType.contains('inek') ||
        lowerType.contains('dana') ||
        lowerType.contains('tosun') ||
        lowerType.contains('boğa') ||
        lowerType.contains('düve') ||
        lowerType.contains('manda') ||
        lowerType.contains('öküz')) {
      emoji = '🐄';
    } else if (lowerType.contains('koyun') ||
        lowerType.contains('koç') ||
        lowerType.contains('kuzu') ||
        lowerType.contains('toklu')) {
      emoji = '🐑';
    } else if (lowerType.contains('keçi') ||
        lowerType.contains('oğlak') ||
        lowerType.contains('teke')) {
      emoji = '🐐';
    } else if (lowerType.contains('tavuk') ||
        lowerType.contains('horoz') ||
        lowerType.contains('civciv')) {
      emoji = '🐔';
    } else if (lowerType.contains('ördek')) {
      emoji = '🦆';
    } else if (lowerType.contains('hindi')) {
      emoji = '🦃';
    } else if (lowerType.contains('arı')) {
      emoji = '🐝';
    }

    return Text(
      emoji,
      style: TextStyle(fontSize: 26, color: color),
    );
  }

  Future<void> _addAnimal(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddAnimalScreen(),
      ),
    );
    if (result != null && result is Animal) {
      onAnimalAdded(result);
    }
  }

  Future<void> _openAnimalDetail(BuildContext context, Animal animal) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimalDetailScreen(animal: animal),
      ),
    );
    if (result != null) {
      if (result == 'delete') {
        onAnimalDeleted(animal.id);
      } else if (result is Animal) {
        onAnimalUpdated(result);
      }
    }
  }

  void _showAllAnimals(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.9,
        initialChildSize: 0.8,
        minChildSize: 0.5,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tüm Hayvanlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: animals.length,
                  itemBuilder: (context, index) {
                    final animal = animals[index];
                    return _buildAnimalItem(context, animal);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
