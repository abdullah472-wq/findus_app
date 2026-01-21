import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  /// ✅ এই মেথডটি মিসিং ছিল, এটি যোগ করুন
  static Future<void> sendNotificationToUser({
    required String toUserId,
    required String title,
    required String body,
    required String type,
    String? relatedUserId,
    String? relatedPostId,
    Map<String, dynamic>? data, // এক্সট্রা ডাটা রিসিভ করার জন্য
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    await _db.collection('notifications').add({
      'toUserId': toUserId,
      'fromUserId': relatedUserId ?? currentUid,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'relatedPostId': relatedPostId,
      'data': data ?? {}, // রিভিউ এর এক্সট্রা ডাটা এখানে থাকবে
    });
  }

  // পুরানো মেথড (যদি অ্যাপের অন্য কোথাও ব্যবহার হয়ে থাকে)
  static Future<void> sendNotification({
    required String toUserId,
    required String fromUserId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    await sendNotificationToUser(
      toUserId: toUserId,
      title: title,
      body: body,
      type: type,
      relatedUserId: fromUserId,
      relatedPostId: relatedId,
    );
  }

  static Future<void> markAsRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({
      'isRead': true,
    });
  }

  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamMyNotifications(String uid) {
    return _db
        .collection('notifications')
        .where('toUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  static Stream<int> getUnreadCount(String uid) {
    return _db
        .collection('notifications')
        .where('toUserId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}