import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/badge/badge_service.dart';
import 'package:findus_app/badge/badge_model.dart';

class LeaderboardScreen extends StatefulWidget {
  final bool isStandalone;

  const LeaderboardScreen({
    super.key,
    this.isStandalone = false,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ==================== STATE ====================
  String _selectedFilter = 'Global';
  String _selectedCategory = 'overall';

  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isLoading = true;
  Map<String, dynamic> _userStats = {};

  // ✅ নতুন: Rank tracking
  int _myRank = 0;
  bool _confettiPlayed = false;

  late ConfettiController _confettiController;

  // ==================== LIFECYCLE ====================
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

  // ==================== DATA LOADING ====================
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
    } catch (e) {
      debugPrint("❌ Load user stats error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    HapticFeedback.lightImpact();
    setState(() {
      _confettiPlayed = false; // Reset confetti on refresh
    });
    await _loadUserStats();
  }

  // ==================== HELPERS ====================
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

  String _formatPoints(int points) {
    if (points >= 1000000) return "${(points / 1000000).toStringAsFixed(1)}M";
    if (points >= 1000) return "${(points / 1000).toStringAsFixed(1)}K";
    return points.toString();
  }

  // ==================== FIRESTORE QUERY ====================
  Stream<QuerySnapshot<Map<String, dynamic>>> _getLeaderboardStream() {
    Query<Map<String, dynamic>> query =
    FirebaseFirestore.instance.collection('users');

    // ✅ Role filter
    if (_selectedFilter == 'Finder') {
      query = query.where('userRole', isEqualTo: 'finder');
    } else if (_selectedFilter == 'Supporter') {
      query = query.where('userRole', isEqualTo: 'maker');
    }

    // ✅ Category sorting (index-friendly - কোনো where isGreaterThan নেই)
    switch (_selectedCategory) {
      case 'jobs':
        query = query.orderBy('jobsCompleted', descending: true);
        break;
      case 'hires':
        query = query.orderBy('hiresCount', descending: true);
        break;
      case 'skill':
        query = query.orderBy('averageRating', descending: true);
        break;
      case 'consistency':
        query = query.orderBy('streakDays', descending: true);
        break;
      case 'earnings':
        query = query.orderBy('totalEarnings', descending: true);
        break;
      case 'referrals':
        query = query.orderBy('referralCount', descending: true);
        break;
      case 'level':
      case 'overall':
      default:
        query = query.orderBy('xpPoints', descending: true);
        break;
    }

    return query.limit(100).snapshots();
  }

  // ==================== SCORE HELPERS ====================
  int _getScoreForCategory(Map<String, dynamic> data, String category) {
    switch (category) {
      case 'jobs':
        return _asInt(data['jobsCompleted']);
      case 'hires':
        return _asInt(data['hiresCount']);
      case 'skill':
        final rating = _asDouble(data['averageRating']);
        return (rating * 100).toInt();
      case 'consistency':
        return _asInt(data['streakDays']);
      case 'earnings':
        return _asInt(data['totalEarnings']);
      case 'referrals':
        return _asInt(data['referralCount']);
      case 'level':
        final xp = _asInt(data['xpPoints']);
        return BadgeService.getNumericLevel(xp);
      default:
        return _asInt(data['xpPoints']);
    }
  }

  String _formatScore(int score, String category) {
    switch (category) {
      case 'skill':
        return (score / 100).toStringAsFixed(1);
      case 'earnings':
        return "৳${_formatPoints(score)}";
      case 'level':
        return "Lv $score";
      default:
        return _formatPoints(score);
    }
  }

  String _getCategoryUnit(String category) {
    switch (category) {
      case 'jobs':
        return 'Done';
      case 'hires':
        return 'Hired';
      case 'skill':
        return 'Rating';
      case 'consistency':
        return 'Days';
      case 'earnings':
        return 'Earned';
      case 'referrals':
        return 'Refs';
      case 'level':
        return 'Level';
      default:
        return 'XP';
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final appBarColor = isDark ? const Color(0xFF2C2C2C) : AppColors.brandMain;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: widget.isStandalone
          ? AppBar(
        title: const Text("LEADERBOARD"),
        centerTitle: true,
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
      )
          : null,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeroSection(isDark),
              _buildCategorySelector(isDark),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _getLeaderboardStream(),
                  builder: (context, snapshot) {
                    // ✅ Error handling
                    if (snapshot.hasError) {
                      return _buildErrorState(textColor, snapshot.error.toString());
                    }

                    // ✅ Loading state
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.brandMain),
                      );
                    }

                    final users = snapshot.data?.docs ?? [];

                    // ✅ Empty state
                    if (users.isEmpty) {
                      return _buildEmptyState(isDark);
                    }

                    // ✅ Calculate my rank
                    _calculateMyRank(users);

                    // ✅ Confetti for top 3
                    _checkAndPlayConfetti(users);

                    return RefreshIndicator(
                      onRefresh: _refreshData,
                      color: AppColors.brandMain,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 20),

                          // ✅ Podium (Top 3)
                          _buildPodium(users.take(3).toList(), isDark),

                          const SizedBox(height: 30),

                          // ✅ Rest of users (4th onwards)
                          if (users.length > 3)
                            ...users.skip(3).toList().asMap().entries.map((entry) {
                              final index = entry.key + 4; // 4th position থেকে
                              final doc = entry.value;
                              return _buildUserTile(doc, index, isDark);
                            }),

                          const SizedBox(height: 100),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // ✅ Confetti Widget
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              gravity: 0.3,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== RANK CALCULATION ====================
  void _calculateMyRank(List<DocumentSnapshot<Map<String, dynamic>>> users) {
    int rank = 0;
    for (int i = 0; i < users.length; i++) {
      if (users[i].id == _currentUid) {
        rank = i + 1;
        break;
      }
    }

    // Update state only if changed
    if (_myRank != rank) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _myRank = rank);
        }
      });
    }
  }

  void _checkAndPlayConfetti(List<DocumentSnapshot<Map<String, dynamic>>> users) {
    if (_confettiPlayed) return;

    final isInTop3 = users.take(3).any((doc) => doc.id == _currentUid);
    if (isInTop3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiPlayed = true;
        _confettiController.play();
        HapticFeedback.heavyImpact();
      });
    }
  }

  // ==================== UI WIDGETS ====================

  // 🏆 Hero Section
  Widget _buildHeroSection(bool isDark) {
    final int myXp = _asInt(_userStats['xpPoints']);
    final int myLevel = BadgeService.getNumericLevel(myXp);
    final double myStars = _asDouble(_userStats['user_accumulated_stars']);
    final badgeRank = BadgeService.getBadgeByStars(myStars);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: widget.isStandalone
            ? null
            : LinearGradient(
          colors: [
            AppColors.brandMain.withOpacity(0.9),
            AppColors.brandDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: widget.isStandalone
            ? (isDark ? const Color(0xFF2C2C2C) : AppColors.brandMain)
            : null,
      ),
      child: SafeArea(
        top: !widget.isStandalone,
        bottom: false,
        child: Column(
          children: [
            // Title (only if not standalone)
            if (!widget.isStandalone)
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

            if (!widget.isStandalone) const SizedBox(height: 16),

            // ✅ User Rank Card
            _buildUserRankCard(isDark, myXp, myLevel, badgeRank),
          ],
        ),
      ),
    );
  }

  // 📇 User Rank Card
  Widget _buildUserRankCard(bool isDark, int xp, int level, BadgeLevel rank) {
    final dummyProgress = BadgeProgress(badgeLevel: rank, totalXP: xp);
    final rankColor = dummyProgress.badgeColor;
    final rankName = dummyProgress.badgeName;
    final userName = _userStats['name']?.toString() ?? 'User';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Badge Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor),
            ),
            child: Icon(Icons.workspace_premium, color: rankColor, size: 24),
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
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "$rankName • Level $level",
                  style: TextStyle(
                    color: rankColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ✅ Rank Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _myRank > 0 && _myRank <= 3
                  ? Colors.amber.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: _myRank > 0 && _myRank <= 3
                  ? Border.all(color: Colors.amber, width: 1.5)
                  : null,
            ),
            child: Column(
              children: [
                Icon(
                  _myRank > 0 && _myRank <= 3
                      ? Icons.emoji_events
                      : Icons.leaderboard,
                  color: _myRank > 0 && _myRank <= 3
                      ? Colors.amber
                      : Colors.white,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  _myRank > 0 ? "#$_myRank" : "N/A",
                  style: TextStyle(
                    color: _myRank > 0 && _myRank <= 3
                        ? Colors.amber
                        : Colors.white,
                    fontSize: 14,
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

  // 🏷️ Category Selector
  Widget _buildCategorySelector(bool isDark) {
    final categories = [
      {'id': 'overall', 'label': 'Overall', 'icon': Icons.leaderboard},
      {'id': 'level', 'label': 'Level', 'icon': Icons.stairs},
      {'id': 'jobs', 'label': 'Jobs', 'icon': Icons.work_history},
      {'id': 'hires', 'label': 'Hires', 'icon': Icons.handshake},
      {'id': 'skill', 'label': 'Rating', 'icon': Icons.star},
      {'id': 'consistency', 'label': 'Streak', 'icon': Icons.local_fire_department},
      {'id': 'earnings', 'label': 'Earned', 'icon': Icons.monetization_on},
      {'id': 'referrals', 'label': 'Refs', 'icon': Icons.people},
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
          // Category Chips
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
                        Icon(cat['icon'] as IconData, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          cat['label'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat['id'] as String);
                    },
                    backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                    selectedColor: AppColors.brandMain,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

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
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFilter = filter);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandMain
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        filter.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey : Colors.black54),
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

  // 🏆 Podium (Top 3)
  Widget _buildPodium(
      List<DocumentSnapshot<Map<String, dynamic>>> top3, bool isDark) {
    if (top3.isEmpty) return const SizedBox();

    final List<DocumentSnapshot<Map<String, dynamic>>?> podiumList =
    List.filled(3, null);

    // Position: [2nd, 1st, 3rd]
    if (top3.isNotEmpty) podiumList[1] = top3[0]; // Rank 1 (center)
    if (top3.length >= 2) podiumList[0] = top3[1]; // Rank 2 (left)
    if (top3.length >= 3) podiumList[2] = top3[2]; // Rank 3 (right)

    return Column(
      children: [
        Text(
          '🏆 TOP CHAMPIONS',
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
            // 2nd Place (Left)
            if (podiumList[0] != null)
              Expanded(child: _podiumItem(podiumList[0]!, 2, isDark))
            else
              const Expanded(child: SizedBox()),

            // 1st Place (Center)
            if (podiumList[1] != null)
              Expanded(child: _podiumItem(podiumList[1]!, 1, isDark))
            else
              const Expanded(child: SizedBox()),

            // 3rd Place (Right)
            if (podiumList[2] != null)
              Expanded(child: _podiumItem(podiumList[2]!, 3, isDark))
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _podiumItem(
      DocumentSnapshot<Map<String, dynamic>> doc, int rank, bool isDark) {
    final data = doc.data() ?? {};
    final String name = (data['name'] ?? 'User').toString();
    final String image = (data['image'] ?? '').toString();
    final int score = _getScoreForCategory(data, _selectedCategory);
    final bool isMe = doc.id == _currentUid;

    final double stars = _asDouble(data['user_accumulated_stars']);
    final badgeRank = BadgeService.getBadgeByStars(stars);
    final dummyProgress = BadgeProgress(badgeLevel: badgeRank, totalXP: 0);
    final badgeColor = dummyProgress.badgeColor;

    // Rank colors
    final Color rankColor = rank == 1
        ? const Color(0xFFFFD700) // Gold
        : rank == 2
        ? const Color(0xFFC0C0C0) // Silver
        : const Color(0xFFCD7F32); // Bronze

    // Podium heights
    final double podiumHeight = rank == 1 ? 100 : rank == 2 ? 80 : 60;

    return GestureDetector(
      onTap: () => _openProfile(doc.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown for 1st place
          if (rank == 1)
            const Text('👑', style: TextStyle(fontSize: 24)),

          // Badge Icon
          Icon(Icons.workspace_premium, color: badgeColor, size: 20),

          const SizedBox(height: 4),

          // Avatar
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: rankColor, width: 3),
                  boxShadow: isMe
                      ? [
                    BoxShadow(
                      color: AppColors.brandMain.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                      : null,
                ),
                child: CircleAvatar(
                  radius: rank == 1 ? 35 : 28,
                  backgroundImage:
                  image.isNotEmpty ? NetworkImage(image) : null,
                  backgroundColor: Colors.grey[200],
                  child: image.isEmpty
                      ? Icon(Icons.person, color: Colors.grey[400])
                      : null,
                ),
              ),
              if (isMe)
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandMain,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'YOU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Name
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

          // Score
          Text(
            _formatScore(score, _selectedCategory),
            style: TextStyle(
              color: rankColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 8),

          // Podium Block
          Container(
            height: podiumHeight,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  rankColor,
                  rankColor.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: rankColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                "#$rank",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 👤 User Tile (4th position onwards)
  Widget _buildUserTile(
      DocumentSnapshot<Map<String, dynamic>> doc, int rank, bool isDark) {
    final data = doc.data() ?? {};
    final bool isMe = doc.id == _currentUid;
    final String name = (data['name'] ?? 'User').toString();
    final String image = (data['image'] ?? '').toString();

    final int score = _getScoreForCategory(data, _selectedCategory);
    final int xp = _asInt(data['xpPoints']);
    final int level = BadgeService.getNumericLevel(xp);

    final double stars = _asDouble(data['user_accumulated_stars']);
    final badgeRank = BadgeService.getBadgeByStars(stars);
    final dummyProgress = BadgeProgress(badgeLevel: badgeRank, totalXP: xp);
    final badgeColor = dummyProgress.badgeColor;
    final rankName = dummyProgress.badgeName;

    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.brandMain.withOpacity(0.1) : cardColor,
        borderRadius: BorderRadius.circular(18),
        border: isMe
            ? Border.all(color: AppColors.brandMain, width: 1.5)
            : Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openProfile(doc.id),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Rank Number
                SizedBox(
                  width: 36,
                  child: Text(
                    "#$rank",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: isMe ? AppColors.brandMain : Colors.grey,
                    ),
                  ),
                ),

                // Avatar with Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage:
                      image.isNotEmpty ? NetworkImage(image) : null,
                      backgroundColor: AppColors.brandLight,
                      child: image.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2C)
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.workspace_premium,
                          size: 14,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMe)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.brandMain,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "LV $level",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                isDark ? Colors.white60 : Colors.grey[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            rankName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Score
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
        ),
      ),
    );
  }

  // ❌ Error State
  Widget _buildErrorState(Color textColor, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              "Failed to load leaderboard",
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Check Firestore indexes",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📭 Empty State
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No ranking data found",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Be the first to join the leaderboard!",
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔗 Navigation
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

  // ℹ️ Info Dialog
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.brandMain),
            SizedBox(width: 10),
            Text('Leaderboard Info'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rankings are based on:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('🏆 Overall: Total XP points'),
            Text('📊 Level: User level'),
            Text('💼 Jobs: Tasks completed'),
            Text('🤝 Hires: People hired'),
            Text('⭐ Rating: Average rating'),
            Text('🔥 Streak: Consecutive active days'),
            Text('💰 Earned: Total earnings'),
            Text('👥 Refs: Referral count'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }
}