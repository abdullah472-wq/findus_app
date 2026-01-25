// lib/screens/tabs/completed_work_tab.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    await Future.delayed(const Duration(milliseconds: 500));
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
      color: AppColors.brandMain,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final err = snapshot.error.toString();
            final isIndex = err.contains('FAILED_PRECONDITION') || err.contains('index');
            return Center(child: Text(isIndex ? "Index required (check console)" : "Error: $err"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 100),
            physics: const BouncingScrollPhysics(),
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
    final receiverId = _s(job['receiverId']).trim();
    final workerId = _s(job['workerId']).trim();
    final otherUserId = (currentUid == workerId) ? receiverId : workerId;

    final completedAt = _asDate(job['completedAt']);
    final timeAgo = _getTimeAgo(completedAt);

    final address = _s(job['location'], 'Location Hidden');
    final price = _s(job['price'] ?? job['offerPrice'], 'Negotiable');

    // Denormalized fallback
    final String otherNameFromDoc = (currentUid == workerId) ? _s(job['receiverName']) : _s(job['workerName']);
    final String otherImageFromDoc = (currentUid == workerId) ? _s(job['receiverImage']) : _s(job['workerImage']);
    final String otherRoleFromDoc = (currentUid == workerId) ? _s(job['receiverRole']) : _s(job['workerRole']);

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: (otherNameFromDoc.isEmpty || otherImageFromDoc.isEmpty)
          ? _db.collection('users').doc(otherUserId).get()
          : Future.value(null),
      builder: (context, snap) {
        String name = otherNameFromDoc.isNotEmpty ? otherNameFromDoc : 'User';
        String role = otherRoleFromDoc.isNotEmpty ? otherRoleFromDoc : 'Member';
        String imageUrl = otherImageFromDoc;

        if (snap.data != null && snap.data!.exists) {
          final u = snap.data!.data() ?? {};
          name = _s(u['name'] ?? u['fullName'], name);
          role = _s(u['userRole'] ?? u['role'], role);
          imageUrl = _s(u['image'] ?? u['imageUrl'], imageUrl);
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
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
                rating: _asDouble(job['rating'], fallback: 4.8).toStringAsFixed(1),
                completed: _asInt(job['completedCount']).toString(),
                reviews: _asInt(job['reviewsCount']).toString(),
                price: price,
                time: timeAgo,
                isVerifiedWorker: job['isVerified'] == true,
                followersCount: _asInt(job['followersCount']),
                margin: EdgeInsets.zero,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),

                // ✅ প্রোফাইল ওপেন লজিক
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

                // ✅ চ্যাট ওপেন লজিক
                onChatTap: () => _connectAgain(context, otherUserId, name, role, imageUrl),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showReviewDialog(context, jobId: jobId, targetId: otherUserId, targetName: name),
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: const Text("Review"),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          foregroundColor: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _connectAgain(context, otherUserId, name, role, imageUrl),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text("Connect"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandMain,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
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

  Future<void> _connectAgain(BuildContext context, String otherId, String name, String role, String img) async {
    if (otherId.isEmpty) return; // ✅ সেফটি চেক

    HapticFeedback.lightImpact();
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final convId = await FirestoreChatService.getOrCreateConversation(otherUserId: otherId);
      if (!context.mounted) return;
      Navigator.pop(context);

      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
        conversationId: convId,
        userName: name,
        userRole: role,
        userImage: img,
      )));
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      _showToast(context, "Connect failed: $e", isError: true);
    }
  }

  Future<void> _showReviewDialog(BuildContext context, {required String jobId, required String targetId, required String targetName}) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null || targetId.isEmpty) return; // ✅ সেফটি চেক

    final controller = TextEditingController();
    double rating = 5.0;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Rate $targetName"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 32),
                  onPressed: () => setModalState(() => rating = i + 1.0),
                )),
              ),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Write your experience...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Submit")),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _db.collection('reviews').add({
          'fromUserId': myUid,
          'targetUserId': targetId,
          'jobId': jobId,
          'rating': rating,
          'comment': controller.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'isAnonymous': false, // ✅ স্ট্রিং 'false' নয়, বুলিয়ান
        });
        if (context.mounted) _showToast(context, "Review submitted!");
      } catch (e) {
        if (context.mounted) _showToast(context, "Failed: $e", isError: true);
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No completed jobs yet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
          const Text("Finished jobs will appear here.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
      ),
    );
  }

  void _showToast(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green));
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }
}