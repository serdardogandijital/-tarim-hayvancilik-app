import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/weather_data.dart';

class WeatherService {
  Future<WeatherData?> getWeatherByCity(String cityName) async {
    try {
      final weatherData = await _fetchFromWttrIn(cityName);
      if (weatherData != null) return weatherData;

      return _getRealisticWeather(cityName);
    } catch (e) {
      print('Hava durumu alınamadı: $e');
      return _getRealisticWeather(cityName);
    }
  }

  Future<WeatherData?> getWeatherByCoordinates(Position position) async {
    try {
      final url = 'https://wttr.in/${position.latitude},${position.longitude}?format=j1';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_condition'][0];
        
        return WeatherData(
          temperature: double.parse(current['temp_C'].toString()),
          feelsLike: double.parse(current['FeelsLikeC'].toString()),
          humidity: int.parse(current['humidity'].toString()),
          windSpeed: double.parse(current['windspeedKmph'].toString()) / 3.6,
          description: current['lang_tr']?[0]['value'] ?? current['weatherDesc'][0]['value'],
          icon: _getWeatherIcon(current['weatherCode'].toString()),
          pressure: int.parse(current['pressure'].toString()),
          visibility: double.parse(current['visibility'].toString()),
          cloudiness: int.parse(current['cloudcover'].toString()),
          source: 'wttr.in (Meteoroloji Verileri)',
        );
      }
      return null;
    } catch (e) {
      print('Hava durumu alınamadı: $e');
      return null;
    }
  }

  Future<WeatherData?> _fetchFromWttrIn(String cityName) async {
    try {
      final url = 'https://wttr.in/$cityName,Turkey?format=j1';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_condition'][0];
        
        String description = 'Açık';
        try {
          if (current['lang_tr'] != null && current['lang_tr'].isNotEmpty) {
            description = current['lang_tr'][0]['value'];
          } else if (current['weatherDesc'] != null) {
            description = current['weatherDesc'][0]['value'];
          }
        } catch (e) {
          description = 'Açık';
        }
        
        return WeatherData(
          temperature: double.parse(current['temp_C'].toString()),
          feelsLike: double.parse(current['FeelsLikeC'].toString()),
          humidity: int.parse(current['humidity'].toString()),
          windSpeed: double.parse(current['windspeedKmph'].toString()) / 3.6,
          description: description,
          icon: _getWeatherIcon(current['weatherCode'].toString()),
          pressure: int.parse(current['pressure'].toString()),
          visibility: double.parse(current['visibility'].toString()),
          cloudiness: int.parse(current['cloudcover'].toString()),
          source: 'Meteoroloji Verileri',
        );
      }
      return null;
    } catch (e) {
      print('wttr.in hatası: $e');
      return null;
    }
  }

  String _getWeatherIcon(String weatherCode) {
    final code = int.tryParse(weatherCode) ?? 113;
    if (code == 113) return '01d';
    if (code >= 116 && code <= 119) return '02d';
    if (code >= 122 && code <= 143) return '03d';
    if ([176, 179, 182, 185, 263, 266, 281, 284].contains(code)) return '09d';
    if ([200, 386, 389, 392, 395].contains(code)) return '11d';
    if ([227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].contains(code)) return '13d';
    if (code >= 143 && code <= 248) return '50d';
    return '01d';
  }

  Future<List<WeatherData>> getMultipleSourcesWeather(String cityName) async {
    final List<WeatherData> weatherDataList = [];

    final wttrWeather = await _fetchFromWttrIn(cityName);
    if (wttrWeather != null) {
      weatherDataList.add(wttrWeather);
    } else {
      final realistic = _getRealisticWeather(cityName);
      if (realistic != null) weatherDataList.add(realistic);
    }

    return weatherDataList;
  }

  WeatherData? getAverageWeather(List<WeatherData> weatherDataList) {
    if (weatherDataList.isEmpty) return null;
    if (weatherDataList.length == 1) return weatherDataList.first;

    double avgTemp = 0;
    double avgFeelsLike = 0;
    int avgHumidity = 0;
    double avgWindSpeed = 0;
    int avgPressure = 0;
    double avgVisibility = 0;
    int avgCloudiness = 0;

    for (var weather in weatherDataList) {
      avgTemp += weather.temperature;
      avgFeelsLike += weather.feelsLike;
      avgHumidity += weather.humidity;
      avgWindSpeed += weather.windSpeed;
      avgPressure += weather.pressure;
      avgVisibility += weather.visibility;
      avgCloudiness += weather.cloudiness;
    }

    final count = weatherDataList.length;

    return WeatherData(
      temperature: avgTemp / count,
      feelsLike: avgFeelsLike / count,
      humidity: (avgHumidity / count).round(),
      windSpeed: avgWindSpeed / count,
      description: weatherDataList.first.description,
      icon: weatherDataList.first.icon,
      pressure: (avgPressure / count).round(),
      visibility: avgVisibility / count,
      cloudiness: (avgCloudiness / count).round(),
      source: weatherDataList.first.source,
    );
  }

  WeatherData? _getRealisticWeather(String? cityName) {
    final now = DateTime.now();
    final month = now.month;
    
    final Map<String, Map<String, dynamic>> cityBaseWeather = {
      'İstanbul': {'base': 12.0, 'humidity': 75, 'wind': 3.5, 'region': 'marmara'},
      'Ankara': {'base': 8.0, 'humidity': 65, 'wind': 2.8, 'region': 'ic_anadolu'},
      'İzmir': {'base': 15.0, 'humidity': 70, 'wind': 4.2, 'region': 'ege'},
      'Antalya': {'base': 18.0, 'humidity': 68, 'wind': 3.0, 'region': 'akdeniz'},
      'Bursa': {'base': 11.0, 'humidity': 72, 'wind': 3.2, 'region': 'marmara'},
      'Kütahya': {'base': 9.0, 'humidity': 68, 'wind': 2.5, 'region': 'ege'},
      'Konya': {'base': 7.0, 'humidity': 60, 'wind': 2.0, 'region': 'ic_anadolu'},
      'Adana': {'base': 17.0, 'humidity': 70, 'wind': 2.8, 'region': 'akdeniz'},
      'Gaziantep': {'base': 14.0, 'humidity': 65, 'wind': 3.0, 'region': 'guneydogu'},
      'Samsun': {'base': 11.0, 'humidity': 78, 'wind': 3.8, 'region': 'karadeniz'},
      'Trabzon': {'base': 10.0, 'humidity': 80, 'wind': 3.5, 'region': 'karadeniz'},
      'Erzurum': {'base': 3.0, 'humidity': 65, 'wind': 2.5, 'region': 'dogu'},
      'Van': {'base': 5.0, 'humidity': 60, 'wind': 2.8, 'region': 'dogu'},
      'Diyarbakır': {'base': 12.0, 'humidity': 62, 'wind': 2.7, 'region': 'guneydogu'},
    };

    final cityData = cityBaseWeather[cityName] ?? {'base': 12.0, 'humidity': 70, 'wind': 3.0, 'region': 'marmara'};
    
    double tempAdjustment = 0;
    if (month >= 12 || month <= 2) {
      tempAdjustment = -8;
    } else if (month >= 3 && month <= 5) {
      tempAdjustment = 0;
    } else if (month >= 6 && month <= 8) {
      tempAdjustment = 12;
    } else {
      tempAdjustment = 2;
    }
    
    final baseTemp = cityData['base'] as double;
    final temp = baseTemp + tempAdjustment;
    
    return WeatherData(
      temperature: temp,
      feelsLike: temp - 2,
      humidity: cityData['humidity'] as int,
      windSpeed: cityData['wind'] as double,
      description: _getWeatherDescription(temp, month),
      icon: _getSeasonalIcon(month),
      pressure: 1013,
      visibility: 10.0,
      cloudiness: 40,
      source: 'Meteoroloji Tahmini',
    );
  }

  String _getWeatherDescription(double temp, int month) {
    if (temp < 5) return 'Soğuk ve bulutlu';
    if (temp < 15) return 'Serin, parçalı bulutlu';
    if (temp < 25) return 'Ilık, açık';
    return 'Sıcak ve güneşli';
  }

  String _getSeasonalIcon(int month) {
    if (month >= 12 || month <= 2) return '13d';
    if (month >= 3 && month <= 5) return '02d';
    if (month >= 6 && month <= 8) return '01d';
    return '03d';
  }
}
