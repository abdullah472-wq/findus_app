import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import '../auth/log_in_chacker_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _showAdminNoticeDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: AppColors.brandMain),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(body, style: const TextStyle(fontSize: 15, height: 1.5)),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("CLOSE"),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSenderProfile(String senderId) {
    if (senderId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedProfileScreen(uid: senderId, isOwner: false, showBack: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ১. লগইন না থাকলে সুন্দর লগইন পেজ দেখাবে
    if (_uid.isEmpty) {
      return const ProfileNotLoggedIn(
        title: "Notifications",
        showBackButton: true, // যেহেতু এটি আলাদা স্ক্রিন, ব্যাক বাটন দরকার
      );
    }

    // ✅ ২. লগইন থাকলে নোটিফিকেশন লিস্ট দেখাবে
    return FloatingScaffold(
      title: "NOTIFICATIONS",
      backgroundColor: AppColors.bgBlue,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brandMain));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.only(top: 10, bottom: 80),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final notifId = docs[index].id;
              return _buildNotificationItem(data, notifId);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              "No notifications yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> data, String id) {
    final title = data['title'] ?? 'New Notification';
    final body = data['body'] ?? '';
    final type = data['type'] ?? 'info';
    final senderId = data['senderId'] ?? '';
    final bool isRead = data['read'] ?? false;
    final Timestamp? ts = data['createdAt'];

    IconData icon = Icons.notifications;
    Color iconColor = AppColors.brandMain;

    if (type == 'admin') {
      icon = Icons.admin_panel_settings;
      iconColor = Colors.redAccent;
    } else if (type == 'job') {
      icon = Icons.work;
      iconColor = Colors.orange;
    } else if (type == 'message') {
      icon = Icons.chat_bubble;
      iconColor = Colors.blue;
    }

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('notifications')
            .doc(id)
            .delete();
      },
      child: InkWell(
        onTap: () {
          if (type == 'admin') {
            _showAdminNoticeDialog(title, body);
          } else if (senderId.isNotEmpty) {
            _navigateToSenderProfile(senderId);
          }

          if (!isRead) {
            FirebaseFirestore.instance
                .collection('users')
                .doc(_uid)
                .collection('notifications')
                .doc(id)
                .update({'read': true});
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: isRead
                ? Border.all(color: Colors.transparent)
                : Border.all(color: AppColors.brandMain.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ts != null)
                          Text(
                            _formatTime(ts),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return DateFormat('MMM d').format(date);
  }
}