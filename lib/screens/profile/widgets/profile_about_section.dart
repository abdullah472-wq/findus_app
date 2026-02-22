import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'profile_shimmer_loading.dart';

// profile_about_section.dart

class ProfileAboutSection extends StatelessWidget {
  final String about;
  final bool isDark;
  final bool isLoading; // ✅ নতুন parameter

  const ProfileAboutSection({
    super.key,
    required this.about,
    required this.isDark,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Me',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.brandMain,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 10),

          // ✅ Loading state
          isLoading
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MiniShimmerLoading(width: double.infinity, height: 14, isDark: isDark),
              const SizedBox(height: 6),
              MiniShimmerLoading(width: double.infinity, height: 14, isDark: isDark),
              const SizedBox(height: 6),
              MiniShimmerLoading(width: 200, height: 14, isDark: isDark),
            ],
          )
              : Text(
            about.isNotEmpty ? about : 'No bio added yet.',
            style: TextStyle(
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}