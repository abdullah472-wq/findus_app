// lib/screens/dashboard/widgets/performance_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:rxdart/rxdart.dart'; // ✅ Add this package

class PerformanceCard extends StatelessWidget {
  final String userId;
  final String userRole;

  const PerformanceCard({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey;

    if (userId.isEmpty) {
      return _buildEmptyCard(cardColor, textColor, isDark);
    }

    // ✅ Combined streams using RxDart
    return StreamBuilder<_CombinedData>(
      stream: _getCombinedStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading(cardColor, isDark);
        }

        if (snapshot.hasError) {
          debugPrint('PerformanceCard error: ${snapshot.error}');
          return _buildErrorCard(cardColor, textColor, isDark);
        }

        final combinedData = snapshot.data ?? _CombinedData({}, {});
        return _buildMainCard(
          context,
          combinedData: combinedData,
          isDark: isDark,
          cardColor: cardColor,
          textColor: textColor,
          subTextColor: subTextColor,
        );
      },
    );
  }

  // ✅ Properly combined stream using RxDart
  Stream<_CombinedData> _getCombinedStream() {
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() ?? {} : <String, dynamic>{});

    final statsStream = FirebaseFirestore.instance
        .collection('user_stats')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() ?? {} : <String, dynamic>{});

    // ✅ CombineLatest - উভয় stream থেকে latest data নিবে
    return Rx.combineLatest2<Map<String, dynamic>, Map<String, dynamic>, _CombinedData>(
      usersStream,
      statsStream,
          (userData, statsData) => _CombinedData(userData, statsData),
    );
  }

  Widget _buildMainCard(
      BuildContext context, {
        required _CombinedData combinedData,
        required bool isDark,
        required Color cardColor,
        required Color textColor,
        required Color subTextColor,
      }) {
    final userData = combinedData.userData;
    final statsData = combinedData.statsData;

    // ✅ Role check
    final bool isFinder = userRole.toLowerCase() == 'finder' ||
        userRole.toLowerCase() == 'worker';

    // ✅ Impressions (from posts + user_stats)
    final impressions = _getMaxValue([
      userData['totalImpressions'],
      userData['impressions'],
      statsData['totalImpressions'],
      statsData['impressions'],
    ]);

    // ✅ Profile Views
    final views = _getMaxValue([
      userData['profileViews'],
      statsData['profileViews'],
    ]);

    // ✅ Role-based third metric
    String thirdLabel;
    int thirdValue;
    IconData thirdIcon;
    Color thirdColor;

    if (isFinder) {
      // Finder: Jobs Completed
      thirdLabel = "Jobs Done";
      thirdValue = _getMaxValue([
        statsData['jobsCompleted'],
        userData['jobsCompleted'],
        userData['completedCount'],
      ]);
      thirdIcon = Icons.work_outline;
      thirdColor = Colors.blue;
    } else {
      // Supporter: Hires Completed
      thirdLabel = "Hires Done";
      thirdValue = _getMaxValue([
        statsData['hiresCompleted'],
        userData['hiresCompleted'],
        userData['completedCount'],
      ]);
      thirdIcon = Icons.handshake_outlined;
      thirdColor = Colors.orange;
    }

    return _buildCard(
      context,
      isDark: isDark,
      cardColor: cardColor,
      textColor: textColor,
      subTextColor: subTextColor,
      impressions: impressions,
      views: views,
      thirdLabel: thirdLabel,
      thirdValue: thirdValue,
      thirdIcon: thirdIcon,
      thirdColor: thirdColor,
    );
  }

  // ✅ Get maximum non-zero value from list
  int _getMaxValue(List<dynamic> values) {
    int maxVal = 0;
    for (var val in values) {
      final intVal = _toInt(val);
      if (intVal > maxVal) {
        maxVal = intVal;
      }
    }
    return maxVal;
  }

  Widget _buildCard(
      BuildContext context, {
        required bool isDark,
        required Color cardColor,
        required Color textColor,
        required Color subTextColor,
        required int impressions,
        required int views,
        required String thirdLabel,
        required int thirdValue,
        required IconData thirdIcon,
        required Color thirdColor,
      }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.brandMain.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: AppColors.brandMain,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Performance",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),

              // Live indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Live",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _perfItem(
                "Impressions",
                _format(impressions),
                Icons.visibility_outlined,
                Colors.purpleAccent,
                textColor,
                subTextColor,
              ),
              _verticalDivider(isDark),
              _perfItem(
                "Profile Views",
                _format(views),
                Icons.person_search_outlined,
                Colors.teal,
                textColor,
                subTextColor,
              ),
              _verticalDivider(isDark),
              _perfItem(
                thirdLabel,
                _format(thirdValue),
                thirdIcon,
                thirdColor,
                textColor,
                subTextColor,
              ),
            ],
          ),

          // ✅ Optional: Show "No data yet" hint if all values are 0
          if (impressions == 0 && views == 0 && thirdValue == 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: Colors.amber.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Complete jobs to see your performance stats!",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _verticalDivider(bool isDark) {
    return Container(
      height: 40,
      width: 1,
      color: isDark ? Colors.white10 : Colors.grey.shade200,
    );
  }

  Widget _perfItem(
      String label,
      String val,
      IconData icon,
      Color iconColor,
      Color textColor,
      Color subTextColor,
      ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: subTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✅ Shimmer with Dark Mode Support
  Widget _buildShimmerLoading(Color cardColor, bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        height: 160,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // ✅ Empty State
  Widget _buildEmptyCard(Color cardColor, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.insights_outlined,
              size: 40,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              "No performance data yet",
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Error State
  Widget _buildErrorCard(Color cardColor, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 8),
            Text(
              "Failed to load performance",
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Helper class for combined data
class _CombinedData {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> statsData;

  _CombinedData(this.userData, this.statsData);
}