import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/constants/app_colors.dart';
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

  // ✅ সেইফ কনভার্সন ফাংশন
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
          // ইনডেক্সিং এরর হ্যান্ডলিং
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
          return Center(child: Text("Something went wrong"));
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
    final receiverId = _s(data['receiverId']).trim();
    final workerId = _s(data['workerId']).trim();
    final participants = (data['participants'] is List) ? List.from(data['participants']) : <dynamic>[];

    final otherUserId = (currentUid == workerId) ? receiverId : workerId;
    final bool canComplete = currentUid == receiverId;

    // ডিফল্ট ভ্যালু হ্যান্ডলিং
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

        // যদি ইউজারের আপডেট করা ডাটা পাওয়া যায়
        if (snap.data != null && snap.data!.exists) {
          final u = snap.data!.data() ?? {};
          name = _s(u['name'], name);
          role = _s(u['userRole'], role);
          imageUrl = _s(u['image'], imageUrl); // 'image' or 'imageUrl'
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
                imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://i.pravatar.cc/150', // ডিফল্ট ইমেজ
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
                        builder: (_) => UnifiedProfileScreen(
                          uid: otherUserId,
                          isOwner: false,
                          showBack: true,
                        ),
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
                    jobData: data,
                  )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canComplete ? AppColors.brandMain : Colors.grey.shade400,
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
        required String receiverId,
        required String workerId,
        required List participants,
        required Map<String, dynamic> jobData,
      }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (currentUser.uid != receiverId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Only Finder can complete this job.")),
      );
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
      final requestRef = _firestore.collection('hire_requests').doc(jobId); // if you used same id

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

        final List parts = (data['participants'] is List) ? List.from(data['participants']) : participants;
        if (parts.isEmpty) {
          // fallback
          parts.addAll([receiverId, workerId]);
        }

        // 1) update ongoing job -> completed (so it disappears from this tab)
        tx.update(ongoingRef, {
          'status': 'completed',
          'endTime': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2) create completed history for BOTH participants
        tx.set(completedRef, {
          'participants': parts,
          'receiverId': receiverId,
          'workerId': workerId,
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'completedBy': currentUser.uid,
          'originalRequestId': _s(data['originalRequestId'], jobId),

          // optional fields for UI
          'price': data['price'] ?? data['offerPrice'],
          'location': data['location'],
          'workerName': data['workerName'],
          'workerImage': data['workerImage'],
          'receiverName': data['receiverName'],
          'receiverImage': data['receiverImage'],
        }, SetOptions(merge: true));

        // 3) optional: hire_requests status completed (if you keep same id)
        tx.update(requestRef, {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // 4) notify supporter
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

      if (!context.mounted) return;
      Navigator.pop(context); // close loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Job marked as completed!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}