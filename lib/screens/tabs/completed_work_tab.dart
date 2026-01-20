import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';

class CompletedWorkTab extends StatefulWidget {
  const CompletedWorkTab({super.key});

  @override
  State<CompletedWorkTab> createState() => _CompletedWorkTabState();
}

class _CompletedWorkTabState extends State<CompletedWorkTab> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? fallback;
  }

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  String _s(dynamic v, [String fallback = '']) => (v ?? fallback).toString();

  DateTime _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
  }

  Future<void> _refresh() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("Please login to see completed jobs."));
    }

    final uid = currentUser.uid;

    final stream = _db
        .collection('completed_jobs')
        .where('participants', arrayContains: uid)
        .orderBy('completedAt', descending: true)
        .snapshots();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final err = snapshot.error.toString();
            final isIndex = err.contains('FAILED_PRECONDITION') || err.contains('index');
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    isIndex
                        ? "Firestore index required.\nFirestore Console → Indexes এ গিয়ে index create করুন.\n\n$err"
                        : "Something went wrong.\n\n$err",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.work_outline, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("No completed jobs yet", style: TextStyle(fontSize: 18, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text("Complete jobs from 'Work in Progress' tab", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final job = doc.data();
              return _buildCompletedJobCard(context, jobId: doc.id, job: job, currentUid: uid);
            },
          );
        },
      ),
    );
  }

  Widget _buildCompletedJobCard(
      BuildContext context, {
        required String jobId,
        required Map<String, dynamic> job,
        required String currentUid,
      }) {
    final receiverId = _s(job['receiverId']).trim(); // finder
    final workerId = _s(job['workerId']).trim();     // supporter

    // ✅ other person based on who is viewing
    final otherUserId = (currentUid == workerId) ? receiverId : workerId;

    final completedAt = _asDate(job['completedAt']);
    final timeAgo = _getTimeAgo(completedAt);

    // job common fields
    final address = _s(job['location'], 'Not provided');
    final price = _s(job['price'], _s(job['offerPrice'], 'Negotiable'));

    // Try denormalized fields first:
    final String otherNameFromDoc = (currentUid == workerId)
        ? _s(job['receiverName'])
        : _s(job['workerName']);

    final String otherImageFromDoc = (currentUid == workerId)
        ? _s(job['receiverImage'])
        : _s(job['workerImage']);

    final String otherRoleFromDoc = (currentUid == workerId)
        ? _s(job['receiverRole'])
        : _s(job['workerRole']);

    final needUserFetch = otherUserId.isNotEmpty &&
        (otherNameFromDoc.isEmpty || otherRoleFromDoc.isEmpty || otherImageFromDoc.isEmpty);

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: needUserFetch ? _db.collection('users').doc(otherUserId).get() : Future.value(null),
      builder: (context, snap) {
        String name = otherNameFromDoc.isNotEmpty ? otherNameFromDoc : 'Unknown';
        String role = otherRoleFromDoc.isNotEmpty ? otherRoleFromDoc : 'User';
        String imageUrl = otherImageFromDoc;

        // extra stats (optional)
        int completedCount = _asInt(job['completedCount']);
        int reviewsCount = _asInt(job['reviewsCount']);
        int followersCount = _asInt(job['followersCount']);
        double ratingVal = _asDouble(job['rating']);

        if (snap.data != null && snap.data!.exists) {
          final u = snap.data!.data() ?? {};
          name = (name == 'Unknown') ? _s(u['name'], _s(u['fullName'], 'Unknown')) : name;
          role = (role == 'User') ? _s(u['userRole'], _s(u['role'], 'User')) : role;
          imageUrl = imageUrl.isEmpty ? _s(u['imageUrl'], _s(u['photoUrl'], '')) : imageUrl;

          // If job doc doesn't have these, take from user doc
          completedCount = completedCount == 0 ? _asInt(u['completedCount']) : completedCount;
          reviewsCount = reviewsCount == 0 ? _asInt(u['reviewsCount']) : reviewsCount;
          followersCount = followersCount == 0 ? _asInt(u['followersCount']) : followersCount;
          ratingVal = ratingVal == 0 ? _asDouble(u['rating']) : ratingVal;
        }

        final ratingStr = ratingVal.toStringAsFixed(1);
        final isVerified = (job['isVerified'] == true) || (completedCount >= 50);
        final isTopRated = ratingVal >= 4.7;

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
                imageUrl: imageUrl,
                address: address,
                rating: ratingStr,
                completed: completedCount.toString(),
                reviews: reviewsCount.toString(),
                price: price,
                time: timeAgo,
                isVerifiedWorker: isVerified,
                isTopRated: isTopRated,
                followersCount: followersCount,
                margin: EdgeInsets.zero,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                onTap: () {
                  if (otherUserId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User id missing")),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UnifiedProfileScreen(uid: otherUserId, isOwner: false),
                    ),
                  );
                },
                onChatTap: () => _connectAgain(context, otherUserId, name, role, imageUrl),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: otherUserId.isEmpty
                            ? null
                            : () => _showReviewDialog(
                          context,
                          jobId: jobId,
                          revieweeId: otherUserId,
                          revieweeName: name,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          foregroundColor: Colors.grey[800],
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        icon: const Icon(Icons.rate_review_outlined, size: 20),
                        label: const Text("Review", style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: otherUserId.isEmpty
                            ? null
                            : () => _connectAgain(context, otherUserId, name, role, imageUrl),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandMain,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.repeat_outlined, size: 20),
                        label: const Text("Connect Again", style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _connectAgain(
      BuildContext context,
      String otherUserId,
      String name,
      String role,
      String imageUrl,
      ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not connect: $e")),
        );
      }
    }
  }

  Future<void> _showReviewDialog(
      BuildContext context, {
        required String jobId,
        required String revieweeId,
        required String revieweeName,
      }) async {
    final reviewerId = _auth.currentUser?.uid;
    if (reviewerId == null) return;

    final reviewController = TextEditingController();
    double selectedRating = 5.0;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Leave a Review"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    revieweeName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  const Text("Rating:"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setState(() => selectedRating = index + 1.0),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  const Text("Your Review:"),
                  TextField(
                    controller: reviewController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: "How was your experience?",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandMain),
                child: const Text("Submit Review"),
              ),
            ],
          );
        },
      ),
    ) ??
        false;

    if (submitted != true) {
      reviewController.dispose();
      return;
    }

    try {
      await _db.collection('reviews').add({
        'reviewerId': reviewerId,
        'revieweeId': revieweeId,
        'jobId': jobId,
        'rating': selectedRating,
        'comment': reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review submitted successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit review: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      reviewController.dispose();
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}