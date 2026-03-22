import 'package:flutter/material.dart';
import '../models/weather.dart';

class EnthusiastMetrics extends StatelessWidget {
  final CurrentWeather current;
  final double currentUv;
  final Color textColor;

  const EnthusiastMetrics({
    super.key,
    required this.current,
    required this.currentUv,
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

  @override
  Widget build(BuildContext context) {
    return Row(
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
          icon: Icons.opacity,
          label: 'Humidity',
          value: '${current.humidity}',
          unit: '%',
          textColor: textColor,
        ),
        const SizedBox(width: 8),
        _MetricTile(
          icon: Icons.wb_sunny,
          label: 'UV Index',
          value: currentUv.round().toString(),
          unit: uvLabel(currentUv),
          valueColor: uvColor(currentUv),
          textColor: textColor,
        ),
        const SizedBox(width: 8),
        _MetricTile(
          icon: Icons.speed,
          label: 'Pressure',
          value: '${current.surfacePressure.round()}',
          unit: 'hPa',
          textColor: textColor,
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
  final Color textColor;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.detail,
    this.valueColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: textColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: textColor.withValues(alpha: 0.55)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: valueColor ?? textColor,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 11,
                color: textColor.withValues(alpha: 0.55),
              ),
            ),
            if (detail != null)
              Text(
                detail!,
                style: TextStyle(
                  fontSize: 11,
                  color: textColor.withValues(alpha: 0.40),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
