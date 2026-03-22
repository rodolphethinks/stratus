import 'package:flutter/material.dart';
import '../models/weather.dart';

class EnthusiastMetrics extends StatelessWidget {
  final CurrentWeather current;
  final double currentUv;
  final double currentVisibility; // km
  final PressureTrend pressureTrend;
  final Color textColor;

  const EnthusiastMetrics({
    super.key,
    required this.current,
    required this.currentUv,
    this.currentVisibility = 0.0,
    this.pressureTrend = PressureTrend.steady,
    required this.textColor,
  });

  static String compassDir(int degrees) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((degrees + 22) ~/ 45) % 8];
  }

  static String uvLabel(double uv) {
    if (uv < 3) return 'Low';
    if (uv < 6) return 'Moderate';
    if (uv < 8) return 'High';
    if (uv < 11) return 'Very High';
    return 'Extreme';
  }

  static Color uvColor(double uv) {
    if (uv < 3) return const Color(0xFF4CAF50);
    if (uv < 6) return const Color(0xFFFFC107);
    if (uv < 8) return const Color(0xFFFF9800);
    if (uv < 11) return const Color(0xFFF44336);
    return const Color(0xFF9C27B0);
  }

  static String _visLabel(double km) {
    if (km <= 0) return '--';
    if (km >= 10) return '${km.round()} km';
    return '${km.toStringAsFixed(1)} km';
  }

  String _trendGlyph() {
    switch (pressureTrend) {
      case PressureTrend.rising: return '↑';
      case PressureTrend.falling: return '↓';
      case PressureTrend.steady: return '→';
    }
  }

  Color _trendColor() {
    switch (pressureTrend) {
      case PressureTrend.rising: return const Color(0xFF4CAF50);
      case PressureTrend.falling: return const Color(0xFFF44336);
      case PressureTrend.steady: return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dew = current.dewPoint;
    final dewComfort = dew < 10 ? 'Comfortable' : dew < 16 ? 'Mild' : 'Humid';

    return Column(
      children: [
        // Row 1: Wind · Humidity · UV
        Row(
          children: [
            _MetricTile(
              icon: Icons.air,
              label: 'Wind',
              value: '${current.windSpeed.round()}',
              unit: 'km/h',
              detail: compassDir(current.windDirection),
              textColor: textColor,
            ),
            const SizedBox(width: 8),
            _MetricTile(
              icon: Icons.water_drop_outlined,
              label: 'Humidity',
              value: '${current.humidity}',
              unit: '%',
              textColor: textColor,
            ),
            const SizedBox(width: 8),
            _MetricTile(
              icon: Icons.wb_sunny_outlined,
              label: 'UV Index',
              value: currentUv.round().toString(),
              unit: uvLabel(currentUv),
              valueColor: uvColor(currentUv),
              textColor: textColor,
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2: Dew Point · Pressure (+trend) · Visibility
        Row(
          children: [
            _MetricTile(
              icon: Icons.thermostat_outlined,
              label: 'Dew Point',
              value: '${dew.round()}°',
              unit: dewComfort,
              textColor: textColor,
            ),
            const SizedBox(width: 8),
            _MetricTile(
              icon: Icons.speed,
              label: 'Pressure',
              value: '${current.surfacePressure.round()}',
              unit: 'hPa',
              detail: _trendGlyph(),
              detailColor: _trendColor(),
              textColor: textColor,
            ),
            const SizedBox(width: 8),
            _MetricTile(
              icon: Icons.visibility_outlined,
              label: 'Visibility',
              value: _visLabel(currentVisibility),
              unit: currentVisibility >= 10
                  ? 'Clear'
                  : currentVisibility >= 4
                      ? 'Good'
                      : currentVisibility >= 1
                          ? 'Moderate'
                          : 'Poor',
              textColor: textColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String? detail;
  final Color? valueColor;
  final Color? detailColor;
  final Color textColor;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.detail,
    this.valueColor,
    this.detailColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          color: textColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: textColor.withValues(alpha: 0.50)),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: valueColor ?? textColor,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: textColor.withValues(alpha: 0.50),
              ),
              textAlign: TextAlign.center,
            ),
            if (detail != null)
              Text(
                detail!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: detailColor ?? textColor.withValues(alpha: 0.40),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
