// lib/screens/tabs/review_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/review_service.dart';
import 'package:findus_app/services/notification_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/badge/badge_service.dart';

class ReviewScreen extends StatefulWidget {
  final String workerId;
  final String postId;
  final String workerName;
  final String role;
  final String imageUrl;

  const ReviewScreen({
    super.key,
    required this.workerId,
    required this.postId,
    required this.workerName,
    required this.role,
    required this.imageUrl,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _rating = 0.0;
  final TextEditingController _commentController = TextEditingController();

  final List<String> _tags = [
    "On time",
    "Polite",
    "Skilled",
    "Clean work",
    "Value for money",
    "Not satisfied"
  ];
  final Set<String> _selectedTags = {};
  bool _wouldHireAgain = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    if (_rating >= 4.5) return "Excellent! 😍";
    if (_rating >= 3.5) return "Good Work! 🙂";
    if (_rating >= 2.5) return "Average 😐";
    if (_rating > 0) return "Needs Improvement ☹️";
    return "Tap a star to rate";
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ FIXED: SUBMIT REVIEW
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _submitReview() async {
    if (_rating == 0) {
      _showSnack("Please select a star rating", Colors.orange);
      return;
    }

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) {
      _showSnack("Please login first", Colors.orange);
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final db = FirebaseFirestore.instance;

      // ✅ 1. Check for duplicate review (outside transaction)
      final existingReview = await db
          .collection('reviews')
          .where('fromUserId', isEqualTo: myUid)
          .where('postId', isEqualTo: widget.postId)
          .limit(1)
          .get();

      if (existingReview.docs.isNotEmpty) {
        _showSnack("You've already reviewed this job!", Colors.orange);
        setState(() => _isSaving = false);
        return;
      }

      // ✅ 2. Prepare comment with tags
      final baseComment = _commentController.text.trim();
      String fullComment = baseComment;
      if (_selectedTags.isNotEmpty) {
        fullComment += "\n\nFeedback: ${_selectedTags.join(', ')}";
      }

      // ✅ 3. Submit review to database
      await ReviewService.addReview(
        targetUserId: widget.workerId,
        postId: widget.postId,
        rating: _rating,
        comment: fullComment,
        targetRole: 'worker',
        fromRole: 'supporter',
        isAnonymous: false,
        wouldHireAgain: _wouldHireAgain,
        tags: _selectedTags.toList(),
      );

      // ════════════════════════════════════════════════════════════════════════
      // ✅ 4. UPDATE WORKER'S STATS (FIXED TRANSACTION)
      // ════════════════════════════════════════════════════════════════════════
      await db.runTransaction((tx) async {
        // ✅ READ PHASE - All reads must come first
        final userRef = db.collection('users').doc(widget.workerId);
        final statsRef = db.collection('user_stats').doc(widget.workerId);

        final userSnap = await tx.get(userRef);
        final statsSnap = await tx.get(statsRef);

        // Get current values
        final userData = userSnap.data() ?? {};
        final statsData = statsSnap.data() ?? {};

        final double currentAccumulatedStars =
        ((userData['accumulated_stars'] ?? 0.0) as num).toDouble();
        final int currentTotalRatings =
        ((userData['total_ratings'] ?? 0) as num).toInt();

        final int oldReviewCount =
        ((statsData['reviewsCount'] ?? 0) as num).toInt();
        final double oldAvgRating =
        ((statsData['avgRating'] ?? 0.0) as num).toDouble();
        final double oldTotalRatingPoints =
        ((statsData['totalRatingPoints'] ?? 0.0) as num).toDouble();

        // Calculate new values
        final int newReviewCount = oldReviewCount + 1;
        final double newTotalRatingPoints = oldTotalRatingPoints + _rating;
        final double newAvgRating = newTotalRatingPoints / newReviewCount;

        // ✅ WRITE PHASE - All writes after all reads

        // Update users collection
        tx.set(
          userRef,
          {
            'accumulated_stars': currentAccumulatedStars + _rating,
            'total_ratings': currentTotalRatings + 1,
            'last_rating_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // Update user_stats collection
        tx.set(
          statsRef,
          {
            'reviewsCount': newReviewCount,
            'avgRating': double.parse(newAvgRating.toStringAsFixed(2)),
            'totalRatingPoints': newTotalRatingPoints,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      // ✅ 5. Send notification to worker (outside transaction)
      await NotificationService.sendNotification(
        toUserId: widget.workerId,
        fromUserId: myUid,
        title: "New Review Received! ⭐",
        body: "You received a ${_rating.toStringAsFixed(1)} star review!",
        type: "review",
      );

      // ✅ 6. Reward Reviewer with XP
      int xpReward = (_rating * 10).toInt(); // 5 star = 50 XP
      await BadgeService.addXP(xpReward);

      // ✅ 7. Update Reviewer's Achievements (non-blocking)
      _updateAchievements();

      debugPrint("✅ Review submitted successfully");
      debugPrint("✅ Worker's stars: +$_rating");
      debugPrint("✅ Reviewer's XP: +$xpReward");

      if (!mounted) return;
      _showSnack("✅ Review submitted! You earned $xpReward XP!", Colors.green);

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("❌ Review submission error: $e");
      if (mounted) {
        _showSnack("Failed to submit review. Please try again.", Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ✅ Non-blocking achievement update
  Future<void> _updateAchievements() async {
    try {
      await Future.wait([
        AchievementService.incrementProgress('daily_give_review'),
        AchievementService.incrementProgress('weekly_give_reviews'),
        AchievementService.incrementProgress('lt_reviews_s1'),
        AchievementService.incrementProgress('lt_reviews_s2'),
        AchievementService.incrementProgress('lt_reviews_s3'),
        AchievementService.syncWeeklyChestFromServer(),
      ]);
    } catch (e) {
      debugPrint('⚠️ Achievement update error: $e');
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ BUILD UI
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final hintColor = isDark ? Colors.grey : Colors.grey.shade600;

    return FloatingScaffold(
      title: "SUBMIT REVIEW",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      bodyPadding: EdgeInsets.zero,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(isDark, cardColor, textColor),
                  const SizedBox(height: 25),
                  _buildStarPicker(isDark, cardColor, textColor),
                  const SizedBox(height: 25),
                  _buildTagSelection(isDark, textColor),
                  const SizedBox(height: 25),
                  _buildCommentInput(isDark, cardColor, textColor, hintColor),
                  const SizedBox(height: 20),
                  _buildHireAgainSwitch(isDark, cardColor, textColor),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(widget.imageUrl),
            backgroundColor: Colors.grey.shade200,
            onBackgroundImageError: (_, __) {},
            child: widget.imageUrl.isEmpty
                ? Icon(Icons.person, size: 30, color: Colors.grey.shade400)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.workerName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.role.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.brandMain,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarPicker(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Text(
            _ratingLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
                  (i) => IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _rating = i + 1.0);
                },
                icon: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 40,
                  color: i < _rating ? Colors.amber : Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSelection(bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Feedback",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _tags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return ChoiceChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (v) {
                HapticFeedback.selectionClick();
                setState(() {
                  v ? _selectedTags.add(tag) : _selectedTags.remove(tag);
                });
              },
              selectedColor: AppColors.brandMain,
              backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : textColor,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.brandMain
                      : (isDark ? Colors.white24 : Colors.grey.shade300),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentInput(
      bool isDark,
      Color cardColor,
      Color textColor,
      Color hintColor,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Write a Comment (Optional)",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _commentController,
          maxLines: 4,
          maxLength: 300,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: "Tell others about your experience...",
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(
                color: AppColors.brandMain,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHireAgainSwitch(bool isDark, Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: SwitchListTile(
        value: _wouldHireAgain,
        onChanged: (v) => setState(() => _wouldHireAgain = v),
        title: Text(
          "Would hire again?",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        activeColor: AppColors.brandMain,
        inactiveThumbColor: isDark ? Colors.grey : Colors.white,
        inactiveTrackColor:
        isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.transparent,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _submitReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandDark,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 5,
          disabledBackgroundColor: Colors.grey,
        ),
        child: _isSaving
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text(
          "SUBMIT REVIEW",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}