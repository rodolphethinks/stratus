import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { simple, enthusiast }

class AppSettings {
  /// General — apply to both modes
  final bool useCelsius;
  final bool showYesterday;
  final bool showSunriseSunset; // markers on hourly chart

  /// Simple mode only
  final bool showBestTimeCard;
  final bool showConfidenceStrip;

  /// Enthusiast mode only
  final bool showMetricsRow; // wind / humidity / UV / pressure row
  final bool showAstronomy;  // sunrise time, sunset time, moon phase
  final bool showRadar;      // radar map

  /// General — applied to both modes
  final bool showAlerts;          // severe weather alert banner
  final bool showHistoricalBadge; // +/- vs historical avg on today row

  /// Best time card activity (stored as string for JSON compatibility)
  final String preferredActivity;

  const AppSettings({
    this.useCelsius = true,
    this.showYesterday = false,
    this.showSunriseSunset = true,
    this.showBestTimeCard = true,
    this.showConfidenceStrip = true,
    this.showMetricsRow = true,
    this.showAstronomy = true,
    this.showRadar = true,
    this.showAlerts = true,
    this.showHistoricalBadge = true,
    this.preferredActivity = 'walking',
  });

  Map<String, dynamic> toJson() => {
        'useCelsius': useCelsius,
        'showYesterday': showYesterday,
        'showSunriseSunset': showSunriseSunset,
        'showBestTimeCard': showBestTimeCard,
        'showConfidenceStrip': showConfidenceStrip,
        'showMetricsRow': showMetricsRow,
        'showAstronomy': showAstronomy,
        'showRadar': showRadar,
        'showAlerts': showAlerts,
        'showHistoricalBadge': showHistoricalBadge,
        'preferredActivity': preferredActivity,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        useCelsius: json['useCelsius'] as bool? ?? true,
        showYesterday: json['showYesterday'] as bool? ?? false,
        showSunriseSunset: json['showSunriseSunset'] as bool? ?? true,
        showBestTimeCard: json['showBestTimeCard'] as bool? ?? true,
        showConfidenceStrip: json['showConfidenceStrip'] as bool? ?? true,
        showMetricsRow: json['showMetricsRow'] as bool? ?? true,
        showAstronomy: json['showAstronomy'] as bool? ?? true,
        showRadar: json['showRadar'] as bool? ?? true,
        showAlerts: json['showAlerts'] as bool? ?? true,
        showHistoricalBadge: json['showHistoricalBadge'] as bool? ?? true,
        preferredActivity: json['preferredActivity'] as String? ?? 'walking',
      );

  AppSettings copyWith({
    bool? useCelsius,
    bool? showYesterday,
    bool? showSunriseSunset,
    bool? showBestTimeCard,
    bool? showConfidenceStrip,
    bool? showMetricsRow,
    bool? showAstronomy,
    bool? showRadar,
    bool? showAlerts,
    bool? showHistoricalBadge,
    String? preferredActivity,
  }) =>
      AppSettings(
        useCelsius: useCelsius ?? this.useCelsius,
        showYesterday: showYesterday ?? this.showYesterday,
        showSunriseSunset: showSunriseSunset ?? this.showSunriseSunset,
        showBestTimeCard: showBestTimeCard ?? this.showBestTimeCard,
        showConfidenceStrip: showConfidenceStrip ?? this.showConfidenceStrip,
        showMetricsRow: showMetricsRow ?? this.showMetricsRow,
        showAstronomy: showAstronomy ?? this.showAstronomy,
        showRadar: showRadar ?? this.showRadar,
        showAlerts: showAlerts ?? this.showAlerts,
        showHistoricalBadge: showHistoricalBadge ?? this.showHistoricalBadge,
        preferredActivity: preferredActivity ?? this.preferredActivity,
      );
}

class SettingsStore {
  static const String _modeKey = 'app_mode';
  static const String _settingsKey = 'app_settings_json';

  Future<AppMode> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_modeKey);
    return val == 'enthusiast' ? AppMode.enthusiast : AppMode.simple;
  }

  Future<void> setMode(AppMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  Future<AppSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(s.toJson()));
  }
}
