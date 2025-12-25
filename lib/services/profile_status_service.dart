import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileStatusService {
  static final ValueNotifier<bool> isTopRated = ValueNotifier(false);
  static final ValueNotifier<bool> isTrusted = ValueNotifier(false);
  static final ValueNotifier<bool> isVerified = ValueNotifier(false);

  static const _keyTopRated = 'status_top_rated';
  static const _keyTrusted = 'status_trusted';
  static const _keyVerified = 'status_verified';

  /// অ্যাপ চালুর সময় একবার লোড
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isTopRated.value = prefs.getBool(_keyTopRated) ?? false;
    isTrusted.value = prefs.getBool(_keyTrusted) ?? false;
    isVerified.value = prefs.getBool(_keyVerified) ?? false;
  }

  static Future<void> setTopRated(bool value) async {
    isTopRated.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTopRated, value);
  }

  static Future<void> setTrusted(bool value) async {
    isTrusted.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTrusted, value);
  }

  static Future<void> setVerified(bool value) async {
    isVerified.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVerified, value);
  }
}