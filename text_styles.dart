import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  // Heading text style
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // Subheading text style
  static const TextStyle subheading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body text style for general content
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
    height: 1.5, // Improved readability
  );

  // Secondary body text style with lighter color
  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Credits text style with italic font
  static const TextStyle credits = TextStyle(
    fontSize: 16,
    fontStyle: FontStyle.italic,
    color: AppColors.textPrimary,
  );

  // Accent text style with bold font and accent color
  static const TextStyle accentText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.accent,
  );
}
