import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _refreshData() async {
    setState(() {});
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ✅ মেইন কন্টেন্ট
          RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              padding: const EdgeInsets.only(top: 80, left: 16, right: 16, bottom: 100), // উপরে বাটনের জন্য জায়গা রাখা হয়েছে
              physics: const BouncingScrollPhysics(),
              children: [
                // ১. পারফরম্যান্স কার্ড
                PerformanceCard(userId: _uid),

                const SizedBox(height: 25),

                // ২. ওয়ার্ক সামারি
                WorkSummarySection(userId: _uid),

                const SizedBox(height: 25),

                // ৩. পোস্ট করা পিন লিস্ট
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

          // ✅ ফ্লোটিং বাটনস (উপরে ডান কোণায়)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: Column(
              children: [
                // ২. অ্যানালিটিক্স বাটন
                _buildFloatingButton(
                  icon: Icons.analytics_outlined,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
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

  // ✅ ফ্লোটিং বাটন উইজেট
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