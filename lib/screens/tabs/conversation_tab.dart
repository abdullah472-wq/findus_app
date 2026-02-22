// lib/screens/tabs/conversation_tab.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/auth/log_in_chacker_screen.dart';
import 'package:findus_app/screens/settings/block_list_screen.dart'; // ✅ Add this
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/badge/badge_service.dart';
import 'package:findus_app/services/blocked_user_service.dart';

import 'package:findus_app/screens/settings/faq_screen.dart';
import 'package:findus_app/screens/settings/help_center_screen.dart';
import 'package:findus_app/screens/settings/privacy_policy_screen.dart';
import 'package:findus_app/screens/settings/terms_conditions_screen.dart';
import 'package:findus_app/screens/settings/community_standards_screen.dart';
import 'package:findus_app/screens/settings/about_app_screen.dart';
import 'package:findus_app/screens/report/report_screen.dart';

// Add these at the top
import 'package:findus_app/screens/tabs/archived_chats_screen.dart';
import 'package:findus_app/screens/tabs/pinned_chats_screen.dart';
import 'package:findus_app/screens/tabs/starred_messages_screen.dart';
import 'package:findus_app/screens/tabs/message_requests_screen.dart';
import 'package:findus_app/screens/tabs/chat_wallpaper_screen.dart';
import 'package:findus_app/screens/settings/block_list_screen.dart';
import 'package:findus_app/screens/settings/faq_screen.dart';
import 'package:findus_app/screens/settings/terms_conditions_screen.dart';




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

  final BlockedUserService _blockedService = BlockedUserService();

  // ✅ For message requests badge
  int _pendingRequests = 0;

  @override
  void initState() {
    super.initState();
    _blockedService.init();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    // Optional: Load pending message requests count
    // You can implement this based on your logic
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          title: Text(
            "Messages",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: textColor,
            ),
          ),

          // ════════════════════════════════════════════════════════════════
          // ✅ NEW SETTINGS MENU
          // ════════════════════════════════════════════════════════════════
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: textColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              offset: const Offset(0, 50),
              onSelected: (value) => _handleAppBarMenu(value),
              itemBuilder: (context) => [
                // 📁 Archived Chats
                _buildMenuItem(
                  value: 'archived',
                  icon: Icons.archive_outlined,
                  label: 'Archived Chats',
                  color: Colors.blueGrey,
                ),

                // 📌 Pinned Chats
                _buildMenuItem(
                  value: 'pinned',
                  icon: Icons.push_pin_outlined,
                  label: 'Pinned Chats',
                  color: AppColors.brandMain,
                ),

                // ⭐ Starred Messages
                _buildMenuItem(
                  value: 'starred',
                  icon: Icons.star_outline,
                  label: 'Starred Messages',
                  color: Colors.amber,
                ),

                const PopupMenuDivider(),

                // 📝 Message Requests
                _buildMenuItem(
                  value: 'requests',
                  icon: Icons.mark_email_unread_outlined,
                  label: 'Message Requests',
                  color: Colors.orange,
                  badge: _pendingRequests > 0 ? '$_pendingRequests' : null,
                ),

                // 🔔 Notification Settings
                _buildMenuItem(
                  value: 'notifications',
                  icon: Icons.notifications_outlined,
                  label: 'Notification Settings',
                  color: Colors.blue,
                ),

                // 🎨 Chat Wallpaper
                _buildMenuItem(
                  value: 'wallpaper',
                  icon: Icons.wallpaper_outlined,
                  label: 'Chat Wallpaper',
                  color: Colors.purple,
                ),

                const PopupMenuDivider(),

                // 🚫 Blocked Users
                _buildMenuItem(
                  value: 'blocked',
                  icon: Icons.block,
                  label: 'Blocked Users',
                  color: Colors.red,
                ),

                // 🗑️ Clear All Chats
                _buildMenuItem(
                  value: 'clear_all',
                  icon: Icons.delete_sweep_outlined,
                  label: 'Clear All Chats',
                  color: Colors.red,
                ),

                const PopupMenuDivider(),

                // ❓ Help & Support
                _buildMenuItem(
                  value: 'help',
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  color: Colors.teal,
                ),
              ],
            ),
            const SizedBox(width: 6),
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
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
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
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.brandMain),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  List<Map<String, dynamic>> conversations = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    data['id'] = doc.id;
                    return data;
                  }).toList();

                  conversations = _filterBlockedUsers(conversations);
                  conversations = _filterDeletedConversations(conversations);
                  conversations = _filterArchivedConversations(conversations);
                  conversations = _filterByTab(conversations);
                  conversations = _filterByQuery(conversations);
                  conversations = _sortConversations(conversations);

                  if (conversations.isEmpty) {
                    return _buildEmptyState(isDark);
                  }

                  return ListView.separated(
                    itemCount: conversations.length,
                    padding: const EdgeInsets.only(top: 8),
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    ),
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

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ MENU ITEM BUILDER
  // ════════════════════════════════════════════════════════════════════════════

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
    String? badge,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ HANDLE APPBAR MENU ACTIONS
  // ════════════════════════════════════════════════════════════════════════════

  void _handleAppBarMenu(String value) {
    switch (value) {
      case 'archived':
        _navigateToArchivedChats();
        break;
      case 'pinned':
        _navigateToPinnedChats();
        break;
      case 'starred':
        _navigateToStarredMessages();
        break;
      case 'requests':
        _navigateToMessageRequests();
        break;
      case 'notifications':
        _showNotificationSettings();
        break;
      case 'wallpaper':
        _navigateToChatWallpaper();
        break;
      case 'blocked':
        _navigateToBlockedUsers();
        break;
      case 'clear_all':
        _showClearAllChatsDialog();
        break;
      case 'help':
        _navigateToHelp();
        break;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📁 ARCHIVED CHATS
  // ════════════════════════════════════════════════════════════════════════════

  void _navigateToArchivedChats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArchivedChatsScreen()),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📌 PINNED CHATS
  // ════════════════════════════════════════════════════════════════════════════

  void _navigateToPinnedChats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PinnedChatsScreen()),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ⭐ STARRED MESSAGES
  // ════════════════════════════════════════════════════════════════════════════

  void _navigateToStarredMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StarredMessagesScreen()),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📝 MESSAGE REQUESTS
  // ════════════════════════════════════════════════════════════════════════════

  void _navigateToMessageRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MessageRequestsScreen()),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔔 NOTIFICATION SETTINGS
  // ════════════════════════════════════════════════════════════════════════════

  void _showNotificationSettings() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Notification Settings",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            _buildNotificationOption(
              icon: Icons.notifications_active,
              title: "All Messages",
              subtitle: "Get notified for all new messages",
              value: true,
              onChanged: (val) {},
            ),

            _buildNotificationOption(
              icon: Icons.volume_off,
              title: "Mute All",
              subtitle: "Temporarily mute all notifications",
              value: false,
              onChanged: (val) {},
            ),

            _buildNotificationOption(
              icon: Icons.vibration,
              title: "Vibration",
              subtitle: "Vibrate on new messages",
              value: true,
              onChanged: (val) {},
            ),

            _buildNotificationOption(
              icon: Icons.preview,
              title: "Message Preview",
              subtitle: "Show message content in notifications",
              value: true,
              onChanged: (val) {},
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.brandMain),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.brandMain,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🎨 CHAT WALLPAPER
  // ════════════════════════════════════════════════════════════════════════════

  void _navigateToChatWallpaper() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatWallpaperScreen()),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🚫 BLOCKED USERS
  // ════════════════════════════════════════════════════════════════════════════

  void _navigateToBlockedUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BlockListScreen()),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🗑️ CLEAR ALL CHATS
  // ════════════════════════════════════════════════════════════════════════════

  void _showClearAllChatsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.red),
            SizedBox(width: 10),
            Text("Clear All Chats"),
          ],
        ),
        content: const Text(
          "Are you sure you want to clear all chats?\n\n"
              "• All messages will be deleted\n"
              "• This action cannot be undone\n"
              "• Other users will still see their copy",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _clearAllChats();
            },
            child: const Text("Clear All", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllChats() async {
    try {
      final conversations = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: _currentUid)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in conversations.docs) {
        batch.update(doc.reference, {
          'deletedBy': FieldValue.arrayUnion([_currentUid]),
        });
      }

      await batch.commit();
      _showSnackBar("All chats cleared 🗑️");
    } catch (e) {
      _showSnackBar("Failed to clear chats", isError: true);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ❓ HELP & SUPPORT
  // ════════════════════════════════════════════════════════════════════════════

  void _navigateToHelp() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              "Help & Support",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // ✅ FAQs - Existing Screen
            ListTile(
              leading: const Icon(Icons.quiz_outlined, color: AppColors.brandMain),
              title: Text(
                "FAQs",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FaqScreen()),
                );
              },
            ),

            // ✅ Contact Support / Help Center - Existing Screen
            ListTile(
              leading: const Icon(Icons.support_agent_outlined, color: AppColors.brandMain),
              title: Text(
                "Help Center",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                );
              },
            ),

            // ✅ Report a Problem - Existing Screen
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: Text(
                "Report a Problem",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportScreen()),
                );
              },
            ),

            const Divider(height: 20),

            // ✅ Privacy Policy - Existing Screen
            ListTile(
              leading: const Icon(Icons.policy_outlined, color: AppColors.brandMain),
              title: Text(
                "Privacy Policy",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                );
              },
            ),

            // ✅ Terms & Conditions - Existing Screen
            ListTile(
              leading: const Icon(Icons.description_outlined, color: AppColors.brandMain),
              title: Text(
                "Terms & Conditions",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TermsAndConditionsScreen()),
                );
              },
            ),

            // ✅ Community Standards - Existing Screen
            ListTile(
              leading: const Icon(Icons.groups_outlined, color: AppColors.brandMain),
              title: Text(
                "Community Standards",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CommunityStandardsScreen()),
                );
              },
            ),

            const Divider(height: 20),

            // ✅ About App - Existing Screen
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.brandMain),
              title: Text(
                "About FindUs",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutAppScreen()),
                );
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔧 REST OF THE CODE (Filter methods, ChatItem, etc.)
  // ════════════════════════════════════════════════════════════════════════════

  // ... (বাকি সব methods আগের মতোই থাকবে)

  List<Map<String, dynamic>> _filterBlockedUsers(List<Map<String, dynamic>> conversations) {
    return conversations.where((chat) {
      final otherUid = (chat['userId'] ?? '').toString();
      if (otherUid.isEmpty) return true;
      return !_blockedService.isBlocked(otherUid);
    }).toList();
  }

  List<Map<String, dynamic>> _filterDeletedConversations(List<Map<String, dynamic>> conversations) {
    return conversations.where((chat) {
      final deletedBy = List<String>.from(chat['deletedBy'] ?? []);
      return !deletedBy.contains(_currentUid);
    }).toList();
  }

  List<Map<String, dynamic>> _filterArchivedConversations(List<Map<String, dynamic>> conversations) {
    return conversations.where((chat) {
      return chat['isArchived'] != true;
    }).toList();
  }

  List<Map<String, dynamic>> _sortConversations(List<Map<String, dynamic>> conversations) {
    conversations.sort((a, b) {
      final aPinned = a['isPinned'] == true ? 0 : 1;
      final bPinned = b['isPinned'] == true ? 0 : 1;

      if (aPinned != bPinned) return aPinned.compareTo(bPinned);

      final aTime = a['updatedAt'] as Timestamp?;
      final bTime = b['updatedAt'] as Timestamp?;

      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;

      return bTime.compareTo(aTime);
    });

    return conversations;
  }


  List<Map<String, dynamic>> _filterByQuery(List<Map<String, dynamic>> base) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return base;
    return base.where((c) =>
        (c['name'] ?? '').toString().toLowerCase().contains(q)
    ).toList();
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            "No conversations yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[500] : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start chatting with someone!",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.brandMain,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildErrorState(String err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              "Error loading messages",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(err, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ⚙️ 3-DOT MENU
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildMoreOptions(String userId, String convId, Map<String, dynamic> chat) {
    final bool isPinned = chat['isPinned'] == true;
    final bool isMuted = chat['isMuted'] == true;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 20, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => _handleMenuAction(value, userId, convId, chat),
      itemBuilder: (context) => [
        // 👤 View Profile
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20, color: Colors.blueGrey),
              SizedBox(width: 12),
              Text("View Profile"),
            ],
          ),
        ),

        // 📌 Pin/Unpin Chat
        PopupMenuItem(
          value: 'pin',
          child: Row(
            children: [
              Icon(
                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                size: 20,
                color: isPinned ? AppColors.brandMain : Colors.blueGrey,
              ),
              const SizedBox(width: 12),
              Text(isPinned ? "Unpin Chat" : "Pin Chat"),
            ],
          ),
        ),

        // 🔔 Mute/Unmute
        PopupMenuItem(
          value: 'mute',
          child: Row(
            children: [
              Icon(
                isMuted ? Icons.notifications_active : Icons.notifications_off_outlined,
                size: 20,
                color: isMuted ? Colors.green : Colors.blueGrey,
              ),
              const SizedBox(width: 12),
              Text(isMuted ? "Unmute" : "Mute Notifications"),
            ],
          ),
        ),

        // ✅ Mark as Read/Unread
        PopupMenuItem(
          value: 'mark_read',
          child: Row(
            children: [
              Icon(Icons.mark_email_read_outlined, size: 20, color: Colors.blueGrey),
              const SizedBox(width: 12),
              Text((chat['unread'] ?? 0) > 0 ? "Mark as Read" : "Mark as Unread"),
            ],
          ),
        ),

        // 📁 Archive Chat
        const PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(Icons.archive_outlined, size: 20, color: Colors.blueGrey),
              SizedBox(width: 12),
              Text("Archive Chat"),
            ],
          ),
        ),

        const PopupMenuDivider(),

        // 🚫 Block User
        const PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              Icon(Icons.block, size: 20, color: Colors.orange),
              SizedBox(width: 12),
              Text("Block User", style: TextStyle(color: Colors.orange)),
            ],
          ),
        ),

        // 🗑️ Delete Chat
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text("Delete Chat", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),

        // ⚠️ Report User
        const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_outlined, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text("Report User", style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, String userId, String convId, Map<String, dynamic> chat) {
    switch (action) {
      case 'profile':
        _viewProfile(userId);
        break;
      case 'pin':
        _togglePinChat(convId, chat['isPinned'] == true);
        break;
      case 'mute':
        _toggleMuteChat(convId, chat['isMuted'] == true);
        break;
      case 'mark_read':
        _toggleReadStatus(convId, (chat['unread'] ?? 0) > 0);
        break;
      case 'archive':
        _archiveChat(convId);
        break;
      case 'block':
      // ✅ Pass full chat data
        _showBlockDialog(userId, chat);
        break;
      case 'delete':
        _showDeleteDialog(convId, chat['name'] ?? 'User');
        break;
      case 'report':
        _showReportDialog(userId, chat['name'] ?? 'User');
        break;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 👤 VIEW PROFILE
  // ════════════════════════════════════════════════════════════════════════════

  void _viewProfile(String userId) {
    if (userId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedProfileScreen(uid: userId, isOwner: false, showBack: true),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📌 PIN/UNPIN CHAT
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _togglePinChat(String convId, bool currentlyPinned) async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(convId)
          .update({'isPinned': !currentlyPinned});

      _showSnackBar(currentlyPinned ? "Chat unpinned" : "Chat pinned 📌");
    } catch (e) {
      _showSnackBar("Failed to update", isError: true);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔔 MUTE/UNMUTE CHAT
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _toggleMuteChat(String convId, bool currentlyMuted) async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(convId)
          .update({'isMuted': !currentlyMuted});

      _showSnackBar(currentlyMuted ? "Notifications enabled 🔔" : "Notifications muted 🔕");
    } catch (e) {
      _showSnackBar("Failed to update", isError: true);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ MARK AS READ/UNREAD
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _toggleReadStatus(String convId, bool hasUnread) async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(convId)
          .update({'unread': hasUnread ? 0 : 1});

      _showSnackBar(hasUnread ? "Marked as read ✓" : "Marked as unread");
    } catch (e) {
      _showSnackBar("Failed to update", isError: true);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 📁 ARCHIVE CHAT
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _archiveChat(String convId) async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(convId)
          .update({'isArchived': true});

      _showSnackBar("Chat archived 📁");
    } catch (e) {
      _showSnackBar("Failed to archive", isError: true);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🚫 BLOCK USER - FIXED VERSION
  // ════════════════════════════════════════════════════════════════════════════

  /// ✅ Show block dialog with chat data
  void _showBlockDialog(String userId, Map<String, dynamic> chat) {
    final userName = chat['name'] ?? 'User';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.orange),
            SizedBox(width: 10),
            Text("Block User"),
          ],
        ),
        content: Text(
          "Are you sure you want to block $userName?\n\n"
              "• They won't be able to message you\n"
              "• Their posts will be hidden from you\n"
              "• You can unblock them anytime from Settings",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              Navigator.pop(ctx);
              _blockUser(userId, chat);
            },
            child: const Text("Block", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// ✅ Block user with proper chat data
  Future<void> _blockUser(String userId, Map<String, dynamic> chat) async {
    final userName = (chat['name'] ?? 'User').toString();
    final userImage = (chat['image'] ?? '').toString();

    try {
      // ✅ Show loading indicator
      _showSnackBar("Blocking $userName...");

      // ✅ Call BlockedUserService with user details
      final success = await _blockedService.blockUser(
        userId,
        targetName: userName,
        targetImage: userImage,
      );

      if (success) {
        // ✅ Refresh the conversation list
        setState(() {});

        if (mounted) {
          _showSnackBar("$userName blocked 🚫");
        }
      } else {
        if (mounted) {
          _showSnackBar("Failed to block user", isError: true);
        }
      }
    } catch (e) {
      debugPrint("❌ Error blocking user: $e");
      if (mounted) {
        _showSnackBar("Failed to block user: $e", isError: true);
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🗑️ DELETE CHAT
  // ════════════════════════════════════════════════════════════════════════════

  void _showDeleteDialog(String convId, String userName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 10),
            Text("Delete Chat"),
          ],
        ),
        content: Text("Delete your conversation with $userName?\n\nThis action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteChat(convId, userName);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(String convId, String userName) async {
    try {
      // Soft delete (recommended)
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(convId)
          .update({
        'deletedBy': FieldValue.arrayUnion([_currentUid])
      });

      _showSnackBar("Chat with $userName deleted 🗑️");
    } catch (e) {
      _showSnackBar("Failed to delete chat", isError: true);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ⚠️ REPORT USER
  // ════════════════════════════════════════════════════════════════════════════

  void _showReportDialog(String userId, String userName) {
    String? selectedReason;
    final reasons = [
      "Spam or scam",
      "Harassment or bullying",
      "Inappropriate content",
      "Fake profile",
      "Other",
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.flag_outlined, color: Colors.red),
              SizedBox(width: 10),
              Text("Report User"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Why are you reporting $userName?"),
              const SizedBox(height: 16),
              ...reasons.map((reason) => RadioListTile<String>(
                title: Text(reason, style: const TextStyle(fontSize: 14)),
                value: reason,
                groupValue: selectedReason,
                onChanged: (val) => setState(() => selectedReason = val),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: selectedReason == null
                  ? null
                  : () {
                Navigator.pop(ctx);
                _reportUser(userId, userName, selectedReason!);
              },
              child: const Text("Report", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportUser(String userId, String userName, String reason) async {
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'reportedUserId': userId,
        'reportedUserName': userName,
        'reportedBy': _currentUid,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      _showSnackBar("Report submitted. Thank you! ⚠️");
    } catch (e) {
      _showSnackBar("Failed to submit report", isError: true);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 💬 CHAT ITEM BUILDER
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildChatItem(Map<String, dynamic> chat, bool isDark, Color cardColor, Color textColor) {
    final lastMsg = (chat['lastMsg'] ?? 'Start chatting...').toString();
    final isPinned = chat['isPinned'] == true;
    final isMuted = chat['isMuted'] == true;

    // ✅ টাইম ফরম্যাটিং
    String timeStr = '';
    if (chat['updatedAt'] != null && chat['updatedAt'] is Timestamp) {
      final dt = (chat['updatedAt'] as Timestamp).toDate();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inDays == 0) {
        timeStr = DateFormat('h:mm a').format(dt); // Today: 10:30 AM
      } else if (diff.inDays == 1) {
        timeStr = 'Yesterday';
      } else if (diff.inDays < 7) {
        timeStr = DateFormat('EEE').format(dt); // Mon, Tue, etc.
      } else {
        timeStr = DateFormat('MMM d').format(dt); // Jan 15
      }
    }

    final unreadCount = (chat['unread'] ?? 0) as int;
    final unread = unreadCount > 0;
    final img = (chat['image'] ?? '').toString();
    final name = (chat['name'] ?? 'User').toString();
    final role = (chat['role'] ?? '').toString();
    final otherUid = (chat['userId'] ?? '').toString();

    // ✅ ব্যাজ লজিক
    final badgeLevelStr = (chat['badgeLevel'] ?? 'newbie').toString();
    final badgeLevel = BadgeLevel.values.firstWhere(
          (e) => e.name == badgeLevelStr,
      orElse: () => BadgeLevel.newbie,
    );

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
              otherUserId: otherUid,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: isPinned
            ? (isDark ? AppColors.brandMain.withOpacity(0.1) : AppColors.brandLight.withOpacity(0.3))
            : cardColor,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (otherUid.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UnifiedProfileScreen(
                        uid: otherUid,
                        isOwner: false,
                        showBack: true,
                      ),
                    ),
                  );
                }
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.brandLight,
                    backgroundImage: img.isNotEmpty ? NetworkImage(img) : null,
                    child: img.isEmpty
                        ? const Icon(Icons.person, color: AppColors.brandDark)
                        : null,
                  ),
                  // ✅ Verified badge
                  if (chat['isVerified'] == true)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
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
                      // ✅ Pinned indicator
                      if (isPinned) ...[
                        Icon(Icons.push_pin, size: 14, color: AppColors.brandMain),
                        const SizedBox(width: 4),
                      ],

                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: unread ? FontWeight.w900 : FontWeight.w600,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),

                      // ✅ Badge Icon Display
                      Icon(Icons.workspace_premium, size: 16, color: badgeColor),

                      // ✅ Muted indicator
                      if (isMuted) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.notifications_off, size: 14, color: Colors.grey),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMsg,
                    style: TextStyle(
                      fontSize: 13,
                      color: unread ? textColor : Colors.grey,
                      fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ডান পাশের অংশ (Time + Unread + 3 Dot)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: unread ? AppColors.brandMain : Colors.grey,
                    fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // ✅ Unread count badge
                    if (unread)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandMain,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    // ✅ 3-Dot Menu
                    _buildMoreOptions(otherUid, chat['id'].toString(), chat),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 🔍 FILTER METHODS
  // ════════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _filterByTab(List<Map<String, dynamic>> base) {
    if (_tabIndex == 1) {
      return base.where((c) =>
      (c['userType'] ?? c['role'] ?? '').toString().toLowerCase() == 'supporter'
      ).toList();
    }
    if (_tabIndex == 2) {
      return base.where((c) =>
      (c['userType'] ?? c['role'] ?? '').toString().toLowerCase() == 'earner'
      ).toList();
    }
    return base;
  }

}