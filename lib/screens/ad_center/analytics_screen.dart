// lib/screens/ad_center/analytics_screen.dart

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
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final subTextColor = isDark ? Colors.white54 : Colors.grey;

    return FloatingScaffold(
      title: 'ANALYTICS',
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.all(16),

      // ✅ এখানে একইসাথে users এবং completed_jobs দুটি কালেকশন থেকে ডাটা নেওয়া হচ্ছে
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brandMain));
          }

          final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('completed_jobs')
                .where('participants', arrayContains: _uid)
                .snapshots(),
            builder: (context, jobSnapshot) {
              if (jobSnapshot.hasError) return _buildError(jobSnapshot.error.toString(), textColor);

              final docs = jobSnapshot.data?.docs ?? [];
              final stats = _calculateStats(docs, userData);

              return Column(
                children: [
                  // ১. স্ট্যাটস গ্রিড (আপডেটেড: ৬টি কার্ড)
                  _buildStatsCards(stats, isDark, cardColor, textColor, subTextColor),

                  const SizedBox(height: 25),

                  // ২. আর্নিং চার্ট
                  _buildChartSection(
                      "Monthly Earnings",
                      stats['monthlyEarnings'],
                      isDark,
                      cardColor,
                      textColor,
                      isBarChart: true
                  ),

                  const SizedBox(height: 25),

                  // ৩. জব ট্রেন্ড
                  _buildChartSection(
                      "Job Completion Trend",
                      stats['monthlyJobs'],
                      isDark,
                      cardColor,
                      textColor,
                      isBarChart: false
                  ),

                  const SizedBox(height: 25),

                  // ৪. পারফরম্যান্স মেট্রিক্স
                  _buildPerformanceMetrics(stats, isDark, cardColor, textColor, subTextColor),

                  const SizedBox(height: 50),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --- Chart Section ---
  Widget _buildChartSection(String title, Map data, bool isDark, Color cardColor, Color textColor, {required bool isBarChart}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
        const SizedBox(height: 12),
        Container(
          height: 250,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
          decoration: BoxDecoration(
            color: cardColor,
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
              ? _buildBarChart(Map<String, double>.from(data), isDark, textColor)
              : _buildLineChart(Map<String, int>.from(data), isDark, textColor),
        ),
      ],
    );
  }

  Widget _buildBarChart(Map<String, double> data, bool isDark, Color textColor) {
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
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: (values.reduce((a, b) => a > b ? a : b) * 1.2),
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                ),
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
                    child: Text(keys[value.toInt()], style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7))),
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
        gridData: FlGridData(show: false),
      ),
    );
  }

  Widget _buildLineChart(Map<String, int> data, bool isDark, Color textColor) {
    if (data.isEmpty) {
      data = {'Jan': 0, 'Feb': 0, 'Mar': 0, 'Apr': 0, 'May': 0, 'Jun': 0};
    }
    final keys = data.keys.toList();
    final values = data.values.toList();

    return LineChart(
      LineChartData(
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(keys.length, (index) {
              return FlSpot(index.toDouble(), values[index].toDouble());
            }),
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.15)),
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
                    child: Text(keys[value.toInt()], style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7))),
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
            color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
      ),
    );
  }

  // --- Calculation Logic (Updated with User Data) ---
  Map<String, dynamic> _calculateStats(List<QueryDocumentSnapshot> docs, Map<String, dynamic> userData) {
    double totalEarned = 0;
    int jobsCompleted = docs.length;
    double totalRating = 0;
    int ratedJobs = 0;

    Map<String, double> monthlyEarnings = {};
    Map<String, int> monthlyJobs = {};

    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final month = DateFormat('MMM').format(DateTime(now.year, now.month - i, 1));
      monthlyEarnings[month] = 0.0;
      monthlyJobs[month] = 0;
    }

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
        final monthKey = DateFormat('MMM').format(date);
        if (monthlyEarnings.containsKey(monthKey)) {
          monthlyEarnings[monthKey] = (monthlyEarnings[monthKey] ?? 0) + amount;
          monthlyJobs[monthKey] = (monthlyJobs[monthKey] ?? 0) + 1;
        }
      }
    }

    // ✅ ইম্প্রেশন এবং ভিউ ডাটা নেওয়া হচ্ছে
    final int impressions = _toInt(userData['totalImpressions'] ?? userData['impressions']);
    final int profileViews = _toInt(userData['profileViews']);

    return {
      'totalEarned': totalEarned,
      'jobsCompleted': jobsCompleted,
      'avgRating': ratedJobs > 0 ? (totalRating / ratedJobs) : 0.0,
      'monthlyEarnings': monthlyEarnings,
      'monthlyJobs': monthlyJobs,
      'impressions': impressions, // ✅ Added
      'profileViews': profileViews, // ✅ Added
    };
  }

  // --- Stats Cards (Updated) ---
  Widget _buildStatsCards(Map stats, bool isDark, Color cardColor, Color textColor, Color subTextColor) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _statCard("Total Earned", "৳${stats['totalEarned'].toInt()}", Icons.attach_money, Colors.green, cardColor, textColor, subTextColor),
        _statCard("Jobs Done", "${stats['jobsCompleted']}", Icons.work_outline, Colors.blue, cardColor, textColor, subTextColor),
        _statCard("Impressions", _format(stats['impressions']), Icons.visibility_outlined, Colors.purpleAccent, cardColor, textColor, subTextColor), // ✅ New
        _statCard("Profile Views", _format(stats['profileViews']), Icons.person_search_outlined, Colors.teal, cardColor, textColor, subTextColor), // ✅ New
        _statCard("Avg Rating", "${stats['avgRating'].toStringAsFixed(1)} ★", Icons.star_border, Colors.amber, cardColor, textColor, subTextColor),
        _statCard("Completion Rate", "100%", Icons.check_circle_outline, Colors.pinkAccent, cardColor, textColor, subTextColor),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          Text(title, style: TextStyle(fontSize: 12, color: subTextColor)),
        ],
      ),
    );
  }

  // --- Performance Metrics (Updated) ---
  Widget _buildPerformanceMetrics(Map stats, bool isDark, Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Performance Metrics", style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
          const SizedBox(height: 10),
          _metricRow("Impressions (Reach)", "${_format(stats['impressions'])} users", textColor, subTextColor),
          _metricRow("Profile Click Rate", "4.5%", textColor, subTextColor), // Example calculation
          _metricRow("Response Time", "Fast (< 1hr)", textColor, subTextColor),
          _metricRow("On-time Arrival", "98%", textColor, subTextColor),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String val, Color textColor, Color subTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: subTextColor, fontSize: 13)),
          Text(val, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13)),
        ],
      ),
    );
  }

  int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  String _format(dynamic val) {
    int n = _toInt(val);
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}K";
    return n.toString();
  }

  Widget _buildError(String err, Color textColor) => Center(child: Text("Error: $err", style: TextStyle(color: textColor)));
}