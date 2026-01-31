// lib/screens/tabs/achievements_tab.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:findus_app/constants/app_colors.dart';
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
  // 🔥 Colorful Premium Hero Card
  // 🔥 Soft Pastel Header Card
  Widget _buildHeroCard(BadgeProgress progress, bool isDark) {
    final gradient = _getLevelGradient(progress.level);
    final String levelName = progress.level.toString().split('.').last.toUpperCase();

    // হালকা ব্যাকগ্রাউন্ডের ওপর গাঢ় টেক্সট
    final textColor = Colors.black87;
    final subTextColor = Colors.black54;
    final levelColor = _getLevelColor(progress.level); // অরিজিনাল কালার আইকনের জন্য

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.15), // শ্যাডো খুব হালকা
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("CURRENT RANK", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: subTextColor)),
                  const SizedBox(height: 4),
                  Text(
                    levelName,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: textColor.withOpacity(0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6), // Glassy white
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${_formatPoints(progress.totalPoints)} XP",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ),
                ],
              ),
              // Big Icon (No Background Box, just the icon floating)
              Icon(Icons.workspace_premium, size: 70, color: levelColor.withOpacity(0.8)),
            ],
          ),
          const SizedBox(height: 20),
          // Status Chips with Darker Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusChip("Top Rated", _isTopRated, textColor),
              _buildStatusChip("Trusted", _isTrusted, textColor),
              _buildStatusChip("Verified", _isVerified, textColor),
            ],
          ),
        ],
      ),
    );
  }

  // Updated Status Chip Helper for Dark Text
  Widget _buildStatusChip(String label, bool isActive, Color textColor) {
    return Opacity(
      opacity: isActive ? 1.0 : 0.4,
      child: Row(
        children: [
          Icon(isActive ? Icons.check_circle : Icons.circle_outlined, size: 16, color: isActive ? Colors.black54 : Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  // 🔥 নতুন ফাংশন: লেভেল অনুযায়ী ব্যাকগ্রাউন্ড কালার
  LinearGradient _getLevelGradient(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.bronze:
        return const LinearGradient(
          colors: [Color(0xFFE65C00), Color(0xFFF9D423)], // Orange to Yellow
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case BadgeLevel.silver:
        return const LinearGradient(
          colors: [Color(0xFF434343), Color(0xFF909FA5)], // Dark Grey to Silver
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case BadgeLevel.gold:
        return const LinearGradient(
          colors: [Color(0xFFFF8008), Color(0xFFFFC837)], // Deep Gold
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case BadgeLevel.platinum:
        return const LinearGradient(
          colors: [Color(0xFF20002C), Color(0xFFcbb4d4)], // Dark Purple to Platinum
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case BadgeLevel.diamond:
        return const LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)], // Cyan to Blue
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)], // Default Greenish
        );
    }
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
  // 🔥 Colorful Soft Quest Card
  Widget _buildQuestCard(AchievementState st, bool isDark) {
    final isCompleted = st.isCompleted;
    final canClaim = isCompleted && !st.claimed;

    // কার্ডের ব্যাকগ্রাউন্ড কালার লজিক (সফট কালারফুল)
    final Gradient cardBackground = isDark
        ? const LinearGradient(colors: [Color(0xFF2C2C2C), Color(0xFF252525)]) // ডার্ক মোড
        : canClaim
        ? const LinearGradient( // ক্লেইম করার জন্য হালকা সবুজ আভা
        colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        begin: Alignment.topLeft, end: Alignment.bottomRight)
        : const LinearGradient( // সাধারণ অবস্থায় হালকা নীল/বেগুনি আভা
        colors: [Color(0xFFF3E5F5), Color(0xFFE3F2FD)],
        begin: Alignment.topLeft, end: Alignment.bottomRight);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: cardBackground,
        borderRadius: BorderRadius.circular(20), // কার্ডগুলো একটু বেশি গোল
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4)
          )
        ],
        border: Border.all(
            color: canClaim ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.5),
            width: 1
        ),
      ),
      child: Row(
        children: [
          // আইকন বক্স
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white, // আইকনের পেছনে সাদা
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: Icon(
              canClaim ? Icons.redeem : Icons.emoji_events_rounded,
              color: canClaim ? Colors.green : const Color(0xFF7986CB), // সফট নীল আইকন
              size: 26,
            ),
          ),
          const SizedBox(width: 16),

          // টেক্সট এবং প্রগ্রেস
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    st.def.title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87
                    )
                ),
                const SizedBox(height: 4),
                Text(
                    st.def.description,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)
                ),
                const SizedBox(height: 10),

                // প্রগ্রেস বার
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (st.progress / st.def.target).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.5),
                    valueColor: AlwaysStoppedAnimation(
                        canClaim ? Colors.greenAccent.shade700 : const Color(0xFF9FA8DA) // সফট ইন্ডিকেটর
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // বাটন অথবা কাউন্ট
          if (canClaim)
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.heavyImpact();
                _confettiController.play();
                await AchievementService.claim(st.def.id);
                if (mounted) setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.green.withOpacity(0.2))
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text("+${st.def.xpReward}", style: const TextStyle(fontWeight: FontWeight.bold)),
            )
          else if (st.claimed)
            const Icon(Icons.check_circle, color: Colors.green, size: 28)
          else
            Text(
                "${st.progress}/${st.def.target}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45)
            ),
        ],
      ),
    );
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