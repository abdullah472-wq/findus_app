import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';

class SupporterPendingRequestsScreen extends StatelessWidget {
  final String postId;
  final String postTitle;

  const SupporterPendingRequestsScreen({
    super.key,
    required this.postId,
    required this.postTitle,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    if (uid == null || uid.isEmpty) {
      return FloatingScaffold(
        title: 'Pending Requests',
        backgroundColor: bgColor,
        titleColor: textColor,
        iconColor: textColor,
        scrollable: false,
        bodyPadding: EdgeInsets.zero,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Please login to view requests',
                style: TextStyle(color: textColor),
              ),
            ],
          ),
        ),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('senderId', isEqualTo: uid)
        .where('postId', isEqualTo: postId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return FloatingScaffold(
      title: postTitle.toUpperCase(),
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            final err = snap.error.toString();
            final needIndex = err.contains('FAILED_PRECONDITION') ||
                err.toLowerCase().contains('index');

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      needIndex ? Icons.build_rounded : Icons.error_outline,
                      size: 60,
                      color: needIndex ? Colors.orange : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      needIndex
                          ? "Firestore index required"
                          : "Something went wrong",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      needIndex
                          ? "Check console for index creation link"
                          : err,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brandMain),
            );
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No pending requests",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Workers haven't responded yet",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white38 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              return _RequestCard(doc: docs[i], isDark: isDark);
            },
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool isDark;

  const _RequestCard({required this.doc, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    // ✅ সঠিক field names
    final finderId = (data['receiverId'] ?? '').toString();
    final finderName = (data['receiverName'] ?? 'Worker').toString();
    final finderImage = (data['receiverImage'] ?? '').toString();
    final finderRole = (data['receiverRole'] ?? 'Finder').toString();

    final location = (data['location'] ?? 'Not set').toString();
    final price = data['price'] ?? data['offerPrice'] ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ Worker Stats সহ
          FutureBuilder<DocumentSnapshot>(
            future: finderId.isNotEmpty
                ? FirebaseFirestore.instance
                .collection('user_stats')
                .doc(finderId)
                .get()
                : null,
            builder: (context, statSnap) {
              final stats = statSnap.data?.data() as Map<String, dynamic>? ?? {};

              return UniversalWorkerCard(
                id: finderId,
                name: finderName,
                role: finderRole,
                imageUrl: finderImage,
                address: location,
                rating: (stats['avgRating'] ?? 0.0).toStringAsFixed(1),
                completed: (stats['jobsCompleted'] ?? 0).toString(),
                reviews: (stats['totalReviews'] ?? 0).toString(),
                price: "৳$price",
                time: "⏳ PENDING",
                margin: EdgeInsets.zero,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                showActionButtons: false,
                showSaveButton: false,
                showShareButton: false,
                onTap: null,
              );
            },
          ),

          // ✅ Action Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _withdrawRequest(context, doc.reference),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("WITHDRAW"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: finderId.isEmpty
                        ? null
                        : () => _openChat(
                      context,
                      finderId,
                      finderName,
                      finderImage,
                      finderRole,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text("CHAT"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandMain,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
  }

  Future<void> _openChat(
      BuildContext context,
      String otherUserId,
      String otherName,
      String otherImage,
      String otherRole,
      ) async {
    try {
      final convId = await FirestoreChatService.getOrCreateConversation(
        otherUserId: otherUserId,
      );

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convId,
            userName: otherName,
            userRole: otherRole,
            userImage: otherImage,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Chat error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to open chat")),
        );
      }
    }
  }

  Future<void> _withdrawRequest(
      BuildContext context,
      DocumentReference ref,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Withdraw Request?"),
        content: const Text(
          "This will cancel your pending job request.\nYou can send a new one later.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text(
              "Withdraw",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception("Request not found");

        final data = snap.data() as Map<String, dynamic>;
        final receiverId = data['receiverId']; // Worker ID
        final senderId = FirebaseAuth.instance.currentUser?.uid;

        // ✅ 1. Update request status
        tx.update(ref, {
          'status': 'withdrawn',
          'withdrawnAt': FieldValue.serverTimestamp(),
          'withdrawnBy': senderId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // ✅ 2. Send notification to Worker
        if (receiverId != null && senderId != null) {
          final notifRef = FirebaseFirestore.instance
              .collection('notifications')
              .doc();

          tx.set(notifRef, {
            'toUserId': receiverId,
            'fromUserId': senderId,
            'type': 'hire_request_withdrawn',
            'title': 'Request Withdrawn',
            'body': 'The employer has withdrawn their job request.',
            'requestId': ref.id,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Request withdrawn successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Withdraw error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to withdraw: ${e.toString()}")),
        );
      }
    }
  }
}