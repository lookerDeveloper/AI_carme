import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF1557B0);
  static const Color primaryLight = Color(0xFF4A90D9);

  static const Color accent = Color(0xFFFF6B35);
  static const Color accentDark = Color(0xFFE55A2B);

  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceVariant = Color(0xFF2A2A2A);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF707070);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);

  static const Color overlay = Color(0x99000000);
  static const Color overlayLight = Color(0x66000000);

  static const Color scoreExcellent = Color(0xFF4CAF50);
  static const Color scoreGood = Color(0xFF8BC34A);
  static const Color scoreAverage = Color(0xFFFFC107);
  static const Color scorePoor = Color(0xFFF44336);

  static Color scoreColor(double score) {
    if (score >= 85) return scoreExcellent;
    if (score >= 70) return scoreGood;
    if (score >= 50) return scoreAverage;
    return scorePoor;
  }
}
