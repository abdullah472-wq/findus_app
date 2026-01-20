import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  // থিম সেটিংস মডেল
  static final ValueNotifier<ThemeSettings> themeSettings = ValueNotifier(
    ThemeSettings(
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

      final isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
      final isAutoTheme = prefs.getBool(_keyAutoTheme) ?? true;
      final fontSize = prefs.getDouble(_keyFontSize) ?? 1.0;
      final isHighContrast = prefs.getBool(_keyHighContrast) ?? false;
      final isReducedMotion = prefs.getBool(_keyReducedMotion) ?? false;

      // সিস্টেম থিম চেক করবে (যদি auto theme enabled থাকে)
      bool finalIsDarkMode = isDarkMode;
      if (isAutoTheme) {
        finalIsDarkMode = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      }

      themeSettings.value = ThemeSettings(
        isDarkMode: finalIsDarkMode,
        isAutoTheme: isAutoTheme,
        fontSize: fontSize,
        isHighContrast: isHighContrast,
        isReducedMotion: isReducedMotion,
      );

      // UI আপডেট করার জন্য notify
      themeSettings.notifyListeners();
    } catch (e) {
      // Error handling
      debugPrint('Error loading theme: $e');
    }
  }

  /// সিঙ্গেল থিম সেটিং আপডেট করবে
  static Future<void> updateThemeSetting({
    bool? isDarkMode,
    bool? isAutoTheme,
    double? fontSize,
    bool? isHighContrast,
    bool? isReducedMotion,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // বর্তমান সেটিংস নিবে
      final currentSettings = themeSettings.value;

      // নতুন সেটিংস তৈরি করবে
      final newSettings = ThemeSettings(
        isDarkMode: isDarkMode ?? currentSettings.isDarkMode,
        isAutoTheme: isAutoTheme ?? currentSettings.isAutoTheme,
        fontSize: fontSize ?? currentSettings.fontSize,
        isHighContrast: isHighContrast ?? currentSettings.isHighContrast,
        isReducedMotion: isReducedMotion ?? currentSettings.isReducedMotion,
      );

      // Auto theme চেক করবে
      bool finalIsDarkMode = newSettings.isDarkMode;
      if (newSettings.isAutoTheme) {
        finalIsDarkMode = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
        newSettings.isDarkMode = finalIsDarkMode;
      }

      // ValueNotifier আপডেট করবে
      themeSettings.value = newSettings;

      // SharedPreferences-এ সেভ করবে
      await prefs.setBool(_keyDarkMode, newSettings.isDarkMode);
      await prefs.setBool(_keyAutoTheme, newSettings.isAutoTheme);
      await prefs.setDouble(_keyFontSize, newSettings.fontSize);
      await prefs.setBool(_keyHighContrast, newSettings.isHighContrast);
      await prefs.setBool(_keyReducedMotion, newSettings.isReducedMotion);

      // UI আপডেট করার জন্য notify
      themeSettings.notifyListeners();
    } catch (e) {
      debugPrint('Error updating theme: $e');
    }
  }

  /// সকল থিম সেটিংস রিসেট করবে (default ভ্যালুতে)
  static Future<void> resetThemeSettings() async {
    await updateThemeSetting(
      isDarkMode: false,
      isAutoTheme: true,
      fontSize: 1.0,
      isHighContrast: false,
      isReducedMotion: false,
    );
  }

  /// শুধু Dark Mode টগল করবে (সিঙ্গেল ফাংশন)
  static Future<void> toggleDarkMode(bool isDark) async {
    await updateThemeSetting(isDarkMode: isDark);
  }

  /// শুধু Auto Theme টগল করবে
  static Future<void> toggleAutoTheme(bool isAuto) async {
    await updateThemeSetting(isAutoTheme: isAuto);
  }

  /// সিস্টেম থিম পরিবর্তন হলে কল হবে
  static void onSystemThemeChanged() {
    // যদি auto theme enabled থাকে
    if (themeSettings.value.isAutoTheme) {
      final isSystemDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;

      // সিস্টেম থিম বর্তমান থিমের সাথে মিলছে কিনা চেক করবে
      if (themeSettings.value.isDarkMode != isSystemDark) {
        themeSettings.value = themeSettings.value.copyWith(isDarkMode: isSystemDark);
        themeSettings.notifyListeners();

        // SharedPreferences-এ আপডেট করবে
        _saveToPrefs();
      }
    }
  }

  /// SharedPreferences-এ থিম সেটিংস সেভ করবে (private method)
  static Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = themeSettings.value;

      await prefs.setBool(_keyDarkMode, settings.isDarkMode);
      await prefs.setBool(_keyAutoTheme, settings.isAutoTheme);
      await prefs.setDouble(_keyFontSize, settings.fontSize);
      await prefs.setBool(_keyHighContrast, settings.isHighContrast);
      await prefs.setBool(_keyReducedMotion, settings.isReducedMotion);
    } catch (e) {
      debugPrint('Error saving theme to prefs: $e');
    }
  }

  /// Font size multiplier getter (UI-তে ব্যবহারের জন্য)
  static double get fontSizeMultiplier => themeSettings.value.fontSize;

  /// High contrast mode getter
  static bool get isHighContrast => themeSettings.value.isHighContrast;

  /// Reduced motion mode getter
  static bool get isReducedMotion => themeSettings.value.isReducedMotion;

  /// Current theme mode getter
  static ThemeMode get currentThemeMode {
    if (themeSettings.value.isAutoTheme) {
      return ThemeMode.system;
    }
    return themeSettings.value.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}

/// থিম সেটিংস মডেল ক্লাস
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

  @override
  String toString() {
    return 'ThemeSettings(isDarkMode: $isDarkMode, isAutoTheme: $isAutoTheme, fontSize: $fontSize, isHighContrast: $isHighContrast, isReducedMotion: $isReducedMotion)';
  }
}