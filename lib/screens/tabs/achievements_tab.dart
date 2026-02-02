// lib/screens/tabs/achievements_tab.dart
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
  int _selectedCategory = 0;
  bool _showCompleted = false;
  late ConfettiController _confettiController;
  late VoidCallback _badgeListener;

  bool _isLoading = true;
  bool _isWorker = true;
  bool _isVerified = false;
  bool _isTrusted = false;
  bool _isTopRated = false;
  int _totalXpEarned = 0;
  int _totalAchievements = 0;
  int _completedAchievements = 0;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'All', 'icon': Icons.all_inclusive, 'color': AppColors.brandMain},
    {'id': 'daily', 'label': 'Daily', 'icon': Icons.today, 'color': Colors.green},
    {'id': 'weekly', 'label': 'Weekly', 'icon': Icons.date_range, 'color': Colors.blue},
    {'id': 'onetime', 'label': 'One-time', 'icon': Icons.flag, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    _badgeListener = () {
      if (mounted) {
        _updateStats();
        setState(() {});
      }
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

      _updateStats();
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _updateStats() {
    final currentPoints = BadgeService.badgeNotifier.value.totalPoints;

    final achievements = AchievementService.getAllForUser(
      isWorker: _isWorker,
      currentPoints: currentPoints,
    );

    int totalXp = 0;
    int completed = 0;

    for (final achievement in achievements) {
      if (achievement.claimed) {
        totalXp += achievement.def.xpReward;
        completed++;
      }
    }

    if (mounted) {
      setState(() {
        _totalXpEarned = totalXp;
        _totalAchievements = achievements.length;
        _completedAchievements = completed;
      });
    }
  }

  String _formatPoints(int points) => points >= 1000 ? "${(points / 1000).toStringAsFixed(1)}K" : points.toString();

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
                // 1. Hero Stats Section
                _buildHeroStats(isDark),

                // 2. Category Selector
                _buildCategorySelector(isDark),

                // 3. Toggle & Stats
                _buildToggleAndStats(isDark),

                // 4. Achievement Grid
                _buildAchievementGrid(isDark),

                const SizedBox(height: 100),
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

  // 🔥 Hero Stats Section
  Widget _buildHeroStats(bool isDark) {
    final progress = BadgeService.badgeNotifier.value;
    final levelColor = progress.levelColor;
    final levelName = progress.level.toString().split('.').last.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandMain.withOpacity(0.9),
            AppColors.brandDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ACHIEVEMENTS",
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

            const SizedBox(height: 20),

            // Progress Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  // Level & Progress
                  Row(
                    children: [
                      // Level Badge (Updated Logic)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: levelColor.withOpacity(0.2), // ✅ হালকা ব্যাকগ্রাউন্ড
                          shape: BoxShape.circle,
                          border: Border.all(color: levelColor, width: 2), // ✅ বর্ডার যোগ করা হয়েছে
                          boxShadow: [
                            BoxShadow(
                              color: levelColor.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Icon(
                          Icons.workspace_premium,
                          color: levelColor, // ✅ আইকনের কালার লেভেল কালারের মতো হবে
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Level Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "CURRENT LEVEL",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              levelName,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "${_formatPoints(progress.totalPoints)} XP",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Next Level
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "NEXT LEVEL",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            _formatPoints(progress.nextLevelPoints),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.progressPercentage.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(levelColor),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Progress Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_formatPoints(progress.totalPoints)} XP",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "${_formatPoints(progress.nextLevelPoints - progress.totalPoints)} XP to go",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats Row
            _buildStatsRow(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem("Total XP", _formatPoints(_totalXpEarned), Icons.emoji_events, Colors.amber),
        _buildStatItem("Completed", "$_completedAchievements/$_totalAchievements", Icons.check_circle, Colors.green),
        _buildStatItem("Active", "${_totalAchievements - _completedAchievements}", Icons.timeline, Colors.blue),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // 🔥 Category Selector
  Widget _buildCategorySelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_categories.length, (index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == index;

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? category['color'] : (isDark ? Colors.white10 : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? category['color'] : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: (category['color'] as Color).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ] : [],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category['label'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // 🔥 Toggle & Stats
  Widget _buildToggleAndStats(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Toggle Button
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
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
                          "Active Quests",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: !_showCompleted ? Colors.white : (isDark ? Colors.white60 : Colors.grey),
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
                            color: _showCompleted ? Colors.white : (isDark ? Colors.white60 : Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Filter Button
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
            ),
            child: Icon(
              Icons.filter_list,
              color: isDark ? Colors.white60 : Colors.grey[600],
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Achievement Grid
  Widget _buildAchievementGrid(bool isDark) {
    final currentPoints = BadgeService.badgeNotifier.value.totalPoints;

    // ✅ Synchronous method ব্যবহার করুন
    final achievements = _showCompleted
        ? AchievementService.getCompletedAchievements(
      isWorker: _isWorker,
      currentPoints: currentPoints,
    )
        : AchievementService.getActiveAchievements(
      isWorker: _isWorker,
      currentPoints: currentPoints,
    );

    // Filter by selected category
    List<AchievementState> filtered = achievements.where((st) {
      if (_selectedCategory == 0) return true;

      final categoryId = _categories[_selectedCategory]['id'];
      if (categoryId == 'daily') return st.def.resetPeriod == ResetPeriod.daily;
      if (categoryId == 'weekly') return st.def.resetPeriod == ResetPeriod.weekly;
      if (categoryId == 'onetime') return st.def.resetPeriod == ResetPeriod.none;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return _buildAchievementCard(filtered[index], isDark);
        },
      ),
    );
  }

  // 🔥 Achievement Card
  Widget _buildAchievementCard(AchievementState st, bool isDark) {
    final isLocked = BadgeService.badgeNotifier.value.totalPoints < st.def.minPoints;
    final isCompleted = st.isCompleted;
    final canClaim = isCompleted && !st.claimed;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final Color borderColor = canClaim // ✅ FIXED: non-nullable Color
        ? Colors.green
        : (isDark ? Colors.white10 : Colors.grey[200]!);

    if (isLocked) {
      return _buildLockedCard(st, isDark);
    }

    return GestureDetector(
      onTap: () => _showAchievementDetails(st),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: canClaim ? 2 : 1), // ✅ FIXED
          boxShadow: [
            if (canClaim) BoxShadow(color: Colors.green.withOpacity(0.15), blurRadius: 15, spreadRadius: 1),
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon & XP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: canClaim ? Colors.green.withOpacity(0.1) : AppColors.brandLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          canClaim ? Icons.redeem : Icons.emoji_events_rounded,
                          color: canClaim ? Colors.green : AppColors.brandMain,
                          size: 24,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bolt, color: Colors.amber, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              "+${st.def.xpReward}",
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    st.def.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Description
                  Text(
                    st.def.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Progress",
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white60 : Colors.grey,
                            ),
                          ),
                          Text(
                            "${st.progress}/${st.def.target}",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white60 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (st.progress / st.def.target).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation(
                            canClaim ? Colors.green : AppColors.brandMain,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Action Button
                  if (!st.claimed)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToTask(st.def.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandMain.withOpacity(0.1),
                          foregroundColor: AppColors.brandMain,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 14),
                        label: Text(
                          _getButtonLabel(st.def.id),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  if (canClaim)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text(
                          "CLAIM REWARD",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),

                  if (st.claimed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text("COMPLETED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Badge for reset period
            if (st.def.resetPeriod != ResetPeriod.none)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: st.def.resetPeriod == ResetPeriod.daily ? Colors.green : Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    st.def.resetPeriod == ResetPeriod.daily ? "DAILY" : "WEEKLY",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedCard(AchievementState st, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.lock_outline, color: Colors.grey, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              st.def.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Unlocks at ${st.def.minPoints} XP",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: Colors.grey, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    "LOCKED",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            _showCompleted ? Icons.emoji_events_outlined : Icons.rocket_launch,
            size: 80,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _showCompleted ? "No achievements yet!" : "All quests completed!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showCompleted
                ? "Complete tasks to earn achievements"
                : "Great job! You've completed all available quests",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 Helper Methods
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkerDocumentsScreen(uid: uid, isOwner: true),
        ),
      );
    } else if (id.contains('job') || id.contains('post')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SupportPostScreen()),
      );
    } else if (id.contains('earn') || id.contains('pin')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EarnPostScreen()),
      );
    } else if (id.contains('profile')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UnifiedProfileEditScreen(uid: uid),
        ),
      );
    } else if (id.contains('login')) {
      // Daily login - already handled by opening app
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Daily check-in recorded!")),
      );
    } else if (id.contains('share')) {
      // Share functionality
      _shareProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Action not available")),
      );
    }
  }

  void _shareProfile() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Share feature coming soon!")),
    );
  }

  void _showAchievementDetails(AchievementState st) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildAchievementDetails(st),
    );
  }

  Widget _buildAchievementDetails(AchievementState st) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLocked = BadgeService.badgeNotifier.value.totalPoints < st.def.minPoints;
    final canClaim = st.isCompleted && !st.claimed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          // Achievement Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: canClaim ? Colors.green.withOpacity(0.1) : AppColors.brandLight.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              canClaim ? Icons.redeem :
              isLocked ? Icons.lock_outline :
              Icons.emoji_events_rounded,
              size: 40,
              color: canClaim ? Colors.green : AppColors.brandMain,
            ),
          ),

          const SizedBox(height: 20),

      // Title
      Text(
        st.def.title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
        textAlign: TextAlign.center,
      ),

      const SizedBox(height: 10),

      // Description
      Text(
        st.def.description,
        style: TextStyle(
          fontSize: 16,
          color: isDark ? Colors.white60 : Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),

      const SizedBox(height: 20),

      // Stats
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDetailStat("XP Reward", "+${st.def.xpReward}", Icons.bolt),
            _buildDetailStat("Progress", "${st.progress}/${st.def.target}", Icons.timeline),
            _buildDetailStat("Type",
              st.def.resetPeriod == ResetPeriod.daily ? "Daily" :
              st.def.resetPeriod == ResetPeriod.weekly ? "Weekly" : "One-time",
              Icons.schedule,
            ),
          ],
        ),
      ),

      const SizedBox(height: 20),

      // Progress Bar
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        Text(
        "Progress",
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white60 : Colors.grey[600],
        ),
      ),
      Text(
        "${((st.progress / st.def.target) * 100).toStringAsFixed(0)}%",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
        ],
        ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (st.progress / st.def.target).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                canClaim ? Colors.green : AppColors.brandMain,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${st.progress} completed",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
              Text(
                "${st.def.target - st.progress} remaining",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),

          const SizedBox(height: 20),

          // Requirements
          if (st.def.minPoints > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: isLocked ? Colors.orange : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isLocked
                          ? "Requires ${st.def.minPoints} XP to unlock"
                          : "Unlocked at ${st.def.minPoints} XP",
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Action Buttons
          if (isLocked)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to XP earning tasks
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.bolt),
                label: const Text(
                  "EARN MORE XP TO UNLOCK",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          else if (canClaim)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  HapticFeedback.heavyImpact();
                  _confettiController.play();
                  await AchievementService.claim(st.def.id);
                  if (mounted) setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(Icons.check),
                label: Text(
                  "CLAIM ${st.def.xpReward} XP REWARD", // ✅ const সরিয়ে দিন
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
          else if (!st.claimed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToTask(st.def.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandMain,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    _getButtonLabel(st.def.id),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      "ACHIEVEMENT COMPLETED",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

          const SizedBox(height: 10),

          // Close Button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CLOSE",
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.brandMain, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Achievements Guide"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoItem("🎯 Daily Quests", "Reset every day, easy XP"),
              _buildInfoItem("📅 Weekly Challenges", "Reset every week, bigger rewards"),
              _buildInfoItem("🏆 One-time Achievements", "Permanent, huge XP boosts"),
              _buildInfoItem("🔓 Locked Achievements", "Require minimum XP to unlock"),
              _buildInfoItem("⚡ XP Rewards", "Earn XP to level up your badge"),
              _buildInfoItem("✅ Progress Tracking", "Track your completion status"),
              const SizedBox(height: 16),
              const Text(
                "Complete tasks to earn XP and level up your badge!",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("GOT IT"),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
