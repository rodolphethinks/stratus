import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather.dart';

class LocationStore {
  static const String _key = 'saved_locations';
  static const String _activeKey = 'active_location_index';

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_activeKey);
  }

  Future<List<SavedLocation>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => SavedLocation.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<SavedLocation> locations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      locations.map((l) => jsonEncode(l.toJson())).toList(),
    );
  }

  Future<int> getActiveIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activeKey) ?? 0;
  }

  Future<void> setActiveIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeKey, index);
  }
}


