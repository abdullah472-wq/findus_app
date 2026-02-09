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
                child: Text(
                  "Firestore index required.\nPlease check console for link.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade300),
                ),
              ),
            );
          }
          return const Center(child: Text("Something went wrong"));
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
    final receiverId = _s(data['receiverId']).trim(); // finder
    final workerId = _s(data['workerId']).trim(); // supporter (naming legacy)
    final participants = (data['participants'] is List) ? List.from(data['participants']) : <dynamic>[];

    final otherUserId = (currentUid == workerId) ? receiverId : workerId;
    final bool canComplete = currentUid == receiverId;

    final String otherNameFromDoc = (currentUid == workerId) ? _s(data['receiverName']) : _s(data['workerName']);
    final String otherImageFromDoc = (currentUid == workerId) ? _s(data['receiverImage']) : _s(data['workerImage']);
    final String otherRoleFromDoc = (currentUid == workerId) ? _s(data['receiverRole']) : _s(data['workerRole']);

    final String location = _s(data['location'], 'Location not available');
    final String price = _s(data['price'], _s(data['offerPrice'], 'Negotiable'));

    final double ratingVal = _asDouble(data['rating']);
    final String ratingStr = ratingVal == 0 ? '0.0' : ratingVal.toStringAsFixed(1);

    final int completedCount = _asInt(data['completedCount']);
    final bool isVerified = (data['isVerified'] == true) || (completedCount >= 50);
    final bool isTopRated = ratingVal >= 4.7;

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
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
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
                time: "ONGOING",
                isVerifiedWorker: isVerified,
                isTopRated: isTopRated,
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
                        builder: (_) => UnifiedProfileScreen(uid: otherUserId, isOwner: false, showBack: true),
                      ),
                    );
                  }
                },
                onChatTap: () async {
                  if (otherUserId.isEmpty) return;

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final convId = await FirestoreChatService.getOrCreateConversation(otherUserId: otherUserId);
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
                  } catch (_) {
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ElevatedButton(
                  onPressed: canComplete
                      ? () => _markJobAsCompleted(
                    context,
                    jobId: docId,
                    receiverId: receiverId,
                    workerId: workerId,
                    participants: participants,
                  )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canComplete ? AppColors.brandMain : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        canComplete ? "Mark as Completed" : "Waiting for Finder to Complete",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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

  Future<void> _markJobAsCompleted(
      BuildContext context, {
        required String jobId,
        required String receiverId, // Finder (Worker)
        required String workerId,   // Supporter (Employer)
        required List participants,
      }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (currentUser.uid != receiverId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Only Finder can complete this job.")));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Complete Job"),
        content: const Text("Are you sure you want to mark this job as completed?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Complete", style: TextStyle(color: AppColors.brandMain)),
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

        if (_s(data['receiverId']) != currentUser.uid) {
          throw Exception('Not allowed');
        }
        if (status != 'ongoing') {
          throw Exception('Job is not ongoing');
        }

        final List parts = (data['participants'] is List) ? List.from(data['participants']) : List.from(participants);
        if (parts.isEmpty) {
          parts.addAll([receiverId, workerId]);
        }

        // 1) Update ongoing -> completed
        tx.update(ongoingRef, {
          'status': 'completed',
          'endTime': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2) Create completed history
        tx.set(
          completedRef,
          {
            'participants': parts,
            'receiverId': receiverId,
            'workerId': workerId,
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
            'completedBy': currentUser.uid,
            'originalRequestId': _s(data['originalRequestId'], jobId),
            'updatedAt': FieldValue.serverTimestamp(),
            'price': data['price'] ?? data['offerPrice'],
            'offerPrice': data['offerPrice'],
            'location': data['location'],
            'workerName': data['workerName'],
            'workerImage': data['workerImage'],
            'receiverName': data['receiverName'],
            'receiverImage': data['receiverImage'],
            'workerRole': data['workerRole'],
            'receiverRole': data['receiverRole'],
          },
          SetOptions(merge: true),
        );

        // 3) Update hire_requests status
        tx.set(
          requestRef,
          {
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // 4) Update user_stats
        final supporterStatsRef = _firestore.collection('user_stats').doc(workerId);
        final finderStatsRef = _firestore.collection('user_stats').doc(receiverId);

        tx.set(
          supporterStatsRef,
          {
            'hiresCompleted': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        tx.set(
          finderStatsRef,
          {
            'jobsCompleted': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      // 5) Notify supporter
      if (workerId.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'toUserId': workerId,
          'fromUserId': receiverId,
          'type': 'job_completed',
          'title': 'Job completed',
          'body': 'Finder marked the job as completed.',
          'jobId': jobId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // ==================================================
      // ✅ ACHIEVEMENT & QUEST UPDATES
      // ==================================================

      // 🟢 1. WORKER (Finder) - Job Completion Chain
      // Daily
      await AchievementService.incrementProgress('daily_complete_job');
      // Weekly
      await AchievementService.incrementProgress('weekly_complete_jobs');
      // Long-Term
      await AchievementService.incrementProgress('lt_jobs_s1');
      await AchievementService.incrementProgress('lt_jobs_s2');
      await AchievementService.incrementProgress('lt_jobs_s3');


      // 🔵 2. EMPLOYER (Supporter) - Hiring Chain Update
      // যেহেতু হায়ারটি সাকসেসফুল হয়েছে, তাই এমপ্লয়ারের হায়ার চেইনেও প্রগ্রেস যোগ হবে
      // (যদিও সে এই মুহূর্তে অনলাইনে নেই, সার্ভারে তার প্রগ্রেস সেভ হবে)
      /*
        নোট: AchievementService ডিফল্টভাবে কারেন্ট ইউজারের জন্য কাজ করে।
        অন্য ইউজারের (Employer) প্রগ্রেস বাড়াতে হলে আমাদের সার্ভিসে অন্য ইউজারের ID সাপোর্টেড থাকতে হবে।
        যদি আপনার সিস্টেমে সার্ভার সাইড (Cloud Functions) থাকে তবে সেখানে করা ভালো।
        তবে ক্লায়েন্ট সাইড থেকে করতে চাইলে আমাদের AchievementService এ অন্য ইউজারের জন্য আপডেট করার মেথড লাগবে।

        আপাতত Worker (Current User) এর প্রগ্রেস আপডেট করা হলো। Employer এর আপডেট
        সাধারণত সে যখন 'Complete' নোটিফিকেশন পেয়ে অ্যাপ ওপেন করবে, তখন সিঙ্ক হতে পারে।
      */

      // Sync Weekly Chest
      await AchievementService.syncWeeklyChestFromServer();


      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Job completed! Quests updated."), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}