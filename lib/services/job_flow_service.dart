// lib/services/job_flow_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class JobFlowService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// ═══════════════════════════════════════════════════════════
  /// 1️⃣ SEND HIRE REQUEST (Supporter → Worker/Finder)
  /// ═══════════════════════════════════════════════════════════
  static Future<String> sendHireRequest({
    required String finderId, // Worker who will receive the request
    required String finderName,
    required String finderRole,
    required String finderImage,

    required String jobTitle,
    String? jobDescription,
    required String location,
    required String price, // e.g. "৳1200 / day"

    // Supporter info (sender)
    String? supporterName,
    String? supporterRole,
    String? supporterImage,
    double? supporterRating,
  }) async {
    final supporterId = _auth.currentUser?.uid;
    if (supporterId == null) throw Exception('Not logged in');
    if (finderId.isEmpty) throw Exception('FinderId empty');
    if (finderId == supporterId) throw Exception('Cannot send request to self');

    // Get current user info if not provided
    final currentUserDoc = await _db.collection('users').doc(supporterId).get();
    final currentUserData = currentUserDoc.data() ?? {};

    final senderName = supporterName ?? currentUserData['name'] ?? 'User';
    final senderRole = supporterRole ?? currentUserData['userRole'] ?? 'supporter';
    final senderImage = supporterImage ?? currentUserData['image'] ?? '';
    final senderRating = supporterRating ??
        (double.tryParse(currentUserData['rating']?.toString() ?? '0') ?? 0.0);

    final reqRef = _db.collection('hire_requests').doc();

    try {
      // 1️⃣ Create hire request
      await reqRef.set({
        // Sender (Supporter/Employer)
        'senderId': supporterId,
        'senderName': senderName,
        'senderRole': senderRole,
        'senderImage': senderImage,
        'senderRating': senderRating,

        // Receiver (Finder/Worker)
        'receiverId': finderId,
        'receiverName': finderName,
        'receiverRole': finderRole,
        'receiverImage': finderImage,

        // Job Details
        'jobTitle': jobTitle,
        'description': jobDescription ?? '',
        'location': location,
        'price': price,
        'offerPrice': price, // Duplicate for compatibility

        // Status
        'status': 'pending',

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2️⃣ Send notification to worker
      await _db.collection('notifications').add({
        'toUserId': finderId,
        'fromUserId': supporterId,
        'type': 'hire_request',
        'title': 'New Job Request! 💼',
        'body': '$senderName wants to hire you for "$jobTitle"',
        'requestId': reqRef.id,
        'jobTitle': jobTitle,
        'price': price,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3️⃣ Update supporter stats
      await _db.collection('user_stats').doc(supporterId).set({
        'requestsSent': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ Hire request sent: ${reqRef.id}');
      return reqRef.id;
    } catch (e) {
      debugPrint('❌ Error sending hire request: $e');
      rethrow;
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// 2️⃣ APPROVE HIRE REQUEST (Worker accepts job)
  /// ═══════════════════════════════════════════════════════════
  static Future<void> approveHireRequest({required String requestId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    final reqRef = _db.collection('hire_requests').doc(requestId);
    final ongoingRef = _db.collection('ongoing_jobs').doc(requestId);

    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(reqRef);
        if (!snap.exists) throw Exception('Request not found');

        final data = snap.data() as Map<String, dynamic>;

        // Extract IDs
        final receiverId = data['receiverId']?.toString() ?? '';
        final supporterId = data['senderId']?.toString() ?? '';
        final status = data['status']?.toString() ?? '';

        // Security checks
        if (receiverId != uid) {
          throw Exception('Not authorized - you are not the receiver');
        }
        if (status != 'pending') {
          throw Exception('Request already processed');
        }

        // 1️⃣ Update hire_requests → ongoing
        tx.update(reqRef, {
          'status': 'ongoing',
          'approvedAt': FieldValue.serverTimestamp(),
          'approvedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2️⃣ Create ongoing_jobs entry
        tx.set(ongoingRef, {
          'participants': [receiverId, supporterId],

          // Worker (Finder)
          'finderId': receiverId,
          'finderName': data['receiverName'] ?? 'Worker',
          'finderImage': data['receiverImage'] ?? '',
          'finderRole': data['receiverRole'] ?? 'finder',

          // Employer (Supporter)
          'supporterId': supporterId,
          'supporterName': data['senderName'] ?? 'Employer',
          'supporterImage': data['senderImage'] ?? '',
          'supporterRole': data['senderRole'] ?? 'supporter',

          // Job Details
          'jobTitle': data['jobTitle'] ?? 'Job',
          'description': data['description'] ?? '',
          'location': data['location'] ?? '',
          'price': data['price'] ?? '',

          // Status
          'status': 'ongoing',
          'startTime': FieldValue.serverTimestamp(),
          'originalRequestId': requestId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 3️⃣ Update Supporter stats
        tx.set(
          _db.collection('user_stats').doc(supporterId),
          {
            'hiresCount': FieldValue.increment(1),
            'hiresOngoing': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // 4️⃣ Update Finder stats
        tx.set(
          _db.collection('user_stats').doc(receiverId),
          {
            'jobsAccepted': FieldValue.increment(1),
            'jobsOngoing': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      // 5️⃣ Send notification to supporter
      final reqSnap = await reqRef.get();
      final reqData = reqSnap.data() ?? {};

      await _db.collection('notifications').add({
        'toUserId': reqData['senderId'],
        'fromUserId': uid,
        'type': 'hire_request_approved',
        'title': 'Request Approved! 🎉',
        'body': '${reqData['receiverName'] ?? 'Worker'} accepted your job request!',
        'requestId': requestId,
        'jobTitle': reqData['jobTitle'],
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Hire request approved: $requestId');
    } catch (e) {
      debugPrint('❌ Error approving hire request: $e');
      rethrow;
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// 3️⃣ COMPLETE JOB (Worker marks job as done)
  /// ═══════════════════════════════════════════════════════════
  static Future<void> completeJob({required String jobId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    final ongoingRef = _db.collection('ongoing_jobs').doc(jobId);
    final completedRef = _db.collection('completed_jobs').doc(jobId);
    final reqRef = _db.collection('hire_requests').doc(jobId);

    try {
      // Get job data first to extract price
      final jobSnap = await ongoingRef.get();
      if (!jobSnap.exists) throw Exception('Ongoing job not found');

      final jobData = jobSnap.data() as Map<String, dynamic>;
      final priceAmount = _extractPrice(jobData['price']);

      await _db.runTransaction((tx) async {
        final snap = await tx.get(ongoingRef);
        if (!snap.exists) throw Exception('Ongoing job not found');

        final data = snap.data() as Map<String, dynamic>;

        final finderId = data['finderId']?.toString() ?? '';
        final supporterId = data['supporterId']?.toString() ?? '';
        final status = data['status']?.toString() ?? '';

        // Security checks
        if (finderId != uid) {
          throw Exception('Only worker can complete the job');
        }
        if (status != 'ongoing') {
          throw Exception('Job is not ongoing');
        }

        final participants = [finderId, supporterId];

        // 1️⃣ Update ongoing_jobs → completed
        tx.update(ongoingRef, {
          'status': 'completed',
          'endTime': FieldValue.serverTimestamp(),
          'completedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2️⃣ Create completed_jobs entry with earnings
        tx.set(completedRef, {
          ...data,
          'participants': participants,
          'finderId': finderId,
          'supporterId': supporterId,
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'completedBy': uid,
          'originalRequestId': data['originalRequestId'] ?? jobId,

          // ✅ Earnings tracking
          'amount': priceAmount,
          'priceOriginal': data['price'],

          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 3️⃣ Update hire_requests
        tx.set(reqRef, {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'completedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 4️⃣ Update Supporter stats
        tx.set(
          _db.collection('user_stats').doc(supporterId),
          {
            'hiresCompleted': FieldValue.increment(1),
            'hiresOngoing': FieldValue.increment(-1),
            'totalSpent': FieldValue.increment(priceAmount),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // 5️⃣ Update Finder (Worker) stats with earnings
        tx.set(
          _db.collection('user_stats').doc(finderId),
          {
            'jobsCompleted': FieldValue.increment(1),
            'jobsOngoing': FieldValue.increment(-1),
            'totalEarned': FieldValue.increment(priceAmount),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      // 6️⃣ Send notification to supporter
      final jobDetails = await ongoingRef.get();
      final jobInfo = jobDetails.data() ?? {};

      await _db.collection('notifications').add({
        'toUserId': jobInfo['supporterId'],
        'fromUserId': uid,
        'type': 'job_completed',
        'title': 'Job Completed! 🎉',
        'body': '${jobInfo['finderName'] ?? 'Worker'} has completed the job.',
        'jobId': jobId,
        'jobTitle': jobInfo['jobTitle'],
        'amount': priceAmount,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Job completed: $jobId (Earned: ৳${priceAmount.toInt()})');
    } catch (e) {
      debugPrint('❌ Error completing job: $e');
      rethrow;
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// 4️⃣ REJECT HIRE REQUEST
  /// ═══════════════════════════════════════════════════════════
  static Future<void> rejectHireRequest({required String requestId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');

    final reqRef = _db.collection('hire_requests').doc(requestId);

    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(reqRef);
        if (!snap.exists) throw Exception('Request not found');

        final data = snap.data() as Map<String, dynamic>;
        final receiverId = data['receiverId']?.toString() ?? '';
        final supporterId = data['senderId']?.toString() ?? '';
        final status = data['status']?.toString() ?? '';

        if (receiverId != uid) throw Exception('Not authorized');
        if (status != 'pending') throw Exception('Request already processed');

        tx.update(reqRef, {
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Send notification
      final reqSnap = await reqRef.get();
      final reqData = reqSnap.data() ?? {};

      await _db.collection('notifications').add({
        'toUserId': reqData['senderId'],
        'fromUserId': uid,
        'type': 'hire_request_rejected',
        'title': 'Request Declined',
        'body': 'Your job request was declined.',
        'requestId': requestId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Hire request rejected: $requestId');
    } catch (e) {
      debugPrint('❌ Error rejecting hire request: $e');
      rethrow;
    }
  }

  /// ═══════════════════════════════════════════════════════════
  /// HELPER: Extract price from string
  /// ═══════════════════════════════════════════════════════════
  static double _extractPrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();

    if (value is String) {
      final cleaned = value
          .replaceAll('৳', '')
          .replaceAll(',', '')
          .replaceAll('BDT', '')
          .replaceAll('/day', '')
          .replaceAll('/job', '')
          .replaceAll('per day', '')
          .replaceAll('per job', '')
          .trim();

      final match = RegExp(r'[\d.]+').firstMatch(cleaned);
      if (match != null) {
        return double.tryParse(match.group(0) ?? '0') ?? 0.0;
      }
    }

    return 0.0;
  }
}