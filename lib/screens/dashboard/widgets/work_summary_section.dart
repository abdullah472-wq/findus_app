import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/dashboard/utils/dashboard_constants.dart';
import 'package:findus_app/screens/dashboard/widgets/pending_jobs_screen.dart';
import 'package:findus_app/screens/dashboard/widgets/supporter_pending_posts_screen.dart';
import 'package:findus_app/screens/dashboard/widgets/stat_card.dart';
import 'package:findus_app/screens/dashboard/my_applications_screen.dart';
import 'package:findus_app/screens/rating_history_screen.dart';
import 'package:findus_app/screens/tabs/completed_work_tab.dart';
import 'package:findus_app/screens/tabs/work_in_progress_tab.dart';

class WorkSummarySection extends StatefulWidget {
  final String userId;
  final String userRole;

  const WorkSummarySection({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<WorkSummarySection> createState() => _WorkSummarySectionState();
}

class _WorkSummarySectionState extends State<WorkSummarySection> {
  late Future<_WorkSummaryData> _future;

  bool get _isFinder =>
      widget.userRole.toLowerCase() == 'finder' ||
          widget.userRole.toLowerCase() == 'worker';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant WorkSummarySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.userRole != widget.userRole) {
      setState(() {
        _future = _load();
      });
    }
  }

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  Future<int> _fetchCountSafe(Query query) async {
    try {
      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      try {
        final snapshot = await query.get();
        return snapshot.docs.length;
      } catch (e2) {
        return 0;
      }
    }
  }

  Future<_WorkSummaryData> _load() async {
    final uid = widget.userId;
    if (uid.isEmpty) {
      return _WorkSummaryData.empty();
    }

    try {
      // 1. Get user stats
      final statsDoc = await FirebaseFirestore.instance
          .collection('user_stats')
          .doc(uid)
          .get();
      final stats = statsDoc.data() ?? {};

      // 2. Completed count
      final int jobsCompleted = _asInt(stats['jobsCompleted']);
      final int hiresCompleted = _asInt(stats['hiresCompleted']);
      final int doneCount = _isFinder ? jobsCompleted : hiresCompleted;

      // 3. Pending count
      late final Query pendingQuery;
      if (_isFinder) {
        pendingQuery = FirebaseFirestore.instance
            .collection('hire_requests')
            .where('receiverId', isEqualTo: uid)
            .where('status', isEqualTo: DashboardConstants.pendingStatus);
      } else {
        pendingQuery = FirebaseFirestore.instance
            .collection('hire_requests')
            .where('senderId', isEqualTo: uid)
            .where('status', isEqualTo: DashboardConstants.pendingStatus);
      }
      final int pendingCount = await _fetchCountSafe(pendingQuery);

      // ✅ 4. Ongoing count
      final int ongoingCount = await _fetchCountSafe(
        FirebaseFirestore.instance
            .collection('ongoing_jobs')
            .where('participants', arrayContains: uid)
            .where('status', isEqualTo: 'ongoing'),
      );

      // ✅ 5. My Applications count (Finder only)
      int myApplicationsCount = 0;
      if (_isFinder) {
        myApplicationsCount = await _fetchCountSafe(
          FirebaseFirestore.instance
              .collection('hire_requests')
              .where('senderId', isEqualTo: uid),
        );
      }

      // 6. Rating & Response Rate
      final double avgRating = _asDouble(stats['avgRating']);
      final int reviewsCount = _asInt(stats['reviewsCount']);
      final double responseRate = _asDouble(stats['responseRate']);

      return _WorkSummaryData(
        doneCount: doneCount,
        pendingCount: pendingCount,
        ongoingCount: ongoingCount,
        myApplicationsCount: myApplicationsCount,
        avgRating: avgRating,
        reviewsCount: reviewsCount,
        responseRate: responseRate,
      );
    } catch (e) {
      debugPrint('WorkSummary _load error: $e');
      return _WorkSummaryData.empty();
    }
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Work Summary",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            // Refresh button
            IconButton(
              onPressed: _refresh,
              icon: Icon(
                Icons.refresh,
                color: isDark ? Colors.white54 : Colors.grey,
                size: 20,
              ),
              tooltip: 'Refresh',
            ),
          ],
        ),

        const SizedBox(height: 12),

        FutureBuilder<_WorkSummaryData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snap.hasError) {
              return _ErrorBox(
                message: "Failed to load summary",
                onRetry: _refresh,
                isDark: isDark,
              );
            }

            final data = snap.data!;
            return _buildContent(context, data, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.brandMain,
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      _WorkSummaryData data,
      bool isDark,
      ) {
    // Dynamic titles based on role
    final doneTitle = _isFinder ? "Jobs Done" : "Hires Done";
    final pendingTitle = _isFinder ? "Pending Jobs" : "Pending Requests";
    final ongoingTitle = _isFinder ? "In Progress" : "Ongoing Hires";

    return Column(
      children: [
        // ✅ Row 1: Done & Pending
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: doneTitle,
                value: data.doneCount.toString(),
                icon: Icons.check_circle_outline,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: Text(doneTitle)),
                        body: const CompletedWorkTab(),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: pendingTitle,
                value: data.pendingCount.toString(),
                icon: Icons.hourglass_empty,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _isFinder
                          ? PendingJobsScreen(userId: widget.userId)
                          : const SupporterPendingPostsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ✅ Row 2: Ongoing & Applications/Rating
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: ongoingTitle,
                value: data.ongoingCount.toString(),
                icon: Icons.work_outline,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: Text(ongoingTitle)),
                        body: const WorkInProgressTab(),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _isFinder
              // Finder: My Applications
                  ? StatCard(
                title: "My Applications",
                value: data.myApplicationsCount.toString(),
                icon: Icons.description_outlined,
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyApplicationsScreen(
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
              )
              // Supporter: Rating
                  : StatCard(
                title: "Avg Rating",
                value: data.avgRating > 0
                    ? data.avgRating.toStringAsFixed(1)
                    : 'New',
                subtitle: data.reviewsCount > 0
                    ? '${data.reviewsCount} reviews'
                    : null,
                icon: Icons.star_rounded,
                color: Colors.amber,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RatingHistoryScreen(
                        targetUserId: widget.userId,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ✅ Row 3: Rating & Response Rate
        Row(
          children: [
            // Rating (Finder)
            if (_isFinder)
              Expanded(
                child: StatCard(
                  title: "Avg Rating",
                  value: data.avgRating > 0
                      ? data.avgRating.toStringAsFixed(1)
                      : 'New',
                  subtitle: data.reviewsCount > 0
                      ? '${data.reviewsCount} reviews'
                      : null,
                  icon: Icons.star_rounded,
                  color: Colors.amber,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RatingHistoryScreen(
                          targetUserId: widget.userId,
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (_isFinder) const SizedBox(width: 12),

            // Response Rate
            Expanded(
              child: StatCard(
                title: "Response Rate",
                value: data.responseRate > 0
                    ? '${data.responseRate.toInt()}%'
                    : 'N/A',
                icon: Icons.bolt,
                color: Colors.teal,
                onTap: () {
                  _showResponseRateInfo(context);
                },
              ),
            ),

            // Spacer for Supporter (to balance the row)
            if (!_isFinder) ...[
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ],
        ),
      ],
    );
  }

  void _showResponseRateInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Response Rate",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Your response rate is calculated based on how quickly you respond to job requests and messages.",
            ),
            const SizedBox(height: 12),
            const Text(
              "Tips to improve:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("• Reply to messages within 1 hour"),
            const Text("• Accept or reject pending requests promptly"),
            const Text("• Keep your profile active"),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ✅ Data Model
class _WorkSummaryData {
  final int doneCount;
  final int pendingCount;
  final int ongoingCount;
  final int myApplicationsCount;
  final double avgRating;
  final int reviewsCount;
  final double responseRate;

  _WorkSummaryData({
    required this.doneCount,
    required this.pendingCount,
    required this.ongoingCount,
    required this.myApplicationsCount,
    required this.avgRating,
    required this.reviewsCount,
    required this.responseRate,
  });

  factory _WorkSummaryData.empty() {
    return _WorkSummaryData(
      doneCount: 0,
      pendingCount: 0,
      ongoingCount: 0,
      myApplicationsCount: 0,
      avgRating: 0.0,
      reviewsCount: 0,
      responseRate: 0.0,
    );
  }
}

// ✅ Error Box
class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorBox({
    required this.message,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.red.withOpacity(0.3) : Colors.red.shade100,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}