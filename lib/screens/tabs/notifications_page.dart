import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final TextEditingController _searchController =
  TextEditingController();
  String _query = '';

  // static / local notifications (সবসময় লিস্টের উপরে থাকবে)
  late final List<Map<String, dynamic>> _staticNotifications;

  @override
  void initState() {
    super.initState();
    _staticNotifications = [
      {
        'id': 'local_welcome',
        'source': 'local',
        'title': 'Welcome to FINDUS!',
        'body':
        'Thanks for joining. Complete your profile to get better matches and trust.',
        'createdAt':
        DateTime.now().subtract(const Duration(minutes: 1)),
        'isRead': false,
      },
      {
        'id': 'local_profile_tip',
        'source': 'local',
        'title': 'Tip: Complete your profile',
        'body':
        'Add your photo, skills and price so others can understand your work easily.',
        'createdAt':
        DateTime.now().subtract(const Duration(minutes: 5)),
        'isRead': false,
      },
      {
        'id': 'local_emergency',
        'source': 'local',
        'title': 'New: Emergency Help',
        'body':
        'Use the Emergency button on the map to quickly access important helplines.',
        'createdAt':
        DateTime.now().subtract(const Duration(minutes: 10)),
        'isRead': false,
      },
    ];
  }

  void _filterNotifications(String query) {
    setState(() {
      _query = query.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn =
        FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.brandLight,
        iconTheme:
        const IconThemeData(color: AppColors.brandDark),
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding:
            const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterNotifications,
              decoration: InputDecoration(
                hintText: "Search notifications...",
                prefixIcon: const Icon(Icons.search,
                    color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: isLoggedIn
                ? _buildLoggedInList()
                : _buildVisitorList(),
          ),
        ],
      ),
    );
  }

  /// Visitor (লগইন না করা user) → শুধু static notifications
  Widget _buildVisitorList() {
    final filteredStatic = _staticNotifications.where((n) {
      if (_query.isEmpty) return true;
      final title =
      (n['title'] ?? '').toString().toLowerCase();
      final body =
      (n['body'] ?? '').toString().toLowerCase();
      return title.contains(_query) || body.contains(_query);
    }).toList();

    if (filteredStatic.isEmpty) {
      return const Center(
        child: Text(
          "No notifications",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: filteredStatic.length,
      itemBuilder: (ctx, i) {
        final n = filteredStatic[i];
        final createdAt = n['createdAt'];
        String timeStr = '';
        if (createdAt is DateTime) {
          timeStr = TimeOfDay.fromDateTime(createdAt)
              .format(ctx);
        }

        final bool isRead = n['isRead'] == true;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
            AppColors.brandMain.withOpacity(0.1),
            child: const Icon(
              Icons.notifications_active,
              color: AppColors.brandMain,
              size: 20,
            ),
          ),
          title: Text(
            n['title'] ?? '',
            style: TextStyle(
              fontWeight: isRead
                  ? FontWeight.normal
                  : FontWeight.bold,
            ),
          ),
          subtitle: Text(
            timeStr,
            style: const TextStyle(
                fontSize: 12, color: Colors.grey),
          ),
          trailing: isRead
              ? null
              : const Icon(
            Icons.circle,
            size: 10,
            color: Colors.blue,
          ),
          onTap: () {
            // static notifications local, remote markAsRead নেই
          },
        );
      },
    );
  }

  /// Logged-in user → static + Firestore notifications একসাথে
  Widget _buildLoggedInList() {
    return StreamBuilder<
        List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: NotificationService.streamMyNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          // backend error হলে কেবল static দেখাই
          return _buildVisitorList();
        }

        final docs = snapshot.data ?? [];

        // Firestore থেকে data map এ পরিণত করছি
        final remote = docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'source': 'remote',
            'title': data['title'] ?? '',
            'body': data['body'] ?? '',
            'createdAt': data['createdAt'],
            'isRead': data['isRead'] == true,
          };
        }).toList();

        // Search filter static + remote – দুইদিকেই
        List<Map<String, dynamic>> staticFiltered =
        _staticNotifications.where((n) {
          if (_query.isEmpty) return true;
          final title =
          (n['title'] ?? '').toString().toLowerCase();
          final body =
          (n['body'] ?? '').toString().toLowerCase();
          return title.contains(_query) ||
              body.contains(_query);
        }).toList();

        List<Map<String, dynamic>> remoteFiltered =
        remote.where((n) {
          if (_query.isEmpty) return true;
          final title =
          (n['title'] ?? '').toString().toLowerCase();
          final body =
          (n['body'] ?? '').toString().toLowerCase();
          return title.contains(_query) ||
              body.contains(_query);
        }).toList();

        // static আগে, remote পরে
        final items = <Map<String, dynamic>>[
          ...staticFiltered,
          ...remoteFiltered,
        ];

        if (items.isEmpty) {
          return const Center(
            child: Text(
              "No notifications found",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final n = items[i];
            final bool isRead = n['isRead'] == true;
            final String source =
            (n['source'] ?? '').toString();

            String timeStr = '';
            final createdAt = n['createdAt'];
            if (createdAt is Timestamp) {
              timeStr = TimeOfDay.fromDateTime(
                  createdAt.toDate())
                  .format(ctx);
            } else if (createdAt is DateTime) {
              timeStr = TimeOfDay.fromDateTime(createdAt)
                  .format(ctx);
            }

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.brandMain
                    .withOpacity(0.1),
                child: const Icon(
                  Icons.notifications_active,
                  color: AppColors.brandMain,
                  size: 20,
                ),
              ),
              title: Text(
                n['title'] ?? '',
                style: TextStyle(
                  fontWeight: isRead
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
              subtitle: Text(
                timeStr,
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey),
              ),
              trailing: isRead
                  ? null
                  : const Icon(
                Icons.circle,
                size: 10,
                color: Colors.blue,
              ),
              onTap: () {
                if (source == 'remote') {
                  final String id =
                  (n['id'] ?? '').toString();
                  if (id.isNotEmpty) {
                    NotificationService.markAsRead(id);
                  }
                }
                // static এর জন্য কিছু করার দরকার নেই
              },
            );
          },
        );
      },
    );
  }
}