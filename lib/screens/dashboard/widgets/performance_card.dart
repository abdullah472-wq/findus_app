import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:shimmer/shimmer.dart';

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

    // ✅ Combined streams from both collections
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
        final userData = combinedData.userData;
        final statsData = combinedData.statsData;

        // ✅ Role check
        final bool isFinder = userRole.toLowerCase() == 'finder' ||
            userRole.toLowerCase() == 'worker';

        // ✅ Impressions (from users or user_stats)
        final impressions = _toInt(userData['totalImpressions']) +
            _toInt(statsData['totalImpressions']);

        // ✅ Profile Views
        final views = _toInt(userData['profileViews']) +
            _toInt(statsData['profileViews']);

        // ✅ Role-based third metric
        String thirdLabel;
        int thirdValue;
        IconData thirdIcon;
        Color thirdColor;

        if (isFinder) {
          // Finder: Jobs Completed
          thirdLabel = "Jobs Done";
          thirdValue = _toInt(statsData['jobsCompleted']) > 0
              ? _toInt(statsData['jobsCompleted'])
              : _toInt(userData['jobsCompleted']);
          thirdIcon = Icons.work_outline;
          thirdColor = Colors.blue;
        } else {
          // Supporter: Hires Completed
          thirdLabel = "Hires Done";
          thirdValue = _toInt(statsData['hiresCompleted']) > 0
              ? _toInt(statsData['hiresCompleted'])
              : _toInt(userData['hiresCompleted']);
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
      },
    );
  }

  // ✅ Combined Stream from users + user_stats
  Stream<_CombinedData> _getCombinedStream() {
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots();

    final statsStream = FirebaseFirestore.instance
        .collection('user_stats')
        .doc(userId)
        .snapshots();

    return usersStream.asyncMap((userDoc) async {
      final statsDoc = await FirebaseFirestore.instance
          .collection('user_stats')
          .doc(userId)
          .get();

      final userData = userDoc.exists
          ? userDoc.data() as Map<String, dynamic>
          : <String, dynamic>{};

      final statsData = statsDoc.exists
          ? statsDoc.data() as Map<String, dynamic>
          : <String, dynamic>{};

      return _CombinedData(userData, statsData);
    });
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