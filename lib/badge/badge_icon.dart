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
    // ১. ওভাররাইড লেভেল চেক
    if (overrideLevel != null) {
      return _buildBadge(
        level: overrideLevel!,
        percentToNext: overridePercentToNext ?? 1.0,
      );
    }

    // ২. গ্লোবাল ইউজার ব্যাজ লিসেনার
    return ValueListenableBuilder<BadgeProgress>(
      valueListenable: BadgeService.badgeNotifier,
      builder: (context, progress, _) {
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

    switch (level) {
      case BadgeLevel.newbie:
        icon = Icons.emoji_people; // অথবা Icons.star_border
        color = Colors.white; // ✅ সাদা কালার
        label = "Newbie";
        break;

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
            // গ্লো ইফেক্ট (সাদা ব্যাজের জন্য ডার্ক ব্যাকগ্রাউন্ডে দরকার হতে পারে)
            if (level == BadgeLevel.newbie)
              Positioned.fill(
                child: Icon(
                  icon,
                  size: size,
                  color: Colors.black.withOpacity(0.2), // হালকা শ্যাডো যাতে সাদার ওপর বোঝা যায়
                ),
              ),

            Icon(
              icon,
              size: size,
              color: color,
              // যদি আইকনটি সলিড না হয়, তবে সাদা রঙ ব্যাকগ্রাউন্ডে মিশে যেতে পারে।
              // তাই প্রয়োজনে shadows প্রপার্টি ব্যবহার করা যেতে পারে।
              shadows: level == BadgeLevel.newbie
                  ? [Shadow(color: Colors.black26, blurRadius: 4)]
                  : null,
            ),

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