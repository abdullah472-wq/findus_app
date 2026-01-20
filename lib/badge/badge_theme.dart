import 'package:flutter/material.dart';
import 'package:findus_app/badge/badge_model.dart';

class AppBadgeTheme {
  // সব লেভেলের জন্য কমন badge icon
  static const IconData baseIcon = Icons.workspace_premium;

  // Colors
  static const Color newbie   = Colors.blueGrey; // Newbie যোগ করা হলো
  static const Color bronze   = Colors.brown;
  static const Color silver   = Colors.grey;
  static const Color gold     = Colors.amber;
  static const Color platinum = Color(0xFFE5E4E2);
  static const Color diamond  = Colors.blue;

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