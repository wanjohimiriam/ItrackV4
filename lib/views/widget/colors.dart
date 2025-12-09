// lib/utils/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF17A2B8); // Cyan/Teal
  static const Color primaryDark = Color(0xFF138496); // Darker shade
  static const Color primaryLight = Color(0xFF5AC8D8); // Lighter shade
  
  // Background Colors
  static const Color background = Color(0xFFFFFFFF); // White
  static const Color cardBackground = Color(0xFFFFFFFF); // White
  
  // Text Colors
  static const Color textPrimary = Color(0xFF000000); // Black
  static const Color textSecondary = Color(0xFF666666); // Gray (derived from black)
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on cyan
  
  // Accent Colors
  static const Color accent = Color(0xFF17A2B8); // Same as primary
  static const Color error = Color(0xFFDC3545); // Red (complementary)
  static const Color warning = Color(0xFFFFC107); // Yellow (complementary)
  static const Color success = Color(0xFF28A745); // Green (complementary)
  
  // Border Colors
  static const Color border = Color(0xFFE0E0E0); // Light gray
  static const Color borderFocused = Color(0xFF17A2B8); // Cyan when focused
}

class AppStyles {
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  
  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}