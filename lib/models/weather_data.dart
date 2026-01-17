class WeatherData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;
  final int pressure;
  final double visibility;
  final int cloudiness;
  final String source;

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.pressure,
    required this.visibility,
    required this.cloudiness,
    required this.source,
  });

  String get weatherIconUrl {
    if (icon.startsWith('http')) {
      return icon;
    }
    return 'https://openweathermap.org/img/wn/$icon@2x.png';
  }

  String get temperatureString => '${temperature.toStringAsFixed(1)}°C';
  String get feelsLikeString => '${feelsLike.toStringAsFixed(1)}°C';
  String get humidityString => '$humidity%';
  String get windSpeedString => '${windSpeed.toStringAsFixed(1)} m/s';
  String get windSpeedKmh => '${(windSpeed * 3.6).toStringAsFixed(1)} km/s';
  String get pressureString => '$pressure hPa';
  String get visibilityString => '${visibility.toStringAsFixed(1)} km';
  String get cloudinessString => '$cloudiness%';

  bool get isSuitableForFarming {
    if (temperature < 5 || temperature > 35) return false;
    if (windSpeed > 10) return false;
    if (humidity < 30 || humidity > 90) return false;
    if (cloudiness > 80) return false;
    
    return true;
  }

  String get farmingAdvice {
    if (temperature < 5) {
      return 'Hava çok soğuk, ekim için uygun değil';
    } else if (temperature > 35) {
      return 'Hava çok sıcak, sulama gerekebilir';
    } else if (windSpeed > 10) {
      return 'Rüzgar çok kuvvetli, ilaçlama yapmayın';
    } else if (humidity < 30) {
      return 'Hava çok kuru, sulama yapın';
    } else if (humidity > 90) {
      return 'Nem çok yüksek, mantar hastalıklarına dikkat';
    } else if (cloudiness > 80) {
      return 'Hava kapalı, yağmur olabilir';
    } else {
      return 'Tarım faaliyetleri için uygun hava koşulları';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feelsLike': feelsLike,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'description': description,
      'icon': icon,
      'pressure': pressure,
      'visibility': visibility,
      'cloudiness': cloudiness,
      'source': source,
    };
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['temperature'].toDouble(),
      feelsLike: json['feelsLike'].toDouble(),
      humidity: json['humidity'],
      windSpeed: json['windSpeed'].toDouble(),
      description: json['description'],
      icon: json['icon'],
      pressure: json['pressure'],
      visibility: json['visibility'].toDouble(),
      cloudiness: json['cloudiness'],
      source: json['source'],
    );
  }
}
