// lib/screens/explore/notifications_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/app_config_service.dart';
import 'package:findus_app/services/notification_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  late final List<_NotifItem> _staticNotifications;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _configSub;

  // Global notice state
  bool _globalEnabled = false;
  String _globalTitle = '';
  String _globalBody = '';
  String _globalPriority = 'normal';
  String _globalActionUrl = '';

  @override
  void initState() {
    super.initState();
    _initStaticNotifs();
    _subscribeToGlobalConfig();
  }

  void _initStaticNotifs() {
    _staticNotifications = [
      _NotifItem.local(
        id: 'local_welcome',
        title: 'Welcome to FINDUS!',
        body: 'Thanks for joining. Complete your profile to get better matches.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
        type: 'system',
      ),
    ];
  }

  void _subscribeToGlobalConfig() {
    _configSub = FirebaseFirestore.instance
        .collection('appConfig')
        .doc('global')
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      if (mounted) {
        setState(() {
          _globalEnabled = data['globalNoticeEnabled'] == true;
          _globalTitle = data['globalNoticeTitle'] ?? '';
          _globalBody = data['globalNoticeBody'] ?? '';
          _globalPriority = data['globalNoticePriority'] ?? 'normal';
          _globalActionUrl = data['globalNoticeActionUrl'] ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _configSub?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // --- Helpers ---
  DateTime _toDateTime(dynamic dt) {
    if (dt is Timestamp) return dt.toDate();
    if (dt is DateTime) return dt;
    return DateTime.now();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) return const Scaffold(body: Center(child: Text("Please login to see notifications")));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FloatingScaffold(
      title: 'NOTIFICATIONS',
      backgroundColor: AppColors.brandLight,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      showBack: true,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: Column(
        children: [
          _buildSearchBar(isDark),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              // ✅ সরাসরি আপনার নতুন ফায়ারবেস স্কিমা অনুযায়ী কুয়েরি
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('toUserId', isEqualTo: _uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

                final remoteDocs = snapshot.data?.docs ?? [];

                // ১. সব নোটিফিকেশন একসাথে করা
                List<_NotifItem> allItems = [
                  if (_globalEnabled) _NotifItem.global(
                      title: _globalTitle,
                      body: _globalBody,
                      priority: _globalPriority,
                      url: _globalActionUrl
                  ),
                  ..._staticNotifications,
                  ...remoteDocs.map((doc) {
                    final data = doc.data();
                    return _NotifItem.remote(
                      id: doc.id,
                      title: data['title'] ?? 'No Title',
                      body: data['body'] ?? '',
                      createdAt: data['createdAt'] ?? Timestamp.now(),
                      isRead: data['isRead'] == true,
                      type: data['type'] ?? 'general',
                    );
                  }),
                ];

                // ২. সার্চ ফিল্টারিং
                if (_query.isNotEmpty) {
                  allItems = allItems.where((n) => n.title.toLowerCase().contains(_query) || n.body.toLowerCase().contains(_query)).toList();
                }

                if (snapshot.connectionState == ConnectionState.waiting && allItems.length <= 1) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (allItems.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: allItems.length,
                  itemBuilder: (context, index) => _buildNotificationCard(allItems[index], isDark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              setState(() => _query = v.trim().toLowerCase());
            });
          },
          decoration: const InputDecoration(
            hintText: "Search notifications...",
            prefixIcon: Icon(Icons.search_rounded, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(_NotifItem item, bool isDark) {
    final dt = _toDateTime(item.createdAt);
    final isUnread = !item.isRead;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnread ? AppColors.brandMain.withOpacity(0.3) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _handleNotifTap(item),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconForType(item),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(item.title, style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, fontSize: 15))),
                        Text(_timeAgo(dt), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(item.body, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade700, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (isUnread) Container(margin: const EdgeInsets.only(left: 8, top: 4), width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.brandMain, shape: BoxShape.circle)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconForType(_NotifItem item) {
    Color bgColor;
    IconData icon;

    if (item.source == _NotifSource.global) {
      bgColor = item.priority == 'high' ? Colors.redAccent : Colors.orange;
      icon = Icons.campaign_rounded;
    } else {
      switch (item.type) {
        case 'emergency': bgColor = Colors.red; icon = Icons.shield_rounded; break;
        case 'hire_request': bgColor = Colors.green; icon = Icons.handshake_rounded; break;
        case 'system': bgColor = Colors.blue; icon = Icons.settings_suggest_rounded; break;
        case 'chat': bgColor = Colors.cyan; icon = Icons.chat_bubble_rounded; break;
        default: bgColor = AppColors.brandMain; icon = Icons.notifications_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bgColor.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: bgColor, size: 22),
    );
  }

  void _handleNotifTap(_NotifItem item) async {
    HapticFeedback.lightImpact();

    // ১. গ্লোবাল নোটিশ হলে লিঙ্ক ওপেন করো
    if (item.source == _NotifSource.global && item.actionUrl.isNotEmpty) {
      final uri = Uri.tryParse(item.actionUrl);
      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    // ২. রিমোট নোটিশ হলে ফায়ারবেসে 'isRead' আপডেট করো
    if (item.source == _NotifSource.remote && !item.isRead) {
      await FirebaseFirestore.instance.collection('notifications').doc(item.id).update({'isRead': true});
    }

    // ৩. লোকাল স্টেট আপডেট
    setState(() => item.isRead = true);
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text("No notifications yet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}

// --- মডেল ---
enum _NotifSource { local, remote, global }

class _NotifItem {
  final String id;
  final _NotifSource source;
  final String title;
  final String body;
  final dynamic createdAt;
  final String type;
  final String priority;
  final String actionUrl;
  bool isRead;

  _NotifItem._({
    required this.id, required this.source, required this.title, required this.body,
    required this.createdAt, required this.isRead, this.type = 'general',
    this.priority = 'normal', this.actionUrl = '',
  });

  factory _NotifItem.local({required String id, required String title, required String body, required DateTime createdAt, required bool isRead, String type = 'general'}) {
    return _NotifItem._(id: id, source: _NotifSource.local, title: title, body: body, createdAt: createdAt, isRead: isRead, type: type);
  }

  factory _NotifItem.remote({required String id, required String title, required String body, required dynamic createdAt, required bool isRead, String type = 'general'}) {
    return _NotifItem._(id: id, source: _NotifSource.remote, title: title, body: body, createdAt: createdAt, isRead: isRead, type: type);
  }

  factory _NotifItem.global({required String title, required String body, String priority = 'normal', String url = ''}) {
    return _NotifItem._(id: 'global_admin_notice', source: _NotifSource.global, title: title, body: body, createdAt: DateTime.now(), isRead: false, priority: priority, actionUrl: url);
  }
}