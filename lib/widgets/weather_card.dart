import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';
import '../models/weather_data.dart';

class WeatherCard extends StatefulWidget {
  final Position? position;
  final String? selectedCity;

  const WeatherCard({super.key, this.position, this.selectedCity});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
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
  void didUpdateWidget(WeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCity != widget.selectedCity ||
        oldWidget.position != widget.position) {
      _fetchWeather();
    }
  }

  Future<void> _fetchWeather() async {
    if (widget.selectedCity == null && widget.position == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      WeatherData? weather;
      
      if (widget.selectedCity != null) {
        final multipleWeather = await _weatherService.getMultipleSourcesWeather(widget.selectedCity!);
        weather = _weatherService.getAverageWeather(multipleWeather);
      } else if (widget.position != null) {
        weather = await _weatherService.getWeatherByCoordinates(widget.position!);
      }

      setState(() {
        _weatherData = weather;
        _isLoading = false;
        if (weather == null) {
          _error = 'Hava durumu bilgisi alınamadı';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Hata: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

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
            children: [
              Icon(
                Icons.wb_sunny,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Hava Durumu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_weatherData != null && !_isLoading) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherInfo(
                  Icons.thermostat,
                  _weatherData!.temperatureString,
                  'Sıcaklık',
                  context,
                ),
                _buildWeatherInfo(
                  Icons.water_drop,
                  _weatherData!.humidityString,
                  'Nem',
                  context,
                ),
                _buildWeatherInfo(
                  Icons.air,
                  _weatherData!.windSpeedKmh,
                  'Rüzgar',
                  context,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _weatherData!.isSuitableForFarming
                    ? Colors.green[50]
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _weatherData!.isSuitableForFarming
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    color: _weatherData!.isSuitableForFarming
                        ? Colors.green[700]
                        : Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _weatherData!.farmingAdvice,
                      style: TextStyle(
                        color: _weatherData!.isSuitableForFarming
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kaynak: ${_weatherData!.source}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[300], size: 40),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _fetchWeather,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            )
          else if (widget.position == null && widget.selectedCity == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Hava durumu bilgisi için konum veya il seçimi gerekli',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(
      IconData icon, String value, String label, BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
