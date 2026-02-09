import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class PerformanceCard extends StatelessWidget {
  final String userId;
  final String userRole; // 'finder' or 'supporter'

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

    // ✅ এখানে users কালেকশন চেক করা হচ্ছে কারণ বেশিরভাগ ডাটা সেখানেই আপডেট হয়
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading(cardColor);
        }

        Map<String, dynamic> data = {};
        if (snapshot.hasData && snapshot.data!.exists) {
          data = snapshot.data!.data() as Map<String, dynamic>;
        }

        // ✅ ডাইনামিক লজিক শুরু
        final bool isFinder = userRole.toLowerCase() == 'finder' || userRole.toLowerCase() == 'worker';

        // ১. ইম্প্রেশন (যদি পোস্ট ইম্প্রেশন আলাদা কালেকশনে থাকে, তবে টোটাল যোগ করা জটিল।
        // তাই ইউজারের প্রোফাইল ডকুমেন্টেই 'totalImpressions' সেভ করা ভালো।)
        final impressions = data['totalImpressions'] ?? data['impressions'] ?? 0;

        // ২. প্রোফাইল ভিউ (এটি user_stats এ থাকতে পারে, তাই ফলব্যাক রাখা হলো)
        final views = data['profileViews'] ?? 0;

        final int hiresCount = _toInt(data['hiresCount']);
        final int jobsCompleted = _toInt(data['jobsCompleted']);

        // ✅ role-based 3rd metric
        final String thirdLabel = isFinder ? "Jobs Done" : "Total Hires";
        final int thirdValue = isFinder ? jobsCompleted : hiresCount;
        final IconData thirdIcon = isFinder ? Icons.work_outline : Icons.handshake_outlined;
        final Color thirdColor = isFinder ? Colors.blue : Colors.orange;

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
                        child: const Icon(Icons.insights_rounded, color: AppColors.brandMain, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Performance",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor
                        ),
                      ),
                    ],
                  ),

                  // Trend (এটি ফিক্সড রাখা হলো, ডাইনামিক করতে চাইলে গত মাসের ডাটা লাগবে)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.trending_up, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text("Live", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
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
                  _perfItem("Impressions", _format(impressions), Icons.visibility_outlined, Colors.purpleAccent, textColor, subTextColor),
                  _verticalDivider(isDark),
                  _perfItem("Profile Views", _format(views), Icons.person_search_outlined, Colors.teal, textColor, subTextColor),
                  _verticalDivider(isDark),
                  _perfItem(thirdLabel, _format(thirdValue), thirdIcon, thirdColor, textColor, subTextColor),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ সেইফ ইন্টিজার কনভার্সন
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

  Widget _perfItem(String label, String val, IconData icon, Color iconColor, Color textColor, Color subTextColor) {
    return Column(
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
                color: textColor
            )
        ),
        const SizedBox(height: 4),
        Text(
            label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: subTextColor
            )
        ),
      ],
    );
  }

  Widget _buildShimmerLoading(Color cardColor) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
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
}