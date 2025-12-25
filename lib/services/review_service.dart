// lib/services/review_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/services/notification_service.dart';

class ReviewService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// নতুন review add করবে এবং target user এর aggregate rating update করবে
  static Future<void> addReview({
    required String targetUserId,   // যাকে রিভিউ দিচ্ছো
    required String postId,         // কোন job/post
    required double rating,         // 1.0 - 5.0
    String comment = '',

    // নতুন ফিল্ডগুলো:
    required String targetRole,     // "worker" / "supporter"
    required String fromRole,       // "worker" / "supporter"
    bool isAnonymous = false,
  }) async {
    final fromUser = _auth.currentUser;
    if (fromUser == null) {
      throw Exception('Not logged in');
    }

    final fromUserId = fromUser.uid;

    final reviewRef = _firestore.collection('reviews').doc();
    final userRef = _firestore.collection('users').doc(targetUserId);

    await _firestore.runTransaction((txn) async {
      // ১) reviews ডক সেট আপ করি
      txn.set(reviewRef, {
        'targetUserId': targetUserId,
        'fromUserId': fromUserId,
        'postId': postId,
        'rating': rating,
        'comment': comment.trim(),
        'createdAt': FieldValue.serverTimestamp(),

        'targetRole': targetRole,
        'fromRole': fromRole,
        'isAnonymous': isAnonymous,
      });
      // transaction শেষে, successful হলে:
      await NotificationService.sendNotificationToUser(
        toUserId: targetUserId,            // worker uid
        title: "You received a new review",
        body: "${rating.toStringAsFixed(1)} ★ - ${comment.isEmpty ? "" : "\"$comment\""}",
        type: "review",
        relatedUserId: fromUserId,
        relatedPostId: postId,
      );

      // ২) শুধুমাত্র worker হলে workerRating আপডেট করবো
      if (targetRole == 'worker') {
        final userSnap = await txn.get(userRef);
        final data = userSnap.data() as Map<String, dynamic>? ?? {};

        final oldRating = (data['workerRating'] ?? 0.0) * 1.0;
        final oldCount = (data['workerReviewCount'] ?? 0) as int;

        final newCount = oldCount + 1;
        final newAvg =
            ((oldRating * oldCount) + rating) / (newCount == 0 ? 1 : newCount);

        txn.update(userRef, {
          'workerRating': double.parse(newAvg.toStringAsFixed(2)),
          'workerReviewCount': newCount,
        });
      }

      // ভবিষ্যতে চাইলে supporter rating এর জন্য আলাদা aggregate এখানে করতে পারো:
      // if (targetRole == 'supporter') { ... }
    });
  }

  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamReviewsForUser(String userId) {
    final q = _firestore
        .collection('reviews')
        .where('targetUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    return q.snapshots().map((snap) => snap.docs);
  }
}