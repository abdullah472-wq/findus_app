// lib/screens/dashboard/pending_jobs_screen.dart

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
  final String? userId;

  const PendingJobsScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final String? authUid = FirebaseAuth.instance.currentUser?.uid;
    final String? uid = authUid ?? userId;

    // ✅ ডার্ক মোড চেক
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

    final pendingStream = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: DashboardConstants.pendingStatus)
        .snapshots();

    return FloatingScaffold(
      title: 'PENDING REQUESTS',
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: pendingStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _ErrorBox(message: 'Error: ${snapshot.error}', isDark: isDark);
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.brandMain));

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return _buildEmptyState(isDark);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            physics: const BouncingScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _buildRequestItem(context, docs[index], isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestItem(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      bool isDark,
      ) {
    final data = doc.data();
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
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
            margin: EdgeInsets.zero,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onChatTap: () => _openChat(context, data),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(context, doc),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: () => _approveRequest(context, doc),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("APPROVE"),
                  ),
                ),
              ],
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
      final convId = await FirestoreChatService.getOrCreateConversation(otherUserId: otherUserId);
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open chat: $e')));
      }
    }
  }

  Future<void> _rejectRequest(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final finderId = FirebaseAuth.instance.currentUser?.uid;
    if (finderId == null) return;

    final confirm = await _confirmDialog(
      context,
      title: 'Reject Request?',
      message: 'Are you sure you want to reject this job request?',
      confirmText: 'REJECT',
      confirmColor: Colors.redAccent,
    );

    if (confirm != true) return;

    try {
      String supporterId = '';
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(doc.reference);
        if (!snap.exists) throw Exception('Request not found');
        final data = snap.data() as Map<String, dynamic>;

        if (data['receiverId'] != finderId) throw Exception('Not allowed');
        if (data['status'] != DashboardConstants.pendingStatus) throw Exception('Already processed');

        supporterId = (data['senderId'] ?? '').toString();

        tx.update(doc.reference, {
          'status': DashboardConstants.rejectedStatus,
          'rejectedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (supporterId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'toUserId': supporterId,
          'fromUserId': finderId,
          'type': 'hire_request_rejected',
          'title': 'Request Rejected',
          'body': 'Your job request was rejected.',
          'requestId': doc.id,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected'), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _approveRequest(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final finderId = FirebaseAuth.instance.currentUser?.uid;
    if (finderId == null) return;

    final confirm = await _confirmDialog(
      context,
      title: 'Approve Request?',
      message: 'Approve to start the job. It will move to "Work in Progress".',
      confirmText: 'APPROVE',
      confirmColor: Colors.green,
    );

    if (confirm != true) return;

    try {
      String supporterId = '';
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(doc.reference);
        if (!snap.exists) throw Exception('Request not found');
        final data = snap.data() as Map<String, dynamic>;

        if (data['receiverId'] != finderId) throw Exception('Not allowed');
        if (data['status'] != DashboardConstants.pendingStatus) throw Exception('Already processed');

        supporterId = (data['senderId'] ?? '').toString();

        // 1. Update Hire Request Status
        tx.update(doc.reference, {
          'status': DashboardConstants.ongoingStatus,
          'approvedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. Create Ongoing Job Entry
        final ongoingRef = FirebaseFirestore.instance.collection('ongoing_jobs').doc(doc.id);
        tx.set(ongoingRef, {
          'participants': [finderId, supporterId],
          'receiverId': finderId,
          'workerId': supporterId,
          'workerName': data['senderName'],
          'workerImage': data['senderImage'],
          'price': data['price'] ?? data['offerPrice'],
          'status': DashboardConstants.ongoingStatus,
          'startTime': FieldValue.serverTimestamp(),
          'originalRequestId': doc.id,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 3. Update User Stats (Hire Count)
        if (supporterId.isNotEmpty) {
          // ✅ Increment supporter hiresCount (Hire-based Trusted denominator)
          final supporterStatsRef = FirebaseFirestore.instance.collection('user_stats').doc(supporterId);

          tx.set(
            supporterStatsRef,
            {
              'hiresCount': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      });

      // Send Notification
      if (supporterId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'toUserId': supporterId,
          'fromUserId': finderId,
          'type': 'hire_request_approved',
          'title': 'Request Approved',
          'body': 'Your job request has been approved!',
          'requestId': doc.id,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job approved successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<bool?> _confirmDialog(BuildContext context, {required String title, required String message, required String confirmText, required Color confirmColor}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No pending requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.grey)),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final bool isDark;
  const _ErrorBox({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
      ),
    );
  }
}