import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:findus_app/services/notification_service.dart'; // 🔹 NEW
import 'package:firebase_auth/firebase_auth.dart';              // 🔹 NEW

/// প্রতিটি ব্লকড ইউজার:
/// { "id": "101", "name": "Rahim (Driver)" }
class BlockedUserService {
  static const String _prefsKey = 'blocked_users_map';

  // Singleton (ইচ্ছা হলে বাদ দিতে পারো)
  static final BlockedUserService _instance =
  BlockedUserService._internal();
  factory BlockedUserService() => _instance;
  BlockedUserService._internal();

  Future<List<Map<String, String>>> _loadBlockedList() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_prefsKey) ?? <String>[];
    final List<Map<String, String>> result = [];

    for (final item in rawList) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(item));
        // কেবল id + name string হিসেবে রাখছি
        result.add({
          'id': (map['id'] ?? '').toString(),
          'name': (map['name'] ?? '').toString(),
        });
      } catch (_) {
        // কোন item corrupt থাকলে স্কিপ করবো
      }
    }
    return result;
  }

  Future<void> _saveBlockedList(List<Map<String, String>> users) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = users.map((m) => jsonEncode(m)).toList();
    await prefs.setStringList(_prefsKey, rawList);
  }

  /// ✅ PublicProfileScreen থেকে ব্যবহার করবে:
  /// await BlockedUserService().blockUser(userId, name);
  Future<void> blockUser(String id, String name) async {
    final current = await _loadBlockedList();
    final index = current.indexWhere((u) => u['id'] == id);

    if (index == -1) {
      // নতুন ইউজার
      current.add({'id': id, 'name': name});
    } else {
      // আগেই থাকলে শুধু name আপডেট
      current[index] = {'id': id, 'name': name};
    }

    await _saveBlockedList(current);

    // 🔹 Notification: যিনি block করলেন, তিনি নিজেই জানবেন কাকে block করেছেন
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      try {
        await NotificationService.sendNotificationToUser(
          toUserId: currentUserId,
          title: 'User blocked',
          body: 'You blocked $name.',
          type: 'block',
          status: 'blocked',
          data: {
            'blockedUserId': id,
            'blockedUserName': name,
            'action': 'block',
          },
        );
      } catch (_) {
        // নোটিফিকেশন পাঠাতে না পারলে অ্যাপ ক্র্যাশ হবে না
      }
    }
  }

  Future<void> unblockUser(String id) async {
    final current = await _loadBlockedList();

    // notification text এর জন্য আগে নামটা বের করে নিই
    String? name;
    for (final u in current) {
      if (u['id'] == id) {
        name = u['name'];
        break;
      }
    }

    current.removeWhere((u) => u['id'] == id);
    await _saveBlockedList(current);

    // 🔹 Notification: unblock করলেও নিজের কাছে log থাকবে
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      try {
        await NotificationService.sendNotificationToUser(
          toUserId: currentUserId,
          title: 'User unblocked',
          body: name != null
              ? 'You unblocked $name.'
              : 'You unblocked a user.',
          type: 'block',
          status: 'unblocked',
          data: {
            'blockedUserId': id,
            'blockedUserName': name,
            'action': 'unblock',
          },
        );
      } catch (_) {
        // ignore
      }
    }
  }

  Future<bool> isBlocked(String id) async {
    final current = await _loadBlockedList();
    return current.any((u) => u['id'] == id);
  }

  Future<List<Map<String, String>>> getBlockedUsers() async {
    return _loadBlockedList();
  }

  Future<void> clearAll() async {
    await _saveBlockedList(<Map<String, String>>[]);
  }
}