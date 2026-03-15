import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class GeocodingService {
  static const String _baseUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  Future<List<SavedLocation>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'name': query.trim(),
      'count': '8',
      'language': 'en',
      'format': 'json',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final results = json['results'] as List? ?? [];

    return results.map((r) {
      final map = r as Map<String, dynamic>;
      final country = map['country'] as String? ?? '';
      final admin1  = map['admin1']  as String? ?? '';
      // Build a location subtitle: "Region, Country" if both exist,
      // or just whichever is non-empty (handles overseas territories like Papeete)
      final locationLabel = [admin1, country]
          .where((s) => s.isNotEmpty)
          .join(', ');
      return SavedLocation(
        name: map['name'] as String,
        country: locationLabel,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
      );
    }).toList();
  }
}


