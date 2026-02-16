import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/services/notification_service.dart';

class ApplyToPostScreen extends StatefulWidget {
  final String postId;

  const ApplyToPostScreen({
    super.key,
    required this.postId,
  });

  @override
  State<ApplyToPostScreen> createState() => _ApplyToPostScreenState();
}

class _ApplyToPostScreenState extends State<ApplyToPostScreen> {
  String _selectedWorkType = 'Urgent';
  double _offerPrice = 100.0;
  final TextEditingController _detailsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  String _generateOtp() => (1000 + Random().nextInt(9000)).toString();

  Future<void> _sendApplication() async {
    final details = _detailsController.text.trim();
    if (details.isEmpty) {
      _snack("Please describe your offer briefly", isError: true);
      return;
    }

    final me = FirebaseAuth.instance.currentUser;
    if (me == null) {
      _snack("Please login again", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = FirebaseFirestore.instance;

      // ✅ 1. Check for duplicate application
      final existingApp = await db
          .collection('hire_requests')
          .where('senderId', isEqualTo: me.uid)
          .where('postId', isEqualTo: widget.postId)
          .where('status', whereIn: ['pending', 'approved'])
          .limit(1)
          .get();

      if (existingApp.docs.isNotEmpty) {
        setState(() => _isLoading = false);
        _snack("You've already applied to this post!", isError: true);
        return;
      }

      // ✅ 2. Load post
      final postSnap = await db.collection('posts').doc(widget.postId).get();
      if (!postSnap.exists) {
        throw Exception("Post not found");
      }
      final post = postSnap.data() ?? {};

      final String ownerId = (post['ownerId'] ?? '').toString();
      if (ownerId.isEmpty) throw Exception("Post owner missing");
      if (ownerId == me.uid) {
        throw Exception("You cannot apply to your own post");
      }

      final int slots = (post['slots'] is num)
          ? (post['slots'] as num).toInt()
          : 1;
      final int approvedCount = (post['approvedCount'] is num)
          ? (post['approvedCount'] as num).toInt()
          : 0;

      // ✅ Check if slots are full
      if (approvedCount >= slots) {
        throw Exception("All slots are filled for this post");
      }

      // ✅ 3. Load applicant profile
      final userSnap = await db.collection('users').doc(me.uid).get();
      final u = userSnap.data() ?? {};

      final applicantName = (u['name'] ?? u['fullName'] ?? 'User').toString();
      final applicantImage = (u['imageUrl'] ?? u['image'] ?? '').toString();
      final applicantRole = (u['userRole'] ?? 'finder').toString();
      final applicantRating = (u['rating'] is num)
          ? (u['rating'] as num).toDouble()
          : 0.0;

      // ✅ 4. Load owner profile
      final ownerSnap = await db.collection('users').doc(ownerId).get();
      final owner = ownerSnap.data() ?? {};

      final ownerName = (owner['name'] ?? 'Owner').toString();
      final ownerImage = (owner['image'] ?? '').toString();
      final ownerRole = (owner['userRole'] ?? 'supporter').toString();

      // ✅ 5. Generate OTP
      final otp = _generateOtp();

      // ✅ 6. Create application
      final reqRef = db.collection('hire_requests').doc();

      await reqRef.set({
        'requestId': reqRef.id,

        // Applicant (Sender - Finder/Worker)
        'senderId': me.uid,
        'senderName': applicantName,
        'senderRole': applicantRole,
        'senderImage': applicantImage,
        'senderRating': applicantRating,

        // Owner (Receiver - Supporter/Employer)
        'receiverId': ownerId,
        'receiverName': ownerName,
        'receiverImage': ownerImage,
        'receiverRole': ownerRole,

        // Post context
        'postId': widget.postId,
        'postTitle': (post['title'] ?? 'Job').toString(),
        'postAddress': (post['address'] ?? '').toString(),
        'postLocation': (post['address'] ?? '').toString(),
        'postPriceLabel': (post['priceLabel'] ?? '').toString(),
        'postSlots': slots,

        // Application info
        'status': 'pending',
        'workType': _selectedWorkType,
        'offerPrice': _offerPrice.toInt(),
        'price': _offerPrice.toInt(),
        'details': details,
        'jobTitle': (post['title'] ?? 'Job').toString(),
        'location': (post['address'] ?? '').toString(),

        // Verification
        'secret_otp': otp,
        'verification_type': 'otp',
        'is_verified': false,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ 7. Send notification to post owner
      try {
        await NotificationService.sendNotificationToUser(
          toUserId: ownerId,
          title: "New Application",
          body: "$applicantName applied to your job post",
          type: "application",
          relatedPostId: widget.postId,
          data: {
            'requestId': reqRef.id,
            'applicantName': applicantName,
          },
        );
      } catch (e) {
        debugPrint('Notification error: $e');
      }

      // ✅ 8. Create in-app notification
      await db.collection('notifications').add({
        'toUserId': ownerId,
        'fromUserId': me.uid,
        'type': 'job_application',
        'title': 'New Application',
        'body': '$applicantName applied to "${post['title'] ?? 'your job'}"',
        'relatedPostId': widget.postId,
        'requestId': reqRef.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ 9. Update achievements
      try {
        await AchievementService.incrementProgress('daily_apply_job');
        await AchievementService.incrementProgress('weekly_apply_jobs');
        await AchievementService.incrementProgress('lt_apply_s1');
        await AchievementService.syncWeeklyChestFromServer();
      } catch (e) {
        debugPrint('Achievement error: $e');
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      // ✅ 10. Show success with OTP
      _showSuccessSheet(otp);
    } catch (e) {
      debugPrint('Application error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  void _showSuccessSheet(String otp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            const Text(
              "Applied Successfully!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.brandDark,
              ),
            ),

            const SizedBox(height: 10),

            // Message
            const Text(
              "Your application is pending approval.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 20),

            // ✅ OTP Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.brandMain.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.brandMain.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: AppColors.brandMain,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Your Verification Code",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // OTP Code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        otp,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandMain,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: otp));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('OTP copied to clipboard'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.copy,
                          color: AppColors.brandMain,
                          size: 20,
                        ),
                        tooltip: 'Copy OTP',
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Share this code with the employer when you arrive",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Done Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close bottom sheet
                  Navigator.pop(context); // Close ApplyToPostScreen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Done",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;

    return FloatingScaffold(
      title: "Apply Details",
      backgroundColor: bgColor,
      titleColor: isDark ? Colors.white : AppColors.brandDark,
      iconColor: isDark ? Colors.white : AppColors.brandDark,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Describe your offer",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              maxLength: 500,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: "Ex: I can do this job tomorrow, have 3 years experience...",
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "When can you do it?",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _chip("Urgent (Now)", "Urgent", isDark),
                const SizedBox(width: 12),
                _chip("Schedule Later", "Scheduled", isDark),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Your Offer Price",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  "৳ ${_offerPrice.toInt()}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.brandMain,
                  ),
                ),
              ],
            ),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.brandMain,
                inactiveTrackColor: Colors.grey.shade300,
                thumbColor: AppColors.brandDark,
                overlayColor: AppColors.brandMain.withOpacity(0.2),
                trackHeight: 6.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
              ),
              child: Slider(
                value: _offerPrice,
                min: 50,
                max: 5000,
                divisions: 99,
                label: _offerPrice.toInt().toString(),
                onChanged: (v) => setState(() => _offerPrice = v),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Send Application",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.send, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value, bool isDark) {
    final isSelected = _selectedWorkType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedWorkType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandMain
                : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandMain
                  : (isDark ? Colors.white24 : Colors.grey.shade300),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.grey[700]),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}