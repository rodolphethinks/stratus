import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../theme/app_theme.dart';

class BestTimeCard extends StatelessWidget {
  final List<HourlyWeather> hours;
  final Color textColor;
  final ActivityType activityType;
  final DateTime? sunriseTime;
  final DateTime? sunsetTime;

  const BestTimeCard({
    super.key,
    required this.hours,
    required this.textColor,
    this.activityType = ActivityType.walking,
    this.sunriseTime,
    this.sunsetTime,
  });

  /// Find the best 2-hour window using activity-specific criteria
  ({String timeRange, String reason, bool found}) _bestWindow() {
    for (int i = 0; i < hours.length - 1; i++) {
      final h = hours[i];
      final h2 = hours[i + 1];
      if (activityType.isSuitable(h, sunriseTime: sunriseTime, sunsetTime: sunsetTime) &&
          activityType.isSuitable(h2, sunriseTime: sunriseTime, sunsetTime: sunsetTime)) {
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
    if (activityType == ActivityType.photography) {
      return 'Golden hour light';
    }
    if (h.precipitationProbability < 10 && h.temperature >= 18) return 'Warm & clear';
    if (h.precipitationProbability < 15 && h.temperature >= 10) return 'Fresh & dry';
    if (h.precipitationProbability < 25) return 'Low rain risk';
    return 'Best window available';
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
          Text(
            result.found ? activityType.emoji : '🏠',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BEST TIME · ${activityType.displayName.toUpperCase()}',
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
