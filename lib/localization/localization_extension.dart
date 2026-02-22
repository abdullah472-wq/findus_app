// lib/localization/localization_extension.dart

import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// Extension for easy access to localization in BuildContext
extension LocalizationExtension on BuildContext {

  // ════════════════════════════════════════════════════════════════════════════
  // CORE TRANSLATION METHODS
  // ════════════════════════════════════════════════════════════════════════════

  /// Get AppLocalizations instance
  /// Example: context.loc.appName
  AppLocalizations get loc {
    final localizations = AppLocalizations.of(this);
    if (localizations == null) {
      throw Exception('AppLocalizations not found in context');
    }
    return localizations;
  }

  /// Simple translation
  /// Example: context.tr('welcome_message')
  String tr(String key, {Map<String, String>? args}) {
    return loc.translate(key, args: args);
  }

  /// Translation with fallback
  /// Example: context.trOrDefault('some_key', 'Default Text')
  String trOrDefault(String key, String defaultText, {Map<String, String>? args}) {
    return loc.tr(key, fallback: defaultText, args: args);
  }

  /// Plural translation
  /// Example: context.plural('items_count', itemCount)
  String plural(String key, int count, {Map<String, String>? args}) {
    return loc.plural(key, count, args: args);
  }

  /// Check if translation exists
  /// Example: if (context.hasTranslation('some_key')) { ... }
  bool hasTranslation(String key) {
    return loc.hasTranslation(key);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LOCALE INFORMATION
  // ════════════════════════════════════════════════════════════════════════════

  /// Get current locale
  /// Example: Locale currentLocale = context.currentLocale;
  Locale get currentLocale => Localizations.localeOf(this);

  /// Get current language code
  /// Example: String lang = context.languageCode; // 'en' or 'bn'
  String get languageCode => currentLocale.languageCode;

  /// Get current country code
  /// Example: String? country = context.countryCode; // 'US' or 'BD'
  String? get countryCode => currentLocale.countryCode;

  /// Get current language name
  /// Example: String name = context.languageName; // 'English' or 'বাংলা'
  String get languageName => loc.currentLanguageName;

  /// Check if current language is RTL (Right-to-Left)
  /// Example: if (context.isRTL) { ... }
  bool get isRTL => loc.isRTL;

  /// Check if current language is Bengali
  /// Example: if (context.isBengali) { ... }
  bool get isBengali => languageCode == 'bn';

  /// Check if current language is English
  /// Example: if (context.isEnglish) { ... }
  bool get isEnglish => languageCode == 'en';

  // ════════════════════════════════════════════════════════════════════════════
  // TEXT DIRECTION
  // ════════════════════════════════════════════════════════════════════════════

  /// Get text direction based on current locale
  /// Example: TextDirection direction = context.textDirection;
  TextDirection get textDirection {
    return isRTL ? TextDirection.rtl : TextDirection.ltr;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // QUICK ACCESS TO COMMON TRANSLATIONS
  // ════════════════════════════════════════════════════════════════════════════

  /// Quick access to common translations
  /// Example: context.commonOk, context.commonCancel

  String get commonOk => tr('ok');
  String get commonCancel => tr('cancel');
  String get commonYes => tr('yes');
  String get commonNo => tr('no');
  String get commonSave => tr('save');
  String get commonDelete => tr('delete');
  String get commonEdit => tr('edit');
  String get commonClose => tr('close');
  String get commonLoading => tr('loading');
  String get commonError => tr('error');
  String get commonSuccess => tr('success');
  String get commonRetry => tr('retry');
  String get commonSearch => tr('search');
  String get commonFilter => tr('filter');
  String get commonShare => tr('share');
  String get commonSettings => tr('settings');
  String get commonLogout => tr('logout');
  String get commonLogin => tr('login');
  String get commonSignup => tr('signup');
  String get commonBack => tr('back');
  String get commonNext => tr('next');
  String get commonSubmit => tr('submit');
  String get commonConfirm => tr('confirm');

  // ════════════════════════════════════════════════════════════════════════════
  // FORMATTED TRANSLATIONS
  // ════════════════════════════════════════════════════════════════════════════

  /// Format currency
  /// Example: context.formatCurrency(1234.56) // '৳1,234.56'
  String formatCurrency(double amount, {String? symbol}) {
    final currencySymbol = symbol ?? (isBengali ? '৳' : '৳');

    // Format number based on locale
    final formatted = amount.toStringAsFixed(2);

    // Add thousand separators
    final parts = formatted.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    // Add commas for thousands
    String formattedInteger = '';
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count == 3) {
        formattedInteger = ',$formattedInteger';
        count = 0;
      }
      formattedInteger = integerPart[i] + formattedInteger;
      count++;
    }

    return '$currencySymbol$formattedInteger.$decimalPart';
  }

  /// Format number (with Bengali numerals support)
  /// Example: context.formatNumber(1234) // '১২৩৪' in Bengali
  String formatNumber(int number) {
    if (isBengali) {
      return _toBengaliNumerals(number.toString());
    }
    return number.toString();
  }

  /// Convert to Bengali numerals
  String _toBengaliNumerals(String number) {
    const englishToBengali = {
      '0': '০',
      '1': '১',
      '2': '২',
      '3': '৩',
      '4': '৪',
      '5': '৫',
      '6': '৬',
      '7': '৭',
      '8': '৮',
      '9': '৯',
    };

    String result = number;
    englishToBengali.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DATE & TIME FORMATTING
  // ════════════════════════════════════════════════════════════════════════════

  /// Format date based on locale
  /// Example: context.formatDate(DateTime.now())
  String formatDate(DateTime date, {String? format}) {
    // You can use intl package for better formatting
    if (isBengali) {
      return '${_toBengaliNumerals(date.day.toString())}-${_toBengaliNumerals(date.month.toString())}-${_toBengaliNumerals(date.year.toString())}';
    }
    return '${date.day}-${date.month}-${date.year}';
  }

  /// Format time
  /// Example: context.formatTime(DateTime.now())
  String formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    if (isBengali) {
      return '${_toBengaliNumerals(hour)}:${_toBengaliNumerals(minute)}';
    }
    return '$hour:$minute';
  }

  // ════════════════════════════════════════════════════════════════════════════
  // VALIDATION MESSAGES
  // ════════════════════════════════════════════════════════════════════════════

  /// Required field validation
  /// Example: context.validationRequired('Email')
  String validationRequired(String fieldName) {
    return tr('validation_required', args: {'field': fieldName});
  }

  /// Invalid format validation
  /// Example: context.validationInvalid('Email')
  String validationInvalid(String fieldName) {
    return tr('validation_invalid', args: {'field': fieldName});
  }

  /// Min length validation
  /// Example: context.validationMinLength('Password', 6)
  String validationMinLength(String fieldName, int minLength) {
    return tr('validation_min_length', args: {
      'field': fieldName,
      'length': minLength.toString(),
    });
  }

  /// Max length validation
  /// Example: context.validationMaxLength('Username', 20)
  String validationMaxLength(String fieldName, int maxLength) {
    return tr('validation_max_length', args: {
      'field': fieldName,
      'length': maxLength.toString(),
    });
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EXTENSION FOR STRINGS (Optional - for reverse translation lookup)
// ════════════════════════════════════════════════════════════════════════════

extension StringLocalizationExtension on String {
  /// Translate this string as a key
  /// Example: 'welcome_message'.tr(context)
  String tr(BuildContext context, {Map<String, String>? args}) {
    return context.tr(this, args: args);
  }

  /// Convert English numerals to Bengali
  /// Example: '123'.toBengaliNumerals()
  String toBengaliNumerals() {
    const englishToBengali = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯',
    };

    String result = this;
    englishToBengali.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }

  /// Convert Bengali numerals to English
  /// Example: '১২৩'.toEnglishNumerals()
  String toEnglishNumerals() {
    const bengaliToEnglish = {
      '০': '0', '১': '1', '২': '2', '৩': '3', '৪': '4',
      '৫': '5', '৬': '6', '৭': '7', '৮': '8', '৯': '9',
    };

    String result = this;
    bengaliToEnglish.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }
}