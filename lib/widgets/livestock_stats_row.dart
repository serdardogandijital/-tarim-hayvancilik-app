import 'package:flutter/material.dart';
import '../models/animal.dart';

// 3 kompakt widget'ı yan yana gösteren row
class LivestockStatsRow extends StatelessWidget {
  final List<Animal> animals;

  const LivestockStatsRow({super.key, required this.animals});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AnimalStatsCard(animals: animals),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _UpcomingRemindersCard(animals: animals),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FeedCalculatorCard(animals: animals),
        ),
      ],
    );
  }
}

// 1. Hayvan İstatistikleri Widget'ı
class _AnimalStatsCard extends StatelessWidget {
  final List<Animal> animals;

  const _AnimalStatsCard({required this.animals});

  @override
  Widget build(BuildContext context) {
    final totalAnimals = animals.length;
    final avgAge = animals.isEmpty
        ? 0
        : animals.map((a) => a.ageInYears).reduce((a, b) => a + b) / animals.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 18, color: Colors.blue[700]),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'İstatistik',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatItem('Toplam', '$totalAnimals hayvan', Icons.pets),
          const SizedBox(height: 6),
          _buildStatItem('Ort. Yaş', '${avgAge.toStringAsFixed(1)} yıl', Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 2. Yaklaşan Hatırlatıcılar Widget'ı
class _UpcomingRemindersCard extends StatelessWidget {
  final List<Animal> animals;

  const _UpcomingRemindersCard({required this.animals});

  @override
  Widget build(BuildContext context) {
    final upcomingReminders = _getUpcomingReminders();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, size: 18, color: Colors.orange[700]),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Hatırlatıcı',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (upcomingReminders.isEmpty)
            Text(
              'Yaklaşan görev yok',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            )
          else
            ...upcomingReminders.take(2).map((reminder) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.orange[700],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reminder,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  List<String> _getUpcomingReminders() {
    final reminders = <String>[];
    for (var animal in animals) {
      // Kızgınlık hatırlatıcısı
      if (animal.daysUntilNextHeat != null && animal.daysUntilNextHeat! <= 7) {
        reminders.add('${animal.name}: ${animal.daysUntilNextHeat} gün sonra kızgınlık');
      }
      // Aşı hatırlatıcısı
      for (var vaccine in animal.vaccines) {
        if (vaccine.nextDate != null) {
          final daysUntil = vaccine.nextDate!.difference(DateTime.now()).inDays;
          if (daysUntil >= 0 && daysUntil <= 7) {
            reminders.add('${animal.name}: ${vaccine.name} aşısı');
          }
        }
      }
    }
    return reminders;
  }
}

// 3. Yem Hesaplayıcı Widget'ı
class _FeedCalculatorCard extends StatelessWidget {
  final List<Animal> animals;

  const _FeedCalculatorCard({required this.animals});

  @override
  Widget build(BuildContext context) {
    final totalDailyFeed = animals
        .where((a) => a.dailyFeedAmount != null)
        .fold<double>(0, (sum, a) => sum + a.dailyFeedAmount!);
    
    final totalMonthlyCost = animals
        .where((a) => a.monthlyFeedCost != null)
        .fold<double>(0, (sum, a) => sum + a.monthlyFeedCost!);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grass, size: 18, color: Colors.green[700]),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Yem',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFeedItem('Günlük', '${totalDailyFeed.toStringAsFixed(1)} kg'),
          const SizedBox(height: 6),
          _buildFeedItem('Aylık Maliyet', '${totalMonthlyCost.toStringAsFixed(0)} ₺'),
        ],
      ),
    );
  }

  Widget _buildFeedItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
