import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum BadgeLevel {
  newbie,   // ✅ এখন এটি 'Starter Badge' (সাদা রঙের)
  bronze,   // পরবর্তী লেভেল
  silver,
  gold,
  platinum,
  diamond
}

@immutable
class BadgeProgress {
  final BadgeLevel level;
  final int totalPoints;
  final int nextLevelPoints;
  final double progressPercentage;

  const BadgeProgress({
    required this.level,
    required this.totalPoints,
    required this.nextLevelPoints,
    this.progressPercentage = 0.0,
  });

  // প্রগ্রেস ক্যালকুলেশন হেল্পার
  double get percentToNext {
    if (progressPercentage > 0.0) return progressPercentage;
    if (nextLevelPoints <= 0) return 1.0; // ম্যাক্স লেভেল

    final ratio = totalPoints / nextLevelPoints;
    return ratio.clamp(0.0, 1.0);
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
}