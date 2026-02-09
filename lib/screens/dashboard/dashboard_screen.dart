import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:findus_app/constants/app_colors.dart';

// Widgets
import 'package:findus_app/screens/dashboard/widgets/performance_card.dart';
import 'package:findus_app/screens/dashboard/widgets/work_summary_section.dart';
import 'package:findus_app/screens/dashboard/widgets/posted_pins_list.dart';

// Screens
import 'package:findus_app/screens/ad_center/analytics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _refreshData() async {
    setState(() {});
    await Future.delayed(const Duration(seconds: 1));
  }

  // ✅ Role fetch (finder / maker)
  Future<String> _getUserRole() async {
    if (_uid.isEmpty) return 'finder';
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      return (doc.data()?['userRole'] ?? 'finder').toString().toLowerCase();
    } catch (_) {
      return 'finder';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    if (_uid.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: Text("Please login again")),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: const EdgeInsets.only(top: 80, left: 16, right: 16, bottom: 100),
              physics: const BouncingScrollPhysics(),
              children: [
                // ✅ ১) PerformanceCard with role
                FutureBuilder<String>(
                  future: _getUserRole(),
                  builder: (context, snap) {
                    final role = snap.data ?? 'finder'; // 'finder' or 'maker'
                    return PerformanceCard(
                      userId: _uid,
                      userRole: role,
                    );
                  },
                ),

                const SizedBox(height: 25),

                // ✅ ২) Work summary
                FutureBuilder<String>(
                  future: _getUserRole(),
                  builder: (context, snap) {
                    final role = snap.data ?? 'finder';
                    return WorkSummarySection(
                      userId: _uid,
                      userRole: role,
                    );
                  },
                ),

                const SizedBox(height: 25),

                // ✅ ৩) Posted pins
                Text(
                  "Your Posted Pins",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                PostedPinsList(userId: _uid),
              ],
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: Column(
              children: [
                _buildFloatingButton(
                  icon: Icons.analytics_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                  ),
                  isDark: isDark,
                  hasBadge: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    bool hasBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                icon,
                size: 22,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (hasBadge)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}