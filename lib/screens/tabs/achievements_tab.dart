// lib/screens/tabs/achievements_tab.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:confetti/confetti.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:findus_app/constants/app_colors.dart';
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
  bool _isWorker = true;
  bool _isVerified = false;
  bool _isTrusted = false;
  bool _isTopRated = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _badgeListener = () { if (mounted) setState(() {}); };
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
    _userSub = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((snap) {
      final data = snap.data() ?? {};
      final rawXp = data['xpPoints'] ?? 0;
      final int xp = rawXp is num ? rawXp.toInt() : int.tryParse(rawXp.toString()) ?? 0;
      BadgeService.setPointsFromServer(xp);

      final userRole = (data['userRole'] ?? 'finder').toString().toLowerCase();
      final rating = AchievementService.getRating(data);
      final completed = AchievementService.getCompletedCount(data);

      if (!mounted) return;
      setState(() {
        _isWorker = userRole == 'finder';
        _isVerified = (data['kyc_completed'] ?? false) == true;
        _isTopRated = rating >= 4.8;
        _isTrusted = completed >= 50 && rating >= 4.5;
        _isLoading = false;
      });
    }, onError: (_) => setState(() => _isLoading = false));
  }

  String _formatPoints(int points) => points >= 1000 ? "${(points / 1000).toStringAsFixed(1)}K" : points.toString();

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
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F6FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                ValueListenableBuilder<BadgeProgress>(
                  valueListenable: BadgeService.badgeNotifier,
                  builder: (context, progress, _) {
                    return Column(
                      children: [
                        _buildHeroCard(progress, isDark),
                        const SizedBox(height: 20),
                        _buildNextMilestone(progress, isDark),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 25),
                _buildToggleButtons(isDark),
                const SizedBox(height: 15),
                ValueListenableBuilder<List<AchievementState>>(
                  valueListenable: AchievementService.achievementsNotifier,
                  builder: (context, achievementsList, __) {
                    final currentPoints = BadgeService.badgeNotifier.value.totalPoints;
                    final achievements = AchievementService.getAllForUser(isWorker: _isWorker, currentPoints: currentPoints);
                    final visible = _isCollectPoint
                        ? achievements.where((st) => !st.claimed).toList()
                        : achievements.where((st) => st.claimed).toList();

                    if (visible.isEmpty) return _buildEmptyState(_isCollectPoint, isDark);

                    return Column(
                      children: visible.map((st) => _buildQuestCard(st, isDark)).toList(),
                    );
                  },
                ),
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

  // 🔥 Hero Section (Top Card)
  Widget _buildHeroCard(BadgeProgress progress, bool isDark) {
    final levelColor = _getLevelColor(progress.level);
    final gradientColors = isDark
        ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
        : [Colors.white, const Color(0xFFF8FBFF)];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: levelColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          // Circular Progress with Glow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: levelColor.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)],
            ),
            child: CircularPercentIndicator(
              radius: 50.0,
              lineWidth: 8.0,
              percent: progress.progressPercentage.clamp(0.0, 1.0),
              animation: true,
              circularStrokeCap: CircularStrokeCap.round,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
              progressColor: levelColor,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_formatPoints(progress.totalPoints), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: levelColor)),
                  Text("XP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.grey : Colors.black54)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _miniBadge(BadgeLevel.bronze, progress.totalPoints),
                    _miniBadge(BadgeLevel.silver, progress.totalPoints),
                    _miniBadge(BadgeLevel.gold, progress.totalPoints),
                    _miniBadge(BadgeLevel.platinum, progress.totalPoints),
                    _miniBadge(BadgeLevel.diamond, progress.totalPoints),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statusIcon(StatusTheme.topRatedIcon, _isTopRated, StatusTheme.topRatedColor),
                      _statusIcon(StatusTheme.trustedIcon, _isTrusted, StatusTheme.trustedColor),
                      _statusIcon(StatusTheme.verifiedIcon, _isVerified, StatusTheme.verifiedColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Mini Badge Helper (Updated Icon)
  Widget _miniBadge(BadgeLevel level, int points) {
    final unlocked = points >= _getThreshold(level);
    return Icon(
      Icons.workspace_premium, // 🔥 আইকন পরিবর্তন করা হয়েছে
      size: 20, // সাইজ একটু বাড়িয়ে দেওয়া হয়েছে যাতে ক্লিয়ার দেখা যায়
      color: unlocked ? _getLevelColor(level) : Colors.grey.withOpacity(0.3),
    );
  }

  // 🔥 Next Level Progress Bar
  Widget _buildNextMilestone(BadgeProgress progress, bool isDark) {
    final nextLevel = BadgeService.getLevelByPoints(progress.totalPoints + 1);
    final targetColor = _getLevelColor(nextLevel);
    final needed = (progress.nextLevelPoints - progress.totalPoints).clamp(0, 999999);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("NEXT LEVEL: ${BadgeService.getFormattedLevelName(nextLevel)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade800)),
              Text("$needed XP LEFT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: targetColor)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.progressPercentage.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(targetColor),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Quest Card (RPG Style)
  Widget _buildQuestCard(AchievementState st, bool isDark) {
    final isCompleted = st.isCompleted;
    final canClaim = isCompleted && !st.claimed;
    final cardColor = isDark ? const Color(0xFF252525) : Colors.white;
    final borderColor = canClaim ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: canClaim ? 2 : 1),
        boxShadow: [
          if (canClaim) BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 12, spreadRadius: 1),
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: canClaim ? Colors.green.withOpacity(0.1) : AppColors.brandLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              canClaim ? Icons.redeem : Icons.emoji_events_rounded,
              color: canClaim ? Colors.green : (isDark ? Colors.grey : AppColors.brandMain),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(st.def.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(st.def.description, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                const SizedBox(height: 8),
                // Mini Progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (st.progress / st.def.target).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(canClaim ? Colors.green : Colors.orange),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Action Button
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 4,
              ),
              child: Text("+${st.def.xpReward} XP", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            )
          else if (st.claimed)
            const Icon(Icons.check_circle_rounded, color: Colors.green)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text("${st.progress}/${st.def.target}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.grey)),
            ),
        ],
      ),
    );
  }

  // --- Small Helpers ---

  Widget _statusIcon(IconData icon, bool active, Color color) {
    return Icon(icon, size: 18, color: active ? color : Colors.grey.withOpacity(0.3));
  }

  Widget _buildToggleButtons(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _toggleBtn("Active Quests", _isCollectPoint, () => setState(() => _isCollectPoint = true), isDark),
          _toggleBtn("Completed", !_isCollectPoint, () => setState(() => _isCollectPoint = false), isDark),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.brandMain : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: active ? Colors.white : (isDark ? Colors.white54 : Colors.grey))),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isCollect, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        children: [
          Icon(isCollect ? Icons.rocket_launch : Icons.done_all, size: 60, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 10),
          Text(isCollect ? "All quests completed!" : "No achievements yet.", style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
        ],
      ),
    );
  }

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
}