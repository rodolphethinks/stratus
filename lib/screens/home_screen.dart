import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import '../services/location_store.dart';
import '../services/settings_store.dart';
import '../theme/app_theme.dart';
import '../widgets/weather_icon.dart';
import '../widgets/nowcast_pill.dart';
import '../widgets/confidence_strip.dart';
import '../widgets/hourly_chart.dart';
import '../widgets/daily_forecast.dart';
import '../widgets/city_switcher.dart';
import '../widgets/best_time_card.dart';
import '../widgets/enthusiast_metrics.dart';
import '../widgets/astronomy_card.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final LocationStore _locationStore = LocationStore();
  final SettingsStore _settingsStore = SettingsStore();

  List<SavedLocation> _locations = [];
  int _activeIndex = 0;
  WeatherData? _weather;
  bool _loading = true;
  String? _error;

  AppMode _mode = AppMode.simple;
  AppSettings _settings = const AppSettings();
  DateTime? _fetchedAt; // for "as of" trust timestamp

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
    await _loadSettings();
    setState(() {
      _locations = locations;
      _activeIndex = activeIndex.clamp(0, locations.length - 1);
    });
    await _fetchWeather();
  }

  Future<void> _loadSettings() async {
    final mode = await _settingsStore.getMode();
    final settings = await _settingsStore.getSettings();
    if (mounted) setState(() { _mode = mode; _settings = settings; });
  }

  Future<void> _fetchWeather() async {
    if (_locations.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final loc = _locations[_activeIndex];
      final data = await _weatherService.fetchWeather(loc.latitude, loc.longitude);
      if (mounted) setState(() { _weather = data; _loading = false; _fetchedAt = DateTime.now(); });
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

  // Visibility helpers
  bool get _showConfidence =>
      _mode == AppMode.enthusiast || _settings.showConfidenceStrip;
  bool get _showBestTime =>
      _mode == AppMode.simple && _settings.showBestTimeCard;
  bool get _showMetrics =>
      _mode == AppMode.enthusiast && _settings.showMetricsRow;
  bool get _showAstronomy =>
      _mode == AppMode.enthusiast && _settings.showAstronomy;
  bool get _showYesterday => _settings.showYesterday;
  bool get _showSunriseSunset => _settings.showSunriseSunset;

  /// One-line smart summary of today's forecast from hourly data
  String _dayHeadline(List<HourlyWeather> hours) {
    if (hours.isEmpty) return '';
    bool isRainy(HourlyWeather h) =>
        h.precipitationProbability >= 30 ||
        h.condition == WeatherCondition.rain ||
        h.condition == WeatherCondition.heavyRain ||
        h.condition == WeatherCondition.drizzle ||
        h.condition == WeatherCondition.thunderstorm ||
        h.condition == WeatherCondition.snow;

    if (hours.any((h) => h.condition == WeatherCondition.thunderstorm)) {
      return 'Thunderstorms possible today';
    }
    if (hours.any((h) => h.condition == WeatherCondition.snow)) {
      return 'Snow expected today';
    }

    final daytimeHours = hours.where((h) => h.isDay).toList();
    final morningH = hours.where((h) => h.time.hour >= 6 && h.time.hour < 12).toList();
    final afternoonH = hours.where((h) => h.time.hour >= 12 && h.time.hour < 18).toList();

    final morningRain = morningH.isNotEmpty && morningH.any(isRainy);
    final afternoonRain = afternoonH.isNotEmpty && afternoonH.any(isRainy);
    final allRain = daytimeHours.isNotEmpty && daytimeHours.every(isRainy);
    final noRain = !hours.any(isRainy);

    if (allRain) return 'Rain expected throughout the day';
    if (noRain) {
      final maxTemp = hours.map((h) => h.temperature).reduce((a, b) => a > b ? a : b);
      if (maxTemp >= 30) return 'Hot and sunny today';
      if (maxTemp >= 22) return 'Sunny and warm today';
      return 'Clear skies all day';
    }
    if (morningRain && !afternoonRain) return 'Rain this morning, clearing this afternoon';
    if (!morningRain && afternoonRain) return 'Clear morning, rain this afternoon';
    return 'Showers possible today';
  }

  void _openSettings() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const SettingsScreen(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    );
    await _loadSettings();
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
    final asOfStr = _fetchedAt != null
        ? DateFormat('h:mm a').format(_fetchedAt!)
        : null;
    final headline = _dayHeadline(w.hourly);

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
                        if (asOfStr != null) ...[  
                          const SizedBox(height: 1),
                          Text(
                            'Updated $asOfStr',
                            style: AppTextStyles.dateLabel(_textColor).copyWith(
                              fontSize: 11,
                              color: _textColor.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _openSettings,
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
                  const SizedBox(height: 4),
                  Text(
                    conditionLabel(w.current.condition),
                    style: AppTextStyles.dateLabel(_textColor).copyWith(
                      color: _textColor.withValues(alpha: 0.60),
                      letterSpacing: 0.2,
                    ),
                  ),
                  // Smart day summary — Simple mode only
                  if (_mode == AppMode.simple && headline.isNotEmpty) ...[  
                    const SizedBox(height: 2),
                    Text(
                      headline,
                      style: AppTextStyles.dateLabel(_textColor).copyWith(
                        fontSize: 13,
                        color: _textColor.withValues(alpha: 0.50),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 4),
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

            // Enthusiast metrics row
            if (_showMetrics) ...[
              const SizedBox(height: 20),
              EnthusiastMetrics(
                current: w.current,
                currentUv: w.hourly.isNotEmpty ? w.hourly.first.uvIndex : 0.0,
                currentVisibility: w.hourly.isNotEmpty ? w.hourly.first.visibility : 0.0,
                pressureTrend: w.pressureTrend,
                textColor: _textColor,
              ),
            ],

            const SizedBox(height: 28),

            // Nowcast pill
            NowcastPill(
              message: w.nowcastMessage,
              isRaining: w.isRaining,
              textColor: _textColor,
              hourlyPrecip: w.hourly.take(6).map((h) => h.precipitationProbability).toList(),
            ),

            // Best time card — Simple mode only
            if (_showBestTime) ...[  
              const SizedBox(height: 16),
              BestTimeCard(hours: w.hourly, textColor: _textColor),
            ],

            // Astronomy card — Enthusiast mode only
            if (_showAstronomy) ...[  
              const SizedBox(height: 16),
              AstronomyCard(
                sunriseTime: w.daily.isNotEmpty ? w.daily.first.sunriseTime : null,
                sunsetTime: w.daily.isNotEmpty ? w.daily.first.sunsetTime : null,
                textColor: _textColor,
              ),
            ],

            // Confidence strip — always in Enthusiast, toggleable in Simple
            if (_showConfidence) ...[  
              const SizedBox(height: 28),
              ConfidenceStrip(
                confidence: w.confidence,
                textColor: _textColor,
              ),
            ],

            const SizedBox(height: 24),

            // Hourly chart
            HourlyChart(
              hours: w.hourly,
              textColor: _textColor,
              sunriseTime: _showSunriseSunset && w.daily.isNotEmpty
                  ? w.daily.first.sunriseTime
                  : null,
              sunsetTime: _showSunriseSunset && w.daily.isNotEmpty
                  ? w.daily.first.sunsetTime
                  : null,
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

}

enum _MoodState { sunny, rainy, overcast, night, nightCloudy }

