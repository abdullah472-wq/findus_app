import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:findus_app/badge/badge_model.dart';

class BadgeService {
  // সব জায়গা থেকে এই notifier listen করলে প্রগ্রেস পাল্টালেই UI আপডেট হবে
  static final ValueNotifier<BadgeProgress> badgeNotifier =
  ValueNotifier<BadgeProgress>(
    const BadgeProgress(
      level: BadgeLevel.newbie,
      totalPoints: 0,
      nextLevelPoints: 1000,
      progressPercentage: 0.0,
    ),
  );

  static const String _pointsKey = 'user_badge_points';
  static const String _pointsHistoryKey = 'user_badge_points_history';

  // থ্রেশহোল্ড – সব জায়গায় এগুলোই use করবে
  static const Map<BadgeLevel, int> _thresholds = {
    BadgeLevel.newbie: 0,
    BadgeLevel.bronze: 1000,
    BadgeLevel.silver: 10000,
    BadgeLevel.gold: 50000,
    BadgeLevel.platinum: 100000,
    BadgeLevel.diamond: 1000000,
  };

  // Threshold getters for easy access
  static int get newbieThreshold => _thresholds[BadgeLevel.newbie]!;
  static int get bronzeThreshold => _thresholds[BadgeLevel.bronze]!;
  static int get silverThreshold => _thresholds[BadgeLevel.silver]!;
  static int get goldThreshold => _thresholds[BadgeLevel.gold]!;
  static int get platinumThreshold => _thresholds[BadgeLevel.platinum]!;
  static int get diamondThreshold => _thresholds[BadgeLevel.diamond]!;

  // লেভেলগুলোর ক্রমিক তালিকা
  static final List<BadgeLevel> _levelOrder = [
    BadgeLevel.newbie,
    BadgeLevel.bronze,
    BadgeLevel.silver,
    BadgeLevel.gold,
    BadgeLevel.platinum,
    BadgeLevel.diamond,
  ];

  static int get maxPoints => _thresholds[BadgeLevel.diamond]!;

  /// অ্যাপ চালু হওয়া মাত্র ১বার কল করবেন (main.dart এ)
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final points = prefs.getInt(_pointsKey) ?? 0;
      await _setPoints(points, save: false);
    } catch (e) {
      debugPrint('BadgeService init error: $e');
      // Default অবস্থায় রাখা
      badgeNotifier.value = const BadgeProgress(
        level: BadgeLevel.newbie,
        totalPoints: 0,
        nextLevelPoints: 1000,
        progressPercentage: 0.0,
      );
    }
  }

  /// যখনই কিছু অ্যাকশনে এক্সপি দিতে চান (job complete, good rating ইত্যাদি)
  static Future<void> addPoints(int value, {String? reason}) async {
    if (value <= 0) return;

    try {
      final current = badgeNotifier.value;
      final newPoints = (current.totalPoints + value).clamp(0, maxPoints);

      await _setPoints(newPoints);

      // Add to history if reason provided
      if (reason != null) {
        await _addToHistory(value, reason);
      }
    } catch (e) {
      debugPrint('BadgeService addPoints error: $e');
      rethrow;
    }
  }

  /// নির্দিষ্ট পয়েন্টে সেট করতে চাইলে (server থেকে আসলে)
  static Future<void> setPointsFromServer(int value) async {
    try {
      final normalized = value.clamp(0, maxPoints);
      if (badgeNotifier.value.totalPoints == normalized) return; // ✅ no-op if same
      await _setPoints(normalized);
    } catch (e) {
      debugPrint('BadgeService setPointsFromServer error: $e');
      rethrow;
    }
  }

  /// Reset points (logout বা অন্য অ্যাকাউন্টে switch করলে)
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pointsKey);
      await prefs.remove(_pointsHistoryKey);
      badgeNotifier.value = const BadgeProgress(
        level: BadgeLevel.newbie,
        totalPoints: 0,
        nextLevelPoints: 1000,
        progressPercentage: 0.0,
      );
    } catch (e) {
      debugPrint('BadgeService reset error: $e');
      rethrow;
    }
  }

  /// Get current badge level by points (optimized)
  static BadgeLevel getLevelByPoints(int points) {
    if (points >= _thresholds[BadgeLevel.diamond]!) {
      return BadgeLevel.diamond;
    } else if (points >= _thresholds[BadgeLevel.platinum]!) {
      return BadgeLevel.platinum;
    } else if (points >= _thresholds[BadgeLevel.gold]!) {
      return BadgeLevel.gold;
    } else if (points >= _thresholds[BadgeLevel.silver]!) {
      return BadgeLevel.silver;
    } else if (points >= _thresholds[BadgeLevel.bronze]!) {
      return BadgeLevel.bronze;
    } else {
      return BadgeLevel.newbie;
    }
  }

  /// Get points needed for next level (optimized)
  static int getNextLevelPoints(BadgeLevel currentLevel) {
    final currentIndex = _levelOrder.indexOf(currentLevel);
    if (currentIndex < 0 || currentIndex >= _levelOrder.length - 1) {
      return _thresholds[BadgeLevel.diamond]!; // Max level
    }

    final nextLevel = _levelOrder[currentIndex + 1];
    return _thresholds[nextLevel]!;
  }

  /// Calculate progress percentage (0.0 to 1.0)
  static double calculateProgressPercentage(int currentPoints, BadgeLevel currentLevel) {
    if (currentLevel == BadgeLevel.diamond) return 1.0;

    final currentThreshold = _thresholds[currentLevel]!;
    final nextThreshold = getNextLevelPoints(currentLevel);

    if (nextThreshold == currentThreshold) return 1.0;

    final progress = (currentPoints - currentThreshold) / (nextThreshold - currentThreshold);
    return progress.clamp(0.0, 1.0);
  }

  /// ভেতরের core logic – level হিসাব করে notifier আপডেট
  static Future<void> _setPoints(int totalPoints, {bool save = true}) async {
    try {
      final level = getLevelByPoints(totalPoints);
      final nextLevelPoints = getNextLevelPoints(level);
      final progressPercentage = calculateProgressPercentage(totalPoints, level);

      final progress = BadgeProgress(
        level: level,
        totalPoints: totalPoints,
        nextLevelPoints: nextLevelPoints,
        progressPercentage: progressPercentage,
      );

      badgeNotifier.value = progress;

      if (save) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_pointsKey, totalPoints);
      }
    } catch (e) {
      debugPrint('BadgeService _setPoints error: $e');
      rethrow;
    }
  }

  /// Store points history for analytics
  static Future<void> _addToHistory(int points, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_pointsHistoryKey) ?? '[]';

      List<dynamic> historyList;
      try {
        historyList = jsonDecode(historyJson) as List<dynamic>;
      } catch (e) {
        historyList = [];
      }

      final history = List<Map<String, dynamic>>.from(
          historyList.map((item) => item as Map<String, dynamic>? ?? {})
      );

      history.add({
        'points': points,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
        'totalAfter': badgeNotifier.value.totalPoints,
      });

      // Keep only last 50 entries
      final limitedHistory = history.length > 50
          ? history.sublist(history.length - 50)
          : history;

      await prefs.setString(_pointsHistoryKey, jsonEncode(limitedHistory));
    } catch (e) {
      debugPrint('BadgeService _addToHistory error: $e');
      // History সেভ না হলেও মেইন পয়েন্টস সেভ হবে
    }
  }

  /// Get points history
  static Future<List<Map<String, dynamic>>> getPointsHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_pointsHistoryKey) ?? '[]';

      if (historyJson.isEmpty || historyJson == '[]') {
        return [];
      }

      final List<dynamic> parsed = jsonDecode(historyJson) as List<dynamic>;
      return List<Map<String, dynamic>>.from(
          parsed.map((item) => item as Map<String, dynamic>)
      );
    } catch (e) {
      debugPrint('BadgeService getPointsHistory error: $e');
      return [];
    }
  }

  /// Get formatted level name
  static String getFormattedLevelName(BadgeLevel level) {
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

  /// Get level description
  static String getLevelDescription(BadgeLevel level) {
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

  /// Check if user leveled up
  static bool hasLeveledUp(BadgeLevel oldLevel, BadgeLevel newLevel) {
    final oldIndex = _levelOrder.indexOf(oldLevel);
    final newIndex = _levelOrder.indexOf(newLevel);

    if (oldIndex == -1 || newIndex == -1) return false;

    return newIndex > oldIndex;
  }

  /// Clean up resources (app close করলে call করুন)
  static void dispose() {
    badgeNotifier.dispose();
  }
}import 'package:flutter/material.dart';

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

  // এই getter টি যোগ করুন
  double get percentToNext => progressPercentage;

  Color get levelColor {
    switch (level) {
      case BadgeLevel.newbie:
        return Colors.grey;
      case BadgeLevel.bronze:
        return Color(0xFFCD7F32); // Bronze color
      case BadgeLevel.silver:
        return Color(0xFFC0C0C0); // Silver color
      case BadgeLevel.gold:
        return Color(0xFFFFD700); // Gold color
      case BadgeLevel.platinum:
        return Color(0xFFE5E4E2); // Platinum color
      case BadgeLevel.diamond:
        return Color(0xFFB9F2FF); // Diamond color
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