import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRoleService {
  static const String _roleKey = 'user_role';

  /// বর্তমান ইউজারের রোল পাবে
  /// forceRefresh: true হলে সার্ভার থেকে নতুন ডাটা আনবে
  static Future<String> getCurrentUserRole({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // যদি রিফ্রেশ না চায় এবং ক্যাশে ডাটা থাকে, তবে ক্যাশ থেকে রিটার্ন করবে
    if (!forceRefresh) {
      String? cachedRole = prefs.getString(_roleKey);
      if (cachedRole != null) return cachedRole;
    }

    // সার্ভার থেকে ডাটা আনা
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          String? role = doc.data()?['userRole'] as String?;
          if (role != null) {
            await prefs.setString(_roleKey, role);
            return role;
          }
        }
      } catch (e) {
        // এরর হলে বা অফলাইনে থাকলে ডিফল্ট রিটার্ন করবে
        return 'finder';
      }
    }

    return 'finder'; // ডিফল্ট রোল
  }

  /// রোল চেক করার হেল্পার
  static bool isFinder(String role) {
    return role.toLowerCase() == 'finder';
  }

  static bool isMaker(String role) {
    return role.toLowerCase() == 'maker';
  }

  /// রোল আপডেট করার মেথড (লোকাল + সার্ভার)
  static Future<void> updateUserRole(String newRole) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // সার্ভার আপডেট
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'userRole': newRole,
    });

    // লোকাল ক্যাশ আপডেট
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, newRole);
  }

  /// লগআউটের সময় ক্যাশ ক্লিয়ার করার জন্য
  static Future<void> clearRoleCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
  }
}