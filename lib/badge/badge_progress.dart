import 'package:flutter/material.dart';

enum BadgeLevel {
  newbie,  // 0 points
  bronze,  // 1000 points
  silver,  // 10000 points
  gold,    // 50000 points
  platinum, // 100000 points
  diamond, // 1000000 points
}

@immutable
class BadgeProgress {
  final BadgeLevel level;
  final int totalPoints;
  final int nextLevelPoints;
  final double progressPercentage; // 0.0 to 1.0

  const BadgeProgress({
    required this.level,
    required this.totalPoints,
    required this.nextLevelPoints,
    required this.progressPercentage,
  });

  int get pointsToNextLevel => (nextLevelPoints - totalPoints).clamp(0, nextLevelPoints);

  bool get isMaxLevel => level == BadgeLevel.diamond;

  String get formattedPoints => totalPoints.toStringAsFixed(0);

  // গেটার: প্রগ্রেস পার্সেন্টেজ
  double get percentToNext => progressPercentage;

  // ✅ কালার আপডেটেড: Newbie এখন সাদা
  Color get levelColor {
    switch (level) {
      case BadgeLevel.newbie:
        return Colors.white; // ✅ আগে গ্রে ছিল, এখন সাদা
      case BadgeLevel.bronze:
        return const Color(0xFFCD7F32); // Bronze color
      case BadgeLevel.silver:
        return const Color(0xFFC0C0C0); // Silver color
      case BadgeLevel.gold:
        return const Color(0xFFFFD700); // Gold color
      case BadgeLevel.platinum:
        return const Color(0xFFE5E4E2); // Platinum color
      case BadgeLevel.diamond:
        return const Color(0xFFB9F2FF); // Diamond color
    }
  }

  BadgeProgress copyWith({
    BadgeLevel? level,
    int? totalPoints,
    int? nextLevelPoints,
    double? progressPercentage,
  }) {
    return BadgeProgress(
      level: level ?? this.level,
      totalPoints: totalPoints ?? this.totalPoints,
      nextLevelPoints: nextLevelPoints ?? this.nextLevelPoints,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BadgeProgress &&
        other.level == level &&
        other.totalPoints == totalPoints &&
        other.nextLevelPoints == nextLevelPoints &&
        other.progressPercentage == progressPercentage;
  }

  @override
  int get hashCode {
    return Object.hash(level, totalPoints, nextLevelPoints, progressPercentage);
  }

  @override
  String toString() {
    return 'BadgeProgress(level: $level, totalPoints: $totalPoints, '
        'nextLevelPoints: $nextLevelPoints, progressPercentage: $progressPercentage)';
  }
}