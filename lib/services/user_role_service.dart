import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRoleService {
  static const String _roleKey = 'user_role';

  /// বর্তমান ইউজারের রোল পাবে (Cache অথবা Firestore থেকে)
  static Future<String> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString(_roleKey);

    if (role == null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          role = doc.data()?['userRole'] as String?;
          if (role != null) {
            await prefs.setString(_roleKey, role);
          }
        }
      }
    }
    return role ?? 'finder'; // ডিফল্ট রোল finder
  }

  /// রোল চেক করার হেল্পার
  static bool isFinder(String role) {
    return role.toLowerCase() == 'finder';
  }

  static bool isMaker(String role) {
    return role.toLowerCase() == 'maker';
  }

  /// রোল আপডেট করার মেথড
  static Future<void> updateUserRole(String newRole) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'userRole': newRole,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, newRole);
  }
}