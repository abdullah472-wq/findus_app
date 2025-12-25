// lib/services/achievement_service.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:findus_app/achievement//achievements_config.dart';
import 'package:findus_app/achievement//achievement_models.dart';
import 'package:findus_app/services/badge_service.dart';
import 'package:findus_app/models/badge_model.dart';     // BadgeLevel
class AchievementService {
  static const String _prefsKey = 'achievements_state_v1';

  /// সব achievement state (definition + progress)
  static final ValueNotifier<List<AchievementState>>
  achievementsNotifier =
  ValueNotifier<List<AchievementState>>([]);

  /// internal map দ্রুত lookup এর জন্য
  static final Map<String, AchievementState> _stateById = {};

  /// app start এ একবার কল করবে (main.dart এ)
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
        final st2 = _resetIfNeeded(st);
        _stateById[id] = st2;
      } catch (_) {
        // ignore invalid
      }
    }

    // config এ নতুন achievement add থাকলে, তাদের default state তৈরি
    for (final def in AchievementsConfig.all) {
      if (!_stateById.containsKey(def.id)) {
        _stateById[def.id] = AchievementState(def: def);
      }
    }

    _publish();
  }

  /// UI তে দেখাবার আগে role / XP অনুযায়ী filter করতে পারো
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

  /// progress বাড়ানো (task event থেকে কল করবে)
  static Future<void> incrementProgress(
      String achievementId, {
        int amount = 1,
      }) async {
    final def = AchievementsConfig.byId(achievementId);
    if (def == null) return;

    final current = _stateById[achievementId] ??
        AchievementState(def: def);

    // reset period check
    final st = _resetIfNeeded(current);

    // completion + claimed হলে আর বাড়ানোর দরকার নেই (resetPeriod == none)
    if (st.def.resetPeriod == ResetPeriod.none &&
        st.isCompleted &&
        st.claimed) {
      return;
    }

    final newProgress = (st.progress + amount)
        .clamp(0, def.target);

    final updated = st.copyWith(
      progress: newProgress,
      lastUpdated: DateTime.now(),
    );

    _stateById[achievementId] = updated;
    await _saveAll();
  }

  /// সরাসরি complete করে দিতে চাইলে (একবারে 100%)
  static Future<void> complete(String achievementId) async {
    final def = AchievementsConfig.byId(achievementId);
    if (def == null) return;

    final current = _stateById[achievementId] ??
        AchievementState(def: def);

    final st = _resetIfNeeded(current);

    final updated = st.copyWith(
      progress: def.target,
      lastUpdated: DateTime.now(),
    );

    _stateById[achievementId] = updated;
    await _saveAll();
  }

  /// XP claim করা – শুধুমাত্র completed কিন্তু এখনও claimed না থাকলে
  static Future<void> claim(String achievementId) async {
    final st = _stateById[achievementId];
    if (st == null) return;

    final def = st.def;

    final state = _resetIfNeeded(st);

    if (!state.isCompleted || state.claimed) {
      return; // কিছু করার নেই
    }

    // ১) BadgeService এ XP যোগ
    await BadgeService.addPoints(def.xpReward);

    // ২) state update: claimed = true
    final updated = state.copyWith(
      claimed: true,
      lastUpdated: DateTime.now(),
    );
    _stateById[achievementId] = updated;

    await _saveAll();
  }

  /// সব state prefs এ save + notifier আপডেট
  static Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();

    final listJson = _stateById.values.map((st) {
      final map = st.toJson();
      return jsonEncode(map);
    }).toList();

    await prefs.setStringList(_prefsKey, listJson);
    _publish();
  }

  static void _publish() {
    achievementsNotifier.value =
    _stateById.values.toList()
      ..sort((a, b) => a.def.id.compareTo(b.def.id));
  }

  /// Reset period (daily/weekly) চেক করে প্রয়োজনে progress reset
  static AchievementState _resetIfNeeded(
      AchievementState st) {
    final rp = st.def.resetPeriod;
    if (rp == ResetPeriod.none) return st;

    final last = st.lastUpdated;
    if (last == null) return st;

    final now = DateTime.now();

    bool needReset = false;

    if (rp == ResetPeriod.daily) {
      // দিন আলাদা হলে reset
      if (last.year != now.year ||
          last.month != now.month ||
          last.day != now.day) {
        needReset = true;
      }
    } else if (rp == ResetPeriod.weekly) {
      // simple approx: 7 দিন পেরিয়ে গেলে reset
      if (now.difference(last).inDays >= 7) {
        needReset = true;
      }
    }

    if (!needReset) return st;

    return AchievementState(def: st.def);
  }

  /// --------- Helper গুলো: worker/profile data থেকে badge/status হিসাব ---------

  /// Map থেকে rating double হিসাবে বের করা
  static double getRatingFromData(Map<String, dynamic> data) {
    final val = data['rating'];
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  /// Map থেকে completed jobs integer হিসাবে বের করা
  /// e.g. "50+", "120 jobs", 35 → 50 / 120 / 35
  static int getCompletedFromData(Map<String, dynamic> data) {
    final raw =
        data['completed'] ?? data['jobsDone'] ?? data['completedJobs'];
    if (raw == null) return 0;
    if (raw is int) return raw;

    final s = raw.toString();
    final match = RegExp(r'\d+').firstMatch(s);
    if (match == null) return 0;
    return int.tryParse(match.group(0)!) ?? 0;
  }

  /// rating + completedJobs থেকে approx points বানিয়ে,
  /// তারপর BadgeService এর threshold অনুযায়ী BadgeLevel বের করে
  static BadgeLevel getBadgeLevel({
    required double rating,
    required int completedJobs,
  }) {
    // সিম্পল point model: rating * 100 + completed * 50
    final points =
        (rating * 100).toInt() + (completedJobs * 50);

    final p = points.clamp(0, BadgeService.maxPoints);

    if (p >= BadgeService.diamondThreshold) {
      return BadgeLevel.diamond;
    } else if (p >= BadgeService.platinumThreshold) {
      return BadgeLevel.platinum;
    } else if (p >= BadgeService.goldThreshold) {
      return BadgeLevel.gold;
    } else if (p >= BadgeService.silverThreshold) {
      return BadgeLevel.silver;
    } else {
      return BadgeLevel.bronze;
    }
  }

  /// উচ্চ rating হলে Top Rated
  static bool isTopRated(double rating) => rating >= 4.8;

  /// Map থেকে verified flag (দুই নামে আসতে পারে)
  static bool isVerifiedFromData(Map<String, dynamic> data) {
    return data['verified'] == true || data['isVerified'] == true;
  }

  /// Map থেকে trusted flag (দুই নামে আসতে পারে)
  static bool isTrustedFromData(Map<String, dynamic> data) {
    return data['trusted'] == true || data['isTrusted'] == true;
  }
}