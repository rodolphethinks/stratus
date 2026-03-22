import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches ERA5 reanalysis data from Open-Meteo archive to compute
/// 5-year historical averages — providing the "is today unusual?" context.
class HistoricalService {
  static const _baseUrl = 'https://archive-api.open-meteo.com/v1';

  /// Returns the 5-year average high and low for the given [month] / [day].
  /// Fetches 5 years of the same calendar date in parallel.
  /// Returns null if all calls fail.
  Future<({double avgHigh, double avgLow})?> fetchAvgForDate({
    required double lat,
    required double lon,
    required int month,
    required int day,
  }) async {
    final now = DateTime.now();

    // Fetch the same calendar date for each of the 5 preceding years
    final futures = List.generate(5, (i) async {
      final year = now.year - 5 + i;
      // Clamp day for months like February in non-leap years
      final lastDayOfMonth = DateTime(year, month + 1, 0).day;
      final effectiveDay = day.clamp(1, lastDayOfMonth);
      final dateStr =
          '$year-${month.toString().padLeft(2, '0')}-${effectiveDay.toString().padLeft(2, '0')}';

      try {
        final uri =
            Uri.parse('$_baseUrl/archive').replace(queryParameters: {
          'latitude': lat.toString(),
          'longitude': lon.toString(),
          'start_date': dateStr,
          'end_date': dateStr,
          'daily': 'temperature_2m_max,temperature_2m_min',
          'timezone': 'auto',
        });

        final resp = await http
            .get(uri)
            .timeout(const Duration(seconds: 8));
        if (resp.statusCode != 200) return null;

        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        final d = json['daily'] as Map<String, dynamic>;
        final highs = d['temperature_2m_max'] as List;
        final lows = d['temperature_2m_min'] as List;
        if (highs.isEmpty || lows.isEmpty) return null;
        final h = (highs[0] as num?)?.toDouble();
        final l = (lows[0] as num?)?.toDouble();
        if (h == null || l == null) return null;
        return (high: h, low: l);
      } catch (_) {
        return null;
      }
    });

    final results = await Future.wait(futures);
    final valid =
        results.whereType<({double high, double low})>().toList();
    if (valid.isEmpty) return null;

    final avgHigh =
        valid.map((r) => r.high).reduce((a, b) => a + b) / valid.length;
    final avgLow =
        valid.map((r) => r.low).reduce((a, b) => a + b) / valid.length;

    return (avgHigh: avgHigh, avgLow: avgLow);
  }
}
