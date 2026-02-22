// lib/services/review_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:findus_app/services/notification_service.dart';

class ReviewService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// Add a new review
  static Future<void> addReview({
    required String targetUserId,
    required String postId,
    required double rating,
    String comment = '',
    String targetRole = 'worker',
    String fromRole = 'supporter',
    bool isAnonymous = false,
    bool wouldHireAgain = true,
    List<String> tags = const [],
  }) async {
    final fromUser = _auth.currentUser;
    if (fromUser == null) {
      throw Exception('Not logged in');
    }

    final fromUserId = fromUser.uid;
    final reviewRef = _firestore.collection('reviews').doc();
    final userRef = _firestore.collection('users').doc(targetUserId);

    await _firestore.runTransaction((txn) async {
      // 1. Create review document
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
        'wouldHireAgain': wouldHireAgain,
        'tags': tags,
      });

      // 2. Update user ratings
      final userSnap = await txn.get(userRef);
      if (userSnap.exists) {
        final data = userSnap.data() ?? {};

        final oldRating = (data['rating'] ?? 0.0) is int
            ? (data['rating'] as int).toDouble()
            : (data['rating'] ?? 0.0) as double;

        final oldCount = (data['reviewsCount'] ?? 0) as int;
        final newCount = oldCount + 1;
        final newAvg = ((oldRating * oldCount) + rating) / newCount;

        final updateData = <String, dynamic>{
          'rating': double.parse(newAvg.toStringAsFixed(2)),
          'reviewsCount': newCount,
        };

        if (targetRole == 'worker') {
          final oldWorkerRating = (data['workerRating'] ?? 0.0) is int
              ? (data['workerRating'] as int).toDouble()
              : (data['workerRating'] ?? 0.0) as double;

          final oldWorkerCount = (data['workerReviewCount'] ?? 0) as int;
          final newWorkerCount = oldWorkerCount + 1;
          final newWorkerAvg =
              ((oldWorkerRating * oldWorkerCount) + rating) / newWorkerCount;

          updateData['workerRating'] =
              double.parse(newWorkerAvg.toStringAsFixed(2));
          updateData['workerReviewCount'] = newWorkerCount;
        }

        txn.update(userRef, updateData);
      }
    });

    // 3. Send notification
    try {
      await NotificationService.sendNotificationToUser(
        toUserId: targetUserId,
        title: "You received a new review",
        body:
        "${rating.toStringAsFixed(1)} ★ - ${comment.isEmpty ? "New rating received" : "\"$comment\""}",
        type: "review",
        relatedUserId: fromUserId,
        relatedPostId: postId,
        data: {
          'rating': rating,
          'targetRole': targetRole,
          'wouldHireAgain': wouldHireAgain,
          'tags': tags,
        },
      );
    } catch (e) {
      debugPrint("Failed to send review notification: $e");
    }
  }

  /// Stream reviews for a user
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamReviewsForUser(String userId) {
    final q = _firestore
        .collection('reviews')
        .where('targetUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    return q.snapshots().map((snap) => snap.docs);
  }
}