import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

import 'profile_boost_screen.dart';
import 'job_post_boost_screen.dart';
import 'instant_boost_screen.dart';

class AdCenterScreen extends StatelessWidget {
  const AdCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        backgroundColor: AppColors.brandLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
        title: const Text(
          "Ad Center",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false, // left aligned
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCard(context),
              const SizedBox(height: 16),
              const Text(
                "Promotion options",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 8),

              // ১) প্রোফাইল বুস্ট
              _PromotionCard(
                icon: Icons.trending_up,
                title: "Boost my profile",
                forWhom: "For Workers & Supporters",
                description:
                "Show your profile higher in search and home feed to get more views and chats.",
                bullets: const [
                  "Higher visibility in nearby search",
                  "Profile highlight in home feed",
                  "Better chance to get more jobs",
                ],
                ctaText: "PROMOTE PROFILE",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileBoostScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // ২) Job posts promotion
              _PromotionCard(
                icon: Icons.campaign_outlined,
                title: "Promote my job posts",
                forWhom: "For Job Makers (Supporters)",
                description:
                "Push your job posts to more local workers and get faster responses.",
                bullets: const [
                  "Job posts appear on top for nearby workers",
                  "Highlight badge on promoted jobs",
                  "More views & applications in less time",
                ],
                ctaText: "PROMOTE JOB POSTS",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const JobPostBoostScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // ৩) Instant boost
              _PromotionCard(
                icon: Icons.bolt_outlined,
                title: "Instant Boost (24 hours)",
                forWhom: "Quick promotion",
                description:
                "Short-time boost for urgent needs. Good when you want results today.",
                bullets: const [
                  "24 hours instant profile boost",
                  "Ideal for urgent jobs or quick hiring",
                  "One-time small payment",
                ],
                ctaText: "TRY INSTANT BOOST",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InstantBoostScreen(),
                    ),
                  );
                },
              ),

              // আগের "Last 7 days performance" ব্লকটা মুছে ফেলা হয়েছে।
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    // এখন ডেমো ডাটা, পরে backend থেকে আনবে
    const String currentMode = "Job Maker / Supporter (demo)";
    const int activePromotions = 2;
    const int monthlySpend = 450; // ৳

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Grow your reach with Ads",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Boost your profile and jobs to reach more people around you.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _smallStat(
                label: "Current mode",
                value: currentMode,
                isPrimary: false,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _smallStat(
                  label: "Active promotions",
                  value: "$activePromotions",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _smallStat(
                  label: "This month spend",
                  value: "৳$monthlySpend",
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // এখন simple – প্রোফাইল বুস্ট স্ক্রিনে নিয়ে যাচ্ছি
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileBoostScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.brandMain),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.brandMain,
              ),
              label: const Text(
                "CREATE NEW PROMOTION",
                style: TextStyle(
                  color: AppColors.brandMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallStat({
    required String label,
    required String value,
    bool isPrimary = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrimary ? 16 : 13,
            fontWeight: FontWeight.w700,
            color: AppColors.brandDark,
          ),
        ),
      ],
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String forWhom;
  final String description;
  final List<String> bullets;
  final String ctaText;
  final VoidCallback? onPressed;

  const _PromotionCard({
    required this.icon,
    required this.title,
    required this.forWhom,
    required this.description,
    required this.bullets,
    required this.ctaText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.brandLight.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.brandDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            forWhom,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          ...bullets.map(
                (b) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.brandMain,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandDark,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                ctaText,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}