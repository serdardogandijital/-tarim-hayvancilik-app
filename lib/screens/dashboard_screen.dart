import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/animal.dart';
import '../models/field.dart';
import '../models/weather_data.dart';
import '../services/animal_storage_service.dart';
import '../services/field_storage_service.dart';
import '../services/location_storage_service.dart';
import '../services/weather_service.dart';
import '../widgets/live_scale_card.dart';
import 'gallery_scale_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _city;
  WeatherData? _weather;
  int _fieldCount = 0;
  int _animalCount = 0;
  int _upcomingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final location = await LocationStorageService.loadLocation();
    final fields = await FieldStorageService.loadFields();
    final animals = await AnimalStorageService.loadAnimals();

    WeatherData? weather;
    try {
      final cityName = location['city'] as String?;
      if (cityName != null && cityName.isNotEmpty) {
        weather = await WeatherService().getWeatherByCity(cityName);
      }
    } catch (_) {}

    final upcoming = _calculateUpcoming(fields, animals);

    if (mounted) {
      setState(() {
        _city = location['city'];
        _weather = weather;
        _fieldCount = fields.length;
        _animalCount = animals.length;
        _upcomingCount = upcoming;
        _isLoading = false;
      });
    }
  }

  int _calculateUpcoming(List<Field> fields, List<Animal> animals) {
    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 7));

    int count = 0;

    for (final field in fields) {
      for (final task in field.tasks) {
        if (!task.isCompleted && task.dueDate != null) {
          final date = task.dueDate!;
          if (!date.isBefore(now) && !date.isAfter(horizon)) {
            count++;
          }
        }
      }
    }

    for (final animal in animals) {
      if (animal.nextHeatDate != null) {
        final date = animal.nextHeatDate!;
        if (!date.isBefore(now) && !date.isAfter(horizon)) {
          count++;
        }
      }
      for (final vaccine in animal.vaccines) {
        if (vaccine.nextDate != null) {
          final date = vaccine.nextDate!;
          if (!date.isBefore(now) && !date.isAfter(horizon)) {
            count++;
          }
        }
      }
    }

    return count;
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('d MMMM yyyy', 'tr_TR').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E8),
      appBar: AppBar(
        title: const Text(
          'Ana Sayfa',
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildOverviewCard(dateText),
              const SizedBox(height: 16),
              const LiveScaleCard(),
              const SizedBox(height: 12),
              _buildGalleryButton(),
              const SizedBox(height: 16),
              Text(
                'Yakında burada daha fazla özet kartı göstereceğiz.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GalleryScaleScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[300]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: Colors.green[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Galeriden Görsel ile Canlı Baskül Tahmini',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String dateText) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFcdeccb), Color(0xFFf3fff1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
            children: [
              Icon(Icons.place, size: 16, color: Colors.green[800]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _city ?? 'Konum seçilmedi',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                dateText,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildWeatherRow(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStatChip('Tarlalar', _fieldCount.toString(), Icons.agriculture)),
              const SizedBox(width: 6),
              Expanded(child: _buildStatChip('Hayvanlar', _animalCount.toString(), Icons.pets)),
              const SizedBox(width: 6),
              Expanded(child: _buildStatChip('Yaklaşan', _upcomingCount.toString(), Icons.notifications_active)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherRow() {
    if (_isLoading) {
      return Row(
        children: const [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Özet yükleniyor...'),
        ],
      );
    }

    if (_weather == null) {
      return Row(
        children: [
          Icon(Icons.wb_sunny_outlined, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Text(
            'Hava verisi yok',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      );
    }

    final weather = _weather!;
    return Row(
      children: [
        Icon(_mapWeatherIcon(weather.icon), color: Colors.orange[700], size: 20),
        const SizedBox(width: 6),
        Text(
          '${weather.temperature.toStringAsFixed(0)}°C',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            weather.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ),
        Text(
          'Nem %${weather.humidity}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  IconData _mapWeatherIcon(String? iconCode) {
    switch (iconCode) {
      case '01d':
        return Icons.wb_sunny;
      case '02d':
      case '03d':
        return Icons.wb_cloudy;
      case '09d':
      case '10d':
        return Icons.grain;
      case '11d':
        return Icons.flash_on;
      case '13d':
        return Icons.ac_unit;
      case '50d':
        return Icons.blur_on;
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  Widget _buildStatChip(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green[700]),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
