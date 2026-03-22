enum WeatherCondition {
  clearDay,
  clearNight,
  partlyCloudy,
  partlyCloudyNight,
  cloudy,
  overcast,
  drizzle,
  rain,
  heavyRain,
  thunderstorm,
  snow,
  fog,
  unknown,
}

WeatherCondition conditionFromWMO(int code, {bool isDay = true}) {
  if (code == 0) return isDay ? WeatherCondition.clearDay : WeatherCondition.clearNight;
  if (code == 1 || code == 2) return isDay ? WeatherCondition.partlyCloudy : WeatherCondition.partlyCloudyNight;
  if (code == 3) return WeatherCondition.overcast;
  if (code == 45 || code == 48) return WeatherCondition.fog;
  if (code >= 51 && code <= 57) return WeatherCondition.drizzle;
  if (code >= 61 && code <= 65) return WeatherCondition.rain;
  if (code >= 66 && code <= 67) return WeatherCondition.rain;
  if (code >= 71 && code <= 77) return WeatherCondition.snow;
  if (code >= 80 && code <= 82) return WeatherCondition.rain;
  if (code >= 85 && code <= 86) return WeatherCondition.snow;
  if (code >= 95 && code <= 99) return WeatherCondition.thunderstorm;
  return WeatherCondition.unknown;
}

String conditionLabel(WeatherCondition c) {
  switch (c) {
    case WeatherCondition.clearDay: return 'Sunny';
    case WeatherCondition.clearNight: return 'Clear';
    case WeatherCondition.partlyCloudy: return 'Partly cloudy';
    case WeatherCondition.partlyCloudyNight: return 'Partly cloudy';
    case WeatherCondition.cloudy: return 'Cloudy';
    case WeatherCondition.overcast: return 'Overcast';
    case WeatherCondition.drizzle: return 'Drizzle';
    case WeatherCondition.rain: return 'Rain';
    case WeatherCondition.heavyRain: return 'Heavy rain';
    case WeatherCondition.thunderstorm: return 'Thunderstorm';
    case WeatherCondition.snow: return 'Snow';
    case WeatherCondition.fog: return 'Fog';
    case WeatherCondition.unknown: return 'Unknown';
  }
}

class CurrentWeather {
  final double temperature;
  final double feelsLike;
  final double windSpeed;
  final int windDirection; // degrees 0-359
  final int humidity;
  final double surfacePressure; // hPa
  final double dailyHigh;
  final double dailyLow;
  final int weatherCode;
  final bool isDay;
  final double precipitationProbability; // next hour

  CurrentWeather({
    required this.temperature,
    required this.feelsLike,
    required this.windSpeed,
    this.windDirection = 0,
    required this.humidity,
    this.surfacePressure = 1013.0,
    required this.dailyHigh,
    required this.dailyLow,
    required this.weatherCode,
    required this.isDay,
    required this.precipitationProbability,
  });

  WeatherCondition get condition => conditionFromWMO(weatherCode, isDay: isDay);
}

class HourlyWeather {
  final DateTime time;
  final double temperature;
  final int precipitationProbability;
  final int weatherCode;
  final bool isDay;
  final double windSpeed;
  final double uvIndex;
  final int humidity;

  HourlyWeather({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.isDay,
    this.windSpeed = 0.0,
    this.uvIndex = 0.0,
    this.humidity = 0,
  });

  WeatherCondition get condition => conditionFromWMO(weatherCode, isDay: isDay);
}

class DailyWeather {
  final DateTime date;
  final double high;
  final double low;
  final int weatherCode;
  final int precipitationProbability;
  final DateTime? sunriseTime; // local time (stored as "fake UTC" matching hourly)
  final DateTime? sunsetTime;

  DailyWeather({
    required this.date,
    required this.high,
    required this.low,
    required this.weatherCode,
    required this.precipitationProbability,
    this.sunriseTime,
    this.sunsetTime,
  });

  WeatherCondition get condition => conditionFromWMO(weatherCode, isDay: true);
}

/// Confidence level derived from ensemble spread
enum ConfidenceLevel { high, medium, low }

class DayConfidence {
  final DateTime date;
  final ConfidenceLevel level;

  DayConfidence({required this.date, required this.level});
}

class WeatherData {
  final CurrentWeather current;
  final List<HourlyWeather> hourly; // 24h
  final List<DailyWeather> daily;   // 7 days
  final List<DayConfidence> confidence; // 7 days
  final String nowcastMessage;
  final bool isRaining;
  final int utcOffsetSeconds;
  final DailyWeather? yesterday;

  WeatherData({
    required this.current,
    required this.hourly,
    required this.daily,
    required this.confidence,
    required this.nowcastMessage,
    required this.isRaining,
    required this.utcOffsetSeconds,
    this.yesterday,
  });
}

class SavedLocation {
  final String name;
  final String country;
  final double latitude;
  final double longitude;

  const SavedLocation({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'country': country,
        'lat': latitude,
        'lon': longitude,
      };

  factory SavedLocation.fromJson(Map<String, dynamic> j) => SavedLocation(
        name: j['name'],
        country: j['country'],
        latitude: j['lat'],
        longitude: j['lon'],
      );
}


