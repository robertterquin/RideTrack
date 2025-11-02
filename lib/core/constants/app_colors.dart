import 'package:flutter/material.dart';

/// RideTrack App Color Palette
/// Extracted from design reference - Orange/Purple/Grey theme
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors - Orange
  static const Color primaryOrange = Color(0xFFFF9966);
  static const Color primaryOrangeDark = Color(0xFFFF7744);
  static const Color primaryOrangeLight = Color(0xFFFFB088);

  // Secondary Colors - Purple/Indigo
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color primaryPurpleDark = Color(0xFF5449E6);
  static const Color primaryPurpleLight = Color(0xFF8E87FF);

  // Neutral Colors - Greys
  static const Color darkGrey = Color(0xFF424242);
  static const Color mediumGrey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFBDBDBD);
  static const Color backgroundGrey = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Background Colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF212121);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // Chart/Progress Colors
  static const Color chartOrange = Color(0xFFFF9966);
  static const Color chartPurple = Color(0xFF6C63FF);
  static const Color chartGrey = Color(0xFF9E9E9E);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, primaryOrangeDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [primaryPurple, primaryPurpleDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
