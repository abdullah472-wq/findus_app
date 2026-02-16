import 'package:flutter/material.dart';
import 'dart:math' as math;

enum BadgeLevel {
  newbie,   // 0 - 99 Stars
  bronze,   // 100+ Stars
  silver,   // 500+ Stars
  gold,     // 2000+ Stars
  platinum, // 5000+ Stars
  diamond,  // 10000+ Stars
}

@immutable
class BadgeProgress {
  final BadgeLevel badgeLevel;  // স্টার দিয়ে নির্ধারিত ব্যাজ
  final int totalXP;            // কাজের এক্টিভিটি (১-১০০ লেভেল)
  final double totalStars;      // মোট জমাকৃত স্টার

  const BadgeProgress({
    required this.badgeLevel,
    required this.totalXP,
    this.totalStars = 0.0,
  });

  // পুরনো কোডের জন্য আলাদা alias getter (parameter না, শুধু getter)
  BadgeLevel get level => badgeLevel;
  int get totalPoints => totalXP;

  //✅ XP → Numeric Level (1 - 100)
  int get numericLevel {
    if (totalXP <= 0) return 1;
    final lvl = (1 + math.sqrt(totalXP / 44)).floor();
    return lvl.clamp(1, 100);
  }

  //✅ প্রগ্রেস বার (0.0 - 1.0)
  double get badgeProgressPercent {
    if (badgeLevel == BadgeLevel.diamond) return 1.0;

    final current = _getStarThreshold(badgeLevel);
    final next = _getNextStarThreshold(badgeLevel);
    if (next <= current) return 1.0;

    return ((totalStars - current) / (next - current)).clamp(0.0, 1.0);
  }

  // কালার
  Color get badgeColor {
    switch (badgeLevel) {
      case BadgeLevel.newbie:
        return Colors.white;
      case BadgeLevel.bronze:
        return const Color(0xFFCD7F32);
      case BadgeLevel.silver:
        return const Color(0xFFC0C0C0);
      case BadgeLevel.gold:
        return const Color(0xFFFFD700);
      case BadgeLevel.platinum:
        return const Color(0xFFE5E4E2);
      case BadgeLevel.diamond:
        return const Color(0xFF00E5FF);
    }
  }

  String get badgeName =>
      badgeLevel.toString().split('.').last.toUpperCase();

  double _getStarThreshold(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.newbie:
        return 0;
      case BadgeLevel.bronze:
        return 100;
      case BadgeLevel.silver:
        return 500;
      case BadgeLevel.gold:
        return 2000;
      case BadgeLevel.platinum:
        return 5000;
      case BadgeLevel.diamond:
        return 10000;
    }
  }

  double _getNextStarThreshold(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.newbie:
        return 100;
      case BadgeLevel.bronze:
        return 500;
      case BadgeLevel.silver:
        return 2000;
      case BadgeLevel.gold:
        return 5000;
      case BadgeLevel.platinum:
        return 10000;
      case BadgeLevel.diamond:
        return 10000;
    }
  }
}