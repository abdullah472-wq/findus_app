// lib/localization/localization_extension.dart

import 'package:flutter/material.dart';
import 'app_localizations.dart';

extension LocalizationExtension on BuildContext {
  /// Simple translation
  /// Example: context.tr(TranslationKeys.welcome);
  String tr(String key, {Map<String, String>? args}) {
    return AppLocalization.of(this)?.translate(key, args: args) ?? key;
  }

  /// Get current locale
  Locale get currentLocale => Localizations.localeOf(this);
}