import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

class PerformanceCard extends StatelessWidget {
  final String userId;

  const PerformanceCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // ✅ ডার্ক মোড চেক
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_stats')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> data = {};

        if (snapshot.hasData && snapshot.data!.exists) {
          data = snapshot.data!.data() as Map<String, dynamic>;
        }

        final impressions = data['impressions'] ?? 0;
        final views = data['profileViews'] ?? 0;
        final hires = data['hires'] ?? 0;

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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights_rounded, color: AppColors.brandMain, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Profile Performance",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                "Overview of how users are interacting with you",
                style: TextStyle(fontSize: 12, color: subTextColor),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _perfItem("Impressions", _format(impressions), Icons.visibility_outlined, Colors.blue, textColor, subTextColor),
                  _perfItem("Views", _format(views), Icons.person_search_outlined, Colors.green, textColor, subTextColor),
                  _perfItem("Hires", _format(hires), Icons.handshake_outlined, Colors.orange, textColor, subTextColor),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _format(dynamic val) {
    int n = (val is int) ? val : int.tryParse(val.toString()) ?? 0;
    if (n >= 1000000) return "${(n / 1000000).toStringAsFixed(1)}M";
    if (n >= 1000) return "${(n / 1000).toStringAsFixed(1)}K";
    return n.toString();
  }

  Widget _perfItem(String label, String val, IconData icon, Color iconColor, Color textColor, Color subTextColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
            val,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textColor
            )
        ),
        const SizedBox(height: 2),
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
}