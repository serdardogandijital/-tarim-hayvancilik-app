import '../widgets/farm_summary_card.dart';
import '../widgets/analysis_credits_card.dart';
import '../services/agenda_service.dart';
import '../services/safe_list_store.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather_data.dart';
import '../services/animal_storage_service.dart';
import '../services/field_storage_service.dart';
import '../services/location_storage_service.dart';
import '../services/weather_service.dart';
import '../widgets/live_scale_card.dart';
import '../widgets/plant_doctor_card.dart';
import 'ai_chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  final VoidCallback? onShowUpdateNotice;

  const DashboardScreen({
    super.key,
    this.onNavigateToTab,
    this.onShowUpdateNotice,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _city;
  WeatherData? _weather;
  int _fieldCount = 0;
  int _animalCount = 0;
  List<AgendaItem> _agenda = [];

  @override
  void initState() {
    super.initState();
    _loadSummary();
    SafeListStore.revision.addListener(_loadSummary);
  }

  @override
  void dispose() {
    SafeListStore.revision.removeListener(_loadSummary);
    super.dispose();
  }

  int _summaryRequest = 0;
  Future<void> _loadSummary() async {
    final request = ++_summaryRequest;
    final location = await LocationStorageService.loadLocation();
    final fields = await FieldStorageService.loadFields();
    final animals = await AnimalStorageService.loadAnimals();

    if (!mounted || request != _summaryRequest) return;
    setState(() {
      _city = location['city'];
      _fieldCount = fields.length;
      _animalCount = animals.length;
      _agenda = AgendaService.build(fields, animals);
      _isLoading = false;
    });
    final cityName = location['city'] as String?;
    final weather = cityName == null || cityName.isEmpty
        ? null
        : await WeatherService().getWeatherByCity(cityName);
    if (!mounted || request != _summaryRequest) return;
    setState(() => _weather = weather);
  }

  Widget _agendaTile(AgendaItem item, {bool inSheet = false}) {
    final days = item.daysFrom(DateTime.now());
    final dateLabel = days < 0
        ? '${-days} gün gecikti'
        : days == 0
        ? 'Bugün'
        : '$days gün sonra';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(
        item.tab == 0 ? Icons.agriculture : Icons.pets,
        color: days < 0 ? Colors.deepOrange : Colors.green,
      ),
      title: Text(item.title),
      subtitle: Text('${item.owner} · $dateLabel'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (inSheet) Navigator.pop(context);
        widget.onNavigateToTab?.call(item.tab);
      },
    );
  }

  void _showAgenda() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Bugün ve yaklaşan işler',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_agenda.isEmpty)
              const Text(
                'Önümüzdeki 7 gün için kayıtlı bir iş yok. Tarla görevlerinize veya hayvanlarınıza tarih ekleyerek başlayın.',
              ),
            ..._agenda.map((item) => _agendaTile(item, inSheet: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaCard() {
    final overdue = _agenda
        .where((item) => item.daysFrom(DateTime.now()) < 0)
        .length;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _showAgenda,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3DF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: Color(0xFF986A25),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yaklaşan işler',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF243C30),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _agenda.isEmpty
                          ? 'Önümüzdeki 7 gün için iş yok'
                          : overdue > 0
                          ? '$overdue geciken · ${_agenda.length} kayıtlı iş'
                          : '${_agenda.length} iş seni bekliyor',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF707B72),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF829085)),
            ],
          ),
        ),
      ),
    );
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
            icon: const Icon(Icons.new_releases_outlined),
            tooltip: 'Yenilikler',
            onPressed: widget.onShowUpdateNotice,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: const Color(0xFF8B8B8B),
            onPressed: _showAgenda,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSummary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LiveScaleCard(),
                const SizedBox(height: 16),
                const PlantDoctorCard(),
                const SizedBox(height: 16),
                const AnalysisCreditsCard(),
                const SizedBox(height: 24),
                const FarmSummaryCard(),
                const SizedBox(height: 12),
                _buildAgendaCard(),
                const SizedBox(height: 16),
                _buildOverviewCard(dateText),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AIChatScreen()),
          );
        },
        backgroundColor: Colors.green[600],
        icon: const Icon(Icons.medical_services, color: Colors.white),
        label: const Text(
          'Bakım Asistanı',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 4,
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
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildWeatherRow(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  'Tarlalar',
                  _fieldCount.toString(),
                  Icons.agriculture,
                  onTap: () {
                    // Tarım sayfasına git (index 0)
                    widget.onNavigateToTab?.call(0);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatChip(
                  'Hayvanlar',
                  _animalCount.toString(),
                  Icons.pets,
                  onTap: () {
                    // Hayvancılık sayfasına git (index 2)
                    widget.onNavigateToTab?.call(2);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildStatChip(
                  'İşler',
                  _agenda.length.toString(),
                  Icons.notifications_active,
                  onTap: _showAgenda,
                ),
              ),
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
          Text('Hava verisi yok', style: TextStyle(color: Colors.grey[700])),
        ],
      );
    }

    final weather = _weather!;
    return Row(
      children: [
        Icon(
          _mapWeatherIcon(weather.icon),
          color: Colors.orange[700],
          size: 20,
        ),
        const SizedBox(width: 6),
        Text(
          '${weather.temperature.toStringAsFixed(0)}°C',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            weather.description,
            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
          ),
        ),
        Text(
          'Nem %${weather.humidity}',
          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
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

  Widget _buildStatChip(
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: onTap != null
              ? Border.all(color: Colors.green.withOpacity(0.3), width: 1)
              : null,
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
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
