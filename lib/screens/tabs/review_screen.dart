// lib/screens/tabs/review_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/review_service.dart';
import 'package:findus_app/services/notification_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

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

  final List<String> _tags = ["On time", "Polite", "Skilled", "Clean work", "Value for money", "Not satisfied"];
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

  Future<void> _submitReview() async {
    if (_rating == 0) {
      _showSnack("Please select a star rating", Colors.orange);
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final baseComment = _commentController.text.trim();
      String fullComment = baseComment;
      if (_selectedTags.isNotEmpty) {
        fullComment += "\n\nFeedback: ${_selectedTags.join(', ')}";
      }

      await ReviewService.addReview(
        targetUserId: widget.workerId,
        postId: widget.postId,
        rating: _rating,
        comment: fullComment,
        targetRole: 'worker',
        fromRole: 'supporter',
        isAnonymous: false,
      );

      final myUid = FirebaseAuth.instance.currentUser?.uid;
      await NotificationService.sendNotification(
        toUserId: widget.workerId,
        fromUserId: myUid ?? 'system',
        title: "New Review Received! ⭐",
        body: "You received a ${_rating.toStringAsFixed(1)} star review for your work.",
        type: "review",
      );

      if (!mounted) return;
      _showSnack("Review submitted successfully!", Colors.green);
      Navigator.pop(context);
    } catch (e) {
      _showSnack("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ডার্ক মোড ভেরিয়েবলস
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(widget.imageUrl),
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.workerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                Text(widget.role.toUpperCase(), style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
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
      ),
      child: Column(
        children: [
          Text(_ratingLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _rating = i + 1.0);
              },
              icon: Icon(
                i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 40, color: i < _rating ? Colors.amber : Colors.grey.shade300,
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSelection(bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick Feedback", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: _tags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return ChoiceChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (v) {
                HapticFeedback.selectionClick();
                setState(() => v ? _selectedTags.add(tag) : _selectedTags.remove(tag));
              },
              selectedColor: AppColors.brandMain,
              backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              labelStyle: TextStyle(color: isSelected ? Colors.white : textColor, fontSize: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentInput(bool isDark, Color cardColor, Color textColor, Color hintColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Write a Comment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
        const SizedBox(height: 10),
        TextField(
          controller: _commentController,
          maxLines: 4,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: "Tell others about your experience...",
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
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
      ),
      child: SwitchListTile(
        value: _wouldHireAgain,
        onChanged: (v) => setState(() => _wouldHireAgain = v),
        title: Text("Would hire again?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
        activeThumbColor: AppColors.brandMain,
        inactiveThumbColor: isDark ? Colors.grey : Colors.white,
        inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 5,
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("SUBMIT REVIEW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}