// lib/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color brandMain = Color(0xFF38B6FF);
  static const Color brandDark = Color(0xFF003F67);
  static const Color brandLight = Color(0xFFD6F9FF);
  static const Color cardPink = Color(0xFFFCE4EC);
  static const Color bgBlue = Color(0xFFE0F7FA);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightText = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF666666);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF2C2C2C);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);

  // AMOLED
  static const Color amoledBlack = Color(0xFF000000);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // ════════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ════════════════════════════════════════════════════════════════════════════

  /// Get background color based on theme
  static Color getBackground(bool isDark, {bool useAmoled = false}) {
    if (isDark && useAmoled) return amoledBlack;
    if (isDark) return darkBackground;
    return bgBlue;
  }

  /// Get surface/card color based on theme
  static Color getSurface(bool isDark, {bool useAmoled = false}) {
    if (isDark && useAmoled) return const Color(0xFF0A0A0A);
    if (isDark) return darkSurface;
    return lightBackground;
  }

  /// Get text color based on theme
  static Color getText(bool isDark) {
    return isDark ? darkText : lightText;
  }

  /// Get secondary text color based on theme
  static Color getTextSecondary(bool isDark) {
    return isDark ? darkTextSecondary : lightTextSecondary;
  }
}