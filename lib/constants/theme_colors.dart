// lib/constants/theme_colors.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

class ThemeColors {
  final bool isDark;
  final bool useAmoled;

  ThemeColors({required this.isDark, this.useAmoled = false});

  Color get background {
    if (isDark && useAmoled) return Colors.black;
    if (isDark) return const Color(0xFF1A1A1A);
    return AppColors.bgBlue;
  }

  Color get surface {
    if (isDark && useAmoled) return const Color(0xFF0A0A0A);
    if (isDark) return const Color(0xFF2C2C2C);
    return Colors.white;
  }

  Color get text => isDark ? Colors.white : Colors.black87;
  Color get textSecondary => isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  Color get divider => isDark ? Colors.grey.shade800 : Colors.grey.shade200;
}