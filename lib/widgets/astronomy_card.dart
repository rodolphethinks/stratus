import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AstronomyCard extends StatelessWidget {
  final DateTime? sunriseTime;
  final DateTime? sunsetTime;
  final Color textColor;

  const AstronomyCard({
    super.key,
    this.sunriseTime,
    this.sunsetTime,
    required this.textColor,
  });

  String _fmt(DateTime? dt) {
    if (dt == null) return '--:--';
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    if (h == 0) return '12:$m AM';
    if (h < 12) return '$h:$m AM';
    if (h == 12) return '12:$m PM';
    return '${h - 12}:$m PM';
  }

  /// Returns 0.0 (new moon) → 0.5 (full moon) → approaching 1.0 (next new moon).
  static double moonPhase(DateTime date) {
    // Known new moon: Jan 6, 2000 UTC
    final known = DateTime.utc(2000, 1, 6);
    final diff = date.difference(known).inDays;
    const cycle = 29.530588853;
    final phase = (diff % cycle) / cycle;
    return phase < 0 ? phase + 1 : phase;
  }

  static String moonPhaseName(double p) {
    if (p < 0.0625) return 'New Moon';
    if (p < 0.1875) return 'Waxing Crescent';
    if (p < 0.3125) return 'First Quarter';
    if (p < 0.4375) return 'Waxing Gibbous';
    if (p < 0.5625) return 'Full Moon';
    if (p < 0.6875) return 'Waning Gibbous';
    if (p < 0.8125) return 'Last Quarter';
    if (p < 0.9375) return 'Waning Crescent';
    return 'New Moon';
  }

  static String moonEmoji(double p) {
    if (p < 0.0625) return '🌑';
    if (p < 0.1875) return '🌒';
    if (p < 0.3125) return '🌓';
    if (p < 0.4375) return '🌔';
    if (p < 0.5625) return '🌕';
    if (p < 0.6875) return '🌖';
    if (p < 0.8125) return '🌗';
    if (p < 0.9375) return '🌘';
    return '🌑';
  }

  @override
  Widget build(BuildContext context) {
    final phase = moonPhase(DateTime.now());
    final phaseName = moonPhaseName(phase);
    final emoji = moonEmoji(phase);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ASTRONOMY', style: AppTextStyles.sectionLabel(textColor)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AstroItem(
                emoji: '🌅',
                primary: _fmt(sunriseTime),
                secondary: 'Sunrise',
                textColor: textColor,
              ),
              _AstroItem(
                emoji: '🌇',
                primary: _fmt(sunsetTime),
                secondary: 'Sunset',
                textColor: textColor,
              ),
              _AstroItem(
                emoji: emoji,
                primary: phaseName,
                secondary: 'Moon',
                textColor: textColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AstroItem extends StatelessWidget {
  final String emoji;
  final String primary;
  final String secondary;
  final Color textColor;

  const _AstroItem({
    required this.emoji,
    required this.primary,
    required this.secondary,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          primary,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          secondary,
          style: TextStyle(
            fontSize: 11,
            color: textColor.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
