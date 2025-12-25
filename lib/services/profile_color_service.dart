import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileColorService {
  static const _key = 'worker_profile_colors_v1';

  static Future<Map<String, int>> _loadMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(raw);
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  static Future<void> _saveMap(Map<String, int> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(map));
  }

  /// ঐ workerKey এর জন্য সেভ করা color index (না থাকলে 0)
  static Future<int> getColorIndex(String workerKey) async {
    if (workerKey.isEmpty) return 0;
    final map = await _loadMap();
    return map[workerKey] ?? 0;
  }

  /// ঐ workerKey এর color index সেট করা
  static Future<void> setColorIndex(String workerKey, int index) async {
    if (workerKey.isEmpty) return;
    final map = await _loadMap();
    map[workerKey] = index;
    await _saveMap(map);
  }
}