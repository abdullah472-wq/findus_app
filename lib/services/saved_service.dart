// lib/services/saved_service.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedService {
  static const _prefsKey = 'saved_workers';

  /// সব saved worker এখানে মেমরিতে থাকবে
  static List<Map<String, dynamic>> savedWorkers = [];

  /// অ্যাপ স্টার্টে একবার কল করবে (main.dart এ)
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    savedWorkers =
        list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  /// ভিতরে কমন key (id/phone/name) বের করার helper
  static String? _extractKey(dynamic source) {
    if (source is String) return source;

    if (source is Map) {
      final m = source as Map;
      if (m['id'] != null && m['id'].toString().isNotEmpty) {
        return m['id'].toString();
      }
      if (m['phone'] != null && m['phone'].toString().isNotEmpty) {
        return m['phone'].toString();
      }
      if (m['name'] != null && m['name'].toString().isNotEmpty) {
        return m['name'].toString();
      }
    }

    return null;
  }

  /// আগেই saved আছে কি না (id/name/phone দিয়ে চেক)
  ///
  /// সাধারণত worker_profile_bottom_sheet থেকে Map পাঠানো থাকবে:
  /// SavedService.isSaved(data)
  static bool isSaved(dynamic workerOrId) {
    final key = _extractKey(workerOrId);
    if (key == null) return false;

    return savedWorkers.any((w) => _extractKey(w) == key);
  }

  /// toggle save / unsave
  ///
  /// সাধারণ pattern:
  ///   await SavedService.toggleSave(data);
  ///   setState(() {});
  static Future<void> toggleSave(dynamic workerOrId) async {
    final key = _extractKey(workerOrId);
    if (key == null) return;

    final idx = savedWorkers.indexWhere((w) => _extractKey(w) == key);

    if (idx >= 0) {
      // আগেই আছে → unsave/remove
      savedWorkers.removeAt(idx);
    } else {
      // নেই → save করি
      if (workerOrId is Map<String, dynamic>) {
        // ডিপ কপি করে রাখি, যাতে বাইরে পরিবর্তন করলে এতে প্রভাব না পড়ে
        final mapCopy = Map<String, dynamic>.from(workerOrId);
        savedWorkers.add(mapCopy);
      } else {
        // Map ছাড়া কিছু পাঠালে আমরা জানি না কীভাবে সেভ করব; skip করে দিচ্ছি
        return;
      }
    }

    await _saveToPrefs();
  }

  /// সরাসরি add করতে চাইলে (toggle ছাড়া)
  static Future<void> addWorker(Map<String, dynamic> worker) async {
    final key = _extractKey(worker);
    if (key != null) {
      savedWorkers.removeWhere((w) => _extractKey(w) == key);
    }

    savedWorkers.add(Map<String, dynamic>.from(worker));
    await _saveToPrefs();
  }

  /// id দিয়ে remove
  static Future<void> removeWorkerById(String id) async {
    savedWorkers.removeWhere((w) => _extractKey(w) == id);
    await _saveToPrefs();
  }

  /// সব clear
  static Future<void> clear() async {
    savedWorkers.clear();
    await _saveToPrefs();
  }

  /// prefs এ সেভ
  static Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = savedWorkers.map((w) => jsonEncode(w)).toList();
    await prefs.setStringList(_prefsKey, list);
  }
}