// lib/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  // ✅ নোটিফিকেশন সেভ করার মেইন ফাংশন
  static Future<void> sendNotification({
    required String toUserId,
    required String fromUserId,
    required String title,
    required String body,
    required String type, // 'hire_request', 'emergency', 'system', 'chat'
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

  // ✅ রিয়েল-টাইম নোটিফিকেশন স্ট্রিম (আপনার পেজের জন্য)
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamMyNotifications(String uid) {
    return _db
        .collection('notifications')
        .where('toUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs);
  }
}