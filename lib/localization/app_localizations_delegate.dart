// lib/localization/app_localizations_delegate.dart

import 'package:flutter/material.dart';
import 'app_localizations.dart';

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  // ════════════════════════════════════════════════════════════════════════════
  // SUPPORTED LOCALES CHECK
  // ════════════════════════════════════════════════════════════════════════════

  @override
  bool isSupported(Locale locale) {
    // Check if the language code is in supported locales
    return AppLocalizations.supportedLocales.any(
          (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LOAD LOCALIZATION
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Ensure we have a supported locale
    final supportedLocale = _getSupportedLocale(locale);

    AppLocalizations localizations = AppLocalizations(supportedLocale);

    bool loaded = await localizations.load();

    if (!loaded) {
      debugPrint('⚠️ Failed to load ${supportedLocale.languageCode}, falling back to default');

      // Fallback to default locale if loading fails
      if (supportedLocale != AppLocalizations.defaultLocale) {
        localizations = AppLocalizations(AppLocalizations.defaultLocale);
        await localizations.load();
      }
    }

    return localizations;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SHOULD RELOAD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;

  // ════════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ════════════════════════════════════════════════════════════════════════════

  /// Get the best matching supported locale
  Locale _getSupportedLocale(Locale locale) {
    // Try to find exact match (language + country)
    for (var supportedLocale in AppLocalizations.supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode &&
          supportedLocale.countryCode == locale.countryCode) {
        return supportedLocale;
      }
    }

    // Try to find language match
    for (var supportedLocale in AppLocalizations.supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }

    // Return default locale if no match found
    debugPrint('⚠️ Locale ${locale.toString()} not supported, using default');
    return AppLocalizations.defaultLocale;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STATIC HELPER
  // ════════════════════════════════════════════════════════════════════════════

  /// Get list of supported language codes
  static List<String> get supportedLanguageCodes {
    return AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toList();
  }

  /// Get list of supported locales
  static List<Locale> get supportedLocales {
    return AppLocalizations.supportedLocales;
  }

  /// Check if a locale is supported
  static bool isSupportedLocale(Locale locale) {
    return AppLocalizations.supportedLocales.any(
          (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  /// Get locale by language code
  static Locale? getLocaleByLanguageCode(String languageCode) {
    try {
      return AppLocalizations.supportedLocales.firstWhere(
            (locale) => locale.languageCode == languageCode,
      );
    } catch (e) {
      return null;
    }
  }

  /// Locale resolution callback for MaterialApp
  static Locale localeResolutionCallback(
      Locale? locale,
      Iterable<Locale> supportedLocales,
      ) {
    // Check if the current device locale is supported
    if (locale != null) {
      for (var supportedLocale in supportedLocales) {
        if (supportedLocale.languageCode == locale.languageCode &&
            supportedLocale.countryCode == locale.countryCode) {
          debugPrint('✅ Using exact locale: ${supportedLocale.toString()}');
          return supportedLocale;
        }
      }

      // If exact match not found, try language code only
      for (var supportedLocale in supportedLocales) {
        if (supportedLocale.languageCode == locale.languageCode) {
          debugPrint('✅ Using language locale: ${supportedLocale.toString()}');
          return supportedLocale;
        }
      }
    }

    // Return default locale
    debugPrint('✅ Using default locale: ${AppLocalizations.defaultLocale}');
    return AppLocalizations.defaultLocale;
  }
}