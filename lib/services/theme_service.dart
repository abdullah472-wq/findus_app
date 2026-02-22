// lib/services/theme_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ✅ Import AppColors from constants
import 'package:findus_app/constants/app_colors.dart';

/// Theme Service - manages app-wide theme settings
class ThemeService {
  // ════════════════════════════════════════════════════════════════════════════
  // SINGLETON PATTERN
  // ════════════════════════════════════════════════════════════════════════════

  static ThemeService? _instance;
  static ThemeService get instance => _instance ??= ThemeService._();

  ThemeService._();

  SharedPreferences? _prefs;

  // ════════════════════════════════════════════════════════════════════════════
  // THEME NOTIFIER
  // ════════════════════════════════════════════════════════════════════════════

  static final ValueNotifier<ThemeSettings> themeSettings = ValueNotifier(
    const ThemeSettings(
      isDarkMode: false,
      isAutoTheme: true,
      fontSize: 1.0,
      isHighContrast: false,
      isReducedMotion: false,
      themePreset: ThemePreset.standard,
      accentColor: AccentColor.blue,
      useAmoledBlack: false,
    ),
  );

  // ════════════════════════════════════════════════════════════════════════════
  // CONSTANTS
  // ════════════════════════════════════════════════════════════════════════════

  static const String _keyDarkMode = 'is_dark_mode';
  static const String _keyAutoTheme = 'is_auto_theme';
  static const String _keyFontSize = 'font_size';
  static const String _keyHighContrast = 'is_high_contrast';
  static const String _keyReducedMotion = 'is_reduced_motion';
  static const String _keyThemePreset = 'theme_preset';
  static const String _keyAccentColor = 'accent_color';
  static const String _keyUseAmoledBlack = 'use_amoled_black';
  static const String _keyThemeHistory = 'theme_history';
  static const String _keyThemeVersion = 'theme_version';

  static const int _currentVersion = 1;
  static const double _minFontSize = 0.8;
  static const double _maxFontSize = 2.0;
  static const int _maxHistoryEntries = 20;

  // ════════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ════════════════════════════════════════════════════════════════════════════

  static Future<void> init({SharedPreferences? prefs}) async {
    try {
      debugPrint('🎨 Initializing Theme Service...');

      instance._prefs = prefs ?? await SharedPreferences.getInstance();
      await instance._migrateIfNeeded();
      await instance.loadTheme();

      debugPrint('✅ Theme Service initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize Theme Service: $e');
      debugPrint('Stack trace: $stackTrace');

      themeSettings.value = const ThemeSettings(
        isDarkMode: false,
        isAutoTheme: true,
        fontSize: 1.0,
        isHighContrast: false,
        isReducedMotion: false,
        themePreset: ThemePreset.standard,
        accentColor: AccentColor.blue,
        useAmoledBlack: false,
      );
    }
  }

  Future<void> loadTheme() async {
    try {
      final prefs = _prefs!;

      final savedIsDarkMode = prefs.getBool(_keyDarkMode) ?? false;
      final isAutoTheme = prefs.getBool(_keyAutoTheme) ?? true;
      final fontSize = prefs.getDouble(_keyFontSize) ?? 1.0;
      final isHighContrast = prefs.getBool(_keyHighContrast) ?? false;
      final isReducedMotion = prefs.getBool(_keyReducedMotion) ?? false;
      final useAmoledBlack = prefs.getBool(_keyUseAmoledBlack) ?? false;

      final themePresetStr = prefs.getString(_keyThemePreset) ?? 'standard';
      final accentColorStr = prefs.getString(_keyAccentColor) ?? 'blue';

      final themePreset = ThemePreset.values.firstWhere(
            (e) => e.name == themePresetStr,
        orElse: () => ThemePreset.standard,
      );

      final accentColor = AccentColor.values.firstWhere(
            (e) => e.name == accentColorStr,
        orElse: () => AccentColor.blue,
      );

      bool finalIsDarkMode = savedIsDarkMode;
      if (isAutoTheme) {
        final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
        finalIsDarkMode = brightness == Brightness.dark;
      }

      final validatedFontSize = fontSize.clamp(_minFontSize, _maxFontSize);

      themeSettings.value = ThemeSettings(
        isDarkMode: finalIsDarkMode,
        isAutoTheme: isAutoTheme,
        fontSize: validatedFontSize,
        isHighContrast: isHighContrast,
        isReducedMotion: isReducedMotion,
        themePreset: themePreset,
        accentColor: accentColor,
        useAmoledBlack: useAmoledBlack,
      );

      debugPrint('✅ Theme loaded: ${themeSettings.value}');
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading theme: $e');
      debugPrint('Stack trace: $stackTrace');

      themeSettings.value = const ThemeSettings(
        isDarkMode: false,
        isAutoTheme: true,
        fontSize: 1.0,
        isHighContrast: false,
        isReducedMotion: false,
        themePreset: ThemePreset.standard,
        accentColor: AccentColor.blue,
        useAmoledBlack: false,
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // UPDATE THEME
  // ════════════════════════════════════════════════════════════════════════════

  static Future<void> updateThemeSetting({
    bool? isDarkMode,
    bool? isAutoTheme,
    double? fontSize,
    bool? isHighContrast,
    bool? isReducedMotion,
    ThemePreset? themePreset,
    AccentColor? accentColor,
    bool? useAmoledBlack,
  }) async {
    try {
      final prefs = instance._prefs!;
      final current = themeSettings.value;

      final userExplicitlySetDarkMode = isDarkMode != null;

      bool newAutoTheme = isAutoTheme ?? current.isAutoTheme;
      bool newDarkMode = isDarkMode ?? current.isDarkMode;

      if (userExplicitlySetDarkMode) {
        newAutoTheme = false;
        debugPrint('🔧 User manually changed dark mode, auto-theme disabled');
      }

      if (newAutoTheme && !userExplicitlySetDarkMode) {
        final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
        newDarkMode = brightness == Brightness.dark;
        debugPrint('🔄 Auto-theme enabled, using system brightness: ${newDarkMode ? 'Dark' : 'Light'}');
      }

      double newFontSize = fontSize ?? current.fontSize;
      if (fontSize != null) {
        newFontSize = fontSize.clamp(_minFontSize, _maxFontSize);
        if (newFontSize != fontSize) {
          debugPrint('⚠️ Font size clamped from $fontSize to $newFontSize');
        }
      }

      final newSettings = ThemeSettings(
        isDarkMode: newDarkMode,
        isAutoTheme: newAutoTheme,
        fontSize: newFontSize,
        isHighContrast: isHighContrast ?? current.isHighContrast,
        isReducedMotion: isReducedMotion ?? current.isReducedMotion,
        themePreset: themePreset ?? current.themePreset,
        accentColor: accentColor ?? current.accentColor,
        useAmoledBlack: useAmoledBlack ?? current.useAmoledBlack,
      );

      themeSettings.value = newSettings;

      final saveOperations = <Future>[
        prefs.setBool(_keyDarkMode, newSettings.isDarkMode),
        prefs.setBool(_keyAutoTheme, newSettings.isAutoTheme),
        prefs.setDouble(_keyFontSize, newSettings.fontSize),
        prefs.setBool(_keyHighContrast, newSettings.isHighContrast),
        prefs.setBool(_keyReducedMotion, newSettings.isReducedMotion),
        prefs.setString(_keyThemePreset, newSettings.themePreset.name),
        prefs.setString(_keyAccentColor, newSettings.accentColor.name),
        prefs.setBool(_keyUseAmoledBlack, newSettings.useAmoledBlack),
      ];

      await Future.wait(saveOperations);

      await instance._trackThemeChange(newSettings);

      debugPrint('✅ Theme updated and saved: $newSettings');
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating theme: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SYSTEM THEME SYNC
  // ════════════════════════════════════════════════════════════════════════════

  static void onSystemThemeChanged() {
    if (themeSettings.value.isAutoTheme) {
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      final isSystemDark = brightness == Brightness.dark;

      if (themeSettings.value.isDarkMode != isSystemDark) {
        debugPrint('🔄 System theme changed: ${isSystemDark ? 'Dark' : 'Light'}');
        updateThemeSetting(isAutoTheme: true);
      }
    } else {
      debugPrint('ℹ️ System theme changed but auto-theme is disabled, ignoring');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // THEME PRESETS
  // ════════════════════════════════════════════════════════════════════════════

  static Future<void> applyPreset(ThemePreset preset) async {
    debugPrint('🎨 Applying preset: ${preset.displayName}');

    switch (preset) {
      case ThemePreset.standard:
        await updateThemeSetting(
          themePreset: preset,
          isHighContrast: false,
          fontSize: 1.0,
          useAmoledBlack: false,
        );
        break;

      case ThemePreset.highContrast:
        await updateThemeSetting(
          themePreset: preset,
          isHighContrast: true,
          fontSize: 1.0,
        );
        break;

      case ThemePreset.large:
        await updateThemeSetting(
          themePreset: preset,
          fontSize: 1.2,
          isHighContrast: false,
        );
        break;

      case ThemePreset.amoled:
        await updateThemeSetting(
          themePreset: preset,
          isDarkMode: true,
          useAmoledBlack: true,
        );
        break;

      case ThemePreset.custom:
        await updateThemeSetting(themePreset: preset);
        break;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CONVENIENCE METHODS
  // ════════════════════════════════════════════════════════════════════════════

  static Future<void> toggleDarkMode(bool isDark) async {
    debugPrint('🌓 Toggling dark mode: $isDark');
    await updateThemeSetting(isDarkMode: isDark);
  }

  static Future<void> toggleAutoTheme(bool isAuto) async {
    debugPrint('🔄 Toggling auto theme: $isAuto');
    await updateThemeSetting(isAutoTheme: isAuto);
  }

  static Future<void> setFontSize(double size) async {
    final clampedSize = size.clamp(_minFontSize, _maxFontSize);
    debugPrint('📏 Setting font size: $clampedSize');
    await updateThemeSetting(fontSize: clampedSize);
  }

  static Future<void> toggleHighContrast(bool enabled) async {
    debugPrint('🔳 Toggling high contrast: $enabled');
    await updateThemeSetting(isHighContrast: enabled);
  }

  static Future<void> toggleReducedMotion(bool enabled) async {
    debugPrint('🎬 Toggling reduced motion: $enabled');
    await updateThemeSetting(isReducedMotion: enabled);
  }

  static Future<void> setAccentColor(AccentColor color) async {
    debugPrint('🎨 Setting accent color: ${color.displayName}');
    await updateThemeSetting(accentColor: color);
  }

  static Future<void> toggleAmoledBlack(bool enabled) async {
    debugPrint('⚫ Toggling AMOLED black: $enabled');
    await updateThemeSetting(useAmoledBlack: enabled);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ════════════════════════════════════════════════════════════════════════════

  static bool get isDarkMode => themeSettings.value.isDarkMode;
  static bool get isAutoTheme => themeSettings.value.isAutoTheme;
  static double get fontSizeMultiplier => themeSettings.value.fontSize;
  static bool get isHighContrast => themeSettings.value.isHighContrast;
  static bool get isReducedMotion => themeSettings.value.isReducedMotion;
  static ThemePreset get currentPreset => themeSettings.value.themePreset;
  static AccentColor get currentAccentColor => themeSettings.value.accentColor;
  static bool get useAmoledBlack => themeSettings.value.useAmoledBlack;

  static Color getAccentColorValue() {
    return themeSettings.value.accentColor.color;
  }

  /// Get background color based on settings
  /// ✅ Now uses AppColors from constants
  static Color getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark && useAmoledBlack) {
      return Colors.black; // Pure black for AMOLED
    } else if (isDark) {
      return const Color(0xFF1A1A1A);
    } else {
      return AppColors.bgBlue; // ✅ Uses imported AppColors
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ANALYTICS
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _trackThemeChange(ThemeSettings settings) async {
    try {
      final prefs = _prefs!;

      final historyJson = prefs.getString(_keyThemeHistory) ?? '[]';
      List<dynamic> history = json.decode(historyJson);

      history.add({
        'isDarkMode': settings.isDarkMode,
        'isAutoTheme': settings.isAutoTheme,
        'preset': settings.themePreset.name,
        'accentColor': settings.accentColor.name,
        'fontSize': settings.fontSize,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (history.length > _maxHistoryEntries) {
        history = history.sublist(history.length - _maxHistoryEntries);
      }

      await prefs.setString(_keyThemeHistory, json.encode(history));

      debugPrint('📊 Theme change tracked (${history.length} entries)');
    } catch (e) {
      debugPrint('❌ Error tracking theme change: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // MIGRATION
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _migrateIfNeeded() async {
    try {
      final prefs = _prefs!;
      final savedVersion = prefs.getInt(_keyThemeVersion) ?? 0;

      if (savedVersion < _currentVersion) {
        debugPrint('🔄 Migrating theme data from v$savedVersion to v$_currentVersion');

        if (savedVersion == 0) {
          debugPrint('  - Migrating from v0 to v1');
        }

        await prefs.setInt(_keyThemeVersion, _currentVersion);
        debugPrint('✅ Migration completed');
      }
    } catch (e) {
      debugPrint('❌ Error during migration: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // RESET
  // ════════════════════════════════════════════════════════════════════════════

  static Future<void> resetToDefault() async {
    debugPrint('🔄 Resetting theme to default');

    await updateThemeSetting(
      isDarkMode: false,
      isAutoTheme: true,
      fontSize: 1.0,
      isHighContrast: false,
      isReducedMotion: false,
      themePreset: ThemePreset.standard,
      accentColor: AccentColor.blue,
      useAmoledBlack: false,
    );

    debugPrint('✅ Theme reset to default');
  }
}

// ════════════════════════════════════════════════════════════════════════════
// THEME SETTINGS MODEL
// ════════════════════════════════════════════════════════════════════════════

class ThemeSettings {
  final bool isDarkMode;
  final bool isAutoTheme;
  final double fontSize;
  final bool isHighContrast;
  final bool isReducedMotion;
  final ThemePreset themePreset;
  final AccentColor accentColor;
  final bool useAmoledBlack;

  const ThemeSettings({
    required this.isDarkMode,
    required this.isAutoTheme,
    required this.fontSize,
    required this.isHighContrast,
    required this.isReducedMotion,
    required this.themePreset,
    required this.accentColor,
    required this.useAmoledBlack,
  });

  ThemeSettings copyWith({
    bool? isDarkMode,
    bool? isAutoTheme,
    double? fontSize,
    bool? isHighContrast,
    bool? isReducedMotion,
    ThemePreset? themePreset,
    AccentColor? accentColor,
    bool? useAmoledBlack,
  }) {
    return ThemeSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isAutoTheme: isAutoTheme ?? this.isAutoTheme,
      fontSize: fontSize ?? this.fontSize,
      isHighContrast: isHighContrast ?? this.isHighContrast,
      isReducedMotion: isReducedMotion ?? this.isReducedMotion,
      themePreset: themePreset ?? this.themePreset,
      accentColor: accentColor ?? this.accentColor,
      useAmoledBlack: useAmoledBlack ?? this.useAmoledBlack,
    );
  }

  @override
  String toString() {
    return 'ThemeSettings('
        'isDarkMode: $isDarkMode, '
        'isAutoTheme: $isAutoTheme, '
        'fontSize: $fontSize, '
        'preset: ${themePreset.name}, '
        'accent: ${accentColor.name}, '
        'amoled: $useAmoledBlack)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ThemeSettings &&
        other.isDarkMode == isDarkMode &&
        other.isAutoTheme == isAutoTheme &&
        other.fontSize == fontSize &&
        other.isHighContrast == isHighContrast &&
        other.isReducedMotion == isReducedMotion &&
        other.themePreset == themePreset &&
        other.accentColor == accentColor &&
        other.useAmoledBlack == useAmoledBlack;
  }

  @override
  int get hashCode {
    return Object.hash(
      isDarkMode,
      isAutoTheme,
      fontSize,
      isHighContrast,
      isReducedMotion,
      themePreset,
      accentColor,
      useAmoledBlack,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// THEME PRESETS
// ════════════════════════════════════════════════════════════════════════════

enum ThemePreset {
  standard,
  highContrast,
  large,
  amoled,
  custom,
}

extension ThemePresetExtension on ThemePreset {
  String get displayName {
    switch (this) {
      case ThemePreset.standard:
        return 'Standard';
      case ThemePreset.highContrast:
        return 'High Contrast';
      case ThemePreset.large:
        return 'Large Text';
      case ThemePreset.amoled:
        return 'AMOLED Dark';
      case ThemePreset.custom:
        return 'Custom';
    }
  }

  String get description {
    switch (this) {
      case ThemePreset.standard:
        return 'Default theme for best experience';
      case ThemePreset.highContrast:
        return 'Better visibility with high contrast';
      case ThemePreset.large:
        return 'Larger text for easier reading';
      case ThemePreset.amoled:
        return 'Pure black for AMOLED displays';
      case ThemePreset.custom:
        return 'Customize your own theme';
    }
  }

  IconData get icon {
    switch (this) {
      case ThemePreset.standard:
        return Icons.smartphone;
      case ThemePreset.highContrast:
        return Icons.contrast;
      case ThemePreset.large:
        return Icons.text_fields;
      case ThemePreset.amoled:
        return Icons.dark_mode;
      case ThemePreset.custom:
        return Icons.palette;
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ACCENT COLORS
// ════════════════════════════════════════════════════════════════════════════

enum AccentColor {
  blue,
  purple,
  green,
  orange,
  red,
  pink,
  teal,
  indigo,
}

extension AccentColorExtension on AccentColor {
  Color get color {
    switch (this) {
      case AccentColor.blue:
        return const Color(0xFF2196F3);
      case AccentColor.purple:
        return const Color(0xFF9C27B0);
      case AccentColor.green:
        return const Color(0xFF4CAF50);
      case AccentColor.orange:
        return const Color(0xFFFF9800);
      case AccentColor.red:
        return const Color(0xFFF44336);
      case AccentColor.pink:
        return const Color(0xFFE91E63);
      case AccentColor.teal:
        return const Color(0xFF009688);
      case AccentColor.indigo:
        return const Color(0xFF3F51B5);
    }
  }

  String get displayName {
    switch (this) {
      case AccentColor.blue:
        return 'Blue';
      case AccentColor.purple:
        return 'Purple';
      case AccentColor.green:
        return 'Green';
      case AccentColor.orange:
        return 'Orange';
      case AccentColor.red:
        return 'Red';
      case AccentColor.pink:
        return 'Pink';
      case AccentColor.teal:
        return 'Teal';
      case AccentColor.indigo:
        return 'Indigo';
    }
  }
}