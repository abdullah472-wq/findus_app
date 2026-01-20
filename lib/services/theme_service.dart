import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // System brightness এর জন্য
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  // থিম সেটিংস মডেল (ValueNotifier)
  static final ValueNotifier<ThemeSettings> themeSettings = ValueNotifier(
    const ThemeSettings(
      isDarkMode: false,
      isAutoTheme: true,
      fontSize: 1.0,
      isHighContrast: false,
      isReducedMotion: false,
    ),
  );

  // SharedPreferences keys
  static const String _keyDarkMode = 'is_dark_mode';
  static const String _keyAutoTheme = 'is_auto_theme';
  static const String _keyFontSize = 'font_size';
  static const String _keyHighContrast = 'is_high_contrast';
  static const String _keyReducedMotion = 'is_reduced_motion';

  /// অ্যাপ স্টার্টের সময় থিম সেটিংস লোড করবে
  static Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedIsDarkMode = prefs.getBool(_keyDarkMode) ?? false;
      final isAutoTheme = prefs.getBool(_keyAutoTheme) ?? true;
      final fontSize = prefs.getDouble(_keyFontSize) ?? 1.0;
      final isHighContrast = prefs.getBool(_keyHighContrast) ?? false;
      final isReducedMotion = prefs.getBool(_keyReducedMotion) ?? false;

      // সিস্টেম থিম চেক করবে (যদি auto theme enabled থাকে)
      bool finalIsDarkMode = savedIsDarkMode;
      if (isAutoTheme) {
        final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
        finalIsDarkMode = brightness == Brightness.dark;
      }

      themeSettings.value = ThemeSettings(
        isDarkMode: finalIsDarkMode,
        isAutoTheme: isAutoTheme,
        fontSize: fontSize,
        isHighContrast: isHighContrast,
        isReducedMotion: isReducedMotion,
      );

    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  /// সিঙ্গেল বা মাল্টিপল থিম সেটিং আপডেট করবে
  static Future<void> updateThemeSetting({
    bool? isDarkMode,
    bool? isAutoTheme,
    double? fontSize,
    bool? isHighContrast,
    bool? isReducedMotion,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = themeSettings.value;

      // ১. লজিক সেটআপ
      bool newAutoTheme = isAutoTheme ?? current.isAutoTheme;
      bool newDarkMode = isDarkMode ?? current.isDarkMode;

      // যদি ইউজার ম্যানুয়ালি ডার্ক মোড চেঞ্জ করে, তাহলে অটো থিম বন্ধ করে দিব
      if (isDarkMode != null) {
        newAutoTheme = false;
      }

      // যদি অটো থিম অন করা হয় (বা আগে থেকেই অন থাকে), তাহলে সিস্টেম থিম নিব
      if (newAutoTheme) {
        final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
        newDarkMode = brightness == Brightness.dark;
      }

      // ২. নতুন অবজেক্ট তৈরি (Immutable way)
      final newSettings = ThemeSettings(
        isDarkMode: newDarkMode,
        isAutoTheme: newAutoTheme,
        fontSize: fontSize ?? current.fontSize,
        isHighContrast: isHighContrast ?? current.isHighContrast,
        isReducedMotion: isReducedMotion ?? current.isReducedMotion,
      );

      // ৩. ValueNotifier আপডেট
      themeSettings.value = newSettings;

      // ৪. SharedPreferences-এ সেভ
      await prefs.setBool(_keyDarkMode, newSettings.isDarkMode);
      await prefs.setBool(_keyAutoTheme, newSettings.isAutoTheme);
      await prefs.setDouble(_keyFontSize, newSettings.fontSize);
      await prefs.setBool(_keyHighContrast, newSettings.isHighContrast);
      await prefs.setBool(_keyReducedMotion, newSettings.isReducedMotion);

    } catch (e) {
      debugPrint('Error updating theme: $e');
    }
  }

  /// সিস্টেম থিম পরিবর্তন হলে কল হবে (অটোমেটিক ডিটেকশনের জন্য)
  /// এটি main.dart এর didChangePlatformBrightness থেকে কল করতে পারেন
  static void onSystemThemeChanged() {
    if (themeSettings.value.isAutoTheme) {
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      final isSystemDark = brightness == Brightness.dark;

      if (themeSettings.value.isDarkMode != isSystemDark) {
        updateThemeSetting(isAutoTheme: true); // Force update logic
      }
    }
  }

  // --- Convenience Methods ---

  static Future<void> toggleDarkMode(bool isDark) async {
    await updateThemeSetting(isDarkMode: isDark);
  }

  static Future<void> toggleAutoTheme(bool isAuto) async {
    await updateThemeSetting(isAutoTheme: isAuto);
  }

  static double get fontSizeMultiplier => themeSettings.value.fontSize;
}

/// থিম সেটিংস মডেল ক্লাস (Immutable)
class ThemeSettings {
  final bool isDarkMode;
  final bool isAutoTheme;
  final double fontSize;
  final bool isHighContrast;
  final bool isReducedMotion;

  const ThemeSettings({
    required this.isDarkMode,
    required this.isAutoTheme,
    required this.fontSize,
    required this.isHighContrast,
    required this.isReducedMotion,
  });

  ThemeSettings copyWith({
    bool? isDarkMode,
    bool? isAutoTheme,
    double? fontSize,
    bool? isHighContrast,
    bool? isReducedMotion,
  }) {
    return ThemeSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isAutoTheme: isAutoTheme ?? this.isAutoTheme,
      fontSize: fontSize ?? this.fontSize,
      isHighContrast: isHighContrast ?? this.isHighContrast,
      isReducedMotion: isReducedMotion ?? this.isReducedMotion,
    );
  }
}