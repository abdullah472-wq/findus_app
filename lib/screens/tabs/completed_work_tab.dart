import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/achievement/achievement_service.dart'; // Achievement

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Scaffold বা FloatingScaffold সরিয়ে দেওয়া হয়েছে
    // কারণ এটি ট্যাবের ভেতরে রেন্ডার হচ্ছে

    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "Please login to see completed jobs",
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
      );
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
            return _buildErrorState(snapshot.error.toString(), isDark);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandMain),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 100),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final job = doc.data();
              return _buildCompletedJobCard(
                context,
                jobId: doc.id,
                job: job,
                currentUid: uid,
                isDark: isDark,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    final isIndex = error.contains('FAILED_PRECONDITION') || error.toLowerCase().contains('index');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIndex ? Icons.build_rounded : Icons.error_outline,
              size: 70,
              color: isIndex ? Colors.orange : Colors.redAccent,
            ),
            const SizedBox(height: 20),
            Text(
              isIndex ? "Firestore Index Required!" : "Something went wrong",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isIndex
                  ? "Check debug console for the link to create index."
                  : error,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedJobCard(
      BuildContext context, {
        required String jobId,
        required Map<String, dynamic> job,
        required String currentUid,
        required bool isDark,
      }) {
    final receiverId = _s(job['receiverId']).trim();
    final workerId = _s(job['workerId']).trim();
    final otherUserId = (currentUid == workerId) ? receiverId : workerId;

    final completedAt = _asDate(job['completedAt']);
    final timeAgo = _getTimeAgo(completedAt);

    final address = _s(job['location'], 'Location Hidden');
    final price = _s(job['price'] ?? job['offerPrice'], 'Negotiable');

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

        final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                rating: _asDouble(job['rating'], fallback: 0.0).toStringAsFixed(1),
                completed: _asInt(job['completedCount']).toString(),
                reviews: _asInt(job['reviewsCount']).toString(),
                price: price,
                time: timeAgo,
                isVerifiedWorker: job['isVerified'] == true,
                followersCount: _asInt(job['followersCount']),
                margin: EdgeInsets.zero,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                showActionButtons: false,
                showSaveButton: false,
                showShareButton: false,
                tagText: "COMPLETED",
                tagColor: Colors.green,
                tagIcon: Icons.check_circle,
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
                onChatTap: () => _connectAgain(context, otherUserId, name, role, imageUrl),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showReviewDialog(
                          context,
                          jobId: jobId,
                          targetId: otherUserId,
                          targetName: name,
                        ),
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: const Text("Review"),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
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

  // ✅ Review Dialog Update (Achievement Trigger)
  Future<void> _showReviewDialog(
      BuildContext context, {
        required String jobId,
        required String targetId,
        required String targetName,
      }) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null || targetId.isEmpty) return;

    final controller = TextEditingController();
    double rating = 5.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Rate $targetName", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
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
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: "Write your experience...",
                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandMain, foregroundColor: Colors.white),
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await _db.runTransaction((tx) async {
        final reviewRef = _db.collection('reviews').doc();
        tx.set(reviewRef, {
          'fromUserId': myUid,
          'targetUserId': targetId,
          'jobId': jobId,
          'rating': rating,
          'comment': controller.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update target stats
        final statsRef = _db.collection('user_stats').doc(targetId);
        final statsSnap = await tx.get(statsRef);
        final stats = statsSnap.data() ?? {};
        final int oldCount = _asInt(stats['reviewsCount']);
        final double oldAvg = _asDouble(stats['avgRating']);
        final int newCount = oldCount + 1;
        final double newAvg = ((oldAvg * oldCount) + rating) / newCount;

        tx.set(statsRef, {
          'reviewsCount': newCount,
          'avgRating': double.parse(newAvg.toStringAsFixed(2)),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // ✅ Update Achievement (Long Term Rating Chain - for Target User technically, but here we can only update local)
      // Note: Rating chain progress should ideally be updated for the TARGET user via Cloud Functions.
      // But we can trigger a notification or handle it when they login.

      if (context.mounted) _showToast(context, "Review submitted!");
    } catch (e) {
      if (context.mounted) _showToast(context, "Failed: $e", isError: true);
    }
  }

  Future<void> _connectAgain(BuildContext context, String otherId, String name, String role, String img) async {
    if (otherId.isEmpty) return;
    HapticFeedback.lightImpact();

    try {
      final convId = await FirestoreChatService.getOrCreateConversation(otherUserId: otherId);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(conversationId: convId, userName: name, userRole: role, userImage: img)),
      );
    } catch (e) {
      _showToast(context, "Connect failed: $e", isError: true);
    }
  }

  void _showToast(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green));
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No completed jobs yet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white60 : Colors.grey)),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    return "Just now";
  }
}