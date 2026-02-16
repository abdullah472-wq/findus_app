import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import '../auth/log_in_chacker_screen.dart';
import 'package:findus_app/screens/settings/help_center_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _showAdminNoticeDialog(String title, String body, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: AppColors.brandMain),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(body, style: TextStyle(fontSize: 15, height: 1.5, color: isDark ? Colors.white70 : Colors.black87)),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                foregroundColor: isDark ? Colors.white : Colors.black,
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

  Future<void> _createWelcomeNotificationIfNeeded() async {
    // আগেই uid চেক করে রাখা আছে, তবু সেফটি
    if (_uid.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();

    final userData = userDoc.data() ?? {};

    final name = (userData['name'] ?? userData['fullName'] ?? 'User').toString();

    final notifRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('notifications');

    // চেক করো আগে কোনো welcome টাইপ notification আছে কিনা
    final existing = await notifRef
        .where('type', isEqualTo: 'welcome')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // আগে থেকেই welcome আছে, আর নতুন করে দেবো না
      return;
    }

    // নতুন welcome notification তৈরি
    await notifRef.add({
      'title': 'Welcome to FindUs, $name!',
      'body':
      'Thanks for joining the FindUs community.\n'
          'You can complete your profile, explore jobs, and start chatting with other members right away.',
      'type': 'welcome',              // type: welcome → icon + action handle করতে সহজ হবে
      'senderId': '',                 // system / admin – চাইলে এখানে "system" লিখতে পারো
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    if (_uid.isEmpty) {
      return const ProfileNotLoggedIn(
        title: "Notifications",
        showBackButton: true,
      );
    }

    return FloatingScaffold(
      title: "NOTIFICATIONS",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
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
            // প্রথমবার এলে welcome notification তৈরি করার ট্রাই
            _createWelcomeNotificationIfNeeded();
            return _buildEmptyState(isDark);
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
              return _buildNotificationItem(data, notifId, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 80, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No notifications yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade500 : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> data, String id, bool isDark) {
    final title = data['title'] ?? 'New Notification';
    final body = data['body'] ?? '';
    final type = (data['type'] ?? 'info').toString().toLowerCase(); // ✅ লোয়ারকেস ফিক্স
    final senderId = data['senderId'] ?? '';
    final bool isRead = data['read'] ?? false;
    final Timestamp? ts = data['createdAt'];

    IconData icon = Icons.notifications;
    Color iconColor = AppColors.brandMain;

    // ✅ আইকন লজিক আপডেট
    if (type.contains('admin')) {
      icon = Icons.admin_panel_settings;
      iconColor = Colors.redAccent;
    } else if (type.contains('job')) {
      icon = Icons.work;
      iconColor = Colors.orange;
    } else if (type.contains('message') || type.contains('chat')) {
      icon = Icons.chat_bubble;
      iconColor = Colors.blue;
    } else if (type.contains('help') || type.contains('welcome')) { // ✅ Welcome/Help ফিক্স
      icon = Icons.support_agent;
      iconColor = Colors.purpleAccent;
    } else if (type.contains('profile')) {
      icon = Icons.visibility;
      iconColor = Colors.teal;
    }

    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    // ✅ আনরিড কালার ফিক্স (ডার্ক মোডে একটু আলাদা)
    final unreadBg = isDark ? const Color(0xFF383838) : Colors.blue.withOpacity(0.05);

    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

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
          // ✅ অ্যাকশন লজিক
          if (type.contains('admin')) {
            _showAdminNoticeDialog(title, body, isDark);
          } else if (type.contains('help') || type.contains('welcome')) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
          } else if (senderId.isNotEmpty) {
            _navigateToSenderProfile(senderId);
          }

          // মার্ক অ্যাজ রিড
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
            color: isRead ? cardColor : unreadBg, // ✅ রিড হলে কার্ড কালার, আনরিড হলে হাইলাইট
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isRead ? Colors.transparent : AppColors.brandMain.withOpacity(0.3),
                width: isRead ? 0 : 1
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // আইকন বক্স
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),

              // টেক্সট কন্টেন্ট
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold, // আনরিড হলে বোল্ড
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ts != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              _formatTime(ts),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold // আনরিড হলে বোল্ড টাইম
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(fontSize: 13, color: subTextColor, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // আনরিড ইন্ডিকেটর ডট (অপশনাল)
              if (!isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 5),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.brandMain,
                    shape: BoxShape.circle,
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