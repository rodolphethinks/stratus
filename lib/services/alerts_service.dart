import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

/// Fetches severe weather alerts via WeatherAPI.
class AlertsService {
  static const _apiKey = '495023151fa84eea81f130329260903';
  static const _baseUrl = 'https://api.weatherapi.com/v1';

  Future<List<WeatherAlert>> fetchAlerts(double lat, double lon) async {
    final uri =
        Uri.parse('$_baseUrl/forecast.json').replace(queryParameters: {
      'key': _apiKey,
      'q': '$lat,$lon',
      'days': '1',
      'alerts': 'yes',
      'aqi': 'no',
    });

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return [];

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final alertsNode = json['alerts'];
    if (alertsNode == null) return [];
    final raw = alertsNode['alert'] as List? ?? [];

    return raw.map((a) {
      final m = a as Map<String, dynamic>;
      return WeatherAlert(
        event: m['event'] as String? ?? 'Weather Alert',
        headline: m['headline'] as String? ?? '',
        severity: m['severity'] as String? ?? 'Unknown',
        description: m['desc'] as String? ?? '',
        instruction: m['instruction'] as String? ?? '',
        expires: m['expires'] as String? ?? '',
      );
    }).toList();
  }
}
