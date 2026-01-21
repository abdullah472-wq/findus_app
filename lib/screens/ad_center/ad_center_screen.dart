// lib/screens/ad_center/ad_center_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

import 'profile_boost_screen.dart';
import 'job_post_boost_screen.dart';
import 'instant_boost_screen.dart';

class AdCenterScreen extends StatelessWidget {
  const AdCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FloatingScaffold(
      title: "AD CENTER",
      backgroundColor: AppColors.brandLight,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ১. প্রিমিয়াম অভারভিউ কার্ড
          _buildPremiumOverview(context, isDark),

          const SizedBox(height: 25),

          const Text(
            "Promotion Options",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // ২. প্রোফাইল বুস্ট (Premium Card)
          _buildBoostCard(
            context: context,
            icon: Icons.trending_up_rounded,
            title: "Boost My Profile",
            subtitle: "Higher visibility in search & home feed",
            color: Colors.blue,
            tag: "POPULAR",
            description: "Show your profile higher in search to get 3x more views and chats from potential clients.",
            onTap: () => _push(context, const ProfileBoostScreen()),
          ),

          const SizedBox(height: 16),

          // ৩. জব পোস্ট বুস্ট
          _buildBoostCard(
            context: context,
            icon: Icons.campaign_rounded,
            title: "Promote Job Posts",
            subtitle: "Get faster responses for your jobs",
            color: Colors.green,
            tag: "BEST FOR CLIENTS",
            description: "Push your job posts to the top for nearby workers and get applications within minutes.",
            onTap: () => _push(context, const JobPostBoostScreen()),
          ),

          const SizedBox(height: 16),

          // ৪. ইনস্ট্যান্ট বুস্ট (Quick Result)
          _buildBoostCard(
            context: context,
            icon: Icons.bolt_rounded,
            title: "Instant 24H Boost",
            subtitle: "Maximum reach for 24 hours",
            color: Colors.orange,
            tag: "URGENT",
            description: "Perfect for emergency jobs or if you want results today. One-time small payment.",
            onTap: () => _push(context, const InstantBoostScreen()),
          ),

          const SizedBox(height: 100), // Bottom Nav Spacing
        ],
      ),
    );
  }

  Widget _buildPremiumOverview(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: AppColors.brandMain.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brandMain.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: AppColors.brandMain, size: 24),
              ),
              const SizedBox(width: 12),
              const Text("Growth Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem("Active Ads", "02", Colors.blue),
              _statItem("Total Views", "1.2K", Colors.green),
              _statItem("Avg. CTR", "4.5%", Colors.orange),
            ],
          ),
          const Divider(height: 35),
          const Text(
            "Reach more people around your location and grow your business today!",
            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildBoostCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String tag,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
          border: Border.all(color: color.withOpacity(0.1), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                  child: Icon(icon, color: color, size: 28),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(tag, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Get Started", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 5),
                Icon(Icons.arrow_forward_rounded, color: color, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}