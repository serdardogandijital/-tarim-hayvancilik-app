import 'package:flutter/material.dart';

import '../models/weather_data.dart';
import '../services/weather_service.dart';

class LivestockWeatherAlert extends StatefulWidget {
  final String? city;

  const LivestockWeatherAlert({super.key, this.city});

  @override
  State<LivestockWeatherAlert> createState() => _LivestockWeatherAlertState();
}

class _LivestockWeatherAlertState extends State<LivestockWeatherAlert> {
  final WeatherService _weatherService = WeatherService();
  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  @override
  void didUpdateWidget(covariant LivestockWeatherAlert oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city) {
      _fetchWeather();
    }
  }

  Future<void> _fetchWeather() async {
    if (widget.city == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final multipleWeather =
          await _weatherService.getMultipleSourcesWeather(widget.city!);
      final weather = _weatherService.getAverageWeather(multipleWeather);

      setState(() {
        _weatherData = weather;
        _isLoading = false;
        if (weather == null) {
          _error = 'Hava verisi alınamadı.';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Hava verisi alınamadı.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.city == null) {
      return _MessageBanner(
        icon: Icons.location_city,
        title: 'Konum seçerek hava uyarılarını görün',
        description: 'Şehir seçtiğinizde hayvan sağlığı için kritik uyarıları burada göstereceğiz.',
        gradient: [
          Theme.of(context).colorScheme.primary.withOpacity(0.15),
          Theme.of(context).colorScheme.primary.withOpacity(0.05),
        ],
      );
    }

    if (_isLoading) {
      return _MessageBanner(
        icon: Icons.cloud_outlined,
        title: 'Hava durumu yükleniyor',
        description: 'Şehriniz için son meteoroloji verileri getiriliyor...',
        showProgress: true,
        gradient: [
          Theme.of(context).colorScheme.primary.withOpacity(0.15),
          Theme.of(context).colorScheme.primary.withOpacity(0.05),
        ],
      );
    }

    if (_error != null || _weatherData == null) {
      return _MessageBanner(
        icon: Icons.error_outline,
        title: 'Hava verisi alınamadı',
        description: 'Lütfen daha sonra tekrar deneyin.',
        gradient: [Colors.grey.shade200, Colors.grey.shade100],
      );
    }

    final alert = _buildAlert(_weatherData!);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: alert.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: alert.gradient.last.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(alert.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _factChip('${_weatherData!.temperature.toStringAsFixed(1)}°C', 'Sıcaklık'),
                    _factChip('${_weatherData!.humidity}%','Nem'),
                    _factChip('${(_weatherData!.windSpeed * 3.6).toStringAsFixed(0)} km/sa','Rüzgar'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _factChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  _AlertInfo _buildAlert(WeatherData data) {
    final temp = data.temperature;
    final humidity = data.humidity;
    final wind = data.windSpeed * 3.6;

    if (temp >= 32) {
      return const _AlertInfo(
        title: 'Aşırı Sıcaklık Uyarısı',
        message: 'Sıcaklık kritik seviyede. Gölgelik alan ve sürekli suya erişim sağlayın, yemlemeyi serin saatlere kaydırın.',
        icon: Icons.wb_sunny,
        gradient: [Color(0xFFFF6B6B), Color(0xFFFFA36C)],
      );
    }

    if (temp <= 0) {
      return const _AlertInfo(
        title: 'Dondurucu Soğuk',
        message: 'Barınakları kapatın, ek yataklık kullanın ve ılık su takviyesi yapın.',
        icon: Icons.ac_unit,
        gradient: [Color(0xFF6B8CFF), Color(0xFF9BCBFF)],
      );
    }

    if (humidity >= 85) {
      return const _AlertInfo(
        title: 'Yüksek Nem Uyarısı',
        message: 'Ahır havalandırmasını artırın, mantar ve solunum rahatsızlıklarına karşı tetikte olun.',
        icon: Icons.water_drop,
        gradient: [Color(0xFF43CBFF), Color(0xFF9708CC)],
      );
    }

    if (wind >= 40) {
      return const _AlertInfo(
        title: 'Şiddetli Rüzgar',
        message: 'Gezinti alanlarını sınırlandırın, hafif yapıları sabitleyin ve yem stoklarını koruyun.',
        icon: Icons.air,
        gradient: [Color(0xFF3C8CE7), Color(0xFF00EAFF)],
      );
    }

    return const _AlertInfo(
      title: 'Koşullar Uygun',
      message: 'Sıcaklık ve nem dengeli. Standart bakım rutinleriyle devam edebilirsiniz.',
      icon: Icons.check_circle_outline,
      gradient: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
    );
  }
}

class _MessageBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final bool showProgress;

  const _MessageBanner({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          if (showProgress) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertInfo {
  final String title;
  final String message;
  final IconData icon;
  final List<Color> gradient;

  const _AlertInfo({
    required this.title,
    required this.message,
    required this.icon,
    required this.gradient,
  });
}
