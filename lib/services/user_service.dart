import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // --- বেসিক মেথড ---

  static Stream<DocumentSnapshot<Map<String, dynamic>>> get currentUserStream {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots();
  }

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

  // --- ✅ সেটিংস স্ক্রিনের জন্য নতুন মেথড ---

  /// বর্তমান লগ-ইন থাকা ইউজারের UID রিটার্ন করে
  static Future<String> getCurrentUserId() async {
    return _auth.currentUser?.uid ?? '';
  }

  /// সাবস্ক্রিপশন টাইপ চেক করে (free/premium/business)
  static Future<String> getSubscriptionType() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'free';

    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data();
      return (data?['subscription_type'] ?? 'free').toString().toLowerCase();
    } catch (e) {
      return 'free';
    }
  }

  /// ইউজার প্রিমিয়াম কিনা চেক করে (premium বা business হলে true)
  static Future<bool> isPremiumUser() async {
    final sub = await getSubscriptionType();
    return sub == 'premium' || sub == 'business' || sub == 'pro';
  }
}