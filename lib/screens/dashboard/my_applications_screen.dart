// lib/screens/dashboard/my_applications_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/widgets/universal_worker_card.dart';

class MyApplicationsScreen extends StatefulWidget {
  final String userId;

  const MyApplicationsScreen({super.key, required this.userId});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: 'MY APPLICATIONS',
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: Column(
        children: [
          // ✅ Tab Bar
          Container(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.brandMain,
              unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
              indicatorColor: AppColors.brandMain,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              tabs: const [
                Tab(text: 'ALL'),
                Tab(text: 'PENDING'),
                Tab(text: 'APPROVED'),
                Tab(text: 'REJECTED'),
              ],
            ),
          ),

          // ✅ Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ApplicationsList(
                  userId: widget.userId,
                  statusFilter: null,
                  isDark: isDark,
                ),
                _ApplicationsList(
                  userId: widget.userId,
                  statusFilter: 'pending',
                  isDark: isDark,
                ),
                _ApplicationsList(
                  userId: widget.userId,
                  statusFilter: 'approved',
                  isDark: isDark,
                ),
                _ApplicationsList(
                  userId: widget.userId,
                  statusFilter: 'rejected',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationsList extends StatelessWidget {
  final String userId;
  final String? statusFilter;
  final bool isDark;

  const _ApplicationsList({
    required this.userId,
    required this.statusFilter,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('senderId', isEqualTo: userId);

    if (statusFilter != null) {
      if (statusFilter == 'approved') {
        // Include both 'approved' and 'ongoing'
        query = query.where('status', whereIn: ['approved', 'ongoing']);
      } else {
        query = query.where('status', isEqualTo: statusFilter);
      }
    }

    query = query.orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          final err = snap.error.toString();
          final needIndex = err.contains('FAILED_PRECONDITION') ||
              err.toLowerCase().contains('index');

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    needIndex ? Icons.build_rounded : Icons.error_outline,
                    size: 60,
                    color: needIndex ? Colors.orange : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    needIndex
                        ? "Firestore index required"
                        : "Something went wrong",
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.brandMain),
          );
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
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
                  statusFilter == null
                      ? "No applications yet"
                      : "No ${statusFilter} applications",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white60 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Apply to jobs to see them here",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          physics: const BouncingScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            return _ApplicationCard(
              doc: docs[i],
              isDark: isDark,
            );
          },
        );
      },
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool isDark;

  const _ApplicationCard({
    required this.doc,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    final receiverId = (data['receiverId'] ?? '').toString();
    final receiverName = (data['receiverName'] ?? 'Employer').toString();
    final receiverImage = (data['receiverImage'] ?? '').toString();
    final receiverRole = (data['receiverRole'] ?? 'Supporter').toString();

    final jobTitle = (data['jobTitle'] ?? 'Job').toString();
    final location = (data['location'] ?? 'Not set').toString();
    final price = data['price'] ?? data['offerPrice'] ?? 'N/A';
    final status = (data['status'] ?? 'pending').toString().toLowerCase();

    // Status display
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'approved':
      case 'ongoing':
        statusColor = Colors.green;
        statusText = status == 'ongoing' ? 'ONGOING' : 'APPROVED';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'REJECTED';
        statusIcon = Icons.cancel;
        break;
      case 'withdrawn':
        statusColor = Colors.grey;
        statusText = 'WITHDRAWN';
        statusIcon = Icons.undo;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'COMPLETED';
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'PENDING';
        statusIcon = Icons.hourglass_top;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Title Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    jobTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Employer Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: receiverImage.isNotEmpty
                      ? NetworkImage(receiverImage)
                      : null,
                  backgroundColor: Colors.grey.shade200,
                  child: receiverImage.isEmpty
                      ? Icon(
                    Icons.person,
                    color: Colors.grey.shade400,
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receiverName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.black45,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "৳$price",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.brandMain,
                      ),
                    ),
                    Text(
                      _getTimeAgo(data['createdAt']),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return '';
    }

    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) return "${(diff.inDays / 30).floor()}mo ago";
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }
}