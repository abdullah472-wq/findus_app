// lib/screens/rating_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:intl/intl.dart';

class RatingHistoryScreen extends StatefulWidget {
  final String targetUserId; // এটিই আপনার ডাটার "targetUserId"

  const RatingHistoryScreen({super.key, required this.targetUserId});

  @override
  State<RatingHistoryScreen> createState() => _RatingHistoryScreenState();
}

class _RatingHistoryScreenState extends State<RatingHistoryScreen> {
  int? _selectedStar; // null = All

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FloatingScaffold(
      title: 'RATINGS & REVIEWS',
      backgroundColor: AppColors.brandLight,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('targetUserId', isEqualTo: widget.targetUserId) // ✅ আপনার ফিল্ড নাম অনুযায়ী
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _buildError(snapshot.error.toString());
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allDocs = snapshot.data!.docs;
          if (allDocs.isEmpty) return _buildEmptyState();

          final stats = _calculateStats(allDocs);

          // ফিল্টারিং লজিক (Rating double হলেও round করে চেক করবে)
          final filteredDocs = _selectedStar == null
              ? allDocs
              : allDocs.where((doc) => (doc['rating'] as num).round() == _selectedStar).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildSummaryCard(stats, isDark),
              const SizedBox(height: 25),
              _buildFilterChips(),
              const SizedBox(height: 15),
              if (filteredDocs.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Text("No reviews found for this rating"),
                ))
              else
                ...filteredDocs.map((doc) => _buildReviewCard(doc.data() as Map<String, dynamic>, isDark)),
            ],
          );
        },
      ),
    );
  }

  // সামারি ক্যালকুলেশন
  Map<String, dynamic> _calculateStats(List<QueryDocumentSnapshot> docs) {
    double totalRating = 0;
    Map<int, int> starCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      double rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      totalRating += rating;
      int starKey = rating.round();
      if (starKey >= 1 && starKey <= 5) {
        starCounts[starKey] = (starCounts[starKey] ?? 0) + 1;
      }
    }

    return {
      'avg': docs.isEmpty ? 0.0 : totalRating / docs.length,
      'total': docs.length,
      'counts': starCounts
    };
  }

  // সামারি কার্ড ডিজাইন
  Widget _buildSummaryCard(Map<String, dynamic> stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                (stats['avg'] as double).toStringAsFixed(1),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
              ),
              const Text("Average", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("${stats['total']} Reviews", style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final star = 5 - index;
                final count = stats['counts'][star] ?? 0;
                final double percent = stats['total'] == 0 ? 0 : count / stats['total'];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text("$star", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                            color: Colors.amber,
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ফিল্টার চিপস
  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip("All", null),
          _filterChip("5 ★", 5),
          _filterChip("4 ★", 4),
          _filterChip("3 ★", 3),
          _filterChip("2 ★", 2),
          _filterChip("1 ★", 1),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int? value) {
    final isSelected = _selectedStar == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedStar = value),
        selectedColor: AppColors.brandMain,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade200),
      ),
    );
  }

  // রিভিউ কার্ড (আপনার ডাটায় রিভিউয়ারের নাম না থাকায় আমরা UID দেখাব অথবা আলাদা Fetch লজিক লাগবে)
  Widget _buildReviewCard(Map<String, dynamic> data, bool isDark) {
    final double rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final String comment = data['comment'] ?? '';
    final String fromUserId = data['fromUserId'] ?? 'Anonymous';
    final String isAnonymous = (data['isAnonymous'] ?? 'false').toString();

    final String dateStr = data['createdAt'] != null
        ? DateFormat('MMM dd, yyyy').format((data['createdAt'] as Timestamp).toDate())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // যদি Anonymous না হয় তবে UID দেখাবে (নামের জন্য আলাদা কুয়েরি করা ভালো)
              Text(
                  isAnonymous == "true" ? "Anonymous User" : "Client ID: ${fromUserId.substring(0, 5)}...",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
              ),
              Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ...List.generate(5, (i) => Icon(
                i < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i < rating.round() ? Colors.amber : Colors.grey.shade300,
                size: 16,
              )),
              const SizedBox(width: 8),
              Text(rating.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(comment, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text("No reviews yet."));
  Widget _buildError(String err) => Center(child: Text("Error: $err"));
}