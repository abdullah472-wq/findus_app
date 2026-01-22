// lib/services/achievement_service.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ✅ শুধু এই ইম্পোর্টগুলো রাখুন
import 'package:findus_app/achievement/achievements_config.dart';
import 'package:findus_app/achievement/achievement_models.dart';
import 'package:findus_app/badge/badge_service.dart';
import 'package:findus_app/badge/badge_model.dart';

class AchievementService {
  static const String _prefsKey = 'achievements_state_v1';

  static final ValueNotifier<List<AchievementState>> achievementsNotifier =
  ValueNotifier<List<AchievementState>>([]);

  static final Map<String, AchievementState> _stateById = {};

  /// অ্যাপ স্টার্টে ডাটা লোড করা
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = prefs.getStringList(_prefsKey) ?? [];

    _stateById.clear();

    for (final raw in listJson) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final id = map['id'] as String?;
        if (id == null) continue;

        final def = AchievementsConfig.byId(id);
        if (def == null) continue;

        final st = AchievementState.fromJson(def, map);
        // ✅ ডেইলি/উইকলি চেক করে রিসেট করা
        _stateById[id] = _resetIfNeeded(st);
      } catch (_) {}
    }

    // নতুন কোনো টাস্ক থাকলে ডিফল্ট স্টেট যোগ করা
    for (final def in AchievementsConfig.all) {
      _stateById.putIfAbsent(def.id, () => AchievementState(def: def));
    }

    _publish();
  }

  /// রিওয়ার্ড (XP) ক্লেইম করা
  static Future<void> claim(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // নটিফায়ার থেকে স্টেট খুঁজে বের করা
    final state = _stateById[id];
    if (state == null) return;

    if (state.isCompleted && !state.claimed) {
      try {
        debugPrint("Claiming reward for: $id");

        // ✅ ১. Firestore আপডেট (ইউজারের টোটাল XP বাড়ানো)
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'xpPoints': FieldValue.increment(state.def.xpReward),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // ✅ ২. ক্লেইম হিস্ট্রি রাখা (ডেইলি কোয়েস্ট ট্র্যাকিংয়ের জন্য)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('claimed_achievements')
            .doc(id)
            .set({
          'claimedAt': FieldValue.serverTimestamp(),
          'xpEarned': state.def.xpReward,
          'period': state.def.resetPeriod.toString(),
        });

        // ✅ ৩. লোকাল স্টেট আপডেট ও সেভ (এটিই মিসিং ছিল)
        final updatedState = state.copyWith(claimed: true);
        _stateById[id] = updatedState;

        // সেভ করা যাতে অ্যাপ রিস্টার্ট দিলেও 'Claimed' থাকে
        await _saveAll();

        // ✅ ৪. লোকাল BadgeService আপডেট (UI-তে XP সাথে সাথে বাড়বে)
        await BadgeService.addPoints(state.def.xpReward);

        debugPrint("Successfully claimed reward for: $id");

      } catch (e) {
        debugPrint("Error claiming reward: $e");
        rethrow;
      }
    }
  }

  /// প্রগ্রেস বাড়ানো (যেমন: ১টি কাজ শেষ করলে কল হবে)
  static Future<void> incrementProgress(String achievementId, {int amount = 1}) async {
    final def = AchievementsConfig.byId(achievementId);
    if (def == null) return;

    final current = _stateById[achievementId] ?? AchievementState(def: def);
    final st = _resetIfNeeded(current);

    // যদি ওয়ান-টাইম টাস্ক হয় এবং অলরেডি ক্লেইমড হয়, তবে আর বাড়বে না
    if (st.def.resetPeriod == ResetPeriod.none && st.claimed) return;

    final updated = st.copyWith(
      progress: (st.progress + amount).clamp(0, def.target),
      lastUpdated: DateTime.now(),
    );

    _stateById[achievementId] = updated;
    await _saveAll();
  }

  /// ডাটা পাবলিশ ও সেভ করা
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

  /// ✅ ডেইলি/উইকলি রিসেট লজিক (ইম্প্রুভড)
  static AchievementState _resetIfNeeded(AchievementState st) {
    if (st.def.resetPeriod == ResetPeriod.none || st.lastUpdated == null) return st;

    final now = DateTime.now();
    final last = st.lastUpdated!;
    bool needReset = false;

    if (st.def.resetPeriod == ResetPeriod.daily) {
      // যদি তারিখ বদলে যায়
      needReset = last.day != now.day || last.month != now.month || last.year != now.year;
    } else if (st.def.resetPeriod == ResetPeriod.weekly) {
      // যদি ৭ দিনের বেশি হয়ে যায়
      needReset = now.difference(last).inDays >= 7;
    }

    // রিসেট হলে প্রগ্রেস ০ এবং ক্লেইমড ফলস হয়ে যাবে
    if (needReset) {
      debugPrint("Resetting task: ${st.def.title}");
      return AchievementState(def: st.def);
    }

    return st;
  }

  static List<AchievementState> getAllForUser({
    required bool isWorker,
    required int currentPoints,
  }) {
    return _stateById.values.where((st) {
      final def = st.def;
      if (def.workerOnly && !isWorker) return false;
      if (def.supporterOnly && isWorker) return false;
      if (currentPoints < def.minPoints) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.def.id.compareTo(b.def.id));
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
    return BadgeLevel.bronze;
  }
}