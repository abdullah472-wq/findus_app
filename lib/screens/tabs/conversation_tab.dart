// lib/screens/tabs/conversation_tab.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/services/conversation_storage.dart';
import 'package:findus_app/screens/auth/log_in_chacker_screen.dart'; // লগইন চেক স্ক্রিন

class ConversationTab extends StatefulWidget {
  const ConversationTab({super.key});

  @override
  State<ConversationTab> createState() => _ConversationTabState();
}

class _ConversationTabState extends State<ConversationTab> {
  List<Map<String, dynamic>> _conversations = [];
  int _tabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (_currentUid != null) {
      _loadConversations();
    }
  }

  Future<void> _loadConversations() async {
    final data = await ConversationStorage.load();
    if (!mounted) return;
    setState(() {
      _conversations = data;
    });
  }

  List<Map<String, dynamic>> get _filteredConversations {
    List<Map<String, dynamic>> base;
    if (_tabIndex == 1) {
      base = _conversations.where((c) => c['userType'] == 'supporter').toList();
    } else if (_tabIndex == 2) {
      base = _conversations.where((c) => c['userType'] == 'earner').toList();
    } else {
      base = List<Map<String, dynamic>>.from(_conversations);
    }

    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return base;

    return base.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final role = (c['role'] ?? '').toString().toLowerCase();
      return name.contains(q) || role.contains(q);
    }).toList();
  }

  void _openUserProfile() {
    if (_currentUid == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedProfileScreen(uid: _currentUid, isOwner: true, showBack: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ১. লগইন চেক
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
            IconButton(
              icon: Icon(Icons.person_outline, color: textColor),
              onPressed: _openUserProfile,
            ),
            const SizedBox(width: 10),
          ],
          bottom: TabBar(
            onTap: (i) => setState(() => _tabIndex = i),
            indicatorColor: AppColors.brandMain,
            labelColor: AppColors.brandMain,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "All"),
              Tab(text: "Supporters"),
              Tab(text: "Earners"),
            ],
          ),
        ),
        body: Column(
          children: [
            // সার্চ বার
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

            // চ্যাট লিস্ট
            Expanded(
              child: _filteredConversations.isEmpty
                  ? Center(child: Text("No conversations found", style: TextStyle(color: Colors.grey.shade500)))
                  : ListView.builder(
                itemCount: _filteredConversations.length,
                padding: const EdgeInsets.only(top: 8),
                itemBuilder: (context, index) {
                  final chat = _filteredConversations[index];
                  return _buildChatItem(chat, isDark, cardColor, textColor);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ২. কাস্টম চ্যাট আইটেম (কার্ডের বদলে লিস্ট টাইল)
  Widget _buildChatItem(Map<String, dynamic> chat, bool isDark, Color cardColor, Color textColor) {
    final lastMsg = chat['lastMessage'] ?? 'Start chatting...';
    final time = chat['time'] ?? '';
    final unread = (chat['unread'] ?? 0) > 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: chat['id'],
              userName: chat['name'],
              userImage: chat['image'],
              userRole: chat['role'],
            ),
          ),
        ).then((_) => _loadConversations()); // ফিরে আসলে রিফ্রেশ হবে
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            // প্রোফাইল ছবি
            GestureDetector(
              onTap: () {
                final uid = chat['userId'] ?? chat['id'];
                if (uid != null) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => UnifiedProfileScreen(uid: uid, isOwner: false, showBack: true)
                      )
                  );
                }
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.brandLight,
                    backgroundImage: (chat['image'] != null && chat['image'].isNotEmpty)
                        ? NetworkImage(chat['image'])
                        : null,
                    child: (chat['image'] == null || chat['image'].isEmpty)
                        ? const Icon(Icons.person, color: AppColors.brandDark)
                        : null,
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

            // নাম ও মেসেজ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat['name'] ?? 'User',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: unread ? FontWeight.w900 : FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: unread ? AppColors.brandMain : Colors.grey,
                          fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg,
                          style: TextStyle(
                            fontSize: 13,
                            color: unread ? textColor : Colors.grey,
                            fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.brandMain,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}