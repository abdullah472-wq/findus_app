// lib/screens/dashboard/widgets/work_summary_section.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:findus_app/screens/dashboard/utils/dashboard_constants.dart';
import 'package:findus_app/screens/dashboard/widgets/pending_jobs_screen.dart';
import 'package:findus_app/screens/dashboard/widgets/stat_card.dart';
import 'package:findus_app/screens/rating_history_screen.dart';
import 'package:findus_app/screens/tabs/completed_work_tab.dart';

class WorkSummarySection extends StatefulWidget {
  final String userId;
  const WorkSummarySection({super.key, required this.userId});

  @override
  State<WorkSummarySection> createState() => _WorkSummarySectionState();
}

class _WorkSummarySectionState extends State<WorkSummarySection> {
  late Future<_WorkSummaryData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant WorkSummarySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      setState(() {
        _future = _load();
      });
    }
  }

  // ✅ নিরাপদ কাউন্ট লজিক (ওয়েব এবং ইন্টারনাল এরর হ্যান্ডেল করবে)
  Future<int> _fetchCountSafe(Query query) async {
    try {
      // প্রথমে দ্রুত কাউন্ট করার চেষ্টা করবে
      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      // যদি count() এরর দেয় (ওয়েবে যেটা হচ্ছে), তবে সাধারণ get() করে দৈর্ঘ্য নিবে
      debugPrint("Count failed, using fallback get(): $e");
      final snapshot = await query.get();
      return snapshot.docs.length;
    }
  }

  Future<_WorkSummaryData> _load() async {
    final uid = widget.userId;
    if (uid.isEmpty) throw Exception('User not found');

    final doneQuery = FirebaseFirestore.instance
        .collection('completed_jobs')
        .where('participants', arrayContains: uid);

    final pendingQuery = FirebaseFirestore.instance
        .collection('hire_requests')
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: DashboardConstants.pendingStatus);

    // ✅ নিরাপদ ফাংশন কল
    final int doneCount = await _fetchCountSafe(doneQuery);
    final int pendingCount = await _fetchCountSafe(pendingQuery);

    return _WorkSummaryData(
      doneCount: doneCount,
      pendingCount: pendingCount,
      avgRatingLabel: '4.8', // এখানে আপনার রেটিং লজিক বসাতে পারেন
      responseRateLabel: '95%',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) {
      return const Text('User not found');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Work Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        FutureBuilder<_WorkSummaryData>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              final err = snap.error.toString();
              final isIndexError = err.contains('FAILED_PRECONDITION') || err.contains('index');

              return _ErrorBox(
                message: isIndexError
                    ? 'Firestore index required.\nConsole-এ গিয়ে index create করুন।'
                    : 'Failed to load work summary.\nCheck your internet or Firebase rules.',
                onRetry: () {
                  setState(() {
                    _future = _load();
                  });
                },
              );
            }

            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            final data = snap.data!;

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: "Jobs Done",
                        value: data.doneCount.toString(),
                        icon: Icons.assignment_turned_in,
                        color: Colors.blue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CompletedWorkTab()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        title: "Pending Jobs",
                        value: data.pendingCount.toString(),
                        icon: Icons.hourglass_empty,
                        color: Colors.orange,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PendingJobsScreen(userId: widget.userId),
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
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RatingHistoryScreen(targetUserId: widget.userId),
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
                            const SnackBar(content: Text('Response rate details coming soon')),
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

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notice', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(color: Colors.red, fontSize: 12)),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}