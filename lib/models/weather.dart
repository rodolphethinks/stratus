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

  /// Magnus approximation for dew point in °C
  double get dewPoint => temperature - (100.0 - humidity) / 5.0;
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
  final double visibility; // km

  HourlyWeather({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.isDay,
    this.windSpeed = 0.0,
    this.uvIndex = 0.0,
    this.humidity = 0,
    this.visibility = 0.0,
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

/// Direction of surface pressure change over the past 3 hours
enum PressureTrend { rising, steady, falling }

class DayConfidence {
  final DateTime date;
  final ConfidenceLevel level;
  /// Ensemble temperature spread in °C (null = index-based fallback)
  final double? spread;

  DayConfidence({required this.date, required this.level, this.spread});
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
  final PressureTrend pressureTrend;
  final List<WeatherAlert> alerts;
  /// Historical 5-year average high for today (null if unavailable)
  final double? historicalAvgHigh;
  /// Historical 5-year average low for today (null if unavailable)
  final double? historicalAvgLow;

  WeatherData({
    required this.current,
    required this.hourly,
    required this.daily,
    required this.confidence,
    required this.nowcastMessage,
    required this.isRaining,
    required this.utcOffsetSeconds,
    this.yesterday,
    this.pressureTrend = PressureTrend.steady,
    this.alerts = const [],
    this.historicalAvgHigh,
    this.historicalAvgLow,
  });
}
/// A severe or notable weather alert from WeatherAPI
class WeatherAlert {
  final String event;
  final String headline;
  final String severity;   // Extreme, Severe, Moderate, Minor
  final String description;
  final String instruction;
  final String expires;

  const WeatherAlert({
    required this.event,
    required this.headline,
    required this.severity,
    this.description = '',
    this.instruction = '',
    this.expires = '',
  });
}

/// Activity types for Best Time suggestions
enum ActivityType {
  walking,
  running,
  cycling,
  gardening,
  photography,
  dining,
  hiking,
  dogWalking,
}

extension ActivityTypeX on ActivityType {
  String get displayName {
    switch (this) {
      case ActivityType.walking: return 'Walking';
      case ActivityType.running: return 'Running';
      case ActivityType.cycling: return 'Cycling';
      case ActivityType.gardening: return 'Gardening';
      case ActivityType.photography: return 'Photography';
      case ActivityType.dining: return 'Outdoor dining';
      case ActivityType.hiking: return 'Hiking';
      case ActivityType.dogWalking: return 'Dog walk';
    }
  }

  String get emoji {
    switch (this) {
      case ActivityType.walking: return '🚶';
      case ActivityType.running: return '🏃';
      case ActivityType.cycling: return '🚴';
      case ActivityType.gardening: return '🌱';
      case ActivityType.photography: return '📸';
      case ActivityType.dining: return '🍽️';
      case ActivityType.hiking: return '🥾';
      case ActivityType.dogWalking: return '🐕';
    }
  }

  static ActivityType fromString(String s) {
    return ActivityType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ActivityType.walking,
    );
  }

  /// Returns true if conditions are suitable for this activity
  bool isSuitable(HourlyWeather h, {DateTime? sunriseTime, DateTime? sunsetTime}) {
    bool isRainy = h.precipitationProbability >= 25 ||
        h.condition == WeatherCondition.rain ||
        h.condition == WeatherCondition.heavyRain ||
        h.condition == WeatherCondition.drizzle ||
        h.condition == WeatherCondition.thunderstorm ||
        h.condition == WeatherCondition.snow;
    switch (this) {
      case ActivityType.walking:
        return h.isDay && !isRainy && h.temperature >= 5 && h.temperature <= 34;
      case ActivityType.running:
        return h.isDay && h.precipitationProbability < 15 &&
            h.temperature >= 3 && h.temperature <= 22 && h.windSpeed < 30 &&
            h.condition != WeatherCondition.thunderstorm;
      case ActivityType.cycling:
        return h.isDay && h.precipitationProbability < 10 &&
            h.temperature >= 6 && h.temperature <= 28 && h.windSpeed < 25;
      case ActivityType.gardening:
        return h.isDay && h.precipitationProbability < 30 &&
            h.temperature >= 8 && h.temperature <= 30;
      case ActivityType.photography:
        if (sunriseTime != null) {
          final minutesFromSunrise = h.time.difference(sunriseTime).inMinutes.abs();
          if (minutesFromSunrise <= 60) return h.precipitationProbability < 30;
        }
        if (sunsetTime != null) {
          final minutesFromSunset = h.time.difference(sunsetTime).inMinutes.abs();
          if (minutesFromSunset <= 60) return h.precipitationProbability < 30;
        }
        return h.isDay && h.precipitationProbability < 20;
      case ActivityType.dining:
        return h.isDay && h.precipitationProbability < 5 &&
            h.temperature >= 15 && h.temperature <= 32 && h.windSpeed < 15;
      case ActivityType.hiking:
        return h.isDay && h.precipitationProbability < 20 &&
            h.temperature >= 5 && h.temperature <= 28 &&
            h.condition != WeatherCondition.thunderstorm;
      case ActivityType.dogWalking:
        return h.isDay && h.precipitationProbability < 20 &&
            h.temperature >= 2 && h.temperature <= 32;
    }
  }
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


