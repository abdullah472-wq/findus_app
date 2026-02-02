import 'dart:async'; // Stream এর জন্য
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // --- বেসিক মেথড (ফিক্সড) ---

  /// রিয়েল-টাইম ইউজার ডাটা স্ট্রিম (rxdart ছাড়া)
  static Stream<DocumentSnapshot<Map<String, dynamic>>> get currentUserStream {
    return _auth.authStateChanges().asyncExpand((user) {
      // asyncExpand ব্যবহার করলে স্ট্রিম ফ্ল্যাটেন (flatten) হয়ে যায়
      if (user == null) {
        // ইউজার না থাকলে একটি এম্পটি বা ডামি স্ট্রিম রিটার্ন করা যায়
        // অথবা এমন একটি স্ট্রিম যা কখনো কিছু এমিট করে না
        return const Stream.empty();
      }
      // ইউজার থাকলে তার ডকুমেন্ট স্ট্রিম রিটার্ন করা
      return _db.collection('users').doc(user.uid).snapshots();
    });
  }

  // বাকি মেথডগুলো আগের মতোই থাকবে...

  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateUserStatus(bool isOnline) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'lastActive': FieldValue.serverTimestamp(),
      });
    }
  }

  // --- সেটিংস স্ক্রিনের জন্য মেথড ---

  static Future<String> getCurrentUserId() async {
    return _auth.currentUser?.uid ?? '';
  }

  static Future<String> getSubscriptionType() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'free';

    try {
      final doc = await _db.collection('users').doc(uid).get(const GetOptions(source: Source.serverAndCache));
      final data = doc.data();
      return (data?['subscription_type'] ?? 'free').toString().toLowerCase();
    } catch (e) {
      return 'free';
    }
  }

  static Future<bool> isPremiumUser() async {
    final sub = await getSubscriptionType();
    return sub == 'pro' || sub == 'business' || sub == 'premium';
  }
}