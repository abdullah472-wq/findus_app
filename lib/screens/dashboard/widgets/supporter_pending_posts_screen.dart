import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'supporter_pending_requests_screen.dart';

class SupporterPendingPostsScreen extends StatelessWidget {
  const SupporterPendingPostsScreen({super.key});

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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Please login to view requests',
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                icon: const Icon(Icons.login),
                label: const Text('Go to Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('senderId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return FloatingScaffold(
      title: 'MY PENDING REQUESTS',
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppColors.brandMain,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snap) {
            if (snap.hasError) {
              final err = snap.error.toString();
              final needIndex = err.contains('FAILED_PRECONDITION') ||
                  err.toLowerCase().contains('index');
              return _ErrorBox(
                message: needIndex
                    ? 'Firestore index required.\nCheck console for link.'
                    : 'Error: $err',
                isDark: isDark,
              );
            }

            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.brandMain),
              );
            }

            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return _EmptyState(
                isDark: isDark,
                text: "No pending requests yet.",
              );
            }

            // ✅ Group by postId with fallback
            final Map<String, _PostGroup> groups = {};

            for (final d in docs) {
              final data = d.data();

              // ✅ Multiple fallbacks for postId
              String postId = (data['postId'] ??
                  data['originalRequestId'] ??
                  '').toString().trim();

              if (postId.isEmpty) {
                postId = d.id; // Use request ID itself
              }

              final title = (data['jobTitle'] ??
                  data['postTitle'] ??
                  'Untitled Job').toString();

              final location = (data['location'] ??
                  data['postLocation'] ??
                  'Not set').toString();

              groups.putIfAbsent(
                postId,
                    () => _PostGroup(
                  postId: postId,
                  title: title,
                  location: location,
                ),
              );
              groups[postId]!.pendingCount++;
            }

            final list = groups.values.toList()
              ..sort((a, b) => b.pendingCount.compareTo(a.pendingCount));

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: list.length,
              itemBuilder: (context, index) {
                return _PostGroupCard(
                  group: list[index],
                  isDark: isDark,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PostGroup {
  final String postId;
  final String title;
  final String location;
  int pendingCount;

  _PostGroup({
    required this.postId,
    required this.title,
    required this.location,
    this.pendingCount = 0,
  });
}

class _PostGroupCard extends StatelessWidget {
  final _PostGroup group;
  final bool isDark;

  const _PostGroupCard({required this.group, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.black54;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SupporterPendingRequestsScreen(
              postId: group.postId,
              postTitle: group.title,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.brandMain.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.work_outline,
                color: AppColors.brandMain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: subColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          group.location,
                          style: TextStyle(
                            color: subColor,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    "${group.pendingCount} Pending",
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: subColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final String text;

  const _EmptyState({required this.isDark, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white60 : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Workers will send requests to your posts",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/create_post');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Job Post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}