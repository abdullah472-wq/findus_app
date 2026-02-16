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

  static String _weekKey(DateTime d) {
    final firstDay = DateTime(d.year, 1, 1);
    final days = d.difference(firstDay).inDays;
    final week = (days / 7).floor() + 1;
    return "${d.year}-W${week.toString().padLeft(2, '0')}";
  }

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
        _stateById[id] = _resetIfNeeded(st);
      } catch (_) {}
    }

    for (final def in AchievementsConfig.all) {
      _stateById.putIfAbsent(def.id, () => AchievementState(def: def));
    }

    _publish();
    await syncWeeklyChestFromServer();
  }

  static Future<void> syncWeeklyChestFromServer() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    const weeklyChestId = 'weekly_daily_chest';
    final def = AchievementsConfig.byId(weeklyChestId);
    if (def == null) return;

    try {
      final statsDoc =
      await FirebaseFirestore.instance.collection('user_stats').doc(uid).get();
      final stats = statsDoc.data() ?? {};

      final now = DateTime.now();
      final wk = _weekKey(now);
      final prevKey = (stats['weekly_daily_weekKey'] ?? '').toString();

      int count = 0;
      if (prevKey == wk) {
        final raw = stats['weekly_daily_done_count'];
        if (raw is num) {
          count = raw.toInt();
        } else {
          count = int.tryParse((raw ?? '0').toString()) ?? 0;
        }
      } else {
        count = 0;
      }

      final current = _stateById[weeklyChestId] ?? AchievementState(def: def);
      final st = _resetIfNeeded(current);

      if (st.claimed) return;

      final updated = st.copyWith(
        progress: count.clamp(0, def.target),
        lastUpdated: DateTime.now(),
      );

      _stateById[weeklyChestId] = updated;
      await _saveAll();
    } catch (e) {
      debugPrint("syncWeeklyChestFromServer error: $e");
    }
  }

  // ✅ NEW METHOD: Sync Profile Chain Logic
  static Future<void> syncProfileChainFromUserDoc({String? uid}) async {
    final userId = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!doc.exists) return;

      final data = doc.data() ?? {};

      final name = (data['name'] ?? '').toString().trim();
      final location = (data['location'] ?? '').toString().trim();
      final image = (data['image'] ?? data['imageUrl'] ?? '').toString().trim();
      final about = (data['about'] ?? '').toString().trim();

      // Logic conditions
      final bool stage1 = name.isNotEmpty && location.isNotEmpty;
      final bool stage2 = stage1 && image.isNotEmpty && about.isNotEmpty;

      final String cvUrl = (data['cvUrl'] ?? '').toString().trim();
      final List<dynamic> portfolioUrls = (data['portfolioUrls'] is List) ? (data['portfolioUrls'] as List) : const [];
      final bool stage3 = stage2 && (cvUrl.isNotEmpty || portfolioUrls.isNotEmpty);

      if (stage1) await incrementProgress('lt_profile_s1', amount: 1);
      if (stage2) await incrementProgress('lt_profile_s2', amount: 1);
      if (stage3) await incrementProgress('lt_profile_s3', amount: 1);

    } catch (e) {
      debugPrint("syncProfileChainFromUserDoc error: $e");
    }
  }

  static List<AchievementState> getAllForUser({
    required bool isWorker,
    required int currentPoints,
    bool isProUser = false,
    bool hasTeam = false,
    bool ignoreChainGating = false,
  }) {
    return _stateById.values.map((st) {
      bool locked = false;
      if (st.def.proOnly && !isProUser) locked = true;
      return st.copyWith(isLocked: locked);
    }).where((st) {
      final def = st.def;

      if (def.workerOnly && !isWorker) return false;
      if (def.supporterOnly && isWorker) return false;
      if (def.teamOnly && !hasTeam) return false;

      if (!ignoreChainGating) {
        final ck = def.chainKey;
        if (ck != null && def.chainStage > 1) {
          final prevStage = def.chainStage - 1;
          final prev = _stateById.values.where((x) {
            return x.def.chainKey == ck && x.def.chainStage == prevStage;
          }).toList();

          if (prev.isEmpty) return false;
          if (prev.first.claimed != true) return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        if (a.claimed != b.claimed) return a.claimed ? 1 : -1;
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? -1 : 1;
        return a.def.minPoints.compareTo(b.def.minPoints);
      });
  }

  static Future<void> claim(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final state = _stateById[id];
    if (state == null) {
      debugPrint("claim($id): state not found");
      return;
    }

    if (!state.isCompleted || state.claimed) {
      debugPrint("claim($id): not completed or already claimed");
      return;
    }

    debugPrint("claim($id): COMPLETED, resetPeriod=${state.def.resetPeriod}");

    final updatedState = state.copyWith(claimed: true);
    _stateById[id] = updatedState;
    await _saveAll();

    // লোকাল XP / ব্যাজ পয়েন্ট আপডেট
    await BadgeService.addPoints(state.def.xpReward);

    // ✅ শুধু daily quest হলে weekly counter আপডেট হবে
    if (state.def.resetPeriod == ResetPeriod.daily) {
      debugPrint("claim($id): updating weekly_daily_done_count");
      try {
        final statsRef =
        FirebaseFirestore.instance.collection('user_stats').doc(uid);
        final now = DateTime.now();
        final wk = _weekKey(now);

        await FirebaseFirestore.instance.runTransaction((tx) async {
          final snap = await tx.get(statsRef);
          final data = snap.data() ?? {};
          final prevKey = (data['weekly_daily_weekKey'] ?? '').toString();

          if (prevKey != wk) {
            tx.set(
              statsRef,
              {
                'weekly_daily_weekKey': wk,
                'weekly_daily_done_count': 1,
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          } else {
            tx.set(
              statsRef,
              {
                'weekly_daily_done_count': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          }
        });

        await syncWeeklyChestFromServer();
      } catch (e) {
        debugPrint("Weekly counter update failed: $e");
      }
    }

    // Firestore users ডকে XP পয়েন্ট আপডেট
    try {
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
        'xpPoints': FieldValue.increment(state.def.xpReward),
        'user_badge_points': FieldValue.increment(state.def.xpReward),
      };
      await FirebaseFirestore.instance.collection('users').doc(uid).update(updateData);
    } catch (e) {
      debugPrint("Error claiming reward (remote only): $e");
    }
  }


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

  // Legacy Method
  static BadgeLevel getBadgeLevelByPoints(int totalPoints) {
    if (totalPoints >= BadgeService.diamondThreshold) return BadgeLevel.diamond;
    if (totalPoints >= BadgeService.platinumThreshold) return BadgeLevel.platinum;
    if (totalPoints >= BadgeService.goldThreshold) return BadgeLevel.gold;
    if (totalPoints >= BadgeService.silverThreshold) return BadgeLevel.silver;
    if (totalPoints >= BadgeService.bronzeThreshold) return BadgeLevel.bronze;
    return BadgeLevel.newbie;
  }

  // ✅ HELPER: Get Rating safely
  static double getRating(Map<String, dynamic> data) {
    final val = data['rating'] ?? data['user_rating'] ?? 0.0;
    return (val is num) ? val.toDouble() : double.tryParse(val.toString()) ?? 0.0;
  }

  // ✅ HELPER: Get Completed Count safely
  static int getCompletedCount(Map<String, dynamic> data) {
    final raw = data['completed'] ?? data['completedCount'] ?? 0;
    if (raw is int) return raw;
    final match = RegExp(r'\d+').firstMatch(raw.toString());
    return int.tryParse(match?.group(0) ?? '0') ?? 0;
  }
}