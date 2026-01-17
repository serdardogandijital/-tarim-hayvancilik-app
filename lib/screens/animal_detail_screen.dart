import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/animal.dart';
import 'add_animal_screen.dart';

class AnimalDetailScreen extends StatelessWidget {
  final Animal animal;

  const AnimalDetailScreen({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(animal.name),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddAnimalScreen(animal: animal),
                ),
              );
              if (result != null && context.mounted) {
                Navigator.pop(context, result);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hayvanı Sil'),
                  content: Text('${animal.name} kaydını silmek istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, 'delete');
                      },
                      child: const Text('Sil', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.pets,
                          size: 30,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              animal.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${animal.type} - ${animal.breed}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            'Genel Bilgiler',
            [
              _buildInfoRow(Icons.cake, 'Doğum Tarihi',
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(animal.birthDate)),
              _buildInfoRow(Icons.calendar_today, 'Yaş', '${animal.ageInYears} yaşında'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            'Üreme Bilgileri',
            [
              if (animal.lastBirthDate != null)
                _buildInfoRow(
                  Icons.child_care,
                  'Son Doğum',
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(animal.lastBirthDate!),
                ),
              if (animal.daysSinceLastBirth != null)
                _buildInfoRow(
                  Icons.access_time,
                  'Son Doğumdan İtibaren',
                  '${animal.daysSinceLastBirth} gün',
                ),
              if (animal.nextHeatDate != null)
                _buildInfoRow(
                  Icons.event,
                  'Sonraki Öğüre',
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(animal.nextHeatDate!),
                ),
              if (animal.daysUntilNextHeat != null)
                _buildInfoRow(
                  Icons.timer,
                  'Kalan Süre',
                  animal.daysUntilNextHeat! > 0
                      ? '${animal.daysUntilNextHeat} gün'
                      : 'Bugün',
                  color: animal.daysUntilNextHeat! <= 7 ? Colors.orange : null,
                ),
            ],
          ),
          if (animal.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              'Notlar',
              [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    animal.notes,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
