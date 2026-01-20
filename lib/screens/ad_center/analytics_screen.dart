// lib/screens/analytics/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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
      backgroundColor: AppColors.brandLight,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
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

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return _buildEmptyState();

          final stats = _calculateStats(docs);

          return ListView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildStatsCards(stats, isDark),
              const SizedBox(height: 25),
              _buildChartSection("Monthly Earnings", stats['monthlyEarnings'], isDark, true),
              const SizedBox(height: 25),
              _buildChartSection("Job Completion Trend", stats['monthlyJobs'], isDark, false),
              const SizedBox(height: 25),
              _buildPerformanceMetrics(stats, isDark),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  // চার্টগুলোকে একটি নির্দিষ্ট হাইট বা AspectRatio এর ভেতর রাখা হয়েছে যাতে Unbounded Height এরর না আসে
  Widget _buildChartSection(String title, Map data, bool isDark, bool isBarChart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          height: 220, // ✅ নির্দিষ্ট উচ্চতা দেওয়া হয়েছে
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: isBarChart
              ? _buildBarChart(Map<String, double>.from(data))
              : _buildLineChart(Map<String, int>.from(data)),
        ),
      ],
    );
  }

  // --- বাকি হেল্পার ফাংশনগুলো আগের মতোই থাকবে, কিন্তু charts গুলো SizedBox এর ভেতর থাকবে ---
  // (আগের দেওয়া Analytics কোডটি ব্যবহার করুন কিন্তু উপরের ListView structure টি ফলো করুন)

  Widget _buildBarChart(Map<String, double> data) {
    if (data.isEmpty) return const Center(child: Text("No data"));
    final sortedKeys = data.keys.toList()..sort();
    return BarChart(
      BarChartData(
        barGroups: sortedKeys.asMap().entries.map((e) => BarChartGroupData(
          x: e.key,
          barRods: [BarChartRodData(toY: data[e.value]!, color: AppColors.brandMain, width: 15)],
        )).toList(),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }

  Widget _buildLineChart(Map<String, int> data) {
    if (data.isEmpty) return const Center(child: Text("No data"));
    final sortedKeys = data.keys.toList()..sort();
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: sortedKeys.asMap().entries.map((e) => FlSpot(e.key.toDouble(), data[e.value]!.toDouble())).toList(),
            isCurved: true,
            color: Colors.green,
            belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
          ),
        ],
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }

  // (Stats Calculation, Error Box, and Formatters as provided before)
  Map<String, dynamic> _calculateStats(List<QueryDocumentSnapshot> docs) { /* logic same as before */ return {}; }
  Widget _buildError(String err) => Center(child: Text("Error: $err"));
  Widget _buildEmptyState() => const Center(child: Text("No data found"));
  Widget _buildStatsCards(Map stats, bool isDark) { return Container(); } // Replace with previous grid
  Widget _buildPerformanceMetrics(Map stats, bool isDark) { return Container(); } // Replace with previous list
  String _formatCompact(double n) => n.toString();
}