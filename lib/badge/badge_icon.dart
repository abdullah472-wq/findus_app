import 'package:flutter/material.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/badge/badge_service.dart';

class BadgeIcon extends StatelessWidget {
  final double size;
  const BadgeIcon({super.key, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BadgeProgress>(
      valueListenable: BadgeService.badgeNotifier,
      builder: (context, stats, _) {

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🏅 ব্যাজ আইকন এবং গ্লো ইফেক্ট
            Stack(
              alignment: Alignment.center,
              children: [
                // গ্লো (যদি গোল্ড বা ডায়মন্ড হয়)
                if (stats.badgeLevel == BadgeLevel.gold || stats.badgeLevel == BadgeLevel.diamond)
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: stats.badgeColor.withOpacity(0.6),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),

                // মেইন আইকন
                Icon(
                  stats.badgeLevel == BadgeLevel.diamond
                      ? Icons.workspace_premium,
                      : Icons.workspace_premium,
                  size: size,
                  color: stats.badgeColor,
                ),
              ],
            ),

            const SizedBox(height: 4),

            // 🏷️ ব্যাজ নাম এবং লেভেল (Gold • Lvl 5)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stats.badgeName.toUpperCase(),
                    style: TextStyle(
                      color: stats.badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text("•", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(width: 4),
                  Text(
                    "Lvl ${stats.numericLevel}", // XP থেকে লেভেল
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ⭐ স্টার প্রগ্রেস বার (Next Badge)
            if (stats.badgeLevel != BadgeLevel.diamond)
              SizedBox(
                width: size + 20,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: stats.badgeProgressPercent,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation(stats.badgeColor),
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${stats.totalStars.toStringAsFixed(0)} / ${_getNextLimit(stats.badgeLevel)} ★",
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  int _getNextLimit(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.newbie: return 100;
      case BadgeLevel.bronze: return 500;
      case BadgeLevel.silver: return 2000;
      case BadgeLevel.gold: return 5000;
      case BadgeLevel.platinum: return 10000;
      default: return 10000;
    }
  }
}