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
        title: const Text("LEADERBOARD", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final users = snapshot.data!.docs;
                if (users.isEmpty) return const Center(child: Text("No data found"));

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 20),
                    // Podium for Top 3
                    _buildPodium(users.take(3).toList(), isDark),
                    const SizedBox(height: 30),
                    // List for Rank 4+
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
    // ১. প্রথমে ইউজার কালেকশন রেফারেন্স নিন
    Query query = FirebaseFirestore.instance.collection('users');

    // ২. যদি ইউজার নির্দিষ্ট কোনো রোল ফিল্টার করে (Finder বা Supporter)
    if (_selectedFilter != 'Global') {
      query = query.where('userRole', isEqualTo: _selectedFilter.toLowerCase());
    }

    // ৩. এবার পয়েন্ট অনুযায়ী সাজান (বড় থেকে ছোট)
    // এবং সেরা ৫০ বা ১০০ জনকে লিমিট করুন
    return query
        .orderBy('xpPoints', descending: true)
        .limit(50)
        .snapshots(); // এটি রিয়েল-টাইম ডাটা দিবে
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
              child: Container(
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
    if (top3.length >= 1) podiumList[1] = top3[0]; // 1st
    if (top3.length >= 2) podiumList[0] = top3[1]; // 2nd
    if (top3.length >= 3) podiumList[2] = top3[2]; // 3rd

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
    final int xp = data['xpPoints'] ?? 0;
    final String image = data['imageUrl'] ?? '';

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
                    child: image.isEmpty ? const Icon(Icons.person) : null,
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
            Text("${_formatPoints(xp)} XP", style: TextStyle(color: AppColors.brandMain, fontWeight: FontWeight.w800, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(DocumentSnapshot doc, int rank, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isMe = doc.id == _currentUid;
    final String name = data['name'] ?? 'User';
    final int xp = data['xpPoints'] ?? 0;
    final String image = data['imageUrl'] ?? '';
    final BadgeLevel level = BadgeService.getLevelByPoints(xp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.brandMain.withOpacity(0.1) : (isDark ? Colors.white05 : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: isMe ? Border.all(color: AppColors.brandMain, width: 1) : null,
      ),
      child: InkWell(
        onTap: () => _openProfile(doc.id),
        child: Row(
          children: [
            SizedBox(width: 30, child: Text("$rank", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))),
            CircleAvatar(
              radius: 20,
              backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
              child: image.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(BadgeService.getFormattedLevelName(level), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ),
            Text(
              _formatPoints(xp),
              style: TextStyle(fontWeight: FontWeight.w900, color: isMe ? AppColors.brandMain : null),
            ),
            const SizedBox(width: 4),
            const Text("XP", style: TextStyle(fontSize: 8, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _openProfile(String uid) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => UnifiedProfileScreen(uid: uid, isOwner: uid == _currentUid)));
  }

  String _formatPoints(int points) {
    if (points >= 1000) return "${(points / 1000).toStringAsFixed(1)}K";
    return points.toString();
  }
}