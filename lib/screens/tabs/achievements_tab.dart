// lib/screens/tabs/achievements_tab.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:confetti/confetti.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/badge/badge_theme.dart';
import 'package:findus_app/constants/status_theme.dart';
import 'package:findus_app/badge/badge_service.dart' hide BadgeLevel;
import 'package:findus_app/badge/badge_model.dart';

import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/achievement/achievement_models.dart';

class AchievementsTab extends StatefulWidget {
  const AchievementsTab({super.key});

  @override
  State<AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<AchievementsTab> {
  bool _isCollectPoint = true;
  late ConfettiController _confettiController;
  late VoidCallback _badgeListener;

  bool _isLoading = true;

  // role flags
  bool _isWorker = true;
  bool _isVerified = false;
  bool _isTrusted = false;
  bool _isTopRated = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    _badgeListener = () {
      if (mounted) setState(() {});
    };
    BadgeService.badgeNotifier.addListener(_badgeListener);

    _listenUserDoc();
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
      setState(() => _isLoading = false);
      return;
    }

    _userSub?.cancel();
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      final data = snap.data() ?? <String, dynamic>{};

      final rawXp = data['xpPoints'] ?? 0;
      final int xp = rawXp is num ? rawXp.toInt() : int.tryParse(rawXp.toString()) ?? 0;
      BadgeService.setPointsFromServer(xp);

      final userRole = (data['userRole'] ?? 'finder').toString().toLowerCase();
      final isWorker = userRole == 'finder';
      final kyc = (data['kyc_completed'] ?? false) == true;

      final rating = AchievementService.getRating(data);
      final completed = AchievementService.getCompletedCount(data);

      final isTopRated = rating >= 4.8;
      final isTrusted = completed >= 50 && rating >= 4.5;

      if (!mounted) return;
      setState(() {
        _isWorker = isWorker;
        _isVerified = kyc;
        _isTopRated = isTopRated;
        _isTrusted = isTrusted;
        _isLoading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  String _formatPoints(int points) {
    if (points >= 1000) return "${(points / 1000).toStringAsFixed(1)}K";
    return points.toString();
  }

  // ✅ লেভেল অনুযায়ী কালার পাওয়ার হেল্পার (levelColor এরর ফিক্স)
  Color _getLevelColor(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.bronze: return const Color(0xFFCD7F32);
      case BadgeLevel.silver: return const Color(0xFFC0C0C0);
      case BadgeLevel.gold: return const Color(0xFFFFD700);
      case BadgeLevel.platinum: return const Color(0xFFE5E4E2);
      case BadgeLevel.diamond: return const Color(0xFFB9F2FF);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                ValueListenableBuilder<BadgeProgress>(
                  valueListenable: BadgeService.badgeNotifier,
                  builder: (context, progress, _) {
                    return Column(
                      children: [
                        _buildTopDashboardCard(progress, isDark),
                        const SizedBox(height: 20),
                        _buildNextBadgeSection(progress, isDark),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 25),
                _buildToggleButtons(isDark),
                const SizedBox(height: 15),

                // ✅ ValueListenableBuilder এর children প্যারামিটার এরর ফিক্স
                ValueListenableBuilder<List<AchievementState>>(
                  valueListenable: AchievementService.achievementsNotifier,
                  builder: (context, achievementsList, __) {
                    final currentPoints = BadgeService.badgeNotifier.value.totalPoints;

                    final achievements = AchievementService.getAllForUser(
                      isWorker: _isWorker,
                      currentPoints: currentPoints,
                    );

                    final visible = _isCollectPoint
                        ? achievements.where((st) => !st.claimed).toList()
                        : achievements.where((st) => st.claimed).toList();

                    if (visible.isEmpty) return _buildEmptyState(_isCollectPoint);

                    return Column(
                      children: visible.map((st) => _buildAchievementItem(st, isDark)).toList(),
                    );
                  },
                ),
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

  Widget _buildTopDashboardCard(BadgeProgress progress, bool isDark) {
    final totalPercent = progress.progressPercentage.clamp(0.0, 1.0);
    final points = progress.totalPoints;
    final lColor = _getLevelColor(progress.level);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF333333), const Color(0xFF222222)]
              : [const Color(0xFFF8F0FF), const Color(0xFFEFE4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: lColor.withOpacity(isDark ? 0.05 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, width: 2),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularPercentIndicator(
                  radius: 54.0,
                  lineWidth: 9.0,
                  percent: totalPercent,
                  animation: true,
                  animationDuration: 1000,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_formatPoints(points), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.brandDark)),
                      Text("XP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.grey)),
                    ],
                  ),
                  backgroundColor: isDark ? Colors.white10 : Colors.white,
                  progressColor: lColor,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: VerticalDivider(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.2), thickness: 1),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _badgeMilestone(BadgeLevel.bronze, points),
                      _badgeMilestone(BadgeLevel.silver, points),
                      _badgeMilestone(BadgeLevel.gold, points),
                      _badgeMilestone(BadgeLevel.platinum, points),
                      _badgeMilestone(BadgeLevel.diamond, points),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statusBadge(icon: StatusTheme.topRatedIcon, label: "Top Rated", active: _isTopRated, color: StatusTheme.topRatedColor, isDark: isDark),
                      _statusBadge(icon: StatusTheme.trustedIcon, label: "Trusted", active: _isTrusted, color: StatusTheme.trustedColor, isDark: isDark),
                      _statusBadge(icon: StatusTheme.verifiedIcon, label: "Verified", active: _isVerified, color: StatusTheme.verifiedColor, isDark: isDark),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextBadgeSection(BadgeProgress progress, bool isDark) {
    final nextLevel = BadgeService.getLevelByPoints(progress.totalPoints + 1);
    final nextLabel = BadgeService.getFormattedLevelName(nextLevel);
    final targetColor = _getLevelColor(nextLevel);
    final barPercent = progress.progressPercentage.clamp(0.0, 1.0);
    final needed = (progress.nextLevelPoints - progress.totalPoints).clamp(0, 999999);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: targetColor.withOpacity(0.2), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: targetColor.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(AppBadgeTheme.baseIcon, color: Colors.orange, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("JOURNEY TO $nextLabel", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0, fontSize: 12, color: isDark ? Colors.white70 : AppColors.brandDark)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: targetColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text("$needed XP TO GO", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: targetColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], borderRadius: BorderRadius.circular(10))),
                    FractionallySizedBox(
                      widthFactor: barPercent,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [targetColor.withOpacity(0.7), targetColor]),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: targetColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeMilestone(BadgeLevel level, int currentPoints) {
    final threshold = _getThreshold(level);
    final unlocked = currentPoints >= threshold;
    final color = _getLevelColor(level);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked ? color.withOpacity(0.1) : Colors.transparent,
            border: Border.all(color: unlocked ? color : Colors.grey.withOpacity(0.2), width: unlocked ? 2 : 1),
          ),
          child: Icon(AppBadgeTheme.baseIcon, color: unlocked ? color : Colors.grey.withOpacity(0.4), size: 16),
        ),
        const SizedBox(height: 4),
        Text(_getShortName(level), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: unlocked ? color : Colors.grey)),
      ],
    );
  }

  Widget _statusBadge({required IconData icon, required String label, required bool active, required Color color, required bool isDark}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // ✅ Colors.white05 ফিক্স
            color: active ? color.withOpacity(0.15) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
            border: Border.all(color: active ? color : Colors.transparent, width: 1.5),
          ),
          child: Icon(icon, color: active ? color : Colors.grey.withOpacity(0.5), size: 17),
        ),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: active ? (isDark ? Colors.white : Colors.black87) : Colors.grey)),
      ],
    );
  }

  Widget _buildAchievementItem(AchievementState st, bool isDark) {
    final progress = (st.progress / st.def.target).clamp(0.0, 1.0);
    final isCompleted = st.isCompleted;
    final canClaim = isCompleted && !st.claimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: canClaim ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.1), width: canClaim ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: canClaim ? Colors.green.withOpacity(0.1) : AppColors.brandLight.withOpacity(0.2),
            radius: 24,
            // ✅ iconForLevel ফিক্স (সরাসরি ব্যাজ আইকন ব্যবহার)
            child: Icon(AppBadgeTheme.baseIcon, color: canClaim ? Colors.green : Colors.grey, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(st.def.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(st.def.description, style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation(canClaim ? Colors.green : (isCompleted ? Colors.blue : Colors.orange)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (canClaim)
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.heavyImpact();
                _confettiController.play();
                await AchievementService.claim(st.def.id);
                if (mounted) setState(() {});
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("+${st.def.xpReward}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text("CLAIM", style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else if (st.claimed)
            const Icon(Icons.check_circle, color: Colors.green, size: 24)
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("+${st.def.xpReward}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : AppColors.brandMain.withOpacity(0.5))),
                const Text("XP", style: TextStyle(fontSize: 8, color: Colors.grey)),
              ],
            ),
        ],
      ),
    );
  }

  // --- Helpers ---
  int _getThreshold(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.bronze: return BadgeService.bronzeThreshold;
      case BadgeLevel.silver: return BadgeService.silverThreshold;
      case BadgeLevel.gold: return BadgeService.goldThreshold;
      case BadgeLevel.platinum: return BadgeService.platinumThreshold;
      case BadgeLevel.diamond: return BadgeService.diamondThreshold;
      default: return 0;
    }
  }

  String _getShortName(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.bronze: return "BRNZ";
      case BadgeLevel.silver: return "SLVR";
      case BadgeLevel.gold: return "GOLD";
      case BadgeLevel.platinum: return "PLAT";
      case BadgeLevel.diamond: return "DMND";
      default: return "";
    }
  }

  Widget _buildToggleButtons(bool isDark) {
    return Container(
      height: 45, padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey[200], borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          _toggleItem("ACTIVE QUESTS", _isCollectPoint, () => setState(() => _isCollectPoint = true)),
          _toggleItem("COMPLETED", !_isCollectPoint, () => setState(() => _isCollectPoint = false)),
        ],
      ),
    );
  }

  Widget _toggleItem(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); onTap(); },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: isActive ? AppColors.brandMain : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isActive ? Colors.white : Colors.grey)),
        ),
      ),
    );
  }

  Color _getTypeColor(ResetPeriod period, bool isDark) {
    switch (period) {
      case ResetPeriod.daily: return Colors.blue;
      case ResetPeriod.weekly: return Colors.purple;
      case ResetPeriod.none: return isDark ? Colors.green : Colors.green[700]!;
    }
  }

  String _getTypeLabel(ResetPeriod period) {
    switch (period) {
      case ResetPeriod.daily: return "DAILY";
      case ResetPeriod.weekly: return "WEEKLY";
      case ResetPeriod.none: return "ONE-TIME";
    }
  }

  Widget _buildEmptyState(bool isCollect) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.emoji_events_outlined, size: 60, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 15),
          Text(isCollect ? "No active quests" : "No completed achievements", style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}