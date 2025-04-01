import 'package:flutter/material.dart';

class AppColors {
  // Primary color (MaterialColor instead of Color)
  static const MaterialColor primary = MaterialColor(
    0xFF1A73E8, // Main color
    <int, Color>{
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(0xFF1A73E8), // Main color (primary shade)
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
    },
  );

  // Secondary color
  static const Color secondary = Color(0xFF34A853);

  // Background colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF212121);

  // Text colors
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.grey;
  static const Color textOnPrimary = Colors.white;

  // Accent colors
  static const Color accent = Color(0xFFFFEB3B);
  static const Color accentSecondary = Color(0xFFFF5722);

  // Border and divider colors
  static const Color border = Color(0xFFDDDDDD);
  static const Color divider = Color(0xFFBDBDBD);
}
