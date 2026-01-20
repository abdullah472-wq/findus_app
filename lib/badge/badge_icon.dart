import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/badge/badge_service.dart';

import 'badge_model.dart';

class BadgeIcon extends StatelessWidget {
  final double size;

  /// যদি অন্য কারও ব্যাজ দেখাতে চান (worker card এর জন্য) তাহলে এগুলো দিতে পারেন
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
    // যদি overrideLevel দেওয়া থাকে → static badge দেখাব
    if (overrideLevel != null) {
      return _buildBadge(
        level: overrideLevel!,
        percentToNext: overridePercentToNext ?? 1.0,
      );
    }

    // নাহলে global user badge ব্যবহার করব
    return ValueListenableBuilder(
      valueListenable: BadgeService.badgeNotifier,
      builder: (context, BadgeProgress progress, _) {
        return _buildBadge(
          level: progress.level,
          percentToNext: progress.percentToNext,
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
        color = Colors.blueGrey.shade100; // নিজের মতো রাখো
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
          children: [
            Icon(icon, size: size, color: color),
            Positioned(
              bottom: -2,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentToNext,
                    backgroundColor: Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.brandMain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.brandDark,
          ),
        ),
      ],
    );
  }
}