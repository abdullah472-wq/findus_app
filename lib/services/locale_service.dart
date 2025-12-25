import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static final ValueNotifier<Locale> localeNotifier =
  ValueNotifier(const Locale('en')); // default English

  static const String _key = 'app_language_code';

  /// অ্যাপ চালু হলে একবার কল করবে (main.dart এ)
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'en';
    localeNotifier.value = Locale(code);
  }

  /// LanguageSettingsScreen থেকে কল করবে
  static Future<void> updateLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
    localeNotifier.value = Locale(languageCode);
  }
}