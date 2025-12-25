import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/badge_model.dart';

class BadgeService {
  // সব জায়গা থেকে এই notifier listen করলে প্রগ্রেস পাল্টালেই UI আপডেট হবে
  static final ValueNotifier<BadgeProgress> badgeNotifier =
  ValueNotifier<BadgeProgress>(
    const BadgeProgress(
      level: BadgeLevel.bronze,
      totalPoints: 0,
      nextLevelPoints: 1000, // প্রথম target: bronze unlock এর জন্য
    ),
  );

  static const String _pointsKey = 'user_badge_points';

  // থ্রেশহোল্ড – সব জায়গায় এগুলোই use করবে (AchievementsTab সহ)
  static const int bronzeThreshold   = 1000;
  static const int silverThreshold   = 10000;
  static const int goldThreshold     = 50000;
  static const int platinumThreshold = 100000;
  static const int diamondThreshold  = 1000000;
  static const int maxPoints         = diamondThreshold;

  /// অ্যাপ চালু হওয়া মাত্র ১বার কল করবেন (main.dart এ)
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final points = prefs.getInt(_pointsKey) ?? 0;
    _setPoints(points, save: false);
  }

  /// যখনই কিছু অ্যাকশনে এক্সপি দিতে চান (job complete, good rating ইত্যাদি)
  static Future<void> addPoints(int value) async {
    final current = badgeNotifier.value;
    final newPoints =
    (current.totalPoints + value).clamp(0, maxPoints);
    await _setPoints(newPoints);
  }

  /// নির্দিষ্ট পয়েন্টে সেট করতে চাইলে (server থেকে আসলে)
  static Future<void> setPointsFromServer(int value) async {
    await _setPoints(value.clamp(0, maxPoints));
  }

  /// ভেতরের core logic – level হিসাব করে notifier আপডেট
  static Future<void> _setPoints(int totalPoints,
      {bool save = true}) async {
    final BadgeLevel level;
    final int nextLevelPoints;

    // উপরের থেকে নিচে নামি – সর্বোচ্চ লেভেল চেক আগে
    if (totalPoints >= diamondThreshold) {
      level = BadgeLevel.diamond;
      nextLevelPoints = diamondThreshold; // max
    } else if (totalPoints >= platinumThreshold) {
      level = BadgeLevel.platinum;
      nextLevelPoints = diamondThreshold;
    } else if (totalPoints >= goldThreshold) {
      level = BadgeLevel.gold;
      nextLevelPoints = platinumThreshold;
    } else if (totalPoints >= silverThreshold) {
      level = BadgeLevel.silver;
      nextLevelPoints = goldThreshold;
    } else if (totalPoints >= bronzeThreshold) {
      // Bronze already unlocked, next target Silver
      level = BadgeLevel.bronze;
      nextLevelPoints = silverThreshold;
    } else {
      // একদম নতুন → Bronze এর নীচে, target Bronze unlock point
      level = BadgeLevel.bronze;
      nextLevelPoints = bronzeThreshold;
    }

    final progress = BadgeProgress(
      level: level,
      totalPoints: totalPoints,
      nextLevelPoints: nextLevelPoints,
    );

    badgeNotifier.value = progress;

    if (save) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_pointsKey, totalPoints);
    }
  }
}