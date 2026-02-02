// lib/services/achievement_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:findus_app/achievement/achievements_config.dart';
import 'package:findus_app/achievement/achievement_models.dart';
import 'package:findus_app/badge/badge_service.dart';
import 'package:findus_app/badge/badge_model.dart';

class AchievementService {
  static const String _prefsKey = 'achievements_state_v2';

  static final ValueNotifier<List<AchievementState>> achievementsNotifier =
  ValueNotifier<List<AchievementState>>([]);

  static final Map<String, AchievementState> _stateById = {};

  /// অ্যাপ স্টার্টে ডাটা লোড করা
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = prefs.getStringList(_prefsKey) ?? [];

    _stateById.clear();

    // ১. লোকাল স্টোরেজ থেকে লোড করা
    for (final raw in listJson) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final id = map['id'] as String?;
        if (id == null) continue;

        final def = AchievementsConfig.byId(id);
        if (def == null) continue;

        final st = AchievementState.fromJson(def, map);
        _stateById[id] = _resetIfNeeded(st);
      } catch (_) {}
    }

    // ২. নতুন বা মিসিং টাস্কগুলো কনফিগ থেকে যোগ করা
    for (final def in AchievementsConfig.all) {
      _stateById.putIfAbsent(def.id, () => AchievementState(def: def));
    }

    _publish();
  }

  /// ✅ Updated: Get all achievements for user
  static List<AchievementState> getAllForUser({
    required bool isWorker,
    required int currentPoints,
  }) {
    return _stateById.values.where((st) {
      final def = st.def;

      // ১. রোলের ভিত্তিতে ফিল্টার
      if (def.workerOnly && !isWorker) return false;
      if (def.supporterOnly && isWorker) return false;

      // ২. আনলকড ফিল্টার (অপশনাল)
      // if (currentPoints < def.minPoints) return false;

      return true;
    }).toList()
      ..sort((a, b) {
        if (a.claimed != b.claimed) return a.claimed ? 1 : -1;
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? -1 : 1;
        return a.def.minPoints.compareTo(b.def.minPoints);
      });
  }

  /// ✅ Get active achievements
  static List<AchievementState> getActiveAchievements({
    required bool isWorker,
    required int currentPoints,
  }) {
    return getAllForUser(isWorker: isWorker, currentPoints: currentPoints)
        .where((st) => !st.claimed)
        .toList();
  }

  /// ✅ Get completed achievements
  static List<AchievementState> getCompletedAchievements({
    required bool isWorker,
    required int currentPoints,
  }) {
    return getAllForUser(isWorker: isWorker, currentPoints: currentPoints)
        .where((st) => st.claimed)
        .toList();
  }

  /// 🔥 REWARD CLAIM METHOD (Role Based XP)
  static Future<void> claim(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final state = _stateById[id];
    if (state == null) return;

    if (!state.isCompleted || state.claimed) return;

    debugPrint("Claiming reward for: $id");

    // ১. লোকালি আপডেট
    final updatedState = state.copyWith(claimed: true);
    _stateById[id] = updatedState;
    await _saveAll();

    // ২. রোল চেক করা (Worker/Supporter)
    // টাস্কটি কোন রোলের জন্য, সেই অনুযায়ী ফিল্ড ঠিক করা
    String specificXpField = '';

    if (state.def.workerOnly) {
      specificXpField = 'worker_xp';
    } else if (state.def.supporterOnly) {
      specificXpField = 'supporter_xp';
    } else {
      // কমন টাস্ক হলে দুটি ফিল্ডেই পয়েন্ট যোগ করা যেতে পারে বা মেইন 'xpPoints' এ রাখা যেতে পারে
      // আপাতত আমরা কমন টাস্কের পয়েন্ট মেইন 'xpPoints' এ রাখছি
      specificXpField = 'xpPoints';
    }

    // ৩. লোকাল সার্ভিসে XP যোগ করা (যাতে UI সাথে সাথে আপডেট হয়)
    await BadgeService.addPoints(state.def.xpReward);

    try {
      // ৪. ফায়ারবেসে নির্দিষ্ট ফিল্ডে আপডেট
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
        // মেইন XP সবসময় বাড়বে (Total XP)
        'xpPoints': FieldValue.increment(state.def.xpReward),
        // ব্যাকওয়ার্ড কম্প্যাটিবিলিটি
        'user_badge_points': FieldValue.increment(state.def.xpReward),
      };

      // স্পেসিফিক রোলের XP ফিল্ড আপডেট (যদি থাকে)
      if (specificXpField == 'worker_xp') {
        updateData['worker_xp'] = FieldValue.increment(state.def.xpReward);
      } else if (specificXpField == 'supporter_xp') {
        updateData['supporter_xp'] = FieldValue.increment(state.def.xpReward);
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update(updateData);

      // ৫. ক্লেইম হিস্ট্রি সেভ করা
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('claimed_achievements')
          .doc(id)
          .set({
        'claimedAt': FieldValue.serverTimestamp(),
        'xpEarned': state.def.xpReward,
        'period': state.def.resetPeriod.toString(),
        'type': state.def.workerOnly ? 'worker' : (state.def.supporterOnly ? 'supporter' : 'common'),
      });

      debugPrint("Successfully claimed reward for: $id");
    } catch (e) {
      debugPrint("Error claiming reward (remote only): $e");
    }
  }

  /// প্রগ্রেস বাড়ানো
  static Future<void> incrementProgress(String achievementId, {int amount = 1}) async {
    final def = AchievementsConfig.byId(achievementId);
    if (def == null) return;

    final current = _stateById[achievementId] ?? AchievementState(def: def);
    final st = _resetIfNeeded(current);

    if (st.def.resetPeriod == ResetPeriod.none && st.claimed) return;

    final updated = st.copyWith(
      progress: (st.progress + amount).clamp(0, def.target),
      lastUpdated: DateTime.now(),
    );

    _stateById[achievementId] = updated;
    await _saveAll();
  }

  static Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = _stateById.values.map((st) => jsonEncode(st.toJson())).toList();
    await prefs.setStringList(_prefsKey, listJson);
    _publish();
  }

  static void _publish() {
    achievementsNotifier.value = _stateById.values.toList()
      ..sort((a, b) => a.def.id.compareTo(b.def.id));
  }

  static AchievementState _resetIfNeeded(AchievementState st) {
    if (st.def.resetPeriod == ResetPeriod.none || st.lastUpdated == null) return st;

    final now = DateTime.now();
    final last = st.lastUpdated!;
    bool needReset = false;

    if (st.def.resetPeriod == ResetPeriod.daily) {
      needReset = last.day != now.day || last.month != now.month || last.year != now.year;
    } else if (st.def.resetPeriod == ResetPeriod.weekly) {
      needReset = now.difference(last).inDays >= 7;
    }

    if (needReset) {
      return AchievementState(def: st.def);
    }
    return st;
  }

  // --- হেল্পার্স ---
  static double getRating(Map<String, dynamic> data) {
    final val = data['rating'] ?? data['user_rating'] ?? 0.0;
    return (val is num) ? val.toDouble() : double.tryParse(val.toString()) ?? 0.0;
  }

  static int getCompletedCount(Map<String, dynamic> data) {
    final raw = data['completed'] ?? data['completedCount'] ?? 0;
    if (raw is int) return raw;
    final match = RegExp(r'\d+').firstMatch(raw.toString());
    return int.tryParse(match?.group(0) ?? '0') ?? 0;
  }

  static BadgeLevel getBadgeLevelByPoints(int totalPoints) {
    if (totalPoints >= BadgeService.diamondThreshold) return BadgeLevel.diamond;
    if (totalPoints >= BadgeService.platinumThreshold) return BadgeLevel.platinum;
    if (totalPoints >= BadgeService.goldThreshold) return BadgeLevel.gold;
    if (totalPoints >= BadgeService.silverThreshold) return BadgeLevel.silver;
    if (totalPoints >= BadgeService.bronzeThreshold) return BadgeLevel.bronze;
    return BadgeLevel.newbie;
  }
}