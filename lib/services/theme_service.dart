import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  // পুরো অ্যাপে যে ValueNotifier শোনা হচ্ছে (main.dart, Settings ইত্যাদি)
  static final ValueNotifier<bool> isDarkMode = ValueNotifier(false);

  static const String _key = 'is_dark_mode';

  /// অ্যাপ স্টার্টের সময় একবার কল হবে (main.dart এ)
  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_key) ?? false;
    isDarkMode.value = saved; // 🔹 main.dart এর ValueListenableBuilder এর ভ্যালু আপডেট
  }

  /// Settings এর Dark Mode সুইচ থেকে কল হবে
  static Future<void> updateTheme(bool isDark) async {
    isDarkMode.value = isDark; // 🔹 সঙ্গে সঙ্গে UI আপডেট হবে

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDark); // 🔹 পরে অ্যাপ ওপেন করলে এই ভ্যালু লোড হবে
  }
}