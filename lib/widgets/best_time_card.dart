import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../theme/app_theme.dart';

class BestTimeCard extends StatelessWidget {
  final List<HourlyWeather> hours;
  final Color textColor;

  const BestTimeCard({
    super.key,
    required this.hours,
    required this.textColor,
  });

  /// Find the best 2-hour daytime window in the next 24h where:
  ///   - isDay is true
  ///   - precipitation probability < 25%
  ///   - temperature in reasonable outdoor range (5–36°C)
  ({String timeRange, String reason, bool found}) _bestWindow() {
    for (int i = 0; i < hours.length - 1; i++) {
      final h = hours[i];
      final h2 = hours[i + 1];
      if (h.isDay &&
          h.precipitationProbability < 25 &&
          h.temperature >= 5 &&
          h.temperature <= 36 &&
          h2.isDay &&
          h2.precipitationProbability < 25) {
        final start = _fmt(h.time.hour);
        final endHour = (h2.time.hour + 1).clamp(0, 23);
        final end = _fmt(endHour);
        final reason = _reason(h);
        return (timeRange: '$start – $end', reason: reason, found: true);
      }
    }
    return (timeRange: '', reason: '', found: false);
  }

  String _reason(HourlyWeather h) {
    final isRainy = h.condition == WeatherCondition.rain ||
        h.condition == WeatherCondition.heavyRain ||
        h.condition == WeatherCondition.drizzle ||
        h.condition == WeatherCondition.thunderstorm ||
        h.condition == WeatherCondition.snow;
    if (isRainy || h.precipitationProbability >= 15) return 'Low rain risk';
    if (h.temperature >= 22) return 'Warm & clear';
    if (h.temperature >= 12) return 'Fresh & dry';
    return 'Cool & clear';
  }

  String _fmt(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  @override
  Widget build(BuildContext context) {
    final result = _bestWindow();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            result.found ? Icons.directions_walk : Icons.home_outlined,
            size: 26,
            color: textColor.withValues(alpha: 0.50),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BEST TIME OUTSIDE',
                  style: AppTextStyles.sectionLabel(textColor),
                ),
                const SizedBox(height: 3),
                if (result.found) ...[
                  Text(
                    result.timeRange,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    result.reason,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withValues(alpha: 0.60),
                    ),
                  ),
                ] else
                  Text(
                    'Challenging conditions today',
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor.withValues(alpha: 0.65),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
