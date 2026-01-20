import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobFlowService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Supporter -> Finder
  static Future<String> sendHireRequest({
    required String finderId, // receiver
    required String location,
    required String price,

    // receiver UI তে দেখানোর জন্য sender info রেখে দিন (denormalized)
    required String supporterName,
    required String supporterRole, // e.g. "supporter"
    required String supporterImage,
    double? supporterRating,
  }) async {
    final supporterId = _auth.currentUser?.uid;
    if (supporterId == null) throw Exception('Not logged in');
    if (finderId.isEmpty) throw Exception('FinderId empty');
    if (finderId == supporterId) throw Exception('Cannot send request to self');

    final reqRef = _db.collection('hire_requests').doc();

    // 1) hire request create
    await reqRef.set({
      'senderId': supporterId,
      'senderName': supporterName,
      'senderRole': supporterRole,
      'senderImage': supporterImage,
      'rating': supporterRating ?? 0,

      'receiverId': finderId,
      'status': 'pending',

      'location': location,
      'price': price,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2) notification -> finder
    await _db.collection('notifications').add({
      'toUserId': finderId,
      'fromUserId': supporterId,
      'type': 'hire_request',
      'title': 'New hire request',
      'requestId': reqRef.id,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return reqRef.id;
  }

  /// Finder approves (receiver)
  /// - hire_requests: pending -> ongoing
  /// - ongoing_jobs: create (docId = requestId to prevent duplicates)
  static Future<void> approveHireRequest({required String requestId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    final db = FirebaseFirestore.instance;
    final reqRef = db.collection('hire_requests').doc(requestId);
    final ongoingRef = db.collection('ongoing_jobs').doc(requestId);

    await db.runTransaction((tx) async {
      final snap = await tx.get(reqRef);
      if (!snap.exists) throw Exception('Request not found');

      final data = snap.data() as Map<String, dynamic>;
      final receiverId = data['receiverId']?.toString() ?? '';
      final supporterId = data['senderId']?.toString() ?? '';
      final status = data['status']?.toString() ?? '';

      if (receiverId != uid) throw Exception('Not receiver');
      if (status != 'pending') throw Exception('Not pending');

      // 1) hire_requests -> ongoing
      tx.update(reqRef, {
        'status': 'ongoing',
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2) ongoing_jobs create (participants contains both)
      tx.set(ongoingRef, {
        'participants': [receiverId, supporterId],
        'receiverId': receiverId,
        'workerId': supporterId,
        'status': 'ongoing',
        'startTime': FieldValue.serverTimestamp(),
        'originalRequestId': requestId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// Finder completes job
  /// - ongoing_jobs: status completed + endTime
  /// - completed_jobs: create history doc
  ///
  /// NOTE: এটা client থেকে কাজ করবে কিনা depends on rules (নীচে rules অপশন দেখুন)
  static Future<void> completeJob({required String jobId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    final db = FirebaseFirestore.instance;
    final ongoingRef = db.collection('ongoing_jobs').doc(jobId);
    final completedRef = db.collection('completed_jobs').doc(jobId);
    final reqRef = db.collection('hire_requests').doc(jobId); // (jobId=requestId হলে)

    await db.runTransaction((tx) async {
      final snap = await tx.get(ongoingRef);
      if (!snap.exists) throw Exception('Ongoing job not found');

      final job = snap.data() as Map<String, dynamic>;
      final receiverId = job['receiverId']?.toString() ?? '';
      final workerId = job['workerId']?.toString() ?? '';
      final status = job['status']?.toString() ?? '';

      if (receiverId != uid) throw Exception('Only finder(receiver) can complete');
      if (status != 'ongoing') throw Exception('Job not ongoing');

      // 1) ongoing_jobs -> completed (so it disappears from "work in progress")
      tx.update(ongoingRef, {
        'status': 'completed',
        'endTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2) completed_jobs create (participants contains both)
      tx.set(completedRef, {
        'participants': [receiverId, workerId],
        'receiverId': receiverId,
        'workerId': workerId,
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'originalRequestId': job['originalRequestId'] ?? jobId,
      }, SetOptions(merge: true));

      // (Optional) hire_requests statusও completed করে দিন
      tx.update(reqRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}