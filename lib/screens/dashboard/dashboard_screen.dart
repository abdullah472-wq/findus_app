// lib/screens/tabs/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/dashboard/widgets/performance_card.dart';
import 'package:findus_app/screens/dashboard/widgets/work_summary_section.dart';
import 'package:findus_app/screens/dashboard/widgets/posted_pins_list.dart';
import 'package:findus_app/screens/explore/notifications_page.dart';
import 'package:findus_app/screens/ad_center/analytics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      body: Stack(
        children: [
          // Main Content (with padding for floating app bar)
          Padding(
            padding: EdgeInsets.only(top: appBarHeight + 10),
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView(
                padding: const EdgeInsets.all(15),
                physics: const BouncingScrollPhysics(),
                children: [
                  // ১. পারফরম্যান্স কার্ড
                  PerformanceCard(isDark: isDark, userId: '',),

                  const SizedBox(height: 25),

                  // ২. ওয়ার্ক সামারি
                  WorkSummarySection(userId: _uid),

                  const SizedBox(height: 25),

                  // ৩. নিজের পোস্ট করা পিন লিস্ট
                  const Text(
                      "Your Posted Pins",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 12),
                  PostedPinsList(userId: _uid),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Floating App Bar (Unified Profile Style)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.brandLight, AppColors.brandLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          // Back Button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Title
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'DASHBOARD',
                                style: TextStyle(
                                  color: AppColors.brandDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),

                          // Analytics Button
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AnalyticsScreen(),
                                ),
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.analytics_outlined,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),

                          // Notifications Button with Badge
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsPage(),
                                ),
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  const Icon(
                                    Icons.notifications_none_rounded,
                                    size: 20,
                                    color: Colors.black,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {});
    await Future.delayed(const Duration(seconds: 1));
  }
}