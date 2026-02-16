import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/achievement/achievement_service.dart';

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
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.login),
              label: const Text('Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                foregroundColor: Colors.white,
              ),
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.brandMain,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 100),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
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
    final isIndex = error.contains('FAILED_PRECONDITION') ||
        error.toLowerCase().contains('index');

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
    // ✅ সঠিক ফিল্ড নাম
    final finderId = _s(job['finderId']).trim();       // Worker
    final supporterId = _s(job['supporterId']).trim(); // Employer

    final otherUserId = (currentUid == supporterId) ? finderId : supporterId;

    final completedAt = _asDate(job['completedAt']);
    final timeAgo = _getTimeAgo(completedAt);

    final address = _s(job['location'], 'Location Hidden');
    final price = _s(job['price'] ?? job['offerPrice'], 'Negotiable');
    final jobTitle = _s(job['jobTitle'], 'Job');

    // ✅ সঠিক নাম ফিল্ড
    final String otherNameFromDoc = (currentUid == supporterId)
        ? _s(job['finderName'])
        : _s(job['supporterName']);

    final String otherImageFromDoc = (currentUid == supporterId)
        ? _s(job['finderImage'])
        : _s(job['supporterImage']);

    final String otherRoleFromDoc = (currentUid == supporterId)
        ? _s(job['finderRole'])
        : _s(job['supporterRole']);

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
                rating: _asDouble(job['rating'], fallback: 0.0)
                    .toStringAsFixed(1),
                completed: _asInt(job['completedCount']).toString(),
                reviews: _asInt(job['reviewsCount']).toString(),
                price: price,
                time: timeAgo,
                isVerifiedWorker: job['isVerified'] == true,
                followersCount: _asInt(job['followersCount']),
                margin: EdgeInsets.zero,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
                showActionButtons: false,
                showSaveButton: false,
                showShareButton: false,
                tagText: "✅ COMPLETED",
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
                onChatTap: () =>
                    _connectAgain(context, otherUserId, name, role, imageUrl),
              ),

              // ✅ Job Info Section
              if (jobTitle.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (job['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _s(job['description']),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

              // ✅ Action Buttons
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor:
                          isDark ? Colors.white70 : Colors.grey.shade700,
                          side: BorderSide(
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _connectAgain(
                            context, otherUserId, name, role, imageUrl),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text("Connect"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandMain,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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

  // ✅ Review Dialog Update (Achievement Trigger Added!)
  Future<void> _showReviewDialog(
      BuildContext context, {
        required String jobId,
        required String targetId,
        required String targetName,
      }) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null || targetId.isEmpty) return;

    // ✅ Check if already reviewed
    final existingReview = await _db
        .collection('reviews')
        .where('fromUserId', isEqualTo: myUid)
        .where('jobId', isEqualTo: jobId)
        .limit(1)
        .get();

    if (existingReview.docs.isNotEmpty) {
      _showToast(context, "You've already reviewed this job!", isError: true);
      return;
    }

    final controller = TextEditingController();
    double rating = 5.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor:
          isDark ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Rate $targetName",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                      (i) => IconButton(
                    icon: Icon(
                      i < rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setModalState(() => rating = i + 1.0),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                maxLength: 200,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: "Write your experience...",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                foregroundColor: Colors.white,
              ),
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await _db.runTransaction((tx) async {
        // 1. Create review
        final reviewRef = _db.collection('reviews').doc();
        tx.set(reviewRef, {
          'fromUserId': myUid,
          'targetUserId': targetId,
          'jobId': jobId,
          'rating': rating,
          'comment': controller.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 2. Update target user stats
        final statsRef = _db.collection('user_stats').doc(targetId);
        final statsSnap = await tx.get(statsRef);
        final stats = statsSnap.data() ?? {};

        final int oldCount = _asInt(stats['reviewsCount']);
        final double oldAvg = _asDouble(stats['avgRating']);
        final int newCount = oldCount + 1;
        final double newAvg = ((oldAvg * oldCount) + rating) / newCount;

        tx.set(
          statsRef,
          {
            'reviewsCount': newCount,
            'avgRating': double.parse(newAvg.toStringAsFixed(2)),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      // ✅ 3. Update Achievements (REVIEWER - যে review দিচ্ছে)
      // Daily
      await AchievementService.incrementProgress('daily_give_review');

      // Weekly
      await AchievementService.incrementProgress('weekly_give_reviews');

      // Long-Term
      await AchievementService.incrementProgress('lt_reviews_s1');
      await AchievementService.incrementProgress('lt_reviews_s2');
      await AchievementService.incrementProgress('lt_reviews_s3');

      // Sync Weekly Chest
      await AchievementService.syncWeeklyChestFromServer();

      if (context.mounted) {
        _showToast(context, "✅ Review submitted! Quest updated.");
      }
    } catch (e) {
      debugPrint('Review error: $e');
      if (context.mounted) {
        _showToast(context, "Failed to submit review", isError: true);
      }
    }
  }

  Future<void> _connectAgain(
      BuildContext context,
      String otherId,
      String name,
      String role,
      String img,
      ) async {
    if (otherId.isEmpty) return;
    HapticFeedback.lightImpact();

    try {
      final convId = await FirestoreChatService.getOrCreateConversation(
        otherUserId: otherId,
      );

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convId,
            userName: name,
            userRole: role,
            userImage: img,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Connect error: $e');
      if (context.mounted) {
        _showToast(context, "Connect failed", isError: true);
      }
    }
  }

  void _showToast(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 80,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No completed jobs yet",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white60 : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your finished work will appear here",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // ✅ Navigate to explore or home
              DefaultTabController.of(context)?.animateTo(0); // Home tab
            },
            icon: const Icon(Icons.explore),
            label: const Text('Find Work'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return "${(diff.inDays / 30).floor()}mo ago";
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }
}