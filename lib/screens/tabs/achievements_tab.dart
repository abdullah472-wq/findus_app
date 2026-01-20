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

  // role flags from Firestore
  bool _isWorker = true; // finder => true, maker => false
  bool _isVerified = false;
  bool _isTrusted = false;
  bool _isTopRated = false;

  // এটি আপনার AchievementService-এর লোড লজিকের আইডিয়া
  bool isClaimedToday(Timestamp? lastClaimed) {
    if (lastClaimed == null) return false;

    DateTime lastDate = lastClaimed.toDate();
    DateTime now = DateTime.now();

    return lastDate.year == now.year &&
        lastDate.month == now.month &&
        lastDate.day == now.day;
  }

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

      // ✅ XP points from server -> BadgeService sync
      final rawXp = data['xpPoints'] ?? 0;
      final int xp = rawXp is num ? rawXp.toInt() : int.tryParse(rawXp.toString()) ?? 0;
      // fire-and-forget (no await)
      BadgeService.setPointsFromServer(xp);

      // ✅ canonical role
      final userRole = (data['userRole'] ?? 'finder').toString().toLowerCase();
      final isWorker = userRole == 'finder';

      final kyc = (data['kyc_completed'] ?? false) == true;

      final rating = AchievementService.getRating(data);
      final completed = AchievementService.getCompletedCount(data);

      // Trusted logic (UnifiedProfileScreen logic-style)
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
    if (points >= 1000000) return "${(points / 1000000).toStringAsFixed(1)}M";
    if (points >= 1000) return "${(points / 1000).toStringAsFixed(1)}K";
    return points.toString();
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
            child: Column(
              children: [
                ValueListenableBuilder<BadgeProgress>(
                  valueListenable: BadgeService.badgeNotifier,
                  builder: (context, progress, _) {
                    return Column(
                      children: [
                        _buildTopDashboardCard(progress, isDark), // ✅ updated
                        const SizedBox(height: 20),
                        _buildNextBadgeSection(progress, isDark),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 25),
                _buildToggleButtons(isDark),
                const SizedBox(height: 15),

                // achievements list
                ValueListenableBuilder<List<AchievementState>>(
                  valueListenable: AchievementService.achievementsNotifier,
                  builder: (context, _, __) {
                    final currentPoints = BadgeService.badgeNotifier.value.totalPoints;

                    final achievements = AchievementService.getAllForUser(
                      isWorker: _isWorker,
                      currentPoints: currentPoints,
                    );

                    final visible = _isCollectPoint
                        ? achievements.where((st) => !st.claimed).toList()
                        : achievements.where((st) => st.claimed).toList();

                    if (visible.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 60,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              _isCollectPoint
                                  ? "No active quests available"
                                  : "No completed achievements yet",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Complete tasks to earn XP and badges!",
                              style: TextStyle(
                                color: Colors.grey.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: visible
                          .map((st) => _buildAchievementItem(st, isDark))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),

          // Confetti
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Bigger card + 5 badge icons (Newbie removed) + nicer layout
  Widget _buildTopDashboardCard(BadgeProgress progress, bool isDark) {
    final totalPercent = progress.progressPercentage.clamp(0.0, 1.0);
    final points = progress.totalPoints;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        // ✅ Gradient for a modern look
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
            color: progress.levelColor.withOpacity(isDark ? 0.05 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          width: 2,
        ),
      ),
      child: IntrinsicHeight( // ✅ Matches height of left and right sides
        child: Row(
          children: [
            // --- Left: XP Progress Circle ---
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
                      Text(
                        _formatPoints(points),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.brandDark,
                        ),
                      ),
                      Text(
                        "XP",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: isDark ? Colors.white10 : Colors.white,
                  progressColor: progress.levelColor,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ],
            ),

            // --- Middle: Elegant Divider ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: VerticalDivider(
                color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.2),
                thickness: 1,
              ),
            ),

            // --- Right: Badge & Status Rows ---
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🏆 Badge Icons Row
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

                  // ✨ Status Icons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statusBadge(
                        icon: StatusTheme.topRatedIcon,
                        label: "Top Rated",
                        active: _isTopRated,
                        color: StatusTheme.topRatedColor,
                        isDark: isDark,
                      ),
                      _statusBadge(
                        icon: StatusTheme.trustedIcon,
                        label: "Trusted",
                        active: _isTrusted,
                        color: StatusTheme.trustedColor,
                        isDark: isDark,
                      ),
                      _statusBadge(
                        icon: StatusTheme.verifiedIcon,
                        label: "Verified",
                        active: _isVerified,
                        color: StatusTheme.verifiedColor,
                        isDark: isDark,
                      ),
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
    final nextTarget = progress.nextLevelPoints;
    final nextLevel = BadgeService.getLevelByPoints(progress.totalPoints + 1);
    final nextLabel = BadgeService.getFormattedLevelName(nextLevel);
    final targetColor = AppBadgeTheme.colorForLevel(nextLevel);
    final barPercent = progress.progressPercentage.clamp(0.0, 1.0);

    final needed = (nextTarget - progress.totalPoints);
    final neededSafe = needed < 0 ? 0 : needed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // ✅ Soft glass-style background
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: targetColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ Left Side: Target Badge Preview Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: targetColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppBadgeTheme.baseIcon,
              color: targetColor,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          // ✅ Right Side: Progress Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "JOURNEY TO $nextLabel",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        fontSize: 12,
                        color: isDark ? Colors.white70 : AppColors.brandDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: targetColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$neededSafe XP TO GO",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: targetColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ✅ Modern Thick Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Glowing Active Bar
                    FractionallySizedBox(
                      widthFactor: barPercent,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [targetColor.withOpacity(0.7), targetColor],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: targetColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ✅ XP Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${progress.totalPoints} XP",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: progress.levelColor,
                      ),
                    ),
                    Text(
                      "$nextTarget XP",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
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

  Widget _buildToggleButtons(bool isDark) {
    return Container(
      height: 45,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _toggleItem(
            "ACTIVE QUESTS",
            _isCollectPoint,
                () => setState(() => _isCollectPoint = true),
          ),
          _toggleItem(
            "COMPLETED",
            !_isCollectPoint,
                () => setState(() => _isCollectPoint = false),
          ),
        ],
      ),
    );
  }

  Widget _toggleItem(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.brandMain : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isActive ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
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
        border: Border.all(
          color: canClaim ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
          width: canClaim ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: canClaim
                ? Colors.green.withOpacity(0.1)
                : AppColors.brandLight.withOpacity(0.2),
            radius: 24,
            child: Icon(
              AppBadgeTheme.iconForLevel(
                AchievementService.getBadgeLevelByPoints(st.def.xpReward),
              ),
              color: canClaim ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        st.def.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTypeColor(st.def.resetPeriod, isDark).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getTypeColor(st.def.resetPeriod, isDark),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        _getTypeLabel(st.def.resetPeriod),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: _getTypeColor(st.def.resetPeriod, isDark),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  st.def.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                          valueColor: AlwaysStoppedAnimation(
                            canClaim ? Colors.green : (isCompleted ? Colors.blue : Colors.orange),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${st.progress}/${st.def.target}",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (canClaim)
            ElevatedButton(
              onPressed: () async {
                // ✅ ১. ফিডব্যাক ও এনিমেশন
                HapticFeedback.heavyImpact();
                _confettiController.play();

                // ✅ ২. ক্লেইম ফাংশন কল (অবশ্যই await দিতে হবে)
                // এটি কল করলে Service-এর ভেতর থেকে Firestore আপডেট হবে
                await AchievementService.claim(st.def.id);

                // ✅ ৩. লোকাল UI আপডেট নিশ্চিত করা
                if (mounted) setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.green.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // ✅ মডার্ন রাউন্ড শেপ
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "+${st.def.xpReward}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    "CLAIM",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
          else if (st.claimed)
          // ✅ ক্লেইম হয়ে গেলে সুন্দর একটি চেক আইকন
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 26,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "REWARDED",
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Colors.green.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            )
          else
          // ✅ এখনো কাজ বাকি থাকলে যেটা দেখাবে
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "+${st.def.xpReward}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white38 : AppColors.brandMain.withOpacity(0.5),
                  ),
                ),
                const Text(
                  "XP",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ✅ New badge milestone widget (clean + label)
  Widget _badgeMilestone(BadgeLevel level, int currentPoints) {
    final threshold = _getThreshold(level);
    final unlocked = currentPoints >= threshold;
    final color = AppBadgeTheme.colorForLevel(level);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: unlocked ? color.withOpacity(0.1) : Colors.transparent,
            border: Border.all(
              color: unlocked ? color : Colors.grey.withOpacity(0.2),
              width: unlocked ? 2 : 1,
            ),
          ),
          child: Icon(
            AppBadgeTheme.baseIcon,
            color: unlocked ? color : Colors.grey.withOpacity(0.4),
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getShortName(level),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: unlocked ? color : Colors.grey,
          ),
        ),
      ],
    );
  }

// Helper: Threshold পাওয়ার জন্য
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

// Helper: ছোট নাম দেখানোর জন্য
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

  // ✅ New status widget (clean + label)
  Widget _statusBadge({
    required IconData icon,
    required String label,
    required bool active,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color.withOpacity(0.15) : (isDark ? Colors.white05 : Colors.black.withOpacity(0.03)),
            border: Border.all(
              color: active ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: active ? color : Colors.grey.withOpacity(0.5),
            size: 17,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: active ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(ResetPeriod period, bool isDark) {
    switch (period) {
      case ResetPeriod.daily:
        return Colors.blue;
      case ResetPeriod.weekly:
        return Colors.purple;
      case ResetPeriod.none:
        return isDark ? Colors.green : Colors.green[700]!;
    }
  }

  String _getTypeLabel(ResetPeriod period) {
    switch (period) {
      case ResetPeriod.daily:
        return "DAILY";
      case ResetPeriod.weekly:
        return "WEEKLY";
      case ResetPeriod.none:
        return "ONE-TIME";
    }
  }
}