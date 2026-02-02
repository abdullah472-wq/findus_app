// lib/screens/tabs/leaderboard_tab.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/badge/badge_service.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';

class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  String _selectedFilter = 'Global'; // Global, Finder, Supporter
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Multi-category support
  String _selectedCategory = 'overall'; // overall, skill, consistency, etc.
  bool _isLoading = true;
  Map<String, dynamic> _userStats = {};
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadUserStats();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userStats = doc.data() ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user stats: $e');
      setState(() => _isLoading = false);
    }
  }

  // Firestore Stream Logic
  Stream<QuerySnapshot> _getLeaderboardStream() {
    Query query = FirebaseFirestore.instance.collection('users');

    if (_selectedFilter == 'Finder') {
      query = query.where('userRole', isEqualTo: 'finder');
    } else if (_selectedFilter == 'Supporter') {
      query = query.where('userRole', isEqualTo: 'maker');
    }

    // Category-based ordering
    switch (_selectedCategory) {
      case 'skill':
        query = query.where('averageRating', isGreaterThan: 0)
            .orderBy('averageRating', descending: true);
        break;
      case 'consistency':
        query = query.where('streakDays', isGreaterThan: 0)
            .orderBy('streakDays', descending: true);
        break;
      case 'earnings':
        query = query.where('totalEarnings', isGreaterThan: 0)
            .orderBy('totalEarnings', descending: true);
        break;
      case 'jobs':
        query = query.where('jobsCompleted', isGreaterThan: 0)
            .orderBy('jobsCompleted', descending: true);
        break;
      case 'referrals':
        query = query.where('referralCount', isGreaterThan: 0)
            .orderBy('referralCount', descending: true);
        break;
      default: // overall
        query = query.orderBy('user_badge_points', descending: true);
    }

    return query.limit(50).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return Stack(
      children: [
        // Background
        Container(color: bgColor),

        // Content
        Column(
          children: [
            // Hero Section
            _buildHeroSection(isDark),

            // Category & Filter Selector
            _buildCategorySelector(isDark),

            // Leaderboard List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getLeaderboardStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.brandMain));
                  }

                  final users = snapshot.data?.docs ?? [];
                  if (users.isEmpty) return Center(child: Text("No ranking data yet", style: TextStyle(color: textColor)));

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 20),
                      // Top 3 Podium
                      if (users.isNotEmpty) _buildPodium(users.take(3).toList(), isDark),
                      const SizedBox(height: 30),

                      // Rank 4+ List
                      if (users.length > 3)
                        ...users.skip(3).map((doc) {
                          final index = users.indexOf(doc);
                          return _buildUserTile(doc, index + 1, isDark);
                        }),
                      const SizedBox(height: 100),
                    ],
                  );
                },
              ),
            ),
          ],
        ),

        // Confetti Animation
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
        ),
      ],
    );
  }

  // --- UI Components ---

  Widget _buildHeroSection(bool isDark) {
    final currentPoints = BadgeService.badgeNotifier.value.totalPoints;
    final badgeLevel = BadgeService.getLevelByPoints(currentPoints);
    final levelColor = _getLevelColor(badgeLevel);

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
                  "LEADERBOARD",
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

            const SizedBox(height: 16),

            // User Rank Card
            _buildUserRankCard(isDark, currentPoints, badgeLevel, levelColor),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRankCard(bool isDark, int points, BadgeLevel level, Color levelColor) {
    // Calculate user's rank (simplified - in real app, you'd query for actual rank)
    final rank = _userStats['leaderboardRank'] ?? 999;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Text(
              "#${rank > 999 ? '999+' : rank}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Position",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  _userStats['name']?.toString() ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${_formatPoints(points)} XP • ${BadgeService.getFormattedLevelName(level)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Badge Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: levelColor,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  BadgeService.getFormattedLevelName(level),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    final categories = [
      {'id': 'overall', 'label': '🏆 Overall', 'icon': Icons.leaderboard},
      {'id': 'skill', 'label': '⭐ Skill', 'icon': Icons.star},
      {'id': 'consistency', 'label': '🔥 Streak', 'icon': Icons.local_fire_department},
      {'id': 'earnings', 'label': '💰 Earnings', 'icon': Icons.monetization_on},
      {'id': 'jobs', 'label': '✅ Jobs', 'icon': Icons.work},
      {'id': 'referrals', 'label': '📣 Referrals', 'icon': Icons.people},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category Scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat['icon'] as IconData, size: 16),
                        const SizedBox(width: 4),
                        Text(cat['label'] as String),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat['id'] as String),
                    backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                    selectedColor: AppColors.brandMain,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Role Filter
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: ['Global', 'Finder', 'Supporter'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brandMain : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        filter.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : (isDark ? Colors.grey : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<DocumentSnapshot> top3, bool isDark) {
    if (top3.isEmpty) return const SizedBox();

    List<DocumentSnapshot?> podiumList = List.filled(3, null);
    if (top3.isNotEmpty) podiumList[1] = top3[0]; // 1st
    if (top3.length >= 2) podiumList[0] = top3[1]; // 2nd
    if (top3.length >= 3) podiumList[2] = top3[2]; // 3rd

    return Column(
      children: [
        Text(
          'TOP 3 CHAMPIONS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (podiumList[0] != null) _podiumItem(podiumList[0]!, 2, 60, isDark),
            if (podiumList[1] != null) _podiumItem(podiumList[1]!, 1, 85, isDark),
            if (podiumList[2] != null) _podiumItem(podiumList[2]!, 3, 55, isDark),
          ],
        ),
      ],
    );
  }

  Widget _podiumItem(DocumentSnapshot doc, int rank, double size, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final String name = data['name'] ?? 'User';
    final int score = _getScoreForCategory(data, _selectedCategory);
    final String image = data['image'] ?? '';

    Color rankColor = rank == 1 ? const Color(0xFFFFD700) :
    rank == 2 ? const Color(0xFFC0C0C0) :
    const Color(0xFFCD7F32);

    return Expanded(
      child: GestureDetector(
        onTap: () => _openProfile(doc.id),
        child: Column(
          children: [
            // Podium
            Container(
              height: rank == 1 ? 120 : rank == 2 ? 100 : 80,
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border.all(color: rankColor, width: 2),
              ),
              child: Center(
                child: Text(
                  "#$rank",
                  style: TextStyle(
                    color: rankColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // User Info
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                    backgroundColor: Colors.grey[200],
                    child: image.isEmpty ? Icon(Icons.person, color: Colors.grey[400], size: 30) : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatScore(score, _selectedCategory),
                    style: TextStyle(
                      color: rankColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
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

  Widget _buildUserTile(DocumentSnapshot doc, int rank, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isMe = doc.id == _currentUid;
    final String name = data['name'] ?? 'User';
    final int score = _getScoreForCategory(data, _selectedCategory);
    final String image = data['image'] ?? '';
    final int xp = int.tryParse(data['user_badge_points']?.toString() ?? '0') ?? 0;
    final BadgeLevel level = BadgeService.getLevelByPoints(xp);

    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.brandMain.withOpacity(0.1) : cardColor,
        borderRadius: BorderRadius.circular(18),
        border: isMe ? Border.all(color: AppColors.brandMain, width: 1.5) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: InkWell(
        onTap: () => _openProfile(doc.id),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                "#$rank",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                ),
              ),
            ),
            CircleAvatar(
              radius: 22,
              backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
              backgroundColor: AppColors.brandLight,
              child: image.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      BadgeService.getFormattedLevelName(level),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatScore(score, _selectedCategory),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: isMe ? AppColors.brandMain : textColor,
                  ),
                ),
                Text(
                  _getCategoryUnit(_selectedCategory),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Methods ---

  int _getScoreForCategory(Map<String, dynamic> data, String category) {
    switch (category) {
      case 'skill':
        return ((data['averageRating'] ?? 0.0) * 100).toInt();
      case 'consistency':
        return data['streakDays'] ?? 0;
      case 'earnings':
        return data['totalEarnings'] ?? 0;
      case 'jobs':
        return data['jobsCompleted'] ?? 0;
      case 'referrals':
        return data['referralCount'] ?? 0;
      default: // overall
        return data['user_badge_points'] ?? 0;
    }
  }

  String _formatScore(int score, String category) {
    switch (category) {
      case 'skill':
        return (score / 100).toStringAsFixed(1);
      case 'earnings':
        return _formatPoints(score);
      default:
        return score.toString();
    }
  }

  String _getCategoryUnit(String category) {
    switch (category) {
      case 'skill':
        return 'Rating';
      case 'consistency':
        return 'Days';
      case 'earnings':
        return '৳';
      case 'jobs':
        return 'Jobs';
      case 'referrals':
        return 'Refs';
      default:
        return 'XP';
    }
  }

  Color _getLevelColor(BadgeLevel level) {
    switch (level) {
      case BadgeLevel.newbie:
        return Colors.white;
      case BadgeLevel.bronze:
        return const Color(0xFFCD7F32);
      case BadgeLevel.silver:
        return const Color(0xFFC0C0C0);
      case BadgeLevel.gold:
        return const Color(0xFFFFD700);
      case BadgeLevel.platinum:
        return const Color(0xFFE5E4E2);
      case BadgeLevel.diamond:
        return const Color(0xFFB9F2FF);
      default:
        return Colors.grey;
    }
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    if (rank <= 10) return Colors.blue;
    if (rank <= 50) return Colors.green;
    return Colors.grey;
  }

  String _formatPoints(int points) {
    if (points >= 1000000) return "${(points / 1000000).toStringAsFixed(1)}M";
    if (points >= 1000) return "${(points / 1000).toStringAsFixed(1)}K";
    return points.toString();
  }

  void _openProfile(String uid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedProfileScreen(
          uid: uid,
          isOwner: uid == _currentUid,
          showBack: true,
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leaderboard Info'),
        content: const Text(
          'Rankings are based on various categories:\n\n'
              '🏆 Overall: Total XP points\n'
              '⭐ Skill: Average rating\n'
              '🔥 Consistency: Daily streak\n'
              '💰 Earnings: Total earnings\n'
              '✅ Jobs: Completed jobs\n'
              '📣 Referrals: Successful referrals\n\n'
              'Filters:\n'
              '• Global: All users\n'
              '• Finder: Job seekers only\n'
              '• Supporter: Job providers only',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}