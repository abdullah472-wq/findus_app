// lib/localization/app_localizations.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // ✅ Static helper method
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // ✅ Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('bn', 'BD'), // Bengali
  ];

  // ✅ Default locale
  static const Locale defaultLocale = Locale('en', 'US');

  late Map<String, String> _localizedStrings;

  // ════════════════════════════════════════════════════════════════════════════
  // LOAD JSON FILE
  // ════════════════════════════════════════════════════════════════════════════

  Future<bool> load() async {
    try {
      // Load the language JSON file
      String jsonString = await rootBundle.loadString(
        'assets/lang/${locale.languageCode}.json',
      );

      Map<String, dynamic> jsonMap = json.decode(jsonString);

      // Convert all values to string
      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });

      debugPrint('✅ Loaded ${locale.languageCode} translations: ${_localizedStrings.length} keys');
      return true;
    } catch (e) {
      debugPrint('❌ Localization Load Error: $e');
      _localizedStrings = {};
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TRANSLATION METHOD
  // ════════════════════════════════════════════════════════════════════════════

  /// Translate a key with optional arguments
  ///
  /// Example:
  /// ```dart
  /// translate('welcome_message', args: {'name': 'John'})
  /// // Returns: "Welcome, John!"
  /// ```
  String translate(String key, {Map<String, String>? args}) {
    String translation = _localizedStrings[key] ?? key;

    // Replace arguments in translation
    if (args != null) {
      args.forEach((argKey, argValue) {
        translation = translation.replaceAll('{$argKey}', argValue);
      });
    }

    return translation;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ════════════════════════════════════════════════════════════════════════════

  /// Get translation with fallback
  String tr(String key, {String? fallback, Map<String, String>? args}) {
    if (_localizedStrings.containsKey(key)) {
      return translate(key, args: args);
    }
    return fallback ?? key;
  }

  /// Plural translation
  ///
  /// Example JSON:
  /// ```json
  /// {
  ///   "items_count_zero": "No items",
  ///   "items_count_one": "1 item",
  ///   "items_count_other": "{count} items"
  /// }
  /// ```
  String plural(String key, int count, {Map<String, String>? args}) {
    String pluralKey;

    if (count == 0) {
      pluralKey = '${key}_zero';
    } else if (count == 1) {
      pluralKey = '${key}_one';
    } else {
      pluralKey = '${key}_other';
    }

    // Merge count into args
    final allArgs = {
      'count': count.toString(),
      ...?args,
    };

    return translate(pluralKey, args: allArgs);
  }

  /// Check if translation exists
  bool hasTranslation(String key) {
    return _localizedStrings.containsKey(key);
  }

  /// Get current language name
  String get currentLanguageName {
    switch (locale.languageCode) {
      case 'bn':
        return 'বাংলা';
      case 'en':
      default:
        return 'English';
    }
  }

  /// Get current language code
  String get languageCode => locale.languageCode;

  /// Get current country code
  String? get countryCode => locale.countryCode;

  /// Check if current language is RTL (Right-to-Left)
  bool get isRTL {
    // Add RTL languages here
    return ['ar', 'ur', 'fa', 'he'].contains(locale.languageCode);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // COMMON TRANSLATIONS (OPTIONAL - for quick access)
  // ════════════════════════════════════════════════════════════════════════════

  String get appName => translate('app_name');
  String get ok => translate('ok');
  String get cancel => translate('cancel');
  String get yes => translate('yes');
  String get no => translate('no');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get close => translate('close');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get retry => translate('retry');
  String get search => translate('search');
  String get filter => translate('filter');
  String get share => translate('share');
  String get settings => translate('settings');
  String get logout => translate('logout');
  String get login => translate('login');
  String get signup => translate('signup');
}

// ════════════════════════════════════════════════════════════════════════════
// EXTENSION FOR EASY ACCESS
// ════════════════════════════════════════════════════════════════════════════

extension LocalizationExtension on BuildContext {
  AppLocalizations get loc {
    return AppLocalizations.of(this)!;
  }

  String tr(String key, {Map<String, String>? args}) {
    return AppLocalizations.of(this)?.translate(key, args: args) ?? key;
  }

  String plural(String key, int count, {Map<String, String>? args}) {
    return AppLocalizations.of(this)?.plural(key, count, args: args) ?? key;
  }
}