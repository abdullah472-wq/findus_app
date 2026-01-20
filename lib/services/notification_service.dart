import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  // ✅ নোটিফিকেশন সেভ করার মেইন ফাংশন
  static Future<void> sendNotification({
    required String toUserId,
    required String fromUserId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    await _db.collection('notifications').add({
      'toUserId': toUserId,
      'fromUserId': fromUserId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'relatedId': relatedId ?? '',
    });
  }

  // ✅ নোটিফিকেশন পড়ার পর আপডেট করা
  static Future<void> markAsRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({
      'isRead': true,
    });
  }

  // ✅ রিয়েল-টাইম নোটিফিকেশন স্ট্রিম (পজিশনাল আর্গুমেন্ট uid সহ)
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamMyNotifications(String uid) {
    return _db
        .collection('notifications')
        .where('toUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  // অপঠিত নোটিফিকেশনের সংখ্যা জানার জন্য (Notification Badge)
  static Stream<int> getUnreadCount(String uid) {
    return _db
        .collection('notifications')
        .where('toUserId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}