import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';

import '../utils/dashboard_constants.dart';

class PendingJobsScreen extends StatelessWidget {
  final String? userId; // optional (but we will prefer auth uid)

  const PendingJobsScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    // ✅ For security + rules consistency, always prefer current auth uid
    final String? authUid = FirebaseAuth.instance.currentUser?.uid;
    final String? uid = authUid ?? userId;

    if (uid == null || uid.isEmpty) {
      return const FloatingScaffold(
        title: 'Pending Requests',
        backgroundColor: AppColors.brandLight,
        titleColor: AppColors.brandDark,
        iconColor: AppColors.brandDark,
        scrollable: false,
        bodyPadding: EdgeInsets.zero,
        body: Center(child: Text('Please login again')),
      );
    }

    final pendingStream = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: DashboardConstants.pendingStatus)
    // .orderBy('createdAt', descending: true) // add if you have createdAt (may need index)
        .snapshots();

    return FloatingScaffold(
      title: 'Pending Requests',
      backgroundColor: AppColors.brandLight,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: pendingStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorBox(message: 'Error: ${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No pending requests',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _buildRequestItem(context, docs[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestItem(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data();

    return Column(
      children: [
        UniversalWorkerCard(
          id: (data['senderId'] ?? '').toString(),
          name: (data['senderName'] ?? 'Unknown').toString(),
          role: (data['senderRole'] ?? 'User').toString(),
          imageUrl: (data['senderImage'] ?? '').toString(),
          address: (data['location'] ?? 'Not set').toString(),
          rating: (data['rating'] ?? 0).toString(),
          completed: "0",
          reviews: "0",
          price: (data['price'] ?? data['offerPrice'] ?? '').toString(),
          time: "WAITING FOR APPROVAL",
          onChatTap: () => _openChat(context, data),
        ),
        const SizedBox(height: 12),
        _buildActionButtons(context, doc),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _rejectRequest(context, doc),
              icon: const Icon(Icons.close, size: 18),
              label: const Text("REJECT"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _approveRequest(context, doc),
              icon: const Icon(Icons.check, size: 18),
              label: const Text("APPROVE"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(BuildContext context, Map<String, dynamic> data) async {
    final otherUserId = data['senderId']?.toString();
    if (otherUserId == null || otherUserId.isEmpty) return;

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
            userName: (data['senderName'] ?? 'User').toString(),
            userImage: (data['senderImage'] ?? '').toString(),
            userRole: (data['senderRole'] ?? 'User').toString(),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open chat: $e')),
      );
    }
  }

  Future<void> _rejectRequest(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) async {
    final finderId = FirebaseAuth.instance.currentUser?.uid;
    if (finderId == null) return;

    final confirm = await _confirmDialog(
      context,
      title: 'Reject request?',
      message: 'Are you sure you want to reject this request?',
      confirmText: 'Reject',
      confirmColor: Colors.red,
    );

    if (confirm != true) return;

    try {
      String supporterId = '';

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(doc.reference);
        if (!snap.exists) throw Exception('Request not found');

        final data = snap.data() as Map<String, dynamic>;
        final receiverId = (data['receiverId'] ?? '').toString();
        supporterId = (data['senderId'] ?? '').toString();
        final status = (data['status'] ?? '').toString();

        if (receiverId != finderId) throw Exception('Not allowed');
        if (status != DashboardConstants.pendingStatus) {
          throw Exception('Request is not pending anymore');
        }

        tx.update(doc.reference, {
          'status': DashboardConstants.rejectedStatus,
          'rejectedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(), // ✅ rules-friendly
        });
      });

      // notify supporter
      if (supporterId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'toUserId': supporterId,
          'fromUserId': finderId,
          'type': 'hire_request_rejected',
          'title': 'Request rejected',
          'body': 'Your request was rejected',
          'requestId': doc.id,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting: $e')),
      );
    }
  }

  Future<void> _approveRequest(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) async {
    final finderId = FirebaseAuth.instance.currentUser?.uid;
    if (finderId == null) return;

    final confirm = await _confirmDialog(
      context,
      title: 'Approve request?',
      message: 'Approve করলে job “Work in progress” এ চলে যাবে। Continue?',
      confirmText: 'Approve',
      confirmColor: Colors.green,
    );

    if (confirm != true) return;

    try {
      String supporterId = '';
      String supporterName = '';
      String supporterImage = '';
      dynamic price;

      // 🔥 NEW: ভেরিফিকেশন ডাটা ভেরিয়েবল
      String secretOtp = '';
      String verificationType = 'otp';

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(doc.reference);
        if (!snap.exists) throw Exception('Request not found');

        final data = snap.data() as Map<String, dynamic>;
        final receiverId = (data['receiverId'] ?? '').toString();
        supporterId = (data['senderId'] ?? '').toString();
        supporterName = (data['senderName'] ?? '').toString();
        supporterImage = (data['senderImage'] ?? '').toString();
        price = data['price'] ?? data['offerPrice'];

        // 🔥 NEW: রিকোয়েস্ট থেকে OTP এবং ভেরিফিকেশন টাইপ কপি করা হচ্ছে
        secretOtp = (data['secret_otp'] ?? '').toString();
        verificationType = (data['verification_type'] ?? 'otp').toString();

        final status = (data['status'] ?? '').toString();

        if (receiverId != finderId) throw Exception('Not allowed');
        if (status != DashboardConstants.pendingStatus) {
          throw Exception('Request is not pending anymore');
        }
        if (supporterId.isEmpty) throw Exception('Invalid senderId');

        // 1) hire_requests: pending -> ongoing
        tx.update(doc.reference, {
          'status': DashboardConstants.ongoingStatus,
          'approvedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2) ongoing_jobs create (doc id = request id prevents duplicates)
        final ongoingRef =
        FirebaseFirestore.instance.collection('ongoing_jobs').doc(doc.id);

        tx.set(ongoingRef, {
          'participants': [finderId, supporterId],
          'receiverId': finderId,   // Earner (Worker)
          'workerId': supporterId,  // Hirer (Client) - *Note: Naming might be confusing based on your role logic, but keeping consistant with your code*
          'workerName': supporterName,
          'workerImage': supporterImage,
          'price': price,
          'status': DashboardConstants.ongoingStatus,
          'startTime': FieldValue.serverTimestamp(),
          'originalRequestId': doc.id,

          // 🔥 NEW: Ongoing জবে OTP ডাটা সেভ করা হলো
          'secret_otp': secretOtp,        // যাতে পরে ম্যাচ করা যায়
          'verification_type': verificationType,
          'is_verified': false,           // কাজ এখনো শেষ হয়নি

          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // notify supporter
      if (supporterId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'toUserId': supporterId,
          'fromUserId': finderId,
          'type': 'hire_request_approved',
          'title': 'Request approved',
          'body': 'Your request has been approved',
          'requestId': doc.id,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving: $e')),
      );
    }
  }

  Future<bool?> _confirmDialog(
      BuildContext context, {
        required String title,
        required String message,
        required String confirmText,
        required Color confirmColor,
      }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}