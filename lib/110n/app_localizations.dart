import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // supported language codes
  static const _supportedLanguages = ['en', 'bn'];

  static bool isSupported(Locale locale) =>
      _supportedLanguages.contains(locale.languageCode);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(
        context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'home_title': 'FINDUS',
      'saved_profiles': 'Saved Profiles',
      'hire_details': 'Hire Details',
      'send_request': 'Send Request',
      'completed_work': 'Completed Work',
      'work_in_progress': 'Work in Progress',
      'messages': 'Messages',
      'progress': 'Progress',
      'saved': 'Saved',
      // ... এখানে ধীরে ধীরে সব কী যোগ করবে
    },
    'bn': {
      'home_title': 'ফাইন্ডাস',
      'saved_profiles': 'সেভ করা প্রোফাইল',
      'hire_details': 'হায়ার ডিটেইলস',
      'send_request': 'রিকোয়েস্ট পাঠাও',
      'completed_work': 'সমাপ্ত কাজ',
      'work_in_progress': 'চলমান কাজ',
      'messages': 'বার্তা',
      'progress': 'অগ্রগতি',
      'saved': 'সেভড',
      // ... ধীরে ধীরে সব কী এর বাংলা
    },
  };

  String t(String key) {
    final lang = _localizedValues[locale.languageCode];
    return lang?[key] ?? _localizedValues['en']![key] ?? key;
  }
}

// LocalizationsDelegate
class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.isSupported(locale);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}