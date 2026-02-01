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
  bool _isCollectPoint = true; // Toggle state
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

    // Badge Listener
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
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _userSub?.cancel();
    _userSub = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((snap) {
      if (!snap.exists) return;

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
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
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
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;

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
                // 1. Hero Card
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

                // 2. Toggle Buttons
                _buildToggleButtons(isDark),

                const SizedBox(height: 15),

                // 3. Quest List
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

          // Confetti Animation
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

  // 🔥 Hero Section
  // 🔥 New Hero Section Design
  Widget _buildHeroCard(BadgeProgress progress, bool isDark) {
    final levelColor = _getLevelColor(progress.level);
    final String levelName = progress.level.toString().split('.').last.toUpperCase(); // e.g., GOLD

    // Background Gradient based on Badge Level
    final gradientColors = isDark
        ? [const Color(0xFF252525), const Color(0xFF151515)]
        : [levelColor.withOpacity(0.1), Colors.white];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: levelColor.withOpacity(0.5),
            width: 2
        ),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Rank Name & Big Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CURRENT RANK",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    levelName,
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: levelColor,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: levelColor.withOpacity(0.5),
                            blurRadius: 15,
                          )
                        ]
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${_formatPoints(progress.totalPoints)} XP",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),

              // Big Badge Icon with Glow
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: levelColor.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: levelColor.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Icon(
                  Icons.workspace_premium, // অথবা আপনার কাস্টম ব্যাজ আইকন
                  size: 45,
                  color: levelColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),
          Divider(color: isDark ? Colors.white10 : Colors.grey.shade300),
          const SizedBox(height: 15),

          // Bottom Row: Status Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusChip("Top Rated", _isTopRated, StatusTheme.topRatedColor, isDark),
              _buildStatusChip("Trusted", _isTrusted, StatusTheme.trustedColor, isDark),
              _buildStatusChip("Verified", _isVerified, StatusTheme.verifiedColor, isDark),
            ],
          ),
        ],
      ),
    );
  }

  // Helper Widget for Status Chips
  Widget _buildStatusChip(String label, bool isActive, Color color, bool isDark) {
    return Opacity(
      opacity: isActive ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : (isDark ? Colors.white10 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: isActive ? color : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? color : (isDark ? Colors.grey : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
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
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("NEXT: ${BadgeService.getFormattedLevelName(nextLevel)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade800)),
              Text("$needed XP LEFT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: targetColor)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.progressPercentage.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(targetColor),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Quest Card
  // 🔥 Quest Card with Action Button
  Widget _buildQuestCard(AchievementState st, bool isDark) {
    final isCompleted = st.isCompleted; // টাস্ক শেষ হয়েছে কিনা
    final canClaim = isCompleted && !st.claimed; // ক্লেইম করা বাকি কিনা
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final borderColor = canClaim ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: canClaim ? 1.5 : 1),
        boxShadow: [
          if (canClaim) BoxShadow(color: Colors.green.withOpacity(0.15), blurRadius: 12, spreadRadius: 1),
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(st.def.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 4),
                    Text(st.def.description, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600)),
                    const SizedBox(height: 8),
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
            ],
          ),

          const SizedBox(height: 12),

          // 🔥 Action Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 1. Progress Text
              if (!canClaim && !st.claimed)
                Text(
                    "${st.progress}/${st.def.target}",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.grey)
                ),

              const Spacer(),

              // 2. Action Button (Upload/Post) - যদি টাস্ক কমপ্লিট না হয়
              if (!isCompleted)
                ElevatedButton.icon(
                  onPressed: () => _navigateToTask(st.def.id), // নেভিগেশন লজিক
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandMain.withOpacity(0.1),
                    foregroundColor: AppColors.brandMain,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: Text(_getButtonLabel(st.def.id), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),

              // 3. Claim Button - যদি টাস্ক কমপ্লিট হয় কিন্তু ক্লেইম না করা হয়
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text("CLAIM +${st.def.xpReward} XP", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),

              // 4. Completed Status - যদি ক্লেইম করা হয়ে থাকে
              if (st.claimed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text("COMPLETED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 🚀 Helper: Get Button Label based on ID
  String _getButtonLabel(String id) {
    if (id.contains('portfolio') || id.contains('cv')) return "Upload Now";
    if (id.contains('job')) return "Post Job";
    if (id.contains('earn')) return "Create Pin";
    if (id.contains('profile')) return "Edit Profile";
    return "Go Now";
  }

  // 🚀 Helper: Navigation Logic
  void _navigateToTask(String id) {
    // এখানে আপনার অ্যাপের রাউট অনুযায়ী পেজ ওপেন করুন
    // উদাহরণস্বরূপ:

    // 1. Upload CV/Portfolio
    if (id.contains('portfolio') || id.contains('cv')) {
      // Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkerDocumentsScreen()));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Redirecting to Documents...")));
    }
    // 2. Post a Job
    else if (id.contains('job')) {
      // Navigator.push(context, MaterialPageRoute(builder: (_) => const PostJobScreen()));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Redirecting to Post Job...")));
    }
    // 3. Earn Post (Pin)
    else if (id.contains('earn')) {
      // Navigator.push(context, MaterialPageRoute(builder: (_) => const EarnPostScreen()));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Redirecting to Earn Post...")));
    }
    // 4. Edit Profile
    else if (id.contains('profile')) {
      // Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Redirecting to Profile...")));
    }
    else {
      // Default
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action not available")));
    }
  }

  // --- Helpers ---

  Widget _buildToggleButtons(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
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
}