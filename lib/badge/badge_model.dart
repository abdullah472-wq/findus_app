// lib/badge/badge_model.dart
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

  // ✅ Points needed to reach next level
  int get pointsToNextLevel => (nextLevelPoints - totalPoints).clamp(0, nextLevelPoints);

  // ✅ Check if user is at max level
  bool get isMaxLevel => level == BadgeLevel.diamond;

  // ✅ Formatted points (no decimals)
  String get formattedPoints => totalPoints.toStringAsFixed(0);

  // ✅ Progress to next level (0.0 to 1.0)
  double get percentToNext => progressPercentage;

  // ✅ Level color based on badge level
  Color get levelColor {
    switch (level) {
      case BadgeLevel.newbie:
        return Colors.white; // ✅ সাদা কালার
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

  // ✅ Level name (formatted)
  String get levelName {
    switch (level) {
      case BadgeLevel.newbie:
        return 'Newbie';
      case BadgeLevel.bronze:
        return 'Bronze';
      case BadgeLevel.silver:
        return 'Silver';
      case BadgeLevel.gold:
        return 'Gold';
      case BadgeLevel.platinum:
        return 'Platinum';
      case BadgeLevel.diamond:
        return 'Diamond';
    }
  }

  // ✅ Level description
  String get levelDescription {
    switch (level) {
      case BadgeLevel.newbie:
        return 'Just getting started';
      case BadgeLevel.bronze:
        return 'Beginner level, keep going!';
      case BadgeLevel.silver:
        return 'Intermediate level, you\'re doing great!';
      case BadgeLevel.gold:
        return 'Advanced level, top performer!';
      case BadgeLevel.platinum:
        return 'Expert level, outstanding work!';
      case BadgeLevel.diamond:
        return 'Master level, you are a legend!';
    }
  }

  // ✅ Copy with method for state updates
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

  // ✅ Factory method for creating from points
  factory BadgeProgress.fromPoints(int points) {
    final level = _getLevelByPoints(points);
    final nextLevelPoints = _getNextLevelPoints(level);
    final progressPercentage = _calculateProgressPercentage(points, level);

    return BadgeProgress(
      level: level,
      totalPoints: points,
      nextLevelPoints: nextLevelPoints,
      progressPercentage: progressPercentage,
    );
  }

  // ✅ Helper: Get level by points
  static BadgeLevel _getLevelByPoints(int points) {
    if (points >= 1000000) return BadgeLevel.diamond;
    if (points >= 100000) return BadgeLevel.platinum;
    if (points >= 50000) return BadgeLevel.gold;
    if (points >= 10000) return BadgeLevel.silver;
    if (points >= 1000) return BadgeLevel.bronze;
    return BadgeLevel.newbie;
  }

  // ✅ Helper: Get next level points
  static int _getNextLevelPoints(BadgeLevel currentLevel) {
    switch (currentLevel) {
      case BadgeLevel.newbie:
        return 1000;
      case BadgeLevel.bronze:
        return 10000;
      case BadgeLevel.silver:
        return 50000;
      case BadgeLevel.gold:
        return 100000;
      case BadgeLevel.platinum:
        return 1000000;
      case BadgeLevel.diamond:
        return 1000000; // Max level
    }
  }

  // ✅ Helper: Calculate progress percentage
  static double _calculateProgressPercentage(int currentPoints, BadgeLevel currentLevel) {
    if (currentLevel == BadgeLevel.diamond) return 1.0;

    final currentThreshold = _getThresholdForLevel(currentLevel);
    final nextThreshold = _getNextLevelPoints(currentLevel);

    if (nextThreshold == currentThreshold) return 1.0;

    final progress = (currentPoints - currentThreshold) / (nextThreshold - currentThreshold);
    return progress.clamp(0.0, 1.0);
  }

  // ✅ Helper: Get threshold for level
  static int _getThresholdForLevel(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.newbie:
        return 0;
      case BadgeLevel.bronze:
        return 1000;
      case BadgeLevel.silver:
        return 10000;
      case BadgeLevel.gold:
        return 50000;
      case BadgeLevel.platinum:
        return 100000;
      case BadgeLevel.diamond:
        return 1000000;
    }
  }

  // ✅ Get level thresholds map
  static Map<BadgeLevel, int> get levelThresholds => {
    BadgeLevel.newbie: 0,
    BadgeLevel.bronze: 1000,
    BadgeLevel.silver: 10000,
    BadgeLevel.gold: 50000,
    BadgeLevel.platinum: 100000,
    BadgeLevel.diamond: 1000000,
  };

  // ✅ Get level order list
  static List<BadgeLevel> get levelOrder => [
    BadgeLevel.newbie,
    BadgeLevel.bronze,
    BadgeLevel.silver,
    BadgeLevel.gold,
    BadgeLevel.platinum,
    BadgeLevel.diamond,
  ];

  // ✅ Get max points
  static int get maxPoints => 1000000;

  // ✅ Equality operators
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

// ✅ Extension for BadgeLevel enum (Optional)
extension BadgeLevelExtension on BadgeLevel {
  Color get color {
    switch (this) {
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
        return const Color(0xFFB9F2FF);
    }
  }

  String get formattedName {
    switch (this) {
      case BadgeLevel.newbie:
        return 'Newbie';
      case BadgeLevel.bronze:
        return 'Bronze';
      case BadgeLevel.silver:
        return 'Silver';
      case BadgeLevel.gold:
        return 'Gold';
      case BadgeLevel.platinum:
        return 'Platinum';
      case BadgeLevel.diamond:
        return 'Diamond';
    }
  }

  String get description {
    switch (this) {
      case BadgeLevel.newbie:
        return 'Just getting started';
      case BadgeLevel.bronze:
        return 'Beginner level, keep going!';
      case BadgeLevel.silver:
        return 'Intermediate level, you\'re doing great!';
      case BadgeLevel.gold:
        return 'Advanced level, top performer!';
      case BadgeLevel.platinum:
        return 'Expert level, outstanding work!';
      case BadgeLevel.diamond:
        return 'Master level, you are a legend!';
    }
  }

  IconData get icon {
    switch (this) {
      case BadgeLevel.newbie:
        return Icons.emoji_people;
      case BadgeLevel.bronze:
        return Icons.military_tech;
      case BadgeLevel.silver:
        return Icons.military_tech;
      case BadgeLevel.gold:
        return Icons.military_tech;
      case BadgeLevel.platinum:
        return Icons.military_tech;
      case BadgeLevel.diamond:
        return Icons.diamond;
    }
  }
}