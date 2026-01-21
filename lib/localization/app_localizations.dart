// lib/localization/app_localization.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalization {
  final Locale locale;

  AppLocalization(this.locale);

  static AppLocalization? of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization);
  }

  late Map<String, String> _localizedStrings;

  // JSON ফাইল লোড করার ফাংশন
  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });
      return true;
    } catch (e) {
      debugPrint("Localization Load Error: $e");
      _localizedStrings = {};
      return false;
    }
  }

  // ট্রান্সলেশন পাওয়ার মেথড
  String translate(String key, {Map<String, String>? args}) {
    String translation = _localizedStrings[key] ?? key;

    // আর্গুমেন্ট রিপ্লেস করার লজিক (যেমন: Hello {name})
    if (args != null) {
      args.forEach((key, value) {
        translation = translation.replaceAll('{$key}', value);
      });
    }

    return translation;
  }
}