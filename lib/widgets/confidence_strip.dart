import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../theme/app_theme.dart';

class ConfidenceStrip extends StatelessWidget {
  final List<DayConfidence> confidence;
  final Color textColor;
  final Function(int)? onDayTap;

  const ConfidenceStrip({
    super.key,
    required this.confidence,
    required this.textColor,
    this.onDayTap,
  });

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  double _opacityFor(ConfidenceLevel level, int index) {
    if (index <= 1) return 1.0;
    switch (level) {
      case ConfidenceLevel.high: return 1.0;
      case ConfidenceLevel.medium: return 0.50;
      case ConfidenceLevel.low: return 0.22;
    }
  }

  String _summaryText() {
    int highCount = 0;
    for (final c in confidence) {
      if (c.level == ConfidenceLevel.high) { highCount++; }
      else { break; }
    }
    if (highCount >= 5) return 'High confidence all week';
    if (highCount >= 3) {
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return 'High confidence through ${days[highCount - 1]}';
    }
    return 'Confidence decreases mid-week';
  }

  String _confidenceExplain(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return 'Models agree closely on this day. Forecast is reliable.';
      case ConfidenceLevel.medium:
        return 'Some model disagreement. Forecast is likely but check back closer to the day.';
      case ConfidenceLevel.low:
        return 'Models diverge significantly. Treat this as a rough guide only.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = confidence.take(7).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FORECAST CONFIDENCE',
          style: AppTextStyles.sectionLabel(textColor),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(days.length, (i) {
            final opacity = _opacityFor(days[i].level, i);
            return Expanded(
              child: GestureDetector(
                onTap: () => _showExplainer(context, days[i], i),
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(days.length, (i) => Expanded(
            child: Center(
              child: Text(
                _days[i % 7],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: textColor.withValues(alpha: 0.45),
                ),
              ),
            ),
          )),
        ),
        const SizedBox(height: 6),
        Text(
          _summaryText(),
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: textColor.withValues(alpha: 0.50),
          ),
        ),
      ],
    );
  }

  void _showExplainer(BuildContext context, DayConfidence day, int index) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final label = index == 0 ? 'Today' : days[index % 7];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfidenceSheet(
        dayLabel: label,
        level: day.level,
        explanation: _confidenceExplain(day.level),
      ),
    );
  }
}

class _ConfidenceSheet extends StatelessWidget {
  final String dayLabel;
  final ConfidenceLevel level;
  final String explanation;

  const _ConfidenceSheet({
    required this.dayLabel,
    required this.level,
    required this.explanation,
  });

  String get _levelLabel {
    switch (level) {
      case ConfidenceLevel.high: return 'High confidence';
      case ConfidenceLevel.medium: return 'Medium confidence';
      case ConfidenceLevel.low: return 'Low confidence';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(dayLabel,
              style: const TextStyle( fontSize: 13, color: Color(0x881A1A2E))),
          const SizedBox(height: 4),
          Text(_levelLabel,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          Text(explanation,
              style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          Text('Confidence is not severity.',
              style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF1A1A2E).withValues(alpha: 0.45))),
        ],
      ),
    );
  }
}


