import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ মডেল ইম্পোর্ট করা হলো
import 'package:findus_app/badge/badge_model.dart';

class BadgeService {
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

  static const Map<BadgeLevel, int> _thresholds = {
    BadgeLevel.newbie: 0,
    BadgeLevel.bronze: 1000,
    BadgeLevel.silver: 10000,
    BadgeLevel.gold: 50000,
    BadgeLevel.platinum: 100000,
    BadgeLevel.diamond: 1000000,
  };

  static int get newbieThreshold => _thresholds[BadgeLevel.newbie]!;
  static int get bronzeThreshold => _thresholds[BadgeLevel.bronze]!;
  static int get silverThreshold => _thresholds[BadgeLevel.silver]!;
  static int get goldThreshold => _thresholds[BadgeLevel.gold]!;
  static int get platinumThreshold => _thresholds[BadgeLevel.platinum]!;
  static int get diamondThreshold => _thresholds[BadgeLevel.diamond]!;

  static final List<BadgeLevel> _levelOrder = [
    BadgeLevel.newbie,
    BadgeLevel.bronze,
    BadgeLevel.silver,
    BadgeLevel.gold,
    BadgeLevel.platinum,
    BadgeLevel.diamond,
  ];

  static int get maxPoints => _thresholds[BadgeLevel.diamond]!;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final points = prefs.getInt(_pointsKey) ?? 0;
      await _setPoints(points, save: false);
    } catch (e) {
      debugPrint('BadgeService init error: $e');
      badgeNotifier.value = const BadgeProgress(
        level: BadgeLevel.newbie,
        totalPoints: 0,
        nextLevelPoints: 1000,
        progressPercentage: 0.0,
      );
    }
  }

  static Future<void> addPoints(int value, {String? reason}) async {
    if (value <= 0) return;
    try {
      final current = badgeNotifier.value;
      final newPoints = (current.totalPoints + value).clamp(0, maxPoints);
      await _setPoints(newPoints);
      if (reason != null) {
        await _addToHistory(value, reason);
      }
    } catch (e) {
      debugPrint('BadgeService addPoints error: $e');
      rethrow;
    }
  }

  static Future<void> setPointsFromServer(int value) async {
    try {
      final normalized = value.clamp(0, maxPoints);
      if (badgeNotifier.value.totalPoints == normalized) return;
      await _setPoints(normalized);
    } catch (e) {
      debugPrint('BadgeService setPointsFromServer error: $e');
      rethrow;
    }
  }

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

  static BadgeLevel getLevelByPoints(int points) {
    if (points >= _thresholds[BadgeLevel.diamond]!) return BadgeLevel.diamond;
    if (points >= _thresholds[BadgeLevel.platinum]!) return BadgeLevel.platinum;
    if (points >= _thresholds[BadgeLevel.gold]!) return BadgeLevel.gold;
    if (points >= _thresholds[BadgeLevel.silver]!) return BadgeLevel.silver;
    if (points >= _thresholds[BadgeLevel.bronze]!) return BadgeLevel.bronze;
    return BadgeLevel.newbie;
  }

  static int getNextLevelPoints(BadgeLevel currentLevel) {
    final currentIndex = _levelOrder.indexOf(currentLevel);
    if (currentIndex < 0 || currentIndex >= _levelOrder.length - 1) {
      return _thresholds[BadgeLevel.diamond]!;
    }
    final nextLevel = _levelOrder[currentIndex + 1];
    return _thresholds[nextLevel]!;
  }

  static double calculateProgressPercentage(int currentPoints, BadgeLevel currentLevel) {
    if (currentLevel == BadgeLevel.diamond) return 1.0;
    final currentThreshold = _thresholds[currentLevel]!;
    final nextThreshold = getNextLevelPoints(currentLevel);
    if (nextThreshold == currentThreshold) return 1.0;
    final progress = (currentPoints - currentThreshold) / (nextThreshold - currentThreshold);
    return progress.clamp(0.0, 1.0);
  }

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
      final limitedHistory = history.length > 50
          ? history.sublist(history.length - 50)
          : history;
      await prefs.setString(_pointsHistoryKey, jsonEncode(limitedHistory));
    } catch (e) {
      debugPrint('BadgeService _addToHistory error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getPointsHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_pointsHistoryKey) ?? '[]';
      if (historyJson.isEmpty || historyJson == '[]') return [];
      final List<dynamic> parsed = jsonDecode(historyJson) as List<dynamic>;
      return List<Map<String, dynamic>>.from(
          parsed.map((item) => item as Map<String, dynamic>)
      );
    } catch (e) {
      debugPrint('BadgeService getPointsHistory error: $e');
      return [];
    }
  }

  static String getFormattedLevelName(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.newbie: return 'Newbie';
      case BadgeLevel.bronze: return 'Bronze';
      case BadgeLevel.silver: return 'Silver';
      case BadgeLevel.gold: return 'Gold';
      case BadgeLevel.platinum: return 'Platinum';
      case BadgeLevel.diamond: return 'Diamond';
    }
  }

  static String getLevelDescription(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.newbie: return 'Just getting started';
      case BadgeLevel.bronze: return 'Beginner level, keep going!';
      case BadgeLevel.silver: return 'Intermediate level, you\'re doing great!';
      case BadgeLevel.gold: return 'Advanced level, top performer!';
      case BadgeLevel.platinum: return 'Expert level, outstanding work!';
      case BadgeLevel.diamond: return 'Master level, you are a legend!';
    }
  }

  static bool hasLeveledUp(BadgeLevel oldLevel, BadgeLevel newLevel) {
    final oldIndex = _levelOrder.indexOf(oldLevel);
    final newIndex = _levelOrder.indexOf(newLevel);
    if (oldIndex == -1 || newIndex == -1) return false;
    return newIndex > oldIndex;
  }

  static void dispose() {
    badgeNotifier.dispose();
  }
}