import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/auth/log_in_chacker_screen.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/badge/badge_service.dart';



class ConversationTab extends StatefulWidget {
  const ConversationTab({super.key});

  @override
  State<ConversationTab> createState() => _ConversationTabState();
}

class _ConversationTabState extends State<ConversationTab> {
  int _tabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openUserProfile() {
    if (_currentUid == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedProfileScreen(uid: _currentUid!, isOwner: true, showBack: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUid == null) {
      return const ProfileNotLoggedIn(title: "Messages", showBackButton: false);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return DefaultTabController(
      length: 3,
      initialIndex: _tabIndex,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0.5,
          title: Text("Messages", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: textColor)),
          actions: [
            IconButton(icon: Icon(Icons.person_outline, color: textColor), onPressed: _openUserProfile),
            const SizedBox(width: 10),
          ],
          bottom: TabBar(
            onTap: (i) => setState(() => _tabIndex = i),
            indicatorColor: AppColors.brandMain,
            labelColor: AppColors.brandMain,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [Tab(text: "All"), Tab(text: "Supporters"), Tab(text: "Earners")],
          ),
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: cardColor,
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textColor),
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: "Search messages...",
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('conversations')
                    .where('participants', arrayContains: _currentUid)
                    .orderBy('updatedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.brandMain));

                  final docs = snapshot.data?.docs ?? [];
                  List<Map<String, dynamic>> conversations = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    data['id'] = doc.id;
                    return data;
                  }).toList();

                  conversations = _filterByTab(conversations);
                  conversations = _filterByQuery(conversations);

                  if (conversations.isEmpty) return Center(child: Text("No conversations found", style: TextStyle(color: Colors.grey.shade500)));

                  return ListView.separated(
                    itemCount: conversations.length,
                    padding: const EdgeInsets.only(top: 8),
                    separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      return _buildChatItem(conversations[index], isDark, cardColor, textColor);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat, bool isDark, Color cardColor, Color textColor) {
    final lastMsg = (chat['lastMsg'] ?? 'Start chatting...').toString();

    // ✅ টাইম ফরম্যাটিং
    String timeStr = '';
    if (chat['updatedAt'] != null && chat['updatedAt'] is Timestamp) {
      final dt = (chat['updatedAt'] as Timestamp).toDate();
      timeStr = DateFormat('h:mm a').format(dt); // e.g. 10:30 AM
    }

    final unreadCount = (chat['unread'] ?? 0) as int;
    final unread = unreadCount > 0;
    final img = (chat['image'] ?? '').toString();
    final name = (chat['name'] ?? 'User').toString();
    final role = (chat['role'] ?? '').toString();
    final otherUid = (chat['userId'] ?? '').toString();

    // ✅ ব্যাজ লজিক (BadgeService থেকে লেভেল অনুযায়ী আইকন/কালার)
    // এখানে ধরে নিচ্ছি chat ডকুমেন্টে 'badgeLevel' বা 'xp' আছে। না থাকলে ডিফল্ট শো করবে।
    final badgeLevelStr = (chat['badgeLevel'] ?? 'newbie').toString();
    final badgeLevel = BadgeLevel.values.firstWhere(
          (e) => e.name == badgeLevelStr,
      orElse: () => BadgeLevel.newbie,
    );

// totalXP / totalStars এখানে না থাকলে শুধু ০/০ দিয়েও রঙ পাওয়া যাবে
    final badgeProgress = BadgeProgress(
      badgeLevel: badgeLevel,
      totalXP: 0,
      totalStars: 0.0,
    );
    final badgeColor = badgeProgress.badgeColor;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: chat['id'].toString(),
              userName: name,
              userImage: img,
              userRole: role,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: cardColor,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (otherUid.isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => UnifiedProfileScreen(uid: otherUid, isOwner: false, showBack: true)));
                }
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.brandLight,
                    backgroundImage: img.isNotEmpty ? NetworkImage(img) : null,
                    child: img.isEmpty ? const Icon(Icons.person, color: AppColors.brandDark) : null,
                  ),
                  if (chat['isVerified'] == true)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.verified, size: 14, color: AppColors.brandMain),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(fontSize: 16, fontWeight: unread ? FontWeight.w900 : FontWeight.w600, color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),

                      // ✅ Badge Icon Display
                      Icon(Icons.workspace_premium, size: 16, color: badgeColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMsg,
                    style: TextStyle(fontSize: 13, color: unread ? textColor : Colors.grey, fontWeight: unread ? FontWeight.bold : FontWeight.normal),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ডান পাশের অংশ (Time + 3 Dot)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeStr, style: TextStyle(fontSize: 11, color: unread ? AppColors.brandMain : Colors.grey, fontWeight: unread ? FontWeight.bold : FontWeight.normal)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (unread)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: AppColors.brandMain, shape: BoxShape.circle),
                      ),

                    // ✅ 3-Dot Menu
                    _buildMoreOptions(otherUid, chat['id']),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 3-Dot Menu Button
  Widget _buildMoreOptions(String userId, String convId) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 20, color: Colors.grey),
      onSelected: (value) {
        if (value == 'profile') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => UnifiedProfileScreen(uid: userId, isOwner: false, showBack: true)));
        } else if (value == 'delete') {
          // TODO: Delete Logic
        } else if (value == 'block') {
          // TODO: Block Logic
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'profile', child: Row(children: [Icon(Icons.person, size: 18), SizedBox(width: 8), Text("View Profile")])),
        const PopupMenuItem(value: 'pin', child: Row(children: [Icon(Icons.push_pin, size: 18), SizedBox(width: 8), Text("Pin Chat")])),
        const PopupMenuItem(value: 'mute', child: Row(children: [Icon(Icons.volume_off, size: 18), SizedBox(width: 8), Text("Mute")])),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'block', child: Row(children: [Icon(Icons.block, size: 18, color: Colors.red), SizedBox(width: 8), Text("Block", style: TextStyle(color: Colors.red))])),
      ],
    );
  }

  List<Map<String, dynamic>> _filterByTab(List<Map<String, dynamic>> base) {
    if (_tabIndex == 1) return base.where((c) => (c['userType'] ?? c['role'] ?? '').toString().toLowerCase() == 'supporter').toList();
    if (_tabIndex == 2) return base.where((c) => (c['userType'] ?? c['role'] ?? '').toString().toLowerCase() == 'earner').toList();
    return base;
  }

  List<Map<String, dynamic>> _filterByQuery(List<Map<String, dynamic>> base) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return base;
    return base.where((c) => (c['name'] ?? '').toString().toLowerCase().contains(q)).toList();
  }

  Widget _buildErrorState(String err) {
    return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text("Error: $err", style: const TextStyle(color: Colors.redAccent))));
  }
}