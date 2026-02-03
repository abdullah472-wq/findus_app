import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/achievement/achievement_models.dart';
import 'package:findus_app/badge/badge_service.dart';
import 'package:findus_app/screens/profile/support_post_screen.dart';
import 'package:findus_app/screens/profile/earn_post_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_edit_screen.dart';
import 'package:findus_app/screens/profile/worker_documents_screen.dart';

class AchievementsTab extends StatefulWidget {
  const AchievementsTab({super.key});

  @override
  State<AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<AchievementsTab> {
  bool _isLoading = true;
  bool _showCompleted = false;

  // role
  bool _isWorker = true; // your app naming: finder = worker side

  int _totalXpEarned = 0;
  int _totalAchievements = 0;
  int _completedAchievements = 0;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  late ConfettiController _confettiController;
  late VoidCallback _badgeListener;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    _badgeListener = () {
      if (!mounted) return;
      _updateStats();
      setState(() {});
    };
    BadgeService.badgeNotifier.addListener(_badgeListener);

    _listenUserDoc();
    _updateStats();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    BadgeService.badgeNotifier.removeListener(_badgeListener);
    _userSub?.cancel();
    super.dispose();
  }

  void _listenUserDoc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _userSub?.cancel();
    _userSub = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((snap) {
      if (!snap.exists) return;
      final data = snap.data() ?? {};

      // XP sync
      final rawXp = data['xpPoints'] ?? 0;
      final int xp = rawXp is num ? rawXp.toInt() : int.tryParse(rawXp.toString()) ?? 0;
      BadgeService.setPointsFromServer(xp);

      // role
      final role = (data['userRole'] ?? 'finder').toString().toLowerCase();
      // you said two roles: finder + maker (supporter). Finder side = worker tasks
      final bool isWorker = role == 'finder';

      if (!mounted) return;
      setState(() {
        _isWorker = isWorker;
        _isLoading = false;
      });

      _updateStats();
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _updateStats() {
    final points = BadgeService.badgeNotifier.value.totalPoints;

    final all = AchievementService.getAllForUser(isWorker: _isWorker, currentPoints: points);

    int totalXp = 0;
    int completed = 0;
    for (final st in all) {
      if (st.claimed) {
        totalXp += st.def.xpReward;
        completed++;
      }
    }

    if (!mounted) return;
    setState(() {
      _totalXpEarned = totalXp;
      _totalAchievements = all.length;
      _completedAchievements = completed;
    });
  }

  // -----------------------
  // CoC-style board pickers
  // -----------------------

  List<AchievementState> _dailyBoard({required bool bonus}) {
    final points = BadgeService.badgeNotifier.value.totalPoints;

    // daily only
    final list = AchievementService.getAllForUser(isWorker: _isWorker, currentPoints: points)
        .where((st) => st.def.resetPeriod == ResetPeriod.daily)
        .where((st) => _showCompleted ? st.claimed : !st.claimed)
        .toList();

    // Sort: claimable > active > others
    list.sort((a, b) {
      final aClaim = (a.isCompleted && !a.claimed) ? 0 : (a.claimed ? 2 : 1);
      final bClaim = (b.isCompleted && !b.claimed) ? 0 : (b.claimed ? 2 : 1);
      if (aClaim != bClaim) return aClaim.compareTo(bClaim);
      // closer to completion first
      final aPct = a.def.target == 0 ? 0.0 : a.progress / a.def.target;
      final bPct = b.def.target == 0 ? 0.0 : b.progress / b.def.target;
      return bPct.compareTo(aPct);
    });

    // 5 core + 2 bonus
    if (list.isEmpty) return [];

    if (!bonus) {
      return list.take(5).toList();
    } else {
      return list.skip(5).take(2).toList();
    }
  }

  AchievementState? _weeklyBigMission() {
    final points = BadgeService.badgeNotifier.value.totalPoints;

    final weekly = AchievementService.getAllForUser(isWorker: _isWorker, currentPoints: points)
        .where((st) => st.def.resetPeriod == ResetPeriod.weekly)
        .where((st) => _showCompleted ? st.claimed : !st.claimed)
        .toList();

    if (weekly.isEmpty) return null;

    // pick: highest reward / or most-progressing
    weekly.sort((a, b) {
      // claimable first
      final aC = (a.isCompleted && !a.claimed) ? 0 : 1;
      final bC = (b.isCompleted && !b.claimed) ? 0 : 1;
      if (aC != bC) return aC.compareTo(bC);
      // higher xp reward first
      return b.def.xpReward.compareTo(a.def.xpReward);
    });

    return weekly.first;
  }

  List<AchievementState> _longTermMissions() {
    final points = BadgeService.badgeNotifier.value.totalPoints;

    final onetime = AchievementService.getAllForUser(isWorker: _isWorker, currentPoints: points)
        .where((st) => st.def.resetPeriod == ResetPeriod.none)
        .where((st) => _showCompleted ? st.claimed : !st.claimed)
        .toList();

    // Sort: claimable first, then completed, then minPoints
    onetime.sort((a, b) {
      final aClaimable = a.isCompleted && !a.claimed;
      final bClaimable = b.isCompleted && !b.claimed;
      if (aClaimable != bClaimable) return aClaimable ? -1 : 1;
      if (a.claimed != b.claimed) return a.claimed ? 1 : -1;
      return a.def.minPoints.compareTo(b.def.minPoints);
    });

    return onetime;
  }

  String _formatPoints(int points) {
    if (points >= 1000000) return "${(points / 1000000).toStringAsFixed(1)}M";
    if (points >= 1000) return "${(points / 1000).toStringAsFixed(1)}K";
    return points.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHero(isDark),
                const SizedBox(height: 12),
                _buildToggle(isDark),
                const SizedBox(height: 12),

                // Daily Board
                _buildSectionTitle("DAILY BOARD", "5 quests + 2 bonus", Icons.today, isDark),
                _buildDailyBoard(isDark),

                const SizedBox(height: 18),

                // Weekly
                _buildSectionTitle("WEEKLY BIG MISSION", "Big reward, resets weekly", Icons.date_range, isDark),
                _buildWeeklyMission(isDark),

                const SizedBox(height: 18),

                // Long-term
                _buildSectionTitle("LONG-TERM MISSIONS", "Permanent progress", Icons.flag, isDark),
                _buildLongTermGrid(isDark),

                const SizedBox(height: 100),
              ],
            ),
          ),

          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
        ],
      ),
    );
  }

  Widget _buildHero(bool isDark) {
    final progress = BadgeService.badgeNotifier.value;
    final levelColor = progress.levelColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandMain.withOpacity(0.9), AppColors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "QUESTS",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white),
                  onPressed: _showInfoDialog,
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: levelColor.withOpacity(0.18),
                          border: Border.all(color: levelColor, width: 2),
                        ),
                        child: Icon(Icons.workspace_premium, color: levelColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TOTAL XP",
                              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75)),
                            ),
                            Text(
                              "${_formatPoints(progress.totalPoints)} XP",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${_formatPoints(progress.pointsToNextLevel)} XP to next",
                              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "COMPLETED",
                            style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7)),
                          ),
                          Text(
                            "$_completedAchievements/$_totalAchievements",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.progressPercentage.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(levelColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat("Total XP Earned", _formatPoints(_totalXpEarned), Icons.emoji_events, Colors.amber),
                _miniStat("Active", "${_totalAchievements - _completedAchievements}", Icons.timeline, Colors.blue),
                _miniStat("Role", _isWorker ? "Finder" : "Supporter", Icons.person, Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.18), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 10)),
      ],
    );
  }

  Widget _buildToggle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showCompleted = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: !_showCompleted ? AppColors.brandMain : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Active",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: !_showCompleted ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showCompleted = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _showCompleted ? AppColors.brandMain : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Completed",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _showCompleted ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle, IconData icon, bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final sub = isDark ? Colors.white60 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brandMain, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.0)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: sub)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBoard(bool isDark) {
    final core = _dailyCore();
    final bonus = _dailyBonus();

    if (core.isEmpty && bonus.isEmpty) {
      return _buildBoardEmpty(isDark, "No daily quests found.");
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ...core.map((st) => _buildQuestRowCard(st, isDark, starTier: 1)),
          if (bonus.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildBonusHeader(isDark),
            ...bonus.map((st) => _buildQuestRowCard(st, isDark, starTier: 1)),
          ],
        ],
      ),
    );
  }

  Widget _buildBonusHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.add_circle_outline, color: Colors.amber.shade700, size: 18),
          const SizedBox(width: 8),
          Text(
            "BONUS QUESTS",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: isDark ? Colors.white : AppColors.brandDark,
            ),
          ),
          const Spacer(),
          Text("2", style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildWeeklyMission(bool isDark) {
    final st = _weeklyBigMissionPick();
    if (st == null) return _buildBoardEmpty(isDark, "No weekly missions available.");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildWeeklyCard(st, isDark),
    );
  }

  Widget _buildLongTermGrid(bool isDark) {
    final list = _longTermPick();
    if (list.isEmpty) return _buildBoardEmpty(isDark, "No long-term missions found.");

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.92,
        ),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final st = list[i];
          final tier = _estimateTier(st);
          return _buildQuestGridCard(st, isDark, tier);
        },
      ),
    );
  }

  int _estimateTier(AchievementState st) {
    // Very simple heuristic for ⭐/⭐⭐/⭐⭐⭐ feel
    final t = st.def.target;
    final r = st.def.xpReward;
    if (r >= 5000 || t >= 20) return 3;
    if (r >= 1500 || t >= 5) return 2;
    return 1;
  }

  // -----------------------
  // Quest cards
  // -----------------------

  Widget _questRowCard(AchievementState st, bool isDark, {required int starTier}) {
    final canClaim = st.isCompleted && !st.claimed;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final sub = isDark ? Colors.white60 : Colors.black54;

    final pct = st.def.target == 0 ? 0.0 : (st.progress / st.def.target).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _showAchievementDetails(st),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canClaim ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200),
            width: canClaim ? 2 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _stars(starTier),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(st.def.title, style: TextStyle(fontWeight: FontWeight.w900, color: textColor)),
                      const SizedBox(height: 3),
                      Text(
                        st.def.description,
                        style: TextStyle(fontSize: 11, color: sub),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _xpPill(st.def.xpReward),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(canClaim ? Colors.green : AppColors.brandMain),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text("${st.progress}/${st.def.target}", style: TextStyle(fontSize: 11, color: sub)),
                const Spacer(),
                if (canClaim)
                  ElevatedButton(
                    onPressed: () => _claim(st),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                    ),
                    child: const Text("CLAIM", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                else if (!st.claimed)
                  OutlinedButton(
                    onPressed: () => _navigateToTask(st.def.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandMain,
                      side: const BorderSide(color: AppColors.brandMain),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_getButtonLabel(st.def.id), style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                    child: const Text(
                      "COMPLETED",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _weeklyCard(AchievementState st, bool isDark) {
    final canClaim = st.isCompleted && !st.claimed;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final sub = isDark ? Colors.white60 : Colors.black54;

    final pct = st.def.target == 0 ? 0.0 : (st.progress / st.def.target).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _showAchievementDetails(st),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: canClaim ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200), width: canClaim ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _stars(3),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(st.def.title, style: TextStyle(fontWeight: FontWeight.w900, color: textColor, fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(st.def.description, style: TextStyle(fontSize: 12, color: sub)),
                    ],
                  ),
                ),
                _xpPill(st.def.xpReward),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(canClaim ? Colors.green : Colors.blue),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text("${st.progress}/${st.def.target}", style: TextStyle(fontSize: 12, color: sub)),
                const Spacer(),
                if (canClaim)
                  ElevatedButton.icon(
                    onPressed: () => _claim(st),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("CLAIM", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                else if (!st.claimed)
                  OutlinedButton.icon(
                    onPressed: () => _navigateToTask(st.def.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(_getButtonLabel(st.def.id), style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                    child: const Text("COMPLETED", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _questGridCard(AchievementState st, bool isDark, int tier) {
    final canClaim = st.isCompleted && !st.claimed;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final sub = isDark ? Colors.white60 : Colors.black54;

    final pct = st.def.target == 0 ? 0.0 : (st.progress / st.def.target).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _showAchievementDetails(st),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: canClaim ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200), width: canClaim ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _stars(tier),
                const Spacer(),
                _xpPill(st.def.xpReward),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              st.def.title,
              style: TextStyle(fontWeight: FontWeight.w900, color: textColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              st.def.description,
              style: TextStyle(fontSize: 11, color: sub),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(canClaim ? Colors.green : AppColors.brandMain),
              ),
            ),
            const SizedBox(height: 10),
            if (canClaim)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _claim(st),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text("CLAIM", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            else if (!st.claimed)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _navigateToTask(st.def.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandMain,
                    side: const BorderSide(color: AppColors.brandMain),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(_getButtonLabel(st.def.id), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            else
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Text("COMPLETED", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyBox(bool isDark, String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Text(
          msg,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
      ),
    );
  }

  Widget _stars(int tier) {
    tier = tier.clamp(1, 3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final active = i < tier;
        return Icon(
          active ? Icons.star_rounded : Icons.star_border_rounded,
          size: 18,
          color: active ? Colors.amber : Colors.grey.withOpacity(0.5),
        );
      }),
    );
  }

  Widget _xpPill(int xp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.amber.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, color: Colors.amber, size: 14),
          const SizedBox(width: 5),
          Text("+$xp", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _claim(AchievementState st) async {
    HapticFeedback.heavyImpact();
    _confettiController.play();
    await AchievementService.claim(st.def.id);
    if (mounted) setState(() {});
  }

  // -----------------------
  // Existing task navigation
  // -----------------------
  String _getButtonLabel(String id) {
    if (id.contains('portfolio') || id.contains('cv')) return "Upload Now";
    if (id.contains('job')) return "Post Job";
    if (id.contains('earn')) return "Create Pin";
    if (id.contains('profile')) return "Edit Profile";
    if (id.contains('login')) return "Check In";
    if (id.contains('share')) return "Share Now";
    return "Start Now";
  }

  void _navigateToTask(String id) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (id.contains('portfolio') || id.contains('cv') || id.contains('upload')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerDocumentsScreen(uid: uid, isOwner: true)));
    } else if (id.contains('job') || id.contains('post')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPostScreen()));
    } else if (id.contains('earn') || id.contains('pin')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const EarnPostScreen()));
    } else if (id.contains('profile')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => UnifiedProfileEditScreen(uid: uid)));
    } else if (id.contains('login')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Daily check-in recorded!")));
    } else if (id.contains('share')) {
      _shareProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action not available")));
    }
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Share feature coming soon!")));
  }

  // -----------------------
  // Details bottom sheet
  // -----------------------
  void _showAchievementDetails(AchievementState st) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _detailsSheet(st),
    );
  }

  Widget _detailsSheet(AchievementState st) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canClaim = st.isCompleted && !st.claimed;

    final pct = st.def.target == 0 ? 0.0 : (st.progress / st.def.target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(26), topRight: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(st.def.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Text(st.def.description, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          _xpPill(st.def.xpReward),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 12,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(canClaim ? Colors.green : AppColors.brandMain),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text("${st.progress}/${st.def.target}", style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
              const Spacer(),
              Text("${(pct * 100).toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            ],
          ),
          const SizedBox(height: 16),
          if (canClaim)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _claim(st);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text("CLAIM REWARD", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          else if (!st.claimed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToTask(st.def.id);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandMain, foregroundColor: Colors.white),
                child: Text(_getButtonLabel(st.def.id), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: const Center(
                child: Text("COMPLETED", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ),
          const SizedBox(height: 10),
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CLOSE", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54))),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Quest Guide"),
        content: const Text(
          "Daily Board: 5 core quests + 2 bonus\n"
              "Weekly Big Mission: big reward, resets weekly\n"
              "Long-term: permanent missions\n\n"
              "Complete quests → claim XP → level up.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  List<AchievementState> _dailyCore() {
    final points = BadgeService.badgeNotifier.value.totalPoints;

    final list = AchievementService.getAllForUser(isWorker: _isWorker, currentPoints: points)
        .where((st) => st.def.resetPeriod == ResetPeriod.daily)
        .where((st) => _showCompleted ? st.claimed : !st.claimed)
        .toList();

    list.sort((a, b) {
      final aClaimable = a.isCompleted && !a.claimed;
      final bClaimable = b.isCompleted && !b.claimed;
      if (aClaimable != bClaimable) return aClaimable ? -1 : 1;

      final aPct = a.def.target == 0 ? 0.0 : a.progress / a.def.target;
      final bPct = b.def.target == 0 ? 0.0 : b.progress / b.def.target;
      return bPct.compareTo(aPct);
    });

    return list.take(5).toList();
  }

  List<AchievementState> _dailyBonus() {
    final points = BadgeService.badgeNotifier.value.totalPoints;

    final list = AchievementService.getAllForUser(isWorker: _isWorker, currentPoints: points)
        .where((st) => st.def.resetPeriod == ResetPeriod.daily)
        .where((st) => _showCompleted ? st.claimed : !st.claimed)
        .toList();

    list.sort((a, b) {
      final aClaimable = a.isCompleted && !a.claimed;
      final bClaimable = b.isCompleted && !b.claimed;
      if (aClaimable != bClaimable) return aClaimable ? -1 : 1;

      final aPct = a.def.target == 0 ? 0.0 : a.progress / a.def.target;
      final bPct = b.def.target == 0 ? 0.0 : b.progress / b.def.target;
      return bPct.compareTo(aPct);
    });

    return list.skip(5).take(2).toList();
  }

  AchievementState? _weeklyBigMissionPick() {
    final points = BadgeService.badgeNotifier.value.totalPoints;

    final weekly = AchievementService.getAllForUser(isWorker: _isWorker, currentPoints: points)
        .where((st) => st.def.resetPeriod == ResetPeriod.weekly)
        .where((st) => _showCompleted ? st.claimed : !st.claimed)
        .toList();

    if (weekly.isEmpty) return null;

    weekly.sort((a, b) {
      final aClaimable = a.isCompleted && !a.claimed;
      final bClaimable = b.isCompleted && !b.claimed;
      if (aClaimable != bClaimable) return aClaimable ? -1 : 1;
      return b.def.xpReward.compareTo(a.def.xpReward);
    });

    return weekly.first;
  }

  List<AchievementState> _longTermPick() {
    final points = BadgeService.badgeNotifier.value.totalPoints;

    final onetime = AchievementService.getAllForUser(isWorker: _isWorker, currentPoints: points)
        .where((st) => st.def.resetPeriod == ResetPeriod.none)
        .where((st) => _showCompleted ? st.claimed : !st.claimed)
        .toList();

    onetime.sort((a, b) {
      final aClaimable = a.isCompleted && !a.claimed;
      final bClaimable = b.isCompleted && !b.claimed;
      if (aClaimable != bClaimable) return aClaimable ? -1 : 1;
      if (a.claimed != b.claimed) return a.claimed ? 1 : -1;
      return a.def.minPoints.compareTo(b.def.minPoints);
    });

    return onetime;
  }


  Widget _buildBoardEmpty(bool isDark, String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Text(msg, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
      ),
    );
  }


  Widget _buildQuestRowCard(AchievementState st, bool isDark, {required int starTier}) {
    final canClaim = st.isCompleted && !st.claimed;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final sub = isDark ? Colors.white60 : Colors.black54;

    final pct = st.def.target == 0 ? 0.0 : (st.progress / st.def.target).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _showAchievementDetails(st),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canClaim ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200),
            width: canClaim ? 2 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _stars(starTier),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(st.def.title, style: TextStyle(fontWeight: FontWeight.w900, color: textColor)),
                      const SizedBox(height: 3),
                      Text(
                        st.def.description,
                        style: TextStyle(fontSize: 11, color: sub),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _xpPill(st.def.xpReward),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(canClaim ? Colors.green : AppColors.brandMain),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text("${st.progress}/${st.def.target}", style: TextStyle(fontSize: 11, color: sub)),
                const Spacer(),
                if (canClaim)
                  ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.heavyImpact();
                      _confettiController.play();
                      await AchievementService.claim(st.def.id);
                      if (mounted) setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                    ),
                    child: const Text("CLAIM", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                else if (!st.claimed)
                  OutlinedButton(
                    onPressed: () => _navigateToTask(st.def.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandMain,
                      side: const BorderSide(color: AppColors.brandMain),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_getButtonLabel(st.def.id), style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                    child: const Text(
                      "COMPLETED",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyCard(AchievementState st, bool isDark) {
    final canClaim = st.isCompleted && !st.claimed;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final sub = isDark ? Colors.white60 : Colors.black54;

    final pct = st.def.target == 0 ? 0.0 : (st.progress / st.def.target).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _showAchievementDetails(st),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: canClaim ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200), width: canClaim ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _stars(3),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(st.def.title, style: TextStyle(fontWeight: FontWeight.w900, color: textColor, fontSize: 16)),
                      const SizedBox(height: 3),
                      Text(st.def.description, style: TextStyle(fontSize: 12, color: sub)),
                    ],
                  ),
                ),
                _xpPill(st.def.xpReward),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(canClaim ? Colors.green : Colors.blue),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text("${st.progress}/${st.def.target}", style: TextStyle(fontSize: 12, color: sub)),
                const Spacer(),
                if (canClaim)
                  ElevatedButton.icon(
                    onPressed: () async {
                      HapticFeedback.heavyImpact();
                      _confettiController.play();
                      await AchievementService.claim(st.def.id);
                      if (mounted) setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("CLAIM", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                else if (!st.claimed)
                  OutlinedButton.icon(
                    onPressed: () => _navigateToTask(st.def.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(_getButtonLabel(st.def.id), style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                    child: const Text("COMPLETED", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestGridCard(AchievementState st, bool isDark, int tier) {
    final canClaim = st.isCompleted && !st.claimed;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final sub = isDark ? Colors.white60 : Colors.black54;

    final pct = st.def.target == 0 ? 0.0 : (st.progress / st.def.target).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _showAchievementDetails(st),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: canClaim ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200), width: canClaim ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _stars(tier),
                const Spacer(),
                _xpPill(st.def.xpReward),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              st.def.title,
              style: TextStyle(fontWeight: FontWeight.w900, color: textColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              st.def.description,
              style: TextStyle(fontSize: 11, color: sub),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(canClaim ? Colors.green : AppColors.brandMain),
              ),
            ),
            const SizedBox(height: 10),
            if (canClaim)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.heavyImpact();
                    _confettiController.play();
                    await AchievementService.claim(st.def.id);
                    if (mounted) setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text("CLAIM", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            else if (!st.claimed)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _navigateToTask(st.def.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandMain,
                    side: const BorderSide(color: AppColors.brandMain),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(_getButtonLabel(st.def.id), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            else
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Text("COMPLETED", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }


}