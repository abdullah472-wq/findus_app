// lib/badge/badge_icon.dart
import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/badge/badge_service.dart';

class BadgeIcon extends StatelessWidget {
  final double size;
  final BadgeLevel? overrideLevel;
  final double? overridePercentToNext;

  const BadgeIcon({
    super.key,
    this.size = 28,
    this.overrideLevel,
    this.overridePercentToNext,
  });

  @override
  Widget build(BuildContext context) {
    // ১. ওভাররাইড লেভেল চেক (Newbie হলে কিছুই দেখাবে না)
    if (overrideLevel != null) {
      if (overrideLevel == BadgeLevel.newbie) return const SizedBox.shrink();
      return _buildBadge(
        level: overrideLevel!,
        percentToNext: overridePercentToNext ?? 1.0,
      );
    }

    // ২. গ্লোবাল ইউজার ব্যাজ লিসেনার
    return ValueListenableBuilder<BadgeProgress>(
      valueListenable: BadgeService.badgeNotifier,
      builder: (context, progress, _) {
        // ✅ Newbie হলে কোনো উইজেট রেন্ডার হবে না
        if (progress.level == BadgeLevel.newbie) {
          return const SizedBox.shrink();
        }

        return _buildBadge(
          level: progress.level,
          percentToNext: progress.progressPercentage,
        );
      },
    );
  }

  Widget _buildBadge({
    required BadgeLevel level,
    required double percentToNext,
  }) {
    IconData icon;
    Color color;
    String label;

    // Exhaustive switch (সব লেভেল হ্যান্ডেল করা হয়েছে)
    switch (level) {
      case BadgeLevel.newbie:
      // এটি প্র্যাকটিক্যালি কল হবে না উপরের চেকের কারণে, তাও সেফটির জন্য রাখা
        return const SizedBox.shrink();

      case BadgeLevel.bronze:
        icon = Icons.military_tech;
        color = const Color(0xFFCD7F32);
        label = "Bronze";
        break;

      case BadgeLevel.silver:
        icon = Icons.military_tech;
        color = Colors.grey.shade400;
        label = "Silver";
        break;

      case BadgeLevel.gold:
        icon = Icons.military_tech;
        color = const Color(0xFFFFD700);
        label = "Gold";
        break;

      case BadgeLevel.platinum:
        icon = Icons.military_tech;
        color = const Color(0xFFE5E4E2);
        label = "Platinum";
        break;

      case BadgeLevel.diamond:
        icon = Icons.diamond;
        color = const Color(0xFF00E5FF);
        label = "Diamond";
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: size, color: color),
            Positioned(
              bottom: -4,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 4,
                width: size,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentToNext,
                    backgroundColor: Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.brandMain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: AppColors.brandDark,
          ),
        ),
      ],
    );
  }
}