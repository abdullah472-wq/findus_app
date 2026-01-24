// lib/screens/analytics/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FloatingScaffold(
      title: 'ANALYTICS',
      backgroundColor: AppColors.bgBlue,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.all(16),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('completed_jobs')
            .where('participants', arrayContains: _uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _buildError(snapshot.error.toString());
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ডেটা না থাকলেও ক্যালকুলেশন চলবে (খালি লিস্ট পাস হবে)
          final docs = snapshot.data?.docs ?? [];
          final stats = _calculateStats(docs);

          return Column(
            children: [
              _buildStatsCards(stats, isDark),
              const SizedBox(height: 25),
              _buildChartSection(
                  "Monthly Earnings",
                  stats['monthlyEarnings'],
                  isDark,
                  isBarChart: true
              ),
              const SizedBox(height: 25),
              _buildChartSection(
                  "Job Completion Trend",
                  stats['monthlyJobs'],
                  isDark,
                  isBarChart: false
              ),
              const SizedBox(height: 25),
              _buildPerformanceMetrics(stats, isDark),
              const SizedBox(height: 50),
            ],
          );
        },
      ),
    );
  }

  // চার্ট সেকশন
  Widget _buildChartSection(String title, Map data, bool isDark, {required bool isBarChart}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          height: 250,
          padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: isBarChart
              ? _buildBarChart(Map<String, double>.from(data))
              : _buildLineChart(Map<String, int>.from(data)),
        ),
      ],
    );
  }

  // ✅ ফিক্সড বার চার্ট (ডেটা না থাকলেও ০ দেখাবে)
  Widget _buildBarChart(Map<String, double> data) {
    // ডেটা না থাকলে ডিফল্ট ০ সেট করা
    if (data.isEmpty) {
      data = {'Jan': 0, 'Feb': 0, 'Mar': 0, 'Apr': 0, 'May': 0, 'Jun': 0};
    }

    final keys = data.keys.toList();
    final values = data.values.toList();

    return BarChart(
      BarChartData(
        barGroups: List.generate(keys.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: values[index],
                color: AppColors.brandMain,
                width: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < keys.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(keys[value.toInt()], style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }

  // ✅ ফিক্সড লাইন চার্ট (ডেটা না থাকলেও ০ দেখাবে)
  Widget _buildLineChart(Map<String, int> data) {
    if (data.isEmpty) {
      data = {'Jan': 0, 'Feb': 0, 'Mar': 0, 'Apr': 0, 'May': 0, 'Jun': 0};
    }

    final keys = data.keys.toList();
    final values = data.values.toList();

    return LineChart(
      LineChartData(
        minY: 0, // 0 থেকে শুরু হবে
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(keys.length, (index) {
              return FlSpot(index.toDouble(), values[index].toDouble());
            }),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.1)
            ),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < keys.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(keys[value.toInt()], style: const TextStyle(fontSize: 10)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
      ),
    );
  }

  // ক্যালকুলেশন লজিক (০ রিটার্ন করবে যদি ডেটা না থাকে)
  Map<String, dynamic> _calculateStats(List<QueryDocumentSnapshot> docs) {
    double totalEarned = 0;
    int jobsCompleted = docs.length;
    double totalRating = 0;
    int ratedJobs = 0;

    Map<String, double> monthlyEarnings = {};
    Map<String, int> monthlyJobs = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] ?? 0).toDouble();
      final rating = (data['rating'] ?? 0).toDouble();
      final Timestamp? ts = data['completedAt'];

      totalEarned += amount;
      if (rating > 0) {
        totalRating += rating;
        ratedJobs++;
      }

      if (ts != null) {
        final date = ts.toDate();
        final monthKey = DateFormat('MMM').format(date); // e.g. "Jan"

        monthlyEarnings[monthKey] = (monthlyEarnings[monthKey] ?? 0) + amount;
        monthlyJobs[monthKey] = (monthlyJobs[monthKey] ?? 0) + 1;
      }
    }

    // যদি কোনো ডেটা না থাকে, ডিফল্ট ০ ভ্যালু দিয়ে ম্যাপ পূরণ করা (গত ৬ মাস)
    if (monthlyEarnings.isEmpty) {
      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        final month = DateFormat('MMM').format(DateTime(now.year, now.month - i, 1));
        monthlyEarnings[month] = 0.0;
        monthlyJobs[month] = 0;
      }
    }

    return {
      'totalEarned': totalEarned,
      'jobsCompleted': jobsCompleted,
      'avgRating': ratedJobs > 0 ? (totalRating / ratedJobs) : 0.0,
      'monthlyEarnings': monthlyEarnings,
      'monthlyJobs': monthlyJobs,
    };
  }

  // স্ট্যাটস কার্ড
  Widget _buildStatsCards(Map stats, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _statCard("Total Earned", "৳${stats['totalEarned'].toInt()}", Icons.attach_money, Colors.green),
        _statCard("Jobs Done", "${stats['jobsCompleted']}", Icons.work_outline, Colors.blue),
        _statCard("Avg Rating", "${stats['avgRating'].toStringAsFixed(1)} ★", Icons.star_border, Colors.amber),
        _statCard("Completion Rate", "100%", Icons.check_circle_outline, Colors.purple),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(Map stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Performance Metrics", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _metricRow("Response Time", "Fast (< 1hr)"),
          _metricRow("On-time Arrival", "98%"),
          _metricRow("Profile Visits", "120+ this week"),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildError(String err) => Center(child: Text("Error: $err"));
}