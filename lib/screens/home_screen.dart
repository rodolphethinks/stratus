import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import '../services/location_store.dart';
import '../theme/app_theme.dart';
import '../widgets/weather_icon.dart';
import '../widgets/nowcast_pill.dart';
import '../widgets/confidence_strip.dart';
import '../widgets/hourly_chart.dart';
import '../widgets/daily_forecast.dart';
import '../widgets/city_switcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final LocationStore _locationStore = LocationStore();

  List<SavedLocation> _locations = [];
  int _activeIndex = 0;
  WeatherData? _weather;
  bool _loading = true;
  String? _error;
  bool _showYesterday = false;

  // Default locations: Seoul first, Paris second
  static const _defaultLocations = [
    SavedLocation(
      name: 'Seoul',
      country: 'South Korea',
      latitude: 37.5665,
      longitude: 126.9780,
    ),
    SavedLocation(
      name: 'Paris',
      country: 'France',
      latitude: 48.8566,
      longitude: 2.3522,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    var locations = await _locationStore.load();
    // Reset if old default (Paris-first) was saved, so new Seoul-first defaults apply
    if (locations.length == 1 && locations.first.name == 'Paris') {
      await _locationStore.clear();
      locations = [];
    }
    if (locations.isEmpty) {
      locations = List<SavedLocation>.from(_defaultLocations);
      await _locationStore.save(locations);
    }
    final activeIndex = await _locationStore.getActiveIndex();
    setState(() {
      _locations = locations;
      _activeIndex = activeIndex.clamp(0, locations.length - 1);
    });
    await _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (_locations.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final loc = _locations[_activeIndex];
      final data = await _weatherService.fetchWeather(loc.latitude, loc.longitude);
      if (mounted) setState(() { _weather = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _selectLocation(int index) async {
    setState(() => _activeIndex = index);
    await _locationStore.setActiveIndex(index);
    await _fetchWeather();
  }

  Future<void> _addLocation(SavedLocation loc) async {
    final updated = [..._locations, loc];
    setState(() => _locations = updated);
    await _locationStore.save(updated);
    await _selectLocation(updated.length - 1);
  }

  Future<void> _removeLocation(int index) async {
    if (index == 0) return; // never remove first
    final updated = List<SavedLocation>.from(_locations)..removeAt(index);
    final newActive = _activeIndex >= updated.length ? updated.length - 1 : _activeIndex;
    setState(() { _locations = updated; _activeIndex = newActive; });
    await _locationStore.save(updated);
    await _locationStore.setActiveIndex(newActive);
  }

  void _showCitySwitcher() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: CitySwitcher(
          locations: _locations,
          activeIndex: _activeIndex,
          onSelect: _selectLocation,
          onAdd: _addLocation,
          onRemove: _removeLocation,
        ),
      ),
    );
  }

  _MoodState get _mood {
    if (_weather == null) return _MoodState.sunny;
    final c = _weather!.current.condition;
    final isDay = _weather!.current.isDay;
    if (!isDay) {
      if (c == WeatherCondition.overcast || c == WeatherCondition.cloudy ||
          c == WeatherCondition.rain || c == WeatherCondition.heavyRain ||
          c == WeatherCondition.drizzle || c == WeatherCondition.thunderstorm) {
        return _MoodState.nightCloudy;
      }
      return _MoodState.night;
    }
    if (c == WeatherCondition.rain ||
        c == WeatherCondition.heavyRain ||
        c == WeatherCondition.thunderstorm ||
        c == WeatherCondition.drizzle) { return _MoodState.rainy; }
    if (c == WeatherCondition.overcast || c == WeatherCondition.cloudy) { return _MoodState.overcast; }
    return _MoodState.sunny;
  }

  Color get _bgColor {
    switch (_mood) {
      case _MoodState.night: return const Color(0xFF1A1C2E);
      case _MoodState.nightCloudy: return const Color(0xFF181C28);
      case _MoodState.rainy: return const Color(0xFFF2F4F8);
      case _MoodState.overcast: return const Color(0xFFF5F6F9);
      case _MoodState.sunny: return const Color(0xFFFAFAF7);
    }
  }

  Color get _textColor {
    switch (_mood) {
      case _MoodState.night:
      case _MoodState.nightCloudy:
        return const Color(0xFFE8EDF5);
      default:
        return AppColors.sunnyText;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: (_mood == _MoodState.night || _mood == _MoodState.nightCloudy)
          ? Brightness.light
          : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _bgColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: Stack(
          key: ValueKey(_mood),
          fit: StackFit.expand,
          children: [
            _buildMoodBackground(),
            SafeArea(
              child: _loading
                  ? _buildLoading()
                  : _error != null
                      ? _buildError()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodBackground() {
    final gradient = switch (_mood) {
      _MoodState.sunny => const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFFFCFA0), Color(0xFFF8F4EE), Color(0xFFEDD4F8)],
          stops: [0.0, 0.52, 1.0],
        ),
      _MoodState.overcast => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCDD5E4), Color(0xFFF0F2F5)],
        ),
      _MoodState.rainy => const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFB4C4DC), Color(0xFFECEFF6)],
        ),
      _MoodState.night => const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF2E3468), Color(0xFF1A1C2E), Color(0xFF282048)],
          stops: [0.0, 0.52, 1.0],
        ),
      _MoodState.nightCloudy => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2840), Color(0xFF181C28), Color(0xFF1E2030)],
          stops: [0.0, 0.55, 1.0],
        ),
    };
    return Container(decoration: BoxDecoration(gradient: gradient));
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 1.5,
        color: _textColor.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load weather',
                style: AppTextStyles.bodyMedium(_textColor)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _fetchWeather,
              child: Text('Try again',
                  style: AppTextStyles.bodyMedium(_textColor).copyWith(
                    decoration: TextDecoration.underline,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final w = _weather!;
    final loc = _locations[_activeIndex];
    final locationNow = DateTime.now().toUtc().add(Duration(seconds: w.utcOffsetSeconds));
    final dateStr = DateFormat('EEEE · MMM d').format(locationNow);

    return RefreshIndicator(
      onRefresh: _fetchWeather,
      color: _textColor,
      backgroundColor: _bgColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Top bar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showCitySwitcher,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(loc.name, style: AppTextStyles.locationName(_textColor)),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, size: 16, color: _textColor.withValues(alpha: 0.45)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(dateStr, style: AppTextStyles.dateLabel(_textColor)),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showSettings(context),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(Icons.more_horiz,
                        color: _textColor.withValues(alpha: 0.55), size: 22),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 36),

            // Hero
            Center(
              child: Column(
                children: [
                  WeatherIcon(
                    condition: w.hourly.isNotEmpty
                        ? w.hourly.first.condition
                        : w.current.condition,
                    size: 44,
                    color: _textColor.withValues(alpha: 0.85),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(w.hourly.isNotEmpty ? w.hourly.first.temperature : w.current.temperature).round()}°',
                    style: AppTextStyles.hero(_textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Feels like ${w.current.feelsLike.round()}°  ·  H: ${w.current.dailyHigh.round()}  L: ${w.current.dailyLow.round()}',
                    style: AppTextStyles.feelsLike(_textColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Nowcast pill
            NowcastPill(
              message: w.nowcastMessage,
              isRaining: w.isRaining,
              textColor: _textColor,
              hourlyPrecip: w.hourly.take(6).map((h) => h.precipitationProbability).toList(),
            ),

            const SizedBox(height: 28),

            // Confidence strip
            ConfidenceStrip(
              confidence: w.confidence,
              textColor: _textColor,
            ),

            const SizedBox(height: 24),

            // Hourly chart
            HourlyChart(
              hours: w.hourly,
              textColor: _textColor,
            ),

            const SizedBox(height: 20),

            // This week
            Text(
              'THIS WEEK',
              style: AppTextStyles.sectionLabel(_textColor),
            ),
            const SizedBox(height: 8),

            DailyForecastList(
              days: w.daily,
              textColor: _textColor,
              yesterday: _showYesterday ? w.yesterday : null,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAF7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
              const SizedBox(height: 20),
              _SettingRow(label: 'Mode', value: 'Simple', onTap: () {}),
              _SettingRow(label: 'Units', value: '°C / km/h', onTap: () {}),
              _SettingRow(label: 'Morning digest', value: '7:00 AM', onTap: () {}),
              _SettingToggleRow(
                label: 'Yesterday',
                subtitle: 'Compare with previous day in forecast',
                value: _showYesterday,
                onChanged: (v) {
                  setSheetState(() {});
                  setState(() => _showYesterday = v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SettingRow({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E))),
            Row(
              children: [
                Text(value, style: const TextStyle(fontSize: 15, color: Color(0x881A1A2E))),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 16, color: Color(0x441A1A2E)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _MoodState { sunny, rainy, overcast, night, nightCloudy }

class _SettingToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E))),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0x661A1A2E))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1A1A2E),
          ),
        ],
      ),
    );
  }
}

