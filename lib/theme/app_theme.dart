import 'package:flutter/material.dart';

class AppColors {
  // Sunny mood
  static const Color sunnyBackground = Color(0xFFFAFAF7);
  static const Color sunnyText = Color(0xFF1A1A2E);
  static const Color sunnySubtle = Color(0xFF1A1A2E);

  // Rainy mood
  static const Color rainyBackground = Color(0xFF1C2333);
  static const Color rainyText = Color(0xFFE8EDF2);

  // Overcast mood
  static const Color overcastBackground = Color(0xFFF0F2F5);
  static const Color overcastText = Color(0xFF1A1A2E);

  // Accent
  static const Color nowcastGreen = Color(0xFF2D9B5A);
  static const Color nowcastGreenBg = Color(0xFFE8F5EE);
  static const Color warmBar = Color(0xFFE8903A);
  static const Color coolBar = Color(0xFF6B9FD4);
  static const Color neutralBar = Color(0xFFABB4C4);
  static const Color precipBlue = Color(0xFF7BACD4);

  // Confidence strip
  static const Color confidenceHigh = Color(0xFF1A1A2E);
  static const Color confidenceMed = Color(0xFF1A1A2E);
  static const Color confidenceLow = Color(0xFF1A1A2E);
}

class AppTextStyles {
  static const String fontFamily = 'Roboto'; // system Roboto on Android, SF Pro on iOS

  static TextStyle hero(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 88,
        fontWeight: FontWeight.w200,
        color: color,
        height: 1.0,
      );

  static TextStyle locationName(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle dateLabel(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color.withValues(alpha: 0.55),
      );

  static TextStyle feelsLike(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color.withValues(alpha: 0.60),
      );

  static TextStyle sectionLabel(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: color.withValues(alpha: 0.45),
      );

  static TextStyle bodyMedium(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle caption(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color.withValues(alpha: 0.55),
      );

  static TextStyle dayLabel(Color color, {bool isToday = false}) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
        color: color,
      );

  static TextStyle tempBig(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle tempSmall(Color color) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color.withValues(alpha: 0.50),
      );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.sunnyBackground),
        scaffoldBackgroundColor: AppColors.sunnyBackground,
        useMaterial3: true,
      );
}


