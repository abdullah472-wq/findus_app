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

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ MAIN APPLICATION SUBMISSION
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _sendApplication() async {
    final details = _detailsController.text.trim();
    if (details.isEmpty) {
      _snack("Please describe your offer briefly", isError: true);
      return;
    }

    if (details.length < 10) {
      _snack("Please provide more details (minimum 10 characters)", isError: true);
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

      // ════════════════════════════════════════════════════════════════════════
      // ✅ 1. CHECK FOR DUPLICATE APPLICATION
      // ════════════════════════════════════════════════════════════════════════
      final existingApp = await db
          .collection('hire_requests')
          .where('senderId', isEqualTo: me.uid)
          .where('postId', isEqualTo: widget.postId)
          .where('status', whereIn: ['pending', 'approved'])
          .limit(1)
          .get();

      if (existingApp.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _snack("You've already applied to this post!", isError: true);
        return;
      }

      // ════════════════════════════════════════════════════════════════════════
      // ✅ 2. LOAD POST DATA (with offline support)
      // ════════════════════════════════════════════════════════════════════════
      final postSnap = await db
          .collection('posts')
          .doc(widget.postId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (!postSnap.exists) {
        throw Exception("Post not found");
      }

      final post = postSnap.data() ?? {};

      final String ownerId = (post['ownerId'] ?? '').toString().trim();
      if (ownerId.isEmpty) throw Exception("Post owner missing");
      if (ownerId == me.uid) {
        throw Exception("You cannot apply to your own post");
      }

      // ✅ Safe type conversion for slots
      final int slots = _toInt(post['slots'], defaultValue: 1);
      final int approvedCount = _toInt(post['approvedCount'], defaultValue: 0);

      // ✅ Check if slots are full
      if (approvedCount >= slots) {
        throw Exception("All slots are filled for this post");
      }

      // ════════════════════════════════════════════════════════════════════════
      // ✅ 3. LOAD APPLICANT PROFILE (with offline support)
      // ════════════════════════════════════════════════════════════════════════
      final userSnap = await db
          .collection('users')
          .doc(me.uid)
          .get(const GetOptions(source: Source.serverAndCache));

      final u = userSnap.data() ?? {};

      final applicantName = _toString(
        u['name'] ?? u['fullName'] ?? u['displayName'],
        defaultValue: 'User',
      );

      // ✅ Get profile image (priority: profileImage > image > imageUrl)
      final applicantImage = _toString(
        u['profileImage'] ?? u['image'] ?? u['imageUrl'] ?? u['photoUrl'],
        defaultValue: '',
      );

      final applicantRole = _toString(
        u['userRole'],
        defaultValue: 'finder',
      );

      final applicantRating = _toDouble(u['rating'], defaultValue: 0.0);

      // ════════════════════════════════════════════════════════════════════════
      // ✅ 4. LOAD OWNER PROFILE (with offline support)
      // ════════════════════════════════════════════════════════════════════════
      final ownerSnap = await db
          .collection('users')
          .doc(ownerId)
          .get(const GetOptions(source: Source.serverAndCache));

      final owner = ownerSnap.data() ?? {};

      final ownerName = _toString(
        owner['name'] ?? owner['fullName'] ?? owner['displayName'],
        defaultValue: 'Owner',
      );

      // ✅ Get owner profile image
      final ownerImage = _toString(
        owner['profileImage'] ?? owner['image'] ?? owner['imageUrl'],
        defaultValue: '',
      );

      final ownerRole = _toString(
        owner['userRole'],
        defaultValue: 'supporter',
      );

      // ════════════════════════════════════════════════════════════════════════
      // ✅ 5. GENERATE OTP
      // ════════════════════════════════════════════════════════════════════════
      final otp = _generateOtp();

      // ════════════════════════════════════════════════════════════════════════
      // ✅ 6. CREATE APPLICATION DOCUMENT
      // ════════════════════════════════════════════════════════════════════════
      final reqRef = db.collection('hire_requests').doc();

      await reqRef.set({
        'requestId': reqRef.id,

        // ✅ Applicant (Sender - Finder/Worker)
        'senderId': me.uid,
        'senderName': applicantName,
        'senderRole': applicantRole,
        'senderImage': applicantImage,
        'senderRating': applicantRating,

        // ✅ Owner (Receiver - Supporter/Employer)
        'receiverId': ownerId,
        'receiverName': ownerName,
        'receiverImage': ownerImage,
        'receiverRole': ownerRole,

        // ✅ Post context
        'postId': widget.postId,
        'postTitle': _toString(post['title'], defaultValue: 'Job'),
        'postAddress': _toString(post['address'], defaultValue: ''),
        'postLocation': _toString(post['address'], defaultValue: ''),
        'postPriceLabel': _toString(post['priceLabel'], defaultValue: ''),
        'postSlots': slots,

        // ✅ Application info
        'status': 'pending',
        'workType': _selectedWorkType,
        'offerPrice': _offerPrice.toInt(),
        'price': _offerPrice.toInt(),
        'details': details,
        'jobTitle': _toString(post['title'], defaultValue: 'Job'),
        'location': _toString(post['address'], defaultValue: ''),

        // ✅ Verification
        'secret_otp': otp,
        'verification_type': 'otp',
        'is_verified': false,

        // ✅ Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ════════════════════════════════════════════════════════════════════════
      // ✅ 7. SEND NOTIFICATION TO POST OWNER (non-blocking)
      // ════════════════════════════════════════════════════════════════════════
      _sendNotifications(
        ownerId: ownerId,
        applicantName: applicantName,
        postTitle: post['title']?.toString() ?? 'Job',
        requestId: reqRef.id,
      );

      // ════════════════════════════════════════════════════════════════════════
      // ✅ 8. UPDATE ACHIEVEMENTS (non-blocking)
      // ════════════════════════════════════════════════════════════════════════
      _updateAchievements();

      if (!mounted) return;
      setState(() => _isLoading = false);

      // ════════════════════════════════════════════════════════════════════════
      // ✅ 9. SHOW SUCCESS SHEET WITH OTP
      // ════════════════════════════════════════════════════════════════════════
      _showSuccessSheet(otp);
    } catch (e) {
      debugPrint('❌ Application error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ SAFE TYPE CONVERSION HELPERS
  // ════════════════════════════════════════════════════════════════════════════
  int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? defaultValue;
  }

  double _toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? defaultValue;
  }

  String _toString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    final str = value.toString().trim();
    if (str.isEmpty || str == 'null') return defaultValue;
    return str;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ NON-BLOCKING NOTIFICATION SENDER
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _sendNotifications({
    required String ownerId,
    required String applicantName,
    required String postTitle,
    required String requestId,
  }) async {
    try {
      // Push notification
      await NotificationService.sendNotificationToUser(
        toUserId: ownerId,
        title: "New Application 🎉",
        body: "$applicantName applied to your job post",
        type: "application",
        relatedPostId: widget.postId,
        data: {
          'requestId': requestId,
          'applicantName': applicantName,
        },
      );

      // In-app notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUserId': ownerId,
        'fromUserId': FirebaseAuth.instance.currentUser?.uid,
        'type': 'job_application',
        'title': 'New Application',
        'body': '$applicantName applied to "$postTitle"',
        'relatedPostId': widget.postId,
        'requestId': requestId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Notification error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ NON-BLOCKING ACHIEVEMENT UPDATER
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _updateAchievements() async {
    try {
      await Future.wait([
        AchievementService.incrementProgress('daily_apply_job'),
        AchievementService.incrementProgress('weekly_apply_jobs'),
        AchievementService.incrementProgress('lt_apply_s1'),
        AchievementService.syncWeeklyChestFromServer(),
      ]);
    } catch (e) {
      debugPrint('⚠️ Achievement error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ SUCCESS BOTTOM SHEET WITH OTP
  // ════════════════════════════════════════════════════════════════════════════
  void _showSuccessSheet(String otp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
        final textColor = isDark ? Colors.white : AppColors.brandDark;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Success Icon
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

              // ✅ Title
              Text(
                "Applied Successfully!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 10),

              // ✅ Message
              Text(
                "Your application is pending approval.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey,
                  fontSize: 14,
                ),
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
                        Text(
                          "Your Verification Code",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ✅ OTP Code
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
                                content: Text('OTP copied to clipboard ✓'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
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

                    Text(
                      "Share this code with the employer when you arrive",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ✅ Done Button
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

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ UI HELPERS
  // ════════════════════════════════════════════════════════════════════════════
  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
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
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return FloatingScaffold(
      title: "Apply Details",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Description Section
            Text(
              "Describe your offer",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              maxLength: 500,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Ex: I can do this job tomorrow, have 3 years experience...",
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: AppColors.brandMain,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Work Type Section
            Text(
              "When can you do it?",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _chip("Urgent (Now)", "Urgent", isDark, cardColor, textColor),
                const SizedBox(width: 12),
                _chip("Schedule Later", "Scheduled", isDark, cardColor, textColor),
              ],
            ),

            const SizedBox(height: 20),

            // ✅ Price Slider Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Your Offer Price",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
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
                inactiveTrackColor: isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
                thumbColor: AppColors.brandDark,
                overlayColor: AppColors.brandMain.withOpacity(0.2),
                trackHeight: 6.0,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 10.0,
                ),
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

            // ✅ Submit Button
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
                  disabledBackgroundColor: Colors.grey,
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

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ CHIP WIDGET (Work Type Selection)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _chip(
      String label,
      String value,
      bool isDark,
      Color cardColor,
      Color textColor,
      ) {
    final isSelected = _selectedWorkType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedWorkType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandMain : cardColor,
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