import 'package:flutter/material.dart';
import 'package:findus_app/badge/badge_model.dart';

class AppBadgeTheme {
  // সব লেভেলের জন্য কমন badge icon
  static const IconData baseIcon = Icons.workspace_premium;

  // Colors
  static const Color newbie   = Colors.white; // ✅ সাদা কালার
  static const Color bronze   = Color(0xFFCD7F32); // Better Bronze
  static const Color silver   = Color(0xFFC0C0C0); // Better Silver
  static const Color gold     = Color(0xFFFFD700); // Better Gold
  static const Color platinum = Color(0xFFE5E4E2);
  static const Color diamond  = Color(0xFF00E5FF); // Cyan Diamond

  static Color colorForLevel(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.newbie:
        return newbie;
      case BadgeLevel.bronze:
        return bronze;
      case BadgeLevel.silver:
        return silver;
      case BadgeLevel.gold:
        return gold;
      case BadgeLevel.platinum:
        return platinum;
      case BadgeLevel.diamond:
        return diamond;
    }
  }

  // label string দিয়ে color (NEXT BADGE সেকশনের জন্য)
  static Color colorForLabel(String label) {
    switch (label.toUpperCase()) {
      case 'NEWBIE':
        return newbie;
      case 'BRONZE':
        return bronze;
      case 'SILVER':
        return silver;
      case 'GOLD':
        return gold;
      case 'PLATINUM':
        return platinum;
      case 'DIAMOND':
        return diamond;
      default:
        return gold;
    }
  }
}