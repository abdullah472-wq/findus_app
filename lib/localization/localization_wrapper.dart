// lib/localization/localization_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // ✅ এই line যোগ করুন
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';
import 'app_localizations_delegate.dart';

class LocalizationWrapper extends ChangeNotifier {

  // ════════════════════════════════════════════════════════════════════════════
  // PROPERTIES
  // ════════════════════════════════════════════════════════════════════════════

  Locale _locale = AppLocalizations.defaultLocale;
  bool _isLoading = true;

  static const String _storageKey = 'selected_language_code';

  // ════════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ════════════════════════════════════════════════════════════════════════════

  /// Current locale
  Locale get locale => _locale;

  /// Current language code
  String get languageCode => _locale.languageCode;

  /// Current language name
  String get languageName {
    switch (_locale.languageCode) {
      case 'bn':
        return 'বাংলা';
      case 'en':
      default:
        return 'English';
    }
  }

  /// Is currently loading saved language
  bool get isLoading => _isLoading;

  /// Check if current language is Bengali
  bool get isBengali => _locale.languageCode == 'bn';

  /// Check if current language is English
  bool get isEnglish => _locale.languageCode == 'en';

  /// Get list of supported locales
  List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  /// Get list of supported language codes
  List<String> get supportedLanguageCodes {
    return supportedLocales.map((locale) => locale.languageCode).toList();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ════════════════════════════════════════════════════════════════════════════

  LocalizationWrapper() {
    _loadSavedLanguage();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LANGUAGE CHANGE METHODS
  // ════════════════════════════════════════════════════════════════════════════

  /// Change language by language code
  /// Example: changeLanguage('bn')
  Future<void> changeLanguage(String languageCode) async {
    try {
      // Check if already selected
      if (_locale.languageCode == languageCode) {
        debugPrint('⚠️ Language already set to: $languageCode');
        return;
      }

      // Validate language code
      if (!_isValidLanguageCode(languageCode)) {
        debugPrint('❌ Invalid language code: $languageCode');
        return;
      }

      // Get locale for language code
      final newLocale = _getLocaleForLanguageCode(languageCode);
      if (newLocale == null) {
        debugPrint('❌ Locale not found for: $languageCode');
        return;
      }

      // Update locale
      _locale = newLocale;
      notifyListeners();

      // Save to preferences
      await _saveLanguage(languageCode);

      debugPrint('✅ Language changed to: $languageCode');
    } catch (e) {
      debugPrint('❌ Error changing language: $e');
    }
  }

  /// Change language by locale
  /// Example: changeLocale(Locale('bn', 'BD'))
  Future<void> changeLocale(Locale locale) async {
    await changeLanguage(locale.languageCode);
  }

  /// Toggle between English and Bengali
  Future<void> toggleLanguage() async {
    final newLanguage = isBengali ? 'en' : 'bn';
    await changeLanguage(newLanguage);
  }

  /// Reset to default language
  Future<void> resetToDefault() async {
    await changeLanguage(AppLocalizations.defaultLocale.languageCode);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PERSISTENCE METHODS
  // ════════════════════════════════════════════════════════════════════════════

  /// Load saved language from SharedPreferences
  Future<void> _loadSavedLanguage() async {
    try {
      _isLoading = true;

      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_storageKey);

      if (savedLanguageCode != null && _isValidLanguageCode(savedLanguageCode)) {
        final savedLocale = _getLocaleForLanguageCode(savedLanguageCode);
        if (savedLocale != null) {
          _locale = savedLocale;
          debugPrint('✅ Loaded saved language: $savedLanguageCode');
        }
      } else {
        // Use system language if available and supported
        _locale = await _getSystemLanguage();
        debugPrint('✅ Using system/default language: ${_locale.languageCode}');
      }
    } catch (e) {
      debugPrint('❌ Error loading saved language: $e');
      _locale = AppLocalizations.defaultLocale;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save language to SharedPreferences
  Future<void> _saveLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, languageCode);
      debugPrint('✅ Saved language: $languageCode');
    } catch (e) {
      debugPrint('❌ Error saving language: $e');
    }
  }

  /// Clear saved language preference
  Future<void> clearSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      debugPrint('✅ Cleared saved language');
    } catch (e) {
      debugPrint('❌ Error clearing saved language: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ════════════════════════════════════════════════════════════════════════════

  /// Check if language code is valid/supported
  bool _isValidLanguageCode(String languageCode) {
    return supportedLanguageCodes.contains(languageCode);
  }

  /// Get Locale object for language code
  Locale? _getLocaleForLanguageCode(String languageCode) {
    try {
      return supportedLocales.firstWhere(
            (locale) => locale.languageCode == languageCode,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get system language if supported, otherwise default
  Future<Locale> _getSystemLanguage() async {
    try {
      // Get system locale
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;

      // Check if system language is supported
      if (_isValidLanguageCode(systemLocale.languageCode)) {
        final locale = _getLocaleForLanguageCode(systemLocale.languageCode);
        if (locale != null) {
          return locale;
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting system language: $e');
    }

    return AppLocalizations.defaultLocale;
  }

  /// Get all available languages with names
  Map<String, String> get availableLanguages {
    return {
      'en': 'English',
      'bn': 'বাংলা',
    };
  }

  /// Check if a specific language is supported
  bool isLanguageSupported(String languageCode) {
    return _isValidLanguageCode(languageCode);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // STATIC HELPER
  // ════════════════════════════════════════════════════════════════════════════

  /// Get LocalizationWrapper from context
  static LocalizationWrapper of(BuildContext context, {bool listen = true}) {
    return Provider.of<LocalizationWrapper>(context, listen: listen);
  }
}