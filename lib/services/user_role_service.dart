import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRoleService {
  static const String _roleKey = 'user_role';

  /// বর্তমান ইউজারের রোল পাবে
  /// forceRefresh: true হলে সার্ভার থেকে নতুন ডাটা আনবে
  static Future<String> getCurrentUserRole({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // যদি রিফ্রেশ না চায় এবং ক্যাশে ডাটা থাকে, তবে ক্যাশ থেকে রিটার্ন করবে
    if (!forceRefresh) {
      String? cachedRole = prefs.getString(_roleKey);
      if (cachedRole != null) return cachedRole;
    }

    // সার্ভার থেকে ডাটা আনা
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.serverAndCache)); // ✅ অফলাইন সাপোর্ট

        if (doc.exists) {
          String? role = doc.data()?['userRole'] as String?;
          if (role != null) {
            await prefs.setString(_roleKey, role);
            return role;
          }
        }
      } catch (e) {
        print('Error getting role: $e'); // ✅ লগিং
        // অফলাইন হলে ক্যাশ থেকে রিটার্ন করার চেষ্টা
        String? cachedRole = prefs.getString(_roleKey);
        if (cachedRole != null) return cachedRole;
      }
    }

    return 'finder'; // ডিফল্ট রোল
  }

  /// রোল চেক করার হেল্পার (Null-Safe)
  static bool isFinder(String? role) {
    if (role == null) return true; // ✅ ডিফল্ট finder
    return role.toLowerCase() == 'worker' || role.toLowerCase() == 'finder';
  }

  static bool isMaker(String? role) {
    if (role == null) return false; // ✅ Null চেক
    return role.toLowerCase() == 'maker';
  }

  /// রোল আপডেট করার মেথড (লোকাল + সার্ভার)
  static Future<void> updateUserRole(String newRole) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // সার্ভার আপডেট
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'userRole': newRole,
      });

      // লোকাল ক্যাশ আপডেট
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_roleKey, newRole);
    } catch (e) {
      print('Error updating role: $e'); // ✅ Error Handling
    }
  }

  /// লগআউটের সময় ক্যাশ ক্লিয়ার করার জন্য
  static Future<void> clearRoleCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_roleKey);
    } catch (e) {
      print('Error clearing role cache: $e'); // ✅ Error Handling
    }
  }

  /// App শুরুতে রোল ক্যাশ করুন (অপশনাল কিন্তু রেকমেন্ডেড)
  static Future<void> initializeRole() async {
    await getCurrentUserRole(forceRefresh: true);
  }
}