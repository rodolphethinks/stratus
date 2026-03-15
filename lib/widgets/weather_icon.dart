import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weather.dart';

/// Draws a single-colour outlined weather icon using canvas primitives.
class WeatherIcon extends StatelessWidget {
  final WeatherCondition condition;
  final double size;
  final Color color;

  const WeatherIcon({
    super.key,
    required this.condition,
    this.size = 32,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WeatherIconPainter(condition: condition, color: color),
    );
  }
}

class _WeatherIconPainter extends CustomPainter {
  final WeatherCondition condition;
  final Color color;

  _WeatherIconPainter({required this.condition, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    switch (condition) {
      case WeatherCondition.clearDay:
        _drawSun(canvas, paint, cx, cy, size);
        break;
      case WeatherCondition.clearNight:
        _drawMoon(canvas, paint, cx, cy, size);
        break;
      case WeatherCondition.partlyCloudy:
        _drawPartlyCloudy(canvas, paint, cx, cy, size);
        break;
      case WeatherCondition.partlyCloudyNight:
        _drawPartlyCloudyNight(canvas, paint, cx, cy, size);
        break;
      case WeatherCondition.cloudy:
      case WeatherCondition.overcast:
        _drawCloud(canvas, paint, cx, cy, size);
        break;
      case WeatherCondition.drizzle:
      case WeatherCondition.rain:
      case WeatherCondition.heavyRain:
        _drawRain(canvas, paint, cx, cy, size);
        break;
      case WeatherCondition.thunderstorm:
        _drawThunder(canvas, paint, cx, cy, size);
        break;
      case WeatherCondition.snow:
        _drawSnow(canvas, paint, cx, cy, size);
        break;
      case WeatherCondition.fog:
        _drawFog(canvas, paint, cx, cy, size);
        break;
      default:
        _drawSun(canvas, paint, cx, cy, size);
    }
  }

  void _drawSun(Canvas canvas, Paint paint, double cx, double cy, Size size) {
    final r = size.width * 0.22;
    canvas.drawCircle(Offset(cx, cy), r, paint);
    final rayLen = size.width * 0.13;
    final rayStart = r + size.width * 0.06;
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        Offset(cx + rayStart * math.cos(angle), cy + rayStart * math.sin(angle)),
        Offset(cx + (rayStart + rayLen) * math.cos(angle), cy + (rayStart + rayLen) * math.sin(angle)),
        paint,
      );
    }
  }

  void _drawMoon(Canvas canvas, Paint paint, double cx, double cy, Size size) {
    // Draw a bold crescent using two circles: outer drawn, inner clipped out
    final outerR = size.width * 0.32;
    final innerR = size.width * 0.24;
    final offset = size.width * 0.14;

    final path = Path();
    // Outer full circle
    path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: outerR));
    // Subtract inner circle shifted right (creates crescent pointing left)
    path.addOval(Rect.fromCircle(center: Offset(cx + offset, cy - offset * 0.3), radius: innerR));
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill,
    );
  }

  void _drawCloud(Canvas canvas, Paint paint, double cx, double cy, Size size) {
    final s = size.width;
    // Cloud made of overlapping circles
    final bigR = s * 0.18;
    final smallR = s * 0.13;
    final midR = s * 0.155;
    // Bottom baseline
    final baseY = cy + s * 0.10;
    // Circle centres
    final c1 = Offset(cx - s * 0.14, baseY - smallR); // left bump
    final c2 = Offset(cx + s * 0.02, baseY - bigR);   // centre bump (tallest)
    final c3 = Offset(cx + s * 0.18, baseY - midR);   // right bump
    // Bottom rectangle
    final rectLeft = cx - s * 0.27;
    final rectRight = cx + s * 0.27;
    final rectBottom = baseY;

    // Draw outline path
    final path = Path();
    // Start at bottom-left
    path.moveTo(rectLeft + s * 0.04, rectBottom);
    // Left arc (c1)
    path.arcToPoint(Offset(c1.dx - smallR, c1.dy),
        radius: Radius.circular(s * 0.04), clockwise: false);
    path.arcToPoint(Offset(c1.dx, c1.dy - smallR),
        radius: Radius.circular(smallR), clockwise: false);
    // Centre arc (c2)
    path.arcToPoint(Offset(c2.dx, c2.dy - bigR),
        radius: Radius.circular(s * 0.10), clockwise: false);
    path.arcToPoint(Offset(c3.dx, c3.dy - midR),
        radius: Radius.circular(bigR), clockwise: false);
    // Right arc (c3)
    path.arcToPoint(Offset(c3.dx + midR, c3.dy),
        radius: Radius.circular(midR), clockwise: false);
    path.arcToPoint(Offset(rectRight - s * 0.02, rectBottom),
        radius: Radius.circular(s * 0.04), clockwise: false);
    // Bottom straight
    path.lineTo(rectLeft + s * 0.04, rectBottom);
    canvas.drawPath(path, paint);
  }

  void _drawPartlyCloudy(Canvas canvas, Paint paint, double cx, double cy, Size size) {
    // Sun in upper-left
    final sunCx = cx - size.width * 0.14;
    final sunCy = cy - size.height * 0.16;
    final sr = size.width * 0.14;
    canvas.drawCircle(Offset(sunCx, sunCy), sr, paint);
    final rayLen = size.width * 0.08;
    final rayStart = sr + size.width * 0.04;
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        Offset(sunCx + rayStart * math.cos(angle), sunCy + rayStart * math.sin(angle)),
        Offset(sunCx + (rayStart + rayLen) * math.cos(angle), sunCy + (rayStart + rayLen) * math.sin(angle)),
        paint,
      );
    }
    // Small cloud in lower-right
    _drawCloud(canvas, paint, cx + size.width * 0.08, cy + size.height * 0.08, size * 0.75);
  }

  void _drawPartlyCloudyNight(Canvas canvas, Paint paint, double cx, double cy, Size size) {
    // Small filled crescent moon in upper-left
    final moonCx = cx - size.width * 0.14;
    final moonCy = cy - size.height * 0.16;
    final outerR = size.width * 0.18;
    final innerR = size.width * 0.135;
    final offset = size.width * 0.08;

    final moonPath = Path();
    moonPath.addOval(Rect.fromCircle(center: Offset(moonCx, moonCy), radius: outerR));
    moonPath.addOval(Rect.fromCircle(center: Offset(moonCx + offset, moonCy - offset * 0.3), radius: innerR));
    moonPath.fillType = PathFillType.evenOdd;
    canvas.drawPath(
      moonPath,
      Paint()..color = paint.color..style = PaintingStyle.fill,
    );

    // Small cloud in lower-right
    _drawCloud(canvas, paint, cx + size.width * 0.08, cy + size.height * 0.08, size * 0.75);
  }

  void _drawRain(Canvas canvas, Paint paint, double cx, double cy, Size size) {
    _drawCloud(canvas, paint, cx, cy - size.height * 0.10, size);
    final spacing = size.width * 0.15;
    for (int i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(cx + i * spacing, cy + size.height * 0.16),
        Offset(cx + i * spacing - size.width * 0.05, cy + size.height * 0.30),
        paint,
      );
    }
  }

  void _drawThunder(Canvas canvas, Paint paint, double cx, double cy, Size size) {
    _drawCloud(canvas, paint, cx, cy - size.height * 0.12, size);
    final boltPath = Path();
    boltPath.moveTo(cx + size.width * 0.04, cy + size.height * 0.10);
    boltPath.lineTo(cx - size.width * 0.06, cy + size.height * 0.22);
    boltPath.lineTo(cx + size.width * 0.02, cy + size.height * 0.22);
    boltPath.lineTo(cx - size.width * 0.06, cy + size.height * 0.36);
    canvas.drawPath(boltPath, paint);
  }

  void _drawSnow(Canvas canvas, Paint paint, double cx, double cy, Size size) {
    _drawCloud(canvas, paint, cx, cy - size.height * 0.10, size);
    final spacing = size.width * 0.15;
    for (int i = -1; i <= 1; i++) {
      final sx = cx + i * spacing;
      canvas.drawLine(
        Offset(sx, cy + size.height * 0.18),
        Offset(sx, cy + size.height * 0.28),
        paint,
      );
      canvas.drawCircle(Offset(sx, cy + size.height * 0.23), size.width * 0.025, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
    }
  }

  void _drawFog(Canvas canvas, Paint paint, double cx, double cy, Size size) {
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;
    for (int i = -1; i <= 1; i++) {
      final y = cy + i * size.height * 0.14;
      final xOffset = i == 0 ? 0.0 : size.width * 0.06;
      canvas.drawLine(
        Offset(cx - size.width * 0.26 + xOffset, y),
        Offset(cx + size.width * 0.26 - xOffset, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherIconPainter old) =>
      old.condition != condition || old.color != color;
}


