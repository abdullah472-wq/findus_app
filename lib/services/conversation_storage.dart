import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ConversationStorage {
  static const _key = 'conversations_v1';

  static Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List list = jsonDecode(raw) as List;
    return list
        .map<Map<String, dynamic>>(
          (e) => Map<String, dynamic>.from(e as Map),
    )
        .toList();
  }

  static Future<void> _save(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list));
  }

  /// একেকটা conversation item:
  /// - id      : conversationId (যেমন uidA_uidB)
  /// - userId  : অন্য user এর uid / key
  static Future<void> upsertConversation({
    required String conversationId, // convId (pair based)
    required String otherUserId,    // যার সাথে কথা হচ্ছে তার uid/key
    required String userType,       // 'earner' / 'supporter'
    required String name,
    required String role,
    required String image,
    required String location,
    required double rating,
  }) async {
    final list = await load();

    final index = list.indexWhere((c) => c['id'] == conversationId);
    final existing = index >= 0 ? Map<String, dynamic>.from(list[index]) : {};

    final updated = <String, dynamic>{
      ...existing,
      'id': conversationId,         // convId
      'userId': otherUserId,        // অন্য user এর uid/key
      'userType': userType,
      'name': name,
      'role': role,
      'image': image,
      'location': location,
      'rating': rating,
      'lastMsg': existing['lastMsg'] ?? '',
      'time': existing['time'] ?? '',
      'unread': existing['unread'] ?? 0,
      'isOnline': existing['isOnline'] ?? true,
      'isVerified': existing['isVerified'] ?? false,
      'isTopRated': existing['isTopRated'] ?? (rating >= 4.8),
      'isTrusted': existing['isTrusted'] ?? (rating >= 4.2),
    };

    if (index >= 0) {
      list[index] = updated;
    } else {
      // নতুন হলে উপরে add করো
      list.insert(0, updated);
    }

    await _save(list);
  }
}