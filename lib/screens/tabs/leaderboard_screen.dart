import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/badge/badge_service.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedFilter = 'Global'; // Global, Finder, Supporter
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text(
          "LEADERBOARD",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildFilterToggle(isDark),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getLeaderboardStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // Index Error Handling
                  if (snapshot.error.toString().contains('index')) {
                    return const Center(child: Text("Firestore index required. Check console log."));
                  }
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data?.docs ?? [];
                if (users.isEmpty) return const Center(child: Text("No ranking data yet"));

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 20),
                    // Podium for Top 3
                    if (users.isNotEmpty) _buildPodium(users.take(3).toList(), isDark),
                    const SizedBox(height: 30),
                    // List for Rank 4+
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
    );
  }

  // --- Firestore Stream Logic ---
  Stream<QuerySnapshot> _getLeaderboardStream() {
    Query query = FirebaseFirestore.instance.collection('users');

    // Filter Logic
    if (_selectedFilter == 'Finder') {
      query = query.where('userRole', isEqualTo: 'finder');
    } else if (_selectedFilter == 'Supporter') {
      query = query.where('userRole', isEqualTo: 'maker'); // 'maker' is usually supporter in your DB logic
    }

    // Default: Sort by XP Points (descending)
    // IMPORTANT: 'xpPoints' field should exist on user docs, if not found use 'user_badge_points'
    return query
        .orderBy('user_badge_points', descending: true) // Using 'user_badge_points' based on your profile screen logic
        .limit(50)
        .snapshots();
  }

  // --- UI Components ---

  Widget _buildFilterToggle(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.symmetric(vertical: 10),
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
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPodium(List<DocumentSnapshot> top3, bool isDark) {
    if (top3.isEmpty) return const SizedBox();

    // Reorder for UI: [2nd, 1st, 3rd]
    List<DocumentSnapshot?> podiumList = List.filled(3, null);
    if (top3.length >= 1) podiumList[1] = top3[0]; // 1st -> Center
    if (top3.length >= 2) podiumList[0] = top3[1]; // 2nd -> Left
    if (top3.length >= 3) podiumList[2] = top3[2]; // 3rd -> Right

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (podiumList[0] != null) _podiumItem(podiumList[0]!, 2, 60, isDark),
        if (podiumList[1] != null) _podiumItem(podiumList[1]!, 1, 85, isDark),
        if (podiumList[2] != null) _podiumItem(podiumList[2]!, 3, 55, isDark),
      ],
    );
  }

  Widget _podiumItem(DocumentSnapshot doc, int rank, double size, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final String name = data['name'] ?? 'User';
    final int xp = int.tryParse(data['user_badge_points']?.toString() ?? '0') ?? 0;
    final String image = data['image'] ?? '';

    Color rankColor = rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey : Colors.brown);

    return Expanded(
      child: GestureDetector(
        onTap: () => _openProfile(doc.id),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 15),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: rankColor, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: size / 2,
                    backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                    backgroundColor: Colors.grey[200],
                    child: image.isEmpty ? Icon(Icons.person, color: Colors.grey[400]) : null,
                  ),
                ),
                Positioned(
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: rankColor, shape: BoxShape.circle),
                    child: Text("$rank", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text("${_formatPoints(xp)} XP", style: const TextStyle(color: AppColors.brandMain, fontWeight: FontWeight.w800, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(DocumentSnapshot doc, int rank, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isMe = doc.id == _currentUid;
    final String name = data['name'] ?? 'User';
    final int xp = int.tryParse(data['user_badge_points']?.toString() ?? '0') ?? 0;
    final String image = data['image'] ?? '';
    final BadgeLevel level = BadgeService.getLevelByPoints(xp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.brandMain.withOpacity(0.1) : (isDark ? Colors.white10 : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: isMe ? Border.all(color: AppColors.brandMain, width: 1) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
        ],
      ),
      child: InkWell(
        onTap: () => _openProfile(doc.id),
        child: Row(
          children: [
            SizedBox(width: 30, child: Text("$rank", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))),
            CircleAvatar(
              radius: 20,
              backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
              backgroundColor: Colors.grey[200],
              child: image.isEmpty ? Icon(Icons.person, color: Colors.grey[400]) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(BadgeService.getFormattedLevelName(level), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatPoints(xp),
                  style: TextStyle(fontWeight: FontWeight.w900, color: isMe ? AppColors.brandMain : null),
                ),
                const Text("XP", style: TextStyle(fontSize: 8, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
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

  String _formatPoints(int points) {
    if (points >= 1000000) return "${(points / 1000000).toStringAsFixed(1)}M";
    if (points >= 1000) return "${(points / 1000).toStringAsFixed(1)}K";
    return points.toString();
  }
}