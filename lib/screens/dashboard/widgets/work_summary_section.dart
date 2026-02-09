import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/screens/dashboard/utils/dashboard_constants.dart';
import 'package:findus_app/screens/dashboard/widgets/pending_jobs_screen.dart';
import 'package:findus_app/screens/dashboard/widgets/supporter_pending_posts_screen.dart'; // Ensure this exists
import 'package:findus_app/screens/dashboard/widgets/stat_card.dart';
import 'package:findus_app/screens/rating_history_screen.dart';
import 'package:findus_app/screens/home_feed_screen.dart';

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
      return _WorkSummaryData(
        doneCount: 0,
        pendingCount: 0,
        avgRatingLabel: '0.0',
        responseRateLabel: 'N/A',
      );
    }

    try {
      final statsDoc = await FirebaseFirestore.instance
          .collection('user_stats')
          .doc(uid)
          .get();
      final stats = statsDoc.data() ?? {};

      final int jobsCompleted = _asInt(stats['jobsCompleted'], fallback: 0);
      final int hiresCompleted = _asInt(stats['hiresCompleted'], fallback: 0);
      final int doneCount = _isFinder ? jobsCompleted : hiresCompleted;

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

      final double avgRating = _asDouble(stats['avgRating'], fallback: 0.0);
      final double responseRate = _asDouble(
          stats['responseRate'], fallback: 95.0);

      return _WorkSummaryData(
        doneCount: doneCount,
        pendingCount: pendingCount,
        avgRatingLabel: avgRating > 0 ? avgRating.toStringAsFixed(1) : 'New',
        responseRateLabel: '${responseRate.toInt()}%',
      );
    } catch (e) {
      debugPrint('WorkSummary _load error: $e');
      return _WorkSummaryData(
        doneCount: 0,
        pendingCount: 0,
        avgRatingLabel: '-',
        responseRateLabel: '-',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    final doneTitle = _isFinder ? "Jobs Done" : "Hired Done";
    final pendingTitle = _isFinder ? "Pending Jobs" : "Pending Requests";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Work Summary",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 12),
        FutureBuilder<_WorkSummaryData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            if (snap.hasError) {
              return _ErrorBox(
                message: "Failed to load summary",
                onRetry: () => setState(() => _future = _load()),
                isDark: isDark,
              );
            }

            final data = snap.data!;

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: doneTitle,
                        value: data.doneCount.toString(),
                        icon: Icons.assignment_turned_in,
                        color: Colors.blue,
                        // ✅ Tab Switching Logic (No AppBar issue here)
                        onTap: () {
                          try {
                            HomeFeedScreen.goToTab(2); // Completed Tab Index
                          } catch (e) {
                            debugPrint("Navigation Error: $e");
                          }
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
                        // ✅ Pending Jobs Screen Open
                        onTap: () =>
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                _isFinder
                                    ? PendingJobsScreen(userId: widget.userId)
                                    : const SupporterPendingPostsScreen(),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: "Avg Rating",
                        value: data.avgRatingLabel,
                        icon: Icons.star_rounded,
                        color: Colors.purple,
                        onTap: () =>
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RatingHistoryScreen(
                                        targetUserId: widget.userId),
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: "Response Rate",
                        value: data.responseRateLabel,
                        icon: Icons.bolt,
                        color: Colors.teal,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Based on average reply time.')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _WorkSummaryData {
  final int doneCount;
  final int pendingCount;
  final String avgRatingLabel;
  final String responseRateLabel;

  _WorkSummaryData({
    required this.doneCount,
    required this.pendingCount,
    required this.avgRatingLabel,
    required this.responseRateLabel,
  });
}

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(message, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}