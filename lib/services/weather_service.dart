import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1';

  Future<WeatherData> fetchWeather(double lat, double lon) async {
    final uri = Uri.parse('$_baseUrl/forecast').replace(queryParameters: {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'current': [
        'temperature_2m',
        'apparent_temperature',
        'relative_humidity_2m',
        'wind_speed_10m',
        'weather_code',
        'is_day',
        'precipitation_probability',
      ].join(','),
      'hourly': [
        'temperature_2m',
        'precipitation_probability',
        'weather_code',
        'is_day',
      ].join(','),
      'daily': [
        'temperature_2m_max',
        'temperature_2m_min',
        'weather_code',
        'precipitation_probability_max',
      ].join(','),
      'forecast_days': '7',
      'past_days': '1',
      'timezone': 'auto',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch weather: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parse(json);
  }

  WeatherData _parse(Map<String, dynamic> json) {
    final cur = json['current'] as Map<String, dynamic>;
    final hourlyRaw = json['hourly'] as Map<String, dynamic>;
    final dailyRaw = json['daily'] as Map<String, dynamic>;
    final utcOffsetSeconds = (json['utc_offset_seconds'] as num?)?.toInt() ?? 0;
    // Location-local "now" so hourly filtering works regardless of machine timezone
    final now = DateTime.now().toUtc().add(Duration(seconds: utcOffsetSeconds));
    final currentCode = (cur['weather_code'] as num).toInt();
    final isDay = (cur['is_day'] as num).toInt() == 1;
    final precipProb = (cur['precipitation_probability'] as num?)?.toDouble() ?? 0.0;

    // Daily high/low for today
    final dailyHighList = (dailyRaw['temperature_2m_max'] as List);
    final dailyLowList = (dailyRaw['temperature_2m_min'] as List);
    final todayHigh = (dailyHighList[0] as num).toDouble();
    final todayLow = (dailyLowList[0] as num).toDouble();

    final current = CurrentWeather(
      temperature: (cur['temperature_2m'] as num).toDouble(),
      feelsLike: (cur['apparent_temperature'] as num).toDouble(),
      windSpeed: (cur['wind_speed_10m'] as num).toDouble(),
      humidity: (cur['relative_humidity_2m'] as num).toInt(),
      dailyHigh: todayHigh,
      dailyLow: todayLow,
      weatherCode: currentCode,
      isDay: isDay,
      precipitationProbability: precipProb,
    );

    // Hourly — next 24 hours from location-local now
    final hourlyTimes = hourlyRaw['time'] as List;
    final hourlyTemps = hourlyRaw['temperature_2m'] as List;
    final hourlyPrecip = hourlyRaw['precipitation_probability'] as List;
    final hourlyCodes = hourlyRaw['weather_code'] as List;
    final hourlyIsDay = hourlyRaw['is_day'] as List;

    final List<HourlyWeather> hourly = [];
    for (int i = 0; i < hourlyTimes.length && hourly.length < 24; i++) {
      // Append 'Z' so Dart treats the location-local time string as UTC.
      // Our `now` is also UTC-expressed (toUtc + offset), so comparisons align.
      final t = DateTime.parse('${hourlyTimes[i]}Z');
      if (t.isAfter(now.subtract(const Duration(minutes: 30)))) {
        hourly.add(HourlyWeather(
          time: t,
          temperature: (hourlyTemps[i] as num).toDouble(),
          precipitationProbability: (hourlyPrecip[i] as num?)?.toInt() ?? 0,
          weatherCode: (hourlyCodes[i] as num).toInt(),
          isDay: (hourlyIsDay[i] as num).toInt() == 1,
        ));
      }
    }

    // Daily — first entry may be yesterday when past_days=1
    final dailyDates = dailyRaw['time'] as List;
    final dailyCodes = dailyRaw['weather_code'] as List;
    final dailyPrecip = dailyRaw['precipitation_probability_max'] as List;

    final todayDate = DateTime.utc(now.year, now.month, now.day);
    DailyWeather? yesterdayData;
    final List<DailyWeather> daily = [];
    for (int i = 0; i < dailyDates.length; i++) {
      final d = DailyWeather(
        date: DateTime.parse(dailyDates[i] as String),
        high: (dailyHighList[i] as num).toDouble(),
        low: (dailyLowList[i] as num).toDouble(),
        weatherCode: (dailyCodes[i] as num).toInt(),
        precipitationProbability: (dailyPrecip[i] as num?)?.toInt() ?? 0,
      );
      final dDate = DateTime.utc(d.date.year, d.date.month, d.date.day);
      if (dDate.isBefore(todayDate)) {
        yesterdayData = d;
      } else {
        daily.add(d);
      }
    }

    // Confidence — purely index-based: more days ahead = less certainty
    final List<DayConfidence> confidence = [];
    for (int i = 0; i < daily.length; i++) {
      ConfidenceLevel level;
      if (i <= 2) {
        level = ConfidenceLevel.high;
      } else if (i <= 4) {
        level = ConfidenceLevel.medium;
      } else {
        level = ConfidenceLevel.low;
      }
      confidence.add(DayConfidence(date: daily[i].date, level: level));
    }

    // Nowcast message — checks both precip probability AND weather condition
    // so the pill stays consistent with the hourly icon strip.
    bool isRainyHour(HourlyWeather h) =>
        h.precipitationProbability >= 25 ||
        h.condition == WeatherCondition.rain ||
        h.condition == WeatherCondition.heavyRain ||
        h.condition == WeatherCondition.drizzle ||
        h.condition == WeatherCondition.thunderstorm ||
        h.condition == WeatherCondition.snow;

    final nextHourPrecip = hourly.isNotEmpty ? hourly.first.precipitationProbability : 0;
    final bool currentRaining = hourly.isNotEmpty && isRainyHour(hourly.first);
    final String nowcast;
    final bool isRaining;
    if (currentRaining) {
      isRaining = true;
      if (nextHourPrecip > 70) {
        nowcast = 'Rain likely in the next hour';
      } else {
        nowcast = 'Rain in progress';
      }
    } else if (nextHourPrecip > 40) {
      nowcast = 'Light rain possible · Medium confidence';
      isRaining = false;
    } else {
      // Find when rain might start
      final rainyHour = hourly.skip(1).where(isRainyHour).firstOrNull;
      if (rainyHour != null) {
        final diff = rainyHour.time.difference(now);
        if (diff.inHours < 1) {
          nowcast = 'Rain approaching · ~${diff.inMinutes} min';
        } else {
          final timeStr = _formatTime(rainyHour.time);
          nowcast = 'Rain possible after $timeStr · Medium confidence';
        }
        isRaining = false;
      } else {
        final clearHours = hourly.where((h) => !isRainyHour(h)).length;
        nowcast = 'No rain for the next ${clearHours}h';
        isRaining = false;
      }
    }

    return WeatherData(
      current: current,
      hourly: hourly,
      daily: daily,
      confidence: confidence,
      nowcastMessage: nowcast,
      isRaining: isRaining,
      utcOffsetSeconds: utcOffsetSeconds,
      yesterday: yesterdayData,
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour;
    if (h == 0) return '12 AM';
    if (h < 12) return '${h}AM';
    if (h == 12) return '12PM';
    return '${h - 12}PM';
  }
}


