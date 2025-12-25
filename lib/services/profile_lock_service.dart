import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileLockService {
  static const _key = 'locked_profiles_v1';

  static Future<List<String>> _loadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List list = jsonDecode(raw) as List;
    return list.cast<String>();
  }

  static Future<void> _saveIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(ids));
  }

  /// ঐ workerId লকড কিনা
  static Future<bool> isLocked(String id) async {
    if (id.isEmpty) return false;
    final ids = await _loadIds();
    return ids.contains(id);
  }

  /// toggle: আগে আনলক থাকলে লক করবে, লক থাকলে আনলক করবে
  /// রিটার্ন করবে নতুন স্ট্যাটাস (true = locked)
  static Future<bool> toggleLock(String id) async {
    if (id.isEmpty) return false;
    final ids = await _loadIds();
    bool locked;

    if (ids.contains(id)) {
      ids.remove(id);
      locked = false;
    } else {
      ids.add(id);
      locked = true;
    }

    await _saveIds(ids);
    return locked;
  }
}