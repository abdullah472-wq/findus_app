import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:findus_app/badge/badge_model.dart';

class BadgeService {
  static final ValueNotifier<BadgeProgress> badgeNotifier =
  ValueNotifier<BadgeProgress>(
    const BadgeProgress(badgeLevel: BadgeLevel.newbie, totalXP: 0, totalStars: 0.0),
  );

  static const String _xpKey = 'user_xp_points';
  static const String _starsKey = 'accumulated_stars';

  // ✅ Legacy Thresholds
  static const int diamondThreshold = 1000000;
  static const int platinumThreshold = 100000;
  static const int goldThreshold = 50000;
  static const int silverThreshold = 10000;
  static const int bronzeThreshold = 1000;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final xp = prefs.getInt(_xpKey) ?? 0;
    final stars = prefs.getDouble(_starsKey) ?? 0.0;
    _updateState(xp, stars, save: false);
  }

  // ✅ XP যোগ করা
  static Future<void> addPoints(int amount) async {
    await addXP(amount);
  }

  static Future<void> addXP(int amount) async {
    final current = badgeNotifier.value;
    await _updateState(current.totalXP + amount, current.totalStars);
  }

  // ✅ সার্ভার থেকে XP সিঙ্ক করা
  static Future<void> setPointsFromServer(int xp) async {
    final current = badgeNotifier.value;
    await _updateState(xp, current.totalStars);
  }

  // ✅ রিভিউ স্টার যোগ করা
  static Future<void> addReviewStars(double rating) async {
    if (rating <= 0) return;
    final current = badgeNotifier.value;
    double newTotalStars = current.totalStars + rating;
    await _updateState(current.totalXP, newTotalStars);
  }

  static Future<void> _updateState(int xp, double stars, {bool save = true}) async {
    BadgeLevel newBadge = getBadgeByStars(stars);

    badgeNotifier.value = BadgeProgress(
      badgeLevel: newBadge,
      totalXP: xp,
      totalStars: stars,
    );

    if (save) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_xpKey, xp);
      await prefs.setDouble(_starsKey, stars);
    }
  }

  // ✅ পাবলিক হেল্পার: স্টার দিয়ে ব্যাজ নির্ণয়
  static BadgeLevel getBadgeByStars(double stars) {
    if (stars >= 10000) return BadgeLevel.diamond;
    if (stars >= 5000) return BadgeLevel.platinum;
    if (stars >= 2000) return BadgeLevel.gold;
    if (stars >= 500) return BadgeLevel.silver;
    if (stars >= 100) return BadgeLevel.bronze;
    return BadgeLevel.newbie;
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ NEW: Rating + Completed Count থেকে Badge Calculate
  // ═══════════════════════════════════════════════════════════
  static BadgeLevel calculateBadgeFromStats({
    required double rating,
    required int completed,
  }) {
    // 👑 Diamond: 100+ completed, 4.8+ rating
    if (completed >= 100 && rating >= 4.8) {
      return BadgeLevel.diamond;
    }

    // 💎 Platinum: 50+ completed, 4.5+ rating
    if (completed >= 50 && rating >= 4.5) {
      return BadgeLevel.platinum;
    }

    // 🥇 Gold: 20+ completed, 4.0+ rating
    if (completed >= 20 && rating >= 4.0) {
      return BadgeLevel.gold;
    }

    // 🥈 Silver: 5+ completed, 3.5+ rating
    if (completed >= 5 && rating >= 3.5) {
      return BadgeLevel.silver;
    }

    // 🥉 Bronze: 1+ completed
    if (completed >= 1) {
      return BadgeLevel.bronze;
    }

    // 🆕 Newbie: Default
    return BadgeLevel.newbie;
  }

  // ✅ XP দিয়ে নিউমেরিক লেভেল (১-১০০)
  static int getNumericLevel(int xp) {
    if (xp <= 0) return 1;
    final lvl = (1 + math.sqrt(xp / 44)).floor();
    return lvl.clamp(1, 100);
  }

  // ✅ নির্দিষ্ট লেভেলে পৌঁছাতে কত XP লাগে
  static int getXpForLevel(int level) {
    if (level <= 1) return 0;
    return (44 * (level - 1) * (level - 1)).toInt();
  }

  // ✅ Legacy Helper: Formatted Name
  static String getFormattedLevelName(BadgeLevel level) {
    return level.toString().split('.').last.toUpperCase();
  }

  static void dispose() {
    badgeNotifier.dispose();
  }
}