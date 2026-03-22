import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

/// Fetches Open-Meteo ensemble forecast to derive scientifically grounded
/// confidence levels from actual model spread — our #1 differentiating feature.
class EnsembleService {
  static const _baseUrl = 'https://ensemble-api.open-meteo.com/v1';

  /// Returns per-day confidence derived from ICON seamless ensemble spread.
  /// Throws on network failure — caller must handle with a fallback.
  Future<List<DayConfidence>> fetchConfidence(
    double lat,
    double lon,
    List<DailyWeather> daily,
  ) async {
    final uri = Uri.parse('$_baseUrl/ensemble').replace(queryParameters: {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'daily': 'temperature_2m_max',
      'models': 'icon_seamless', // 20 members, global coverage
      'forecast_days': '7',
      'timezone': 'auto',
    });

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Ensemble API ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final dailyRaw = json['daily'] as Map<String, dynamic>;
    final times = dailyRaw['time'] as List;

    // Find all member keys, e.g. temperature_2m_max_member01 … member20
    final memberKeys = dailyRaw.keys
        .where((k) => k.startsWith('temperature_2m_max_member'))
        .toList();

    final List<DayConfidence> result = [];
    for (int i = 0; i < times.length && i < daily.length; i++) {
      final values = memberKeys
          .map((k) => (dailyRaw[k] as List)[i])
          .whereType<num>()
          .map((n) => n.toDouble())
          .toList();

      if (values.length < 3) {
        result.add(DayConfidence(
            date: daily[i].date,
            level: ConfidenceLevel.medium,
            spread: null));
        continue;
      }

      // Standard deviation across members
      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
              values.length;
      final std = sqrt(variance);

      // Map spread to confidence level
      ConfidenceLevel level;
      if (std < 1.5) {
        level = ConfidenceLevel.high;
      } else if (std < 3.0) {
        level = ConfidenceLevel.medium;
      } else {
        level = ConfidenceLevel.low;
      }

      result.add(DayConfidence(
          date: DateTime.parse(times[i] as String),
          level: level,
          spread: double.parse(std.toStringAsFixed(1))));
    }

    return result;
  }
}
