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

    // ট্রানজ্যাকশন রান করা হচ্ছে শুধুমাত্র ডাটাবেজ আপডেটের জন্য
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

      // ২) শুধুমাত্র worker হলে workerRating আপডেট করবো
      // (Supporter এর জন্যও লজিক চাইলে এখানে যোগ করা যাবে)
      final userSnap = await txn.get(userRef);
      if (userSnap.exists) {
        final data = userSnap.data() ?? {};

        // মেইন রেটিং (সবার জন্য)
        final oldRating = (data['rating'] ?? 0.0) is int
            ? (data['rating'] as int).toDouble()
            : (data['rating'] ?? 0.0) as double;

        final oldCount = (data['reviewsCount'] ?? 0) as int;

        final newCount = oldCount + 1;
        final newAvg = ((oldRating * oldCount) + rating) / newCount;

        // আপডেট ম্যাপ তৈরি
        final updateData = <String, dynamic>{
          'rating': double.parse(newAvg.toStringAsFixed(2)),
          'reviewsCount': newCount,
        };

        // যদি স্পেসিফিক রোল-বেসড রেটিং ফিল্ড থাকে
        if (targetRole == 'worker') {
          final oldWorkerRating = (data['workerRating'] ?? 0.0) is int
              ? (data['workerRating'] as int).toDouble()
              : (data['workerRating'] ?? 0.0) as double;

          final oldWorkerCount = (data['workerReviewCount'] ?? 0) as int;

          final newWorkerCount = oldWorkerCount + 1;
          final newWorkerAvg = ((oldWorkerRating * oldWorkerCount) + rating) / newWorkerCount;

          updateData['workerRating'] = double.parse(newWorkerAvg.toStringAsFixed(2));
          updateData['workerReviewCount'] = newWorkerCount;
        }

        txn.update(userRef, updateData);
      }
    });

    // ৩) ট্রানজ্যাকশন সফল হলে নোটিফিকেশন পাঠানো (Transaction এর বাইরে)
    try {
      await NotificationService.sendNotificationToUser(
        toUserId: targetUserId,
        title: "You received a new review",
        body: "${rating.toStringAsFixed(1)} ★ - ${comment.isEmpty ? "New rating received" : "\"$comment\""}",
        type: "review",
        relatedUserId: fromUserId,
        relatedPostId: postId,
        data: {
          'rating': rating,
          'targetRole': targetRole,
        },
      );
    } catch (e) {
      // নোটিফিকেশন ফেইল করলেও রিভিউ সেভ থাকবে, তাই এখানে ক্রাশ করানো হবে না
      print("Failed to send review notification: $e");
    }
  }

  /// নির্দিষ্ট ইউজারের সব রিভিউ স্ট্রিম করার জন্য
  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  streamReviewsForUser(String userId) {
    final q = _firestore
        .collection('reviews')
        .where('targetUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    return q.snapshots().map((snap) => snap.docs);
  }
}