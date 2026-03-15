import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../widgets/weather_icon.dart';

class HourlyChart extends StatelessWidget {
  final List<HourlyWeather> hours;
  final Color textColor;

  const HourlyChart({
    super.key,
    required this.hours,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    const colWidth = 60.0;
    final visible = hours.take(24).toList();
    final totalWidth = visible.length * colWidth;
    return SizedBox(
      height: 140,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          height: 140,
          child: CustomPaint(
            painter: _HourlyChartPainter(
              hours: visible,
              textColor: textColor,
            ),
            child: Row(
              children: visible.map((h) {
                return SizedBox(
                  width: colWidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      WeatherIcon(
                        condition: h.condition,
                        size: 20,
                        color: textColor.withValues(alpha: 0.75),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _HourlyChartPainter extends CustomPainter {
  final List<HourlyWeather> hours;
  final Color textColor;

  _HourlyChartPainter({required this.hours, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (hours.isEmpty) return;

    final temps = hours.map((h) => h.temperature).toList();
    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final tempRange = (maxTemp - minTemp).clamp(6.0, double.infinity);

    // Chart area: icons take top 38pt, time labels take bottom 18pt
    const iconHeight = 38.0;
    const timeHeight = 18.0;
    const precipHeight = 20.0;
    final chartTop = iconHeight;
    final chartBottom = size.height - timeHeight - precipHeight;
    final chartHeight = chartBottom - chartTop;

    final n = hours.length;
    final colWidth = size.width / n;

    List<Offset> points = [];
    for (int i = 0; i < n; i++) {
      final norm = (hours[i].temperature - minTemp) / tempRange;
      final x = colWidth * (i + 0.5);
      final y = chartBottom - norm * chartHeight * 0.7 - chartHeight * 0.1;
      points.add(Offset(x, y));
    }

    // Draw area fill under curve
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, chartBottom);
    fillPath.lineTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i - 1].dy);
      final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }
    fillPath.lineTo(points.last.dx, chartBottom);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()..color = textColor.withValues(alpha: 0.05),
    );

    // Draw curve line
    final curvePath = Path();
    curvePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp1 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i - 1].dy);
      final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
      curvePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
    }

    canvas.drawPath(
      curvePath,
      Paint()
        ..color = textColor.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    // Draw temperature labels above each point
    for (int i = 0; i < points.length; i++) {
      final tempStr = '${hours[i].temperature.round()}°';
      final tp = TextPainter(
        text: TextSpan(
          text: tempStr,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(points[i].dx - tp.width / 2, points[i].dy - tp.height - 4));
    }

    // Draw time labels
    for (int i = 0; i < n; i++) {
      final h = hours[i];
      String label;
      if (i == 0) {
        label = 'Now';
      } else if (h.time.minute == 0) {
        final hour = h.time.hour;
        label = hour == 0 ? '12AM' : hour < 12 ? '${hour}AM' : hour == 12 ? '12PM' : '${hour - 12}PM';
      } else {
        final hour = h.time.hour;
        label = hour < 12 ? '${hour}AM' : '${hour - 12}PM';
      }

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 10,
            color: textColor.withValues(alpha: 0.50),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = colWidth * (i + 0.5);
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - timeHeight + 2));
    }

    // Draw precip bars — use textColor so they're visible on both light and dark backgrounds
    for (int i = 0; i < n; i++) {
      final prob = hours[i].precipitationProbability / 100.0;
      if (prob < 0.25) continue;
      final barHeight = precipHeight * prob * 0.85;
      final x = colWidth * (i + 0.5);
      final top = size.height - timeHeight - barHeight;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 2, top, 4, barHeight),
          const Radius.circular(2),
        ),
        Paint()..color = textColor.withValues(alpha: 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HourlyChartPainter old) => old.hours != hours;
}


