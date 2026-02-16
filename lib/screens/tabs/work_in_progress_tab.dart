import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';

class WorkInProgressTab extends StatefulWidget {
  const WorkInProgressTab({super.key});

  @override
  State<WorkInProgressTab> createState() => _WorkInProgressTabState();
}

class _WorkInProgressTabState extends State<WorkInProgressTab> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  String _s(dynamic v, [String fallback = '']) => (v ?? fallback).toString();

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("Please login to see ongoing jobs."));
    }

    final uid = currentUser.uid;

    final stream = _firestore
        .collection('ongoing_jobs')
        .where('participants', arrayContains: uid)
        .where('status', isEqualTo: 'ongoing')
        .orderBy('startTime', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final err = snapshot.error.toString();
          if (err.contains('FAILED_PRECONDITION') || err.contains('index')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      "Firestore index required.\nPlease check Firebase console.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade300),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_off_outlined, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                const Text(
                  "No work in progress right now.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            return _buildWorkCard(context, data: data, docId: doc.id, currentUid: uid);
          },
        );
      },
    );
  }

  Widget _buildWorkCard(
      BuildContext context, {
        required Map<String, dynamic> data,
        required String docId,
        required String currentUid,
      }) {
    // ✅ সঠিক ফিল্ড নাম ব্যবহার
    final finderId = _s(data['finderId']).trim();       // Worker (কাজ করবে)
    final supporterId = _s(data['supporterId']).trim(); // Employer (hire করেছে)

    final participants = (data['participants'] is List)
        ? List.from(data['participants'])
        : <dynamic>[];

    // ✅ অন্য ইউজার খুঁজে বের করো
    final otherUserId = (currentUid == supporterId) ? finderId : supporterId;

    // ✅ শুধু Finder complete করতে পারবে
    final bool canComplete = currentUid == finderId;

    // ✅ সঠিক নাম ফিল্ড
    final String otherNameFromDoc = (currentUid == supporterId)
        ? _s(data['finderName'])
        : _s(data['supporterName']);

    final String otherImageFromDoc = (currentUid == supporterId)
        ? _s(data['finderImage'])
        : _s(data['supporterImage']);

    final String otherRoleFromDoc = (currentUid == supporterId)
        ? _s(data['finderRole'])
        : _s(data['supporterRole']);

    final String location = _s(data['location'], 'Location not available');
    final String price = _s(data['price'], _s(data['offerPrice'], 'Negotiable'));
    final String jobTitle = _s(data['jobTitle'], 'Job');

    // Stats from ongoing_jobs document (if stored)
    final double ratingVal = _asDouble(data['rating']);
    final String ratingStr = ratingVal == 0 ? '0.0' : ratingVal.toStringAsFixed(1);
    final int completedCount = _asInt(data['completedCount']);

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _needFetchOther(otherNameFromDoc, otherRoleFromDoc, otherImageFromDoc, otherUserId)
          ? _firestore.collection('users').doc(otherUserId).get()
          : Future.value(null),
      builder: (context, snap) {
        String name = otherNameFromDoc.isNotEmpty ? otherNameFromDoc : 'Unknown User';
        String role = otherRoleFromDoc.isNotEmpty ? otherRoleFromDoc : 'User';
        String imageUrl = otherImageFromDoc;

        if (snap.data != null && snap.data!.exists) {
          final u = snap.data!.data() ?? {};
          name = _s(u['name'], name);
          role = _s(u['userRole'], role);
          imageUrl = _s(u['image'], imageUrl);
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              UniversalWorkerCard(
                id: otherUserId,
                name: name,
                role: role,
                imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://i.pravatar.cc/150',
                address: location,
                rating: ratingStr,
                completed: completedCount.toString(),
                reviews: _asInt(data['reviewsCount']).toString(),
                price: price,
                time: "⏳ ONGOING",
                isVerifiedWorker: completedCount >= 50,
                isTopRated: ratingVal >= 4.7,
                followersCount: _asInt(data['followersCount']),
                margin: EdgeInsets.zero,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                onTap: () {
                  if (otherUserId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UnifiedProfileScreen(
                          uid: otherUserId,
                          isOwner: false,
                          showBack: true,
                        ),
                      ),
                    );
                  }
                },
                onChatTap: () => _openChat(context, otherUserId, name, role, imageUrl),
              ),

              // ✅ Job Info Section
              if (jobTitle.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black26
                        : Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (data['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _s(data['description']),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

              // ✅ Complete Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ElevatedButton(
                  onPressed: canComplete
                      ? () => _markJobAsCompleted(
                    context,
                    jobId: docId,
                    finderId: finderId,
                    supporterId: supporterId,
                    participants: participants,
                  )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canComplete
                        ? AppColors.brandMain
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        canComplete
                            ? "Mark as Completed"
                            : "Waiting for Worker to Complete",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _needFetchOther(String name, String role, String image, String otherId) {
    if (otherId.isEmpty) return false;
    return name.isEmpty || role.isEmpty || image.isEmpty || name == 'Unknown';
  }

  Future<void> _openChat(
      BuildContext context,
      String otherUserId,
      String name,
      String role,
      String imageUrl,
      ) async {
    if (otherUserId.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final convId = await FirestoreChatService.getOrCreateConversation(
        otherUserId: otherUserId,
      );

      if (!context.mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convId,
            userName: name,
            userRole: role,
            userImage: imageUrl,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Chat error: $e');
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open chat')),
        );
      }
    }
  }

  Future<void> _markJobAsCompleted(
      BuildContext context, {
        required String jobId,
        required String finderId,    // ✅ Worker (কাজ করছে)
        required String supporterId, // ✅ Employer (hire করেছে)
        required List participants,
      }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // ✅ শুধু Finder complete করতে পারবে
    if (currentUser.uid != finderId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Only the worker can complete this job.")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Complete Job"),
        content: const Text(
          "Mark this job as completed?\n\nThis will:\n"
              "• Move it to Completed tab\n"
              "• Update your stats\n"
              "• Notify the employer",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
            ),
            child: const Text("Complete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final ongoingRef = _firestore.collection('ongoing_jobs').doc(jobId);
      final completedRef = _firestore.collection('completed_jobs').doc(jobId);
      final requestRef = _firestore.collection('hire_requests').doc(jobId);

      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ongoingRef);
        if (!snap.exists) throw Exception('Ongoing job not found');

        final data = snap.data() as Map<String, dynamic>;
        final status = _s(data['status']);

        // Security checks
        if (_s(data['finderId']) != currentUser.uid) {
          throw Exception('Not authorized');
        }

        if (status != 'ongoing') {
          throw Exception('Job is not ongoing');
        }

        final List parts = (data['participants'] is List)
            ? List.from(data['participants'])
            : [finderId, supporterId];

        // ✅ 1. Update ongoing_jobs status
        tx.update(ongoingRef, {
          'status': 'completed',
          'endTime': FieldValue.serverTimestamp(),
          'completedBy': currentUser.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // ✅ 2. Create completed_jobs entry
        tx.set(completedRef, {
          ...data,
          'participants': parts,
          'finderId': finderId,
          'supporterId': supporterId,
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'completedBy': currentUser.uid,
          'originalRequestId': _s(data['originalRequestId'], jobId),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // ✅ 3. Update hire_requests
        tx.set(requestRef, {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'completedBy': currentUser.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // ✅ 4. Update Supporter (Employer) stats
        final supporterStatsRef = _firestore.collection('user_stats').doc(supporterId);
        tx.set(supporterStatsRef, {
          'hiresCompleted': FieldValue.increment(1),
          'hiresOngoing': FieldValue.increment(-1), // ✅ Decrement!
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // ✅ 5. Update Finder (Worker) stats
        final finderStatsRef = _firestore.collection('user_stats').doc(finderId);
        tx.set(finderStatsRef, {
          'jobsCompleted': FieldValue.increment(1),
          'jobsOngoing': FieldValue.increment(-1), // ✅ Decrement!
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // ✅ 6. Send notification to Supporter
      if (supporterId.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'toUserId': supporterId,
          'fromUserId': finderId,
          'type': 'job_completed',
          'title': 'Job Completed! 🎉',
          'body': 'The worker has marked your job as completed.',
          'jobId': jobId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // ✅ 7. Update Achievements (WORKER ONLY)
      // Daily
      await AchievementService.incrementProgress('daily_complete_job');

      // Weekly
      await AchievementService.incrementProgress('weekly_complete_jobs');

      // Long-Term
      await AchievementService.incrementProgress('lt_jobs_s1');
      await AchievementService.incrementProgress('lt_jobs_s2');
      await AchievementService.incrementProgress('lt_jobs_s3');

      // Sync Weekly Chest
      await AchievementService.syncWeeklyChestFromServer();

      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Job completed! Quests updated."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('Complete job error: $e');
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to complete: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}