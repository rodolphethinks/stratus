import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../theme/app_theme.dart';
import '../widgets/weather_icon.dart';

class DailyForecastList extends StatelessWidget {
  final List<DailyWeather> days;
  final Color textColor;
  final DailyWeather? yesterday;

  const DailyForecastList({
    super.key,
    required this.days,
    required this.textColor,
    this.yesterday,
  });

  Color _barColor(double high) {
    if (high >= 22)  return AppColors.warmBar;                   // orange
    if (high >= 15)  return const Color(0xFFD4A455);             // amber
    if (high >= 8)   return AppColors.neutralBar;                // cool grey
    if (high >= 0)   return AppColors.coolBar;                   // blue
    if (high >= -10) return const Color(0xFF5B7FC4);             // deep blue
    if (high >= -20) return const Color(0xFF7055B0);             // blue-violet
    return const Color(0xFF8B45A0);                              // purple (arctic)
  }

  Color _barStartColor(double low) {
    if (low >= 0)    return AppColors.coolBar.withValues(alpha: 0.65);
    if (low >= -10)  return const Color(0xFF5B7FC4).withValues(alpha: 0.80);
    if (low >= -20)  return const Color(0xFF7055B0).withValues(alpha: 0.80);
    return const Color(0xFF8B45A0).withValues(alpha: 0.80);
  }

  @override
  Widget build(BuildContext context) {
    final visible = days.take(5).toList();
    // Use display-rounded values so bars with identical shown temps always align
    final weekHighR = visible.map((d) => d.high.round()).reduce((a, b) => a > b ? a : b).toDouble();
    final weekLowR  = visible.map((d) => d.low.round()).reduce((a, b) => a < b ? a : b).toDouble();
    final absRangeR = (weekHighR - weekLowR).clamp(1.0, double.infinity);

    Widget buildRow(DailyWeather d, String label, bool isToday, {double opacity = 1.0}) {
      final barColor = _barColor(d.high);
      final loR = d.low.round().toDouble();
      final hiR = d.high.round().toDouble();
      final barLeft  = ((loR - weekLowR) / absRangeR).clamp(0.0, 1.0);
      final barWidth = ((hiR - loR)      / absRangeR).clamp(0.0, 1.0 - barLeft);
      return Opacity(
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 72,
                  child: Text(label, style: AppTextStyles.dayLabel(textColor, isToday: isToday)),
                ),
                SizedBox(
                  width: 32,
                  child: Center(
                    child: WeatherIcon(
                      condition: d.condition,
                      size: 22,
                      color: textColor.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  child: Text('${d.low.round()}°',
                      style: AppTextStyles.tempSmall(textColor), textAlign: TextAlign.right),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(builder: (ctx, constraints) {
                    final totalWidth = constraints.maxWidth;
                    return Stack(children: [
                      Positioned(
                        left: barLeft * totalWidth,
                        width: (barWidth * totalWidth).clamp(6.0, totalWidth),
                        top: 0, bottom: 0,
                        child: Center(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_barStartColor(d.low), barColor],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ]);
                  }),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 30,
                  child: Text('${d.high.round()}°',
                      style: AppTextStyles.tempBig(textColor), textAlign: TextAlign.left),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (yesterday != null)
          buildRow(yesterday!, 'Yesterday', false, opacity: 0.38),
        ...List.generate(visible.length, (i) {
          final d = visible[i];
          final isToday = i == 0;
          final label = isToday ? 'Today' : _dayName(d.date);
          return buildRow(d, label, isToday);
        }),
      ],
    );
  }

  String _dayName(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }
}


