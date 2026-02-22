import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // --- বেসিক মেথড (ফিক্সড) ---

  /// রিয়েল-টাইম ইউজার ডাটা স্ট্রিম (rxdart ছাড়া)
  static Stream<DocumentSnapshot<Map<String, dynamic>>> get currentUserStream {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return const Stream.empty();
      }
      return _db.collection('users').doc(user.uid).snapshots();
    });
  }

  /// ইউজার ডাটা একবার নিয়ে আসা (অফলাইন সাপোর্ট সহ)
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache)); // ✅ অফলাইন সাপোর্ট
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e'); // ✅ লগিং
      return null;
    }
  }

  /// ইউজার স্ট্যাটাস আপডেট (অনলাইন/অফলাইন)
  static Future<void> updateUserStatus(bool isOnline) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await _db.collection('users').doc(uid).update({
          'isOnline': isOnline,
          'lastActive': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Status update failed: $e'); // ✅ Error Handling
      }
    }
  }

  // --- সেটিংস স্ক্রিনের জন্য মেথড ---

  /// বর্তমান ইউজারের ID
  static Future<String> getCurrentUserId() async {
    return _auth.currentUser?.uid ?? '';
  }

  /// সাবস্ক্রিপশন টাইপ নিয়ে আসা
  static Future<String> getSubscriptionType() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'free';

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache)); // ✅ অফলাইন সাপোর্ট
      final data = doc.data();
      return (data?['subscription_type'] ?? 'free').toString().toLowerCase();
    } catch (e) {
      print('Error getting subscription: $e'); // ✅ লগিং
      return 'free';
    }
  }

  /// প্রিমিয়াম ইউজার কিনা চেক করা
  static Future<bool> isPremiumUser() async {
    final sub = await getSubscriptionType();
    return sub == 'pro' || sub == 'business' || sub == 'premium';
  }

  /// লগআউট করার সময় স্ট্যাটাস আপডেট
  static Future<void> logout() async {
    await updateUserStatus(false); // ✅ অফলাইন করা
    await _auth.signOut();
  }
}