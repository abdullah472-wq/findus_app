import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/user_role_service.dart';

// Widgets
import 'package:findus_app/screens/dashboard/widgets/performance_card.dart';
import 'package:findus_app/screens/dashboard/widgets/work_summary_section.dart';
import 'package:findus_app/screens/dashboard/widgets/posted_pins_list.dart';

// Screens
import 'package:findus_app/screens/ad_center/analytics_screen.dart';
import 'package:findus_app/screens/dashboard/my_applications_screen.dart'; // ✅ NEW

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  String? _userRole;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    setState(() => _isLoading = true);

    try {
      final role = await UserRoleService.getCurrentUserRole();

      if (mounted) {
        setState(() {
          _userRole = role;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard role load error: $e');

      if (mounted) {
        setState(() {
          _userRole = 'finder';
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadUserRole();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    // ✅ Not logged in
    if (_uid.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 80,
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                "Please login to view dashboard",
                style: TextStyle(fontSize: 16, color: textColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                icon: const Icon(Icons.login),
                label: const Text('Go to Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Loading state
    if (_isLoading || _userRole == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.brandMain),
        ),
      );
    }

    final bool isFinder = UserRoleService.isFinder(_userRole!);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics_outlined, color: textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AnalyticsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.brandMain,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            // ✅ Error banner
            if (_hasError)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failed to load user role. Using default mode.',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ✅ 1) Performance Card
            PerformanceCard(
              userId: _uid,
              userRole: _userRole!,
            ),

            const SizedBox(height: 20),

            // ✅ 2) Quick Actions Row (NEW!)
            _buildQuickActionsRow(context, isDark, isFinder),

            const SizedBox(height: 20),

            // ✅ 3) My Applications Card (NEW! - শুধু Finder দের জন্য)
            if (isFinder) ...[
              _MyApplicationsCard(userId: _uid, isDark: isDark),
              const SizedBox(height: 20),
            ],

            // ✅ 4) Work Summary
            WorkSummarySection(
              userId: _uid,
              userRole: _userRole!,
            ),

            const SizedBox(height: 25),

            // ✅ 5) Posted Pins Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Your Posted Pins",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/create_pin');
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandMain,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            PostedPinsList(userId: _uid),
          ],
        ),
      ),
    );
  }

  // ✅ Quick Actions Row
  Widget _buildQuickActionsRow(BuildContext context, bool isDark, bool isFinder) {
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Row(
      children: [
        // My Applications (Finder only)
        if (isFinder)
          Expanded(
            child: _QuickActionButton(
              icon: Icons.description_outlined,
              label: "My Applications",
              color: Colors.blue,
              cardColor: cardColor,
              textColor: textColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyApplicationsScreen(userId: _uid),
                  ),
                );
              },
            ),
          ),

        if (isFinder) const SizedBox(width: 12),

        // Analytics
        Expanded(
          child: _QuickActionButton(
            icon: Icons.analytics_outlined,
            label: "Analytics",
            color: Colors.purple,
            cardColor: cardColor,
            textColor: textColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AnalyticsScreen(),
                ),
              );
            },
          ),
        ),

        const SizedBox(width: 12),

        // Reviews / Ratings
        Expanded(
          child: _QuickActionButton(
            icon: Icons.star_outline,
            label: "My Reviews",
            color: Colors.amber,
            cardColor: cardColor,
            textColor: textColor,
            onTap: () {
              Navigator.pushNamed(context, '/rating_history');
            },
          ),
        ),
      ],
    );
  }
}

// ✅ Quick Action Button Widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color cardColor;
  final Color textColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.cardColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ My Applications Card Widget (Detail View)
class _MyApplicationsCard extends StatelessWidget {
  final String userId;
  final bool isDark;

  const _MyApplicationsCard({
    required this.userId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.black54;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('hire_requests')
          .where('senderId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        int pending = 0;
        int approved = 0;
        int rejected = 0;
        int total = 0;

        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString().toLowerCase();
            total++;

            if (status == 'pending') {
              pending++;
            } else if (status == 'approved' || status == 'ongoing') {
              approved++;
            } else if (status == 'rejected') {
              rejected++;
            }
          }
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MyApplicationsScreen(userId: userId),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "My Applications",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              "$total total applications",
                              style: TextStyle(
                                fontSize: 12,
                                color: subColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: subColor,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Status counts
                Row(
                  children: [
                    _StatusChip(
                      label: "Pending",
                      count: pending,
                      color: Colors.orange,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: "Approved",
                      count: approved,
                      color: Colors.green,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: "Rejected",
                      count: rejected,
                      color: Colors.red,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ✅ Status Chip Widget
class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isDark;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}