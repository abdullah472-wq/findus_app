import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedFilter = 'Global'; // Global, Finder, Supporter
  String _selectedCategory = 'overall'; // overall, level, skill, consistency, etc.

  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mounted) return;

      setState(() {
        _userStats = doc.data() ?? {};
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ----------------------------
  // XP -> Level (1..100) mapping
  // 300 XP/day target:
  // Level 50 ~ 1y, Level 100 ~ 4y (approx)
  // ----------------------------
  int _levelFromXp(int xp) {
    if (xp <= 0) return 1;
    const double a = 44.0;
    final lvl = 1 + math.sqrt(xp / a).floor();
    return lvl.clamp(1, 100);
  }

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  double _asDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  // Firestore Stream Logic
  Stream<QuerySnapshot<Map<String, dynamic>>> _getLeaderboardStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('users');

    // Role filter
    if (_selectedFilter == 'Finder') {
      query = query.where('userRole', isEqualTo: 'finder');
    } else if (_selectedFilter == 'Supporter') {
      query = query.where('userRole', isEqualTo: 'maker');
    }

    // Category-based ordering
    switch (_selectedCategory) {
      case 'skill':
      // Ensure you store averageRating as a number in users
        query = query.where('averageRating', isGreaterThan: 0).orderBy('averageRating', descending: true);
        break;

      case 'consistency':
        query = query.where('streakDays', isGreaterThan: 0).orderBy('streakDays', descending: true);
        break;

      case 'earnings':
        query = query.where('totalEarnings', isGreaterThan: 0).orderBy('totalEarnings', descending: true);
        break;

      case 'jobs':
        query = query.where('jobsCompleted', isGreaterThan: 0).orderBy('jobsCompleted', descending: true);
        break;

      case 'referrals':
        query = query.where('referralCount', isGreaterThan: 0).orderBy('referralCount', descending: true);
        break;

      case 'level':
      // Level is derived from xpPoints, so sort by xpPoints
        query = query.orderBy('xpPoints', descending: true);
        break;

      case 'overall':
      default:
        query = query.orderBy('xpPoints', descending: true);
        break;
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
        Container(color: bgColor),

        Column(
          children: [
            _buildHeroSection(isDark),

            _buildCategorySelector(isDark),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getLeaderboardStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: textColor)));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.brandMain));
                  }

                  final users = snapshot.data?.docs ?? [];
                  if (users.isEmpty) {
                    return Center(child: Text("No ranking data yet", style: TextStyle(color: textColor)));
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 20),
                      if (users.isNotEmpty) _buildPodium(users.take(3).toList(), isDark),
                      const SizedBox(height: 30),
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

        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
        ),
      ],
    );
  }

  // ---------------- UI ----------------

  Widget _buildHeroSection(bool isDark) {
    final int myXp = _asInt(_userStats['xpPoints'], fallback: 0);
    final int myLevel = _levelFromXp(myXp);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandMain.withOpacity(0.9), AppColors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            _buildUserRankCard(isDark, myXp, myLevel),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRankCard(bool isDark, int xp, int level) {
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: Text(
              "#${rank > 999 ? '999+' : rank}",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Your Position", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                Text(
                  (_userStats['name']?.toString() ?? 'User'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Level $level • ${_formatPoints(xp)} XP",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                const Icon(Icons.stairs, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text("LV $level", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
      {'id': 'level', 'label': '🎮 Level', 'icon': Icons.stairs},
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
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

  Widget _buildPodium(List<DocumentSnapshot<Map<String, dynamic>>> top3, bool isDark) {
    if (top3.isEmpty) return const SizedBox();

    final List<DocumentSnapshot<Map<String, dynamic>>?> podiumList = List.filled(3, null);
    if (top3.isNotEmpty) podiumList[1] = top3[0]; // 1st
    if (top3.length >= 2) podiumList[0] = top3[1]; // 2nd
    if (top3.length >= 3) podiumList[2] = top3[2]; // 3rd

    return Column(
      children: [
        Text(
          'TOP 3 CHAMPIONS',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (podiumList[0] != null) _podiumItem(podiumList[0]!, 2, isDark),
            if (podiumList[1] != null) _podiumItem(podiumList[1]!, 1, isDark),
            if (podiumList[2] != null) _podiumItem(podiumList[2]!, 3, isDark),
          ],
        ),
      ],
    );
  }

  Widget _podiumItem(DocumentSnapshot<Map<String, dynamic>> doc, int rank, bool isDark) {
    final data = doc.data() ?? {};
    final String name = (data['name'] ?? 'User').toString();
    final String image = (data['image'] ?? '').toString();
    final int score = _getScoreForCategory(data, _selectedCategory);

    final Color rankColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
        ? const Color(0xFFC0C0C0)
        : const Color(0xFFCD7F32);

    return Expanded(
      child: GestureDetector(
        onTap: () => _openProfile(doc.id),
        child: Column(
          children: [
            Container(
              height: rank == 1 ? 120 : rank == 2 ? 100 : 80,
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.3),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                border: Border.all(color: rankColor, width: 2),
              ),
              child: Center(
                child: Text(
                  "#$rank",
                  style: TextStyle(color: rankColor, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatScore(score, _selectedCategory, data),
                    style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(DocumentSnapshot<Map<String, dynamic>> doc, int rank, bool isDark) {
    final data = doc.data() ?? {};
    final bool isMe = doc.id == _currentUid;

    final String name = (data['name'] ?? 'User').toString();
    final String image = (data['image'] ?? '').toString();

    final int score = _getScoreForCategory(data, _selectedCategory);

    final int xp = _asInt(data['xpPoints'], fallback: 0);
    final int level = _levelFromXp(xp);

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
            BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        onTap: () => _openProfile(doc.id),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                "#$rank",
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "LV $level • ${_formatPoints(xp)} XP",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatScore(score, _selectedCategory, data),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: isMe ? AppColors.brandMain : textColor,
                  ),
                ),
                Text(
                  _getCategoryUnit(_selectedCategory),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Helpers ----------------

  int _getScoreForCategory(Map<String, dynamic> data, String category) {
    switch (category) {
      case 'skill':
      // rating score (x100)
        final rating = _asDouble(data['averageRating'], fallback: 0.0);
        return (rating * 100).toInt();

      case 'consistency':
        return _asInt(data['streakDays'], fallback: 0);

      case 'earnings':
        return _asInt(data['totalEarnings'], fallback: 0);

      case 'jobs':
        return _asInt(data['jobsCompleted'], fallback: 0);

      case 'referrals':
        return _asInt(data['referralCount'], fallback: 0);

      case 'level':
        final xp = _asInt(data['xpPoints'], fallback: 0);
        return _levelFromXp(xp);

      case 'overall':
      default:
        return _asInt(data['xpPoints'], fallback: 0);
    }
  }

  String _formatScore(int score, String category, Map<String, dynamic> data) {
    switch (category) {
      case 'skill':
        return (score / 100).toStringAsFixed(1);
      case 'earnings':
        return _formatPoints(score);
      case 'level':
        return "Lv $score";
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
      case 'level':
        return 'Level';
      default:
        return 'XP';
    }
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
              '🎮 Level: Derived from XP (1-100)\n'
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