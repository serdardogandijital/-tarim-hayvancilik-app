import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/weather_data.dart';

class WeatherService {
  WeatherService({http.Client? client}) : _client = client;
  final http.Client? _client;
  Future<WeatherData?> getWeatherByCity(String cityName) async {
    try {
      final weatherData = await _fetchFromWttrIn(cityName);
      if (weatherData != null) return weatherData;

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<WeatherData?> getWeatherByCoordinates(Position position) async {
    try {
      final url =
          'https://wttr.in/${position.latitude},${position.longitude}?format=j1';
      final response = await (_client?.get ?? http.get)(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_condition'][0];

        return WeatherData(
          temperature: double.parse(current['temp_C'].toString()),
          feelsLike: double.parse(current['FeelsLikeC'].toString()),
          humidity: int.parse(current['humidity'].toString()),
          windSpeed: double.parse(current['windspeedKmph'].toString()) / 3.6,
          description:
              current['lang_tr']?[0]['value'] ??
              current['weatherDesc'][0]['value'],
          icon: _getWeatherIcon(current['weatherCode'].toString()),
          pressure: int.parse(current['pressure'].toString()),
          visibility: double.parse(current['visibility'].toString()),
          cloudiness: int.parse(current['cloudcover'].toString()),
          source: 'wttr.in',
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<WeatherData?> _fetchFromWttrIn(String cityName) async {
    try {
      final url = 'https://wttr.in/$cityName,Turkey?format=j1';
      final response = await (_client?.get ?? http.get)(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_condition'][0];

        String description = 'Açıklama alınamadı';
        try {
          if (current['lang_tr'] != null && current['lang_tr'].isNotEmpty) {
            description = current['lang_tr'][0]['value'];
          } else if (current['weatherDesc'] != null) {
            description = current['weatherDesc'][0]['value'];
          }
        } catch (e) {
          description = 'Açıklama alınamadı';
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
          source: 'wttr.in',
        );
      }
      return null;
    } catch (e) {
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
    if ([
      227,
      230,
      317,
      320,
      323,
      326,
      329,
      332,
      335,
      338,
      350,
      362,
      365,
      368,
      371,
      374,
      377,
    ].contains(code))
      return '13d';
    if (code >= 143 && code <= 248) return '50d';
    return '01d';
  }

  Future<List<WeatherData>> getMultipleSourcesWeather(String cityName) async {
    final List<WeatherData> weatherDataList = [];

    final wttrWeather = await _fetchFromWttrIn(cityName);
    if (wttrWeather != null) {
      weatherDataList.add(wttrWeather);
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
}
