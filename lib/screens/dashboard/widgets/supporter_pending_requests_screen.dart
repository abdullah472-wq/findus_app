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
        body: Center(child: Text('Please login again', style: TextStyle(color: textColor))),
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
      title: 'PENDING • $postTitle',
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
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brandMain));
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No pending requests for this post",
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
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

    final finderId = (data['receiverId'] ?? '').toString();
    final finderName = (data['receiverName'] ?? data['workerName'] ?? 'Finder').toString(); // fallback
    final finderImage = (data['receiverImage'] ?? data['workerImage'] ?? '').toString();

    // NOTE: hire_requests currently stores sender info clearly; receiver info maybe not denormalized.
    // So show the sender card? Actually supporter is sender. We want to show receiver (finder).
    // If receiverName/receiverImage not present, you can fetch users doc later. For now fallback.

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          UniversalWorkerCard(
            id: finderId,
            name: finderName,
            role: "Finder",
            imageUrl: finderImage,
            address: (data['postLocation'] ?? data['location'] ?? 'Not set').toString(),
            rating: (data['rating'] ?? 0).toString(),
            completed: "0",
            reviews: "0",
            price: "৳${(data['offerPrice'] ?? 0)}",
            time: "PENDING",
            margin: EdgeInsets.zero,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            showActionButtons: false,
            showSaveButton: false,
            showShareButton: false,
            onTap: null,
          ),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: finderId.isEmpty ? null : () => _openChat(context, finderId, finderName, finderImage),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text("CHAT"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandMain,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Future<void> _openChat(BuildContext context, String otherUserId, String otherName, String otherImage) async {
    try {
      final convId = await FirestoreChatService.getOrCreateConversation(otherUserId: otherUserId);
      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convId,
            userName: otherName,
            userRole: "Finder",
            userImage: otherImage,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Chat failed: $e")));
      }
    }
  }

  Future<void> _withdrawRequest(BuildContext context, DocumentReference ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Withdraw Request?"),
        content: const Text("This will remove your pending request."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Withdraw", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception("Request not found");

        final data = snap.data() as Map<String, dynamic>;
        final receiverId = data['receiverId']; // Worker ID

        // 1. Update status
        tx.update(ref, {
          'status': 'withdrawn',
          'withdrawnAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 🔔 NOTIFICATION: To Worker (Receiver)
        if (receiverId != null) {
          final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
          tx.set(notifRef, {
            'toUserId': receiverId,
            'fromUserId': FirebaseAuth.instance.currentUser?.uid,
            'type': 'hire_request_withdrawn',
            'title': 'Job Request Withdrawn',
            'body': 'The employer has withdrawn their job request.',
            'requestId': ref.id,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request withdrawn")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
      }
    }
  }
}