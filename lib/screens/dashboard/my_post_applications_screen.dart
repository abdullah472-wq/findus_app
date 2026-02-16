import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';
import 'package:findus_app/achievement/achievement_service.dart';

class MyPostApplicationsScreen extends StatelessWidget {
  final String postId;

  const MyPostApplicationsScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    if (uid == null) {
      return FloatingScaffold(
        title: "Applications",
        backgroundColor: bgColor,
        titleColor: textColor,
        iconColor: textColor,
        scrollable: false,
        bodyPadding: EdgeInsets.zero,
        body: const Center(child: Text("Please login again")),
      );
    }

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    final appsStream = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('postId', isEqualTo: postId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return FloatingScaffold(
      title: "APPLICATIONS",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: postRef.get(),
        builder: (context, postSnap) {
          if (!postSnap.hasData) return const Center(child: CircularProgressIndicator());
          if (!postSnap.data!.exists) return const Center(child: Text("Post not found"));

          final post = postSnap.data!.data() ?? {};
          final ownerId = (post['ownerId'] ?? '').toString();
          if (ownerId != uid) {
            return const Center(child: Text("Not allowed"));
          }

          final int slots = (post['slots'] is num) ? (post['slots'] as num).toInt() : 1;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: appsStream,
            builder: (context, snap) {
              if (snap.hasError) {
                final err = snap.error.toString();
                final needIndex = err.contains('FAILED_PRECONDITION') || err.toLowerCase().contains('index');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      needIndex ? "Index required (check console link)" : "Error: $err",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                );
              }
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snap.data!.docs;

              return Column(
                children: [
                  _HeaderBar(
                    title: (post['title'] ?? '').toString(),
                    address: (post['address'] ?? '').toString(),
                    slots: slots,
                    isDark: isDark,
                  ),
                  Expanded(
                    child: docs.isEmpty
                        ? Center(
                      child: Text(
                        "No pending applications",
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      physics: const BouncingScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        return _ApplicationCard(
                          doc: docs[i],
                          postId: postId,
                          postSlots: slots,
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final String title;
  final String address;
  final int slots;
  final bool isDark;

  const _HeaderBar({
    required this.title,
    required this.address,
    required this.slots,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = isDark ? Colors.white : Colors.black87;
    final s = isDark ? Colors.white60 : Colors.black54;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.isEmpty ? "Job Post" : title, style: TextStyle(color: t, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text(address.isEmpty ? "Address not set" : address, style: TextStyle(color: s, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.group, size: 16, color: AppColors.brandMain),
              const SizedBox(width: 6),
              Text("Slots: $slots", style: TextStyle(color: t, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Text("Pending only", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String postId;
  final int postSlots;
  final bool isDark;

  const _ApplicationCard({
    required this.doc,
    required this.postId,
    required this.postSlots,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    final applicantId = (data['senderId'] ?? '').toString();
    final applicantName = (data['senderName'] ?? 'User').toString();
    final applicantRole = (data['senderRole'] ?? '').toString();
    final applicantImage = (data['senderImage'] ?? '').toString();
    final offer = (data['offerPrice'] ?? 0).toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          UniversalWorkerCard(
            id: applicantId,
            name: applicantName,
            role: applicantRole,
            imageUrl: applicantImage,
            address: (data['postAddress'] ?? '').toString(),
            rating: (data['senderRating'] ?? 0).toString(),
            completed: "0",
            reviews: "0",
            price: "৳$offer",
            time: "PENDING",
            margin: EdgeInsets.zero,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            showActionButtons: false,
            showSaveButton: false,
            showShareButton: false,
            tagText: "PENDING",
            tagColor: Colors.orange,
            tagIcon: Icons.hourglass_top,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("REJECT"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveOneAndMaybeRejectRest(context),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("APPROVE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _iconBtn(
                  context,
                  Icons.chat_bubble_outline,
                      () => _openChat(context, applicantId, applicantName, applicantRole, applicantImage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.brandMain, size: 20),
      ),
    );
  }

  Future<void> _openChat(BuildContext context, String otherId, String name, String role, String img) async {
    if (otherId.isEmpty) return;
    try {
      final cid = await FirestoreChatService.getOrCreateConversation(otherUserId: otherId);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversationId: cid, userName: name, userRole: role, userImage: img),
        ),
      );
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Chat failed: $e")));
    }
  }

  Future<void> _reject(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject application?"),
        content: const Text("This request will be rejected."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Reject", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      final data = doc.data() as Map<String, dynamic>; // Applicant info

      await doc.reference.update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 🔔 NOTIFICATION: To Rejected Applicant
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUserId': data['senderId'],
        'fromUserId': uid,
        'type': 'application_rejected',
        'title': 'Application Status',
        'body': 'Your application was not selected for this job.',
        'postId': postId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  /// If slots > 1: just approve this one (no auto-reject here).
  Future<void> _approveOneAndMaybeRejectRest(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Approve Application?"),
        content: Text(
          postSlots == 1
              ? "Approving will auto-reject all other pending applications for this post."
              : "Approve this applicant? You can approve up to $postSlots applicants.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text(
              "Approve",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final db = FirebaseFirestore.instance;
    final postRef = db.collection('posts').doc(postId);
    final data = doc.data() as Map<String, dynamic>;

    try {
      await db.runTransaction((tx) async {
        final postSnap = await tx.get(postRef);
        if (!postSnap.exists) throw Exception("Post not found");

        final post = postSnap.data() as Map<String, dynamic>;
        final ownerId = (post['ownerId'] ?? '').toString();

        if (ownerId != uid) {
          throw Exception("Not authorized");
        }

        final int slots = (post['slots'] is num)
            ? (post['slots'] as num).toInt()
            : 1;

        final int approvedCount = (post['approvedCount'] is num)
            ? (post['approvedCount'] as num).toInt()
            : 0;

        if (approvedCount >= slots) {
          throw Exception("All slots are already filled");
        }

        // ✅ 1. Approve application
        tx.update(doc.reference, {
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
          'approvedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // ✅ 2. Update post
        final int newApproved = approvedCount + 1;
        final bool isFilled = newApproved >= slots;

        tx.set(postRef, {
          'approvedCount': newApproved,
          'status': isFilled ? 'filled' : 'open',
          'updatedAt': FieldValue.serverTimestamp(),
          if (slots == 1 || isFilled) 'autoRejectPending': true,
        }, SetOptions(merge: true));

        // ✅ 3. Create ongoing job
        final ongoingRef = db.collection('ongoing_jobs').doc(doc.id);

        tx.set(ongoingRef, {
          'participants': [uid, data['senderId']],

          // ✅ Consistent field names
          'supporterId': uid,              // Employer
          'finderId': data['senderId'],    // Worker

          'supporterName': post['ownerName'] ?? 'Employer',
          'supporterImage': post['ownerImage'] ?? '',
          'supporterRole': 'Supporter',

          'finderName': data['senderName'] ?? 'Worker',
          'finderImage': data['senderImage'] ?? '',
          'finderRole': data['senderRole'] ?? 'Finder',

          'jobTitle': post['title'] ?? 'Job',
          'description': post['description'] ?? '',
          'location': post['address'] ?? '',
          'price': data['offerPrice'] ?? data['price'] ?? '0',

          'status': 'ongoing',
          'startTime': FieldValue.serverTimestamp(),
          'originalRequestId': doc.id,
          'postId': postId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // ✅ 4. Update Supporter (Employer) Stats
        final supporterStatsRef = db.collection('user_stats').doc(uid);
        tx.set(supporterStatsRef, {
          'hiresCount': FieldValue.increment(1),
          'hiresOngoing': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // ✅ 5. Update Finder (Worker) Stats
        final finderStatsRef = db.collection('user_stats').doc(data['senderId']);
        tx.set(finderStatsRef, {
          'jobsAccepted': FieldValue.increment(1),
          'jobsOngoing': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // ✅ 6. Send notification to approved applicant
      await db.collection('notifications').add({
        'toUserId': data['senderId'],
        'fromUserId': uid,
        'type': 'application_approved',
        'title': 'Application Accepted! 🎉',
        'body': 'Your application has been approved. Check Work in Progress tab.',
        'postId': postId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ 7. Update Employer Achievements
      await AchievementService.incrementProgress('daily_hire');
      await AchievementService.incrementProgress('weekly_hire');
      await AchievementService.incrementProgress('lt_hire_s1');
      await AchievementService.incrementProgress('lt_hire_s2');
      await AchievementService.incrementProgress('lt_hire_s3');
      await AchievementService.syncWeeklyChestFromServer();

      // ✅ 8. Handle auto-rejects (if slots filled)
      final postSnap2 = await db.collection('posts').doc(postId).get();
      final post2 = postSnap2.data() ?? {};
      final bool autoReject = (post2['autoRejectPending'] ?? false) == true;

      if (autoReject) {
        final pendingApps = await db
            .collection('hire_requests')
            .where('postId', isEqualTo: postId)
            .where('status', isEqualTo: 'pending')
            .get();

        final batch = db.batch();

        for (final d in pendingApps.docs) {
          if (d.id == doc.id) continue; // Skip approved one

          // Reject application
          batch.update(d.reference, {
            'status': 'rejected',
            'rejectedAt': FieldValue.serverTimestamp(),
            'rejectedBy': 'system',
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Send notification
          final rejectedData = d.data();
          final notifRef = db.collection('notifications').doc();

          batch.set(notifRef, {
            'toUserId': rejectedData['senderId'],
            'fromUserId': uid,
            'type': 'application_rejected',
            'title': 'Application Update',
            'body': 'The job position has been filled. Better luck next time!',
            'postId': postId,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // Clear auto-reject flag
        batch.set(
          db.collection('posts').doc(postId),
          {'autoRejectPending': false},
          SetOptions(merge: true),
        );

        await batch.commit();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Application approved! Job started."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Approve error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to approve: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}