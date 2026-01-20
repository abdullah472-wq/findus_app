import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/review_service.dart';
import 'package:findus_app/services/notification_service.dart'; // Notification service import

class ReviewScreen extends StatefulWidget {
  final String workerId;     // যার উপর review দিচ্ছো (UID)
  final String postId;       // কোন job/post এর জন্য
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

  // Quick feedback tags
  final List<String> _tags = [
    "On time",
    "Polite",
    "Skilled",
    "Clean work",
    "Value for money",
    "Not satisfied",
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
    if (_rating >= 4.5) return "Excellent";
    if (_rating >= 3.5) return "Good";
    if (_rating >= 2.5) return "Average";
    if (_rating >= 1.5) return "Poor";
    if (_rating > 0) return "Very Bad";
    return "Tap a star to rate";
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please give a star rating first."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // extra comment এর সাথে tags + hireAgain information জুড়ে দিচ্ছি
      final baseComment = _commentController.text.trim();
      final extraParts = <String>[];

      if (_selectedTags.isNotEmpty) {
        extraParts.add("Tags: ${_selectedTags.join(', ')}");
      }
      extraParts.add(
        "Would hire again: ${_wouldHireAgain ? "Yes" : "No"}",
      );

      final fullComment = [
        baseComment,
        ...extraParts,
      ].where((s) => s.isNotEmpty).join("\n");

      // 🔹 ১) আগে Firestore এ review save
      await ReviewService.addReview(
        targetUserId: widget.workerId,
        postId: widget.postId,
        rating: _rating,
        comment: fullComment,
        targetRole: 'worker',     // এই screen থেকে শুধু worker রিভিউ ধরলাম
        fromRole: 'supporter',    // সাধারণত supporter থেকেই worker কে রিভিউ
        isAnonymous: false,       // future এ চাইলে UI তে checkbox দিয়ে নেবে
      );

      // 🔹 ২) তারপর worker এর জন্য `review` টাইপ notification
      await NotificationService.sendNotificationToUser(
        toUserId: widget.workerId,        // যাকে রিভিউ দেওয়া হয়েছে (worker)
        title: "New review received",
        body: "You received a ${_rating.toStringAsFixed(1)}★ review for a recent job.",
        type: "review",
        relatedPostId: widget.postId,     // কোন কাজের জন্য রিভিউ
        data: {
          'rating': _rating,
          'comment': fullComment,
          'tags': _selectedTags.toList(),
          'wouldHireAgain': _wouldHireAgain,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Review submitted successfully."),
          backgroundColor: AppColors.brandMain,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to submit review: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text(
          "Rate & Review",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.brandLight,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // উপরের অংশ স্ক্রলেবল
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWorkerHeader(),
                    const SizedBox(height: 20),
                    _buildRatingSection(),
                    const SizedBox(height: 20),
                    _buildTagSection(),
                    const SizedBox(height: 20),
                    _buildCommentBox(),
                    const SizedBox(height: 20),
                    _buildHireAgainToggle(),
                  ],
                ),
              ),
            ),

            // নিচে Submit বাটন
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  )
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandMain,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    "SUBMIT REVIEW",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------- UI সেকশনগুলো ---------

  Widget _buildWorkerHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(widget.imageUrl),
            radius: 26,
            onBackgroundImageError: (_, __) => const Icon(Icons.person), // Error handling for image
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.workerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.role.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Rate this completed work",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Text(
            "How was your experience?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
                  (i) => IconButton(
                onPressed: () {
                  setState(() => _rating = i + 1.0);
                },
                icon: Icon(
                  Icons.star,
                  size: 32,
                  color: i < _rating ? Colors.amber : Colors.grey[300],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _ratingLabel,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick feedback (optional)",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.brandDark,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags.map((tag) {
            final bool selected = _selectedTags.contains(tag);
            return ChoiceChip(
              label: Text(
                tag,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? Colors.white : AppColors.brandDark,
                ),
              ),
              selected: selected,
              selectedColor: AppColors.brandMain,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected ? AppColors.brandMain : Colors.grey.shade300,
              ),
              onSelected: (_) => _toggleTag(tag),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Write your review",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.brandDark,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Describe your experience (optional)...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHireAgainToggle() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SwitchListTile(
        value: _wouldHireAgain,
        activeColor: AppColors.brandMain,
        onChanged: (v) => setState(() => _wouldHireAgain = v),
        title: const Text(
          "Would you hire this worker again?",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.brandDark,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          _wouldHireAgain ? "Yes, I would hire again" : "No, I won't hire again",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}