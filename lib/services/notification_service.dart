// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// টপ-লেভেল `notifications` কালেকশনে নোটিফিকেশন ডক যোগ করবে
  ///
  /// ফায়ারস্টোর ডক স্ট্রাকচার (প্রতি notification):
  /// - title        : String
  /// - body         : String
  /// - type         : String (job_post, hire_request, review, payment, admin, ...)
  /// - toUserId     : String (receiver)
  /// - fromUserId   : String (sender, optional → না দিলে currentUser.uid)
  /// - relatedUserId: String? (optional)
  /// - relatedPostId: String? (optional)
  /// - status       : String? (optional: pending/accepted/... ইত্যাদি)
  /// - data         : Map<String, dynamic> (extra payload; default = {})
  /// - createdAt    : Timestamp (serverTimestamp)
  /// - isRead       : bool
  static Future<void> sendNotificationToUser({
    required String toUserId,
    String? fromUserId,
    required String title,
    required String body,
    String type = 'general',
    String? relatedUserId,
    String? relatedPostId,
    String? status,
    Map<String, dynamic>? data,
  }) async {
    final currentUserId = _auth.currentUser?.uid;

    final notificationData = <String, dynamic>{
      'title': title,
      'body': body,
      'type': type,
      'toUserId': toUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    };

    // fromUserId: param থাকলে ওটা, না থাকলে currentUser.uid, একদমই না থাকলে ফিল্ড বাদ
    final effectiveFromUserId = fromUserId ?? currentUserId;
    if (effectiveFromUserId != null) {
      notificationData['fromUserId'] = effectiveFromUserId;
    }

    if (relatedUserId != null) {
      notificationData['relatedUserId'] = relatedUserId;
    }
    if (relatedPostId != null) {
      notificationData['relatedPostId'] = relatedPostId;
    }
    if (status != null) {
      notificationData['status'] = status;
    }

    // সব সময় data ফিল্ড থাকবে, না থাকলে খালি map
    notificationData['data'] = data ?? <String, dynamic>{};

    await _firestore.collection('notifications').add(notificationData);
  }

  /// current user এর notifications stream (top-level `notifications` থেকে)
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamMyNotifications() {
    final uid = _auth.currentUser!.uid;

    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  /// notification read হিসেবে mark করা
  static Future<void> markAsRead(String notifId) async {
    await _firestore
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }
}