// lib/localization/localization_wrapper.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationWrapper extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocalizationWrapper() {
    _loadSavedLanguage();
  }

  // ভাষা পরিবর্তন করার ফাংশন
  Future<void> changeLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);
    notifyListeners();

    // প্রিফারেন্স সেভ করা
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }

  // অ্যাপ চালুর সময় সেভ করা ভাষা লোড করা
  Future<void> _loadSavedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedLang = prefs.getString('language_code');
    if (savedLang != null) {
      _locale = Locale(savedLang);
      notifyListeners();
    }
  }
}