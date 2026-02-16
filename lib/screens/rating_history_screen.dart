// lib/screens/rating_history_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:intl/intl.dart';

class RatingHistoryScreen extends StatefulWidget {
  final String targetUserId;

  const RatingHistoryScreen({super.key, required this.targetUserId});

  @override
  State<RatingHistoryScreen> createState() => _RatingHistoryScreenState();
}

class _RatingHistoryScreenState extends State<RatingHistoryScreen> {
  int? _selectedStar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: 'RATINGS & REVIEWS',
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('targetUserId', isEqualTo: widget.targetUserId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString(), isDark);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.brandMain),
            );
          }

          final allDocs = snapshot.data!.docs;

          if (allDocs.isEmpty) {
            return _buildEmptyState(textColor, isDark);
          }

          final stats = _calculateStats(allDocs);

          final filteredDocs = _selectedStar == null
              ? allDocs
              : allDocs.where((doc) {
            final rating = (doc['rating'] as num?)?.toDouble() ?? 0.0;
            return rating.round() == _selectedStar;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.brandMain,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                _buildSummaryCard(stats, isDark),
                const SizedBox(height: 25),
                _buildFilterChips(isDark),
                const SizedBox(height: 15),

                if (filteredDocs.isEmpty)
                  _buildEmptyFilterState(isDark)
                else
                  ...filteredDocs.map((doc) {
                    return _buildReviewCard(
                      doc.data() as Map<String, dynamic>,
                      isDark,
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

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
      'counts': starCounts,
    };
  }

  Widget _buildSummaryCard(Map<String, dynamic> stats, bool isDark) {
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                (stats['avg'] as double).toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  SizedBox(width: 4),
                  Text(
                    "Average",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "${stats['total']} Reviews",
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final star = 5 - index;
                final count = stats['counts'][star] ?? 0;
                final double percent = stats['total'] == 0
                    ? 0
                    : count / stats['total'];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        "$star",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: isDark
                                ? Colors.white10
                                : Colors.grey.shade100,
                            color: Colors.amber,
                            minHeight: 7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white54 : Colors.grey,
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

  Widget _buildFilterChips(bool isDark) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip("All", null, isDark),
          _filterChip("5 ★", 5, isDark),
          _filterChip("4 ★", 4, isDark),
          _filterChip("3 ★", 3, isDark),
          _filterChip("2 ★", 2, isDark),
          _filterChip("1 ★", 1, isDark),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int? value, bool isDark) {
    final isSelected = _selectedStar == value;
    final chipColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isSelected
        ? Colors.white
        : (isDark ? Colors.white : Colors.black);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedStar = value),
        selectedColor: AppColors.brandMain,
        backgroundColor: chipColor,
        labelStyle: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? Colors.transparent
                : Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> data, bool isDark) {
    final double rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
    final String comment = data['comment'] ?? '';
    final String fromUserId = data['fromUserId'] ?? 'Unknown';
    final bool isAnon = data['isAnonymous'] is bool
        ? data['isAnonymous']
        : (data['isAnonymous'] == 'true');

    final String dateStr = data['createdAt'] != null
        ? DateFormat('MMM dd, yyyy').format(
      (data['createdAt'] as Timestamp).toDate(),
    )
        : '';

    // ✅ Tags support
    final List<String> tags = data['tags'] is List
        ? (data['tags'] as List).map((e) => e.toString()).toList()
        : [];

    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ User Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: isAnon
                    ? _buildAnonymousUser(isDark)
                    : _buildUserInfo(fromUserId, isDark),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ✅ Star Rating
          Row(
            children: [
              ...List.generate(5, (i) {
                return Icon(
                  i < rating.round()
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: i < rating.round()
                      ? Colors.amber
                      : Colors.grey.shade400,
                  size: 16,
                );
              }),
              const SizedBox(width: 8),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),

          // ✅ Tags
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandMain.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.brandMain.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.brandDark,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // ✅ Comment
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ Anonymous User Widget
  Widget _buildAnonymousUser(bool isDark) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.grey.shade300,
          child: const Icon(Icons.person, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          "Anonymous User",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ✅ User Info Widget with FutureBuilder
  Widget _buildUserInfo(String userId, bool isDark) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
              ),
              const SizedBox(width: 10),
              const Text('Loading...', style: TextStyle(fontSize: 13)),
            ],
          );
        }

        final userData = snap.data?.data() as Map<String, dynamic>?;
        final name = userData?['name'] ?? 'User';
        final image = userData?['image'] ?? userData?['imageUrl'] ?? '';

        return Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: image.isNotEmpty
                  ? NetworkImage(image)
                  : null,
              backgroundColor: Colors.grey.shade300,
              child: image.isEmpty
                  ? const Icon(Icons.person, size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyFilterState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          children: [
            Icon(
              Icons.filter_list_off,
              size: 50,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "No reviews found for $_selectedStar ★",
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => setState(() => _selectedStar = null),
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear Filter'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 80,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No reviews yet",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Reviews will appear here",
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String err, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: isDark ? Colors.red.shade300 : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              "Failed to load reviews",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              err,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}