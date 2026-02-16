// lib/screens/hire_request_screen.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/services/notification_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/achievement/achievement_service.dart'; // ✅ NEW

class HireRequestScreen extends StatefulWidget {
  final Worker worker;

  const HireRequestScreen({super.key, required this.worker});

  @override
  State<HireRequestScreen> createState() => _HireRequestScreenState();
}

class _HireRequestScreenState extends State<HireRequestScreen> {
  String _selectedWorkType = 'Urgent';
  double _offerPrice = 100.0;
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController(); // ✅ NEW
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default price from worker
    _offerPrice = widget.worker.price?.toDouble() ?? 100.0;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final details = _detailsController.text.trim();
    final location = _locationController.text.trim();

    if (details.isEmpty) {
      _showSnackbar("Please describe your problem briefly", isError: true);
      return;
    }

    if (location.isEmpty) {
      _showSnackbar("Please enter work location", isError: true);
      return;
    }

    final finderId = widget.worker.uid.trim();
    if (finderId.isEmpty) {
      _showSnackbar("Worker user ID missing", isError: true);
      return;
    }

    final supporter = FirebaseAuth.instance.currentUser;
    if (supporter == null) {
      _showSnackbar("Please login again", isError: true);
      return;
    }

    if (supporter.uid == finderId) {
      _showSnackbar("You cannot send request to yourself", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Check for duplicate pending request
      final existingRequest = await FirebaseFirestore.instance
          .collection('hire_requests')
          .where('senderId', isEqualTo: supporter.uid)
          .where('receiverId', isEqualTo: finderId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        setState(() => _isLoading = false);
        _showSnackbar(
          "You already have a pending request to ${widget.worker.name}!",
          isError: true,
        );
        return;
      }

      final result = await _createHireRequestAndNotification(
        supporterId: supporter.uid,
        finderId: finderId,
        workType: _selectedWorkType,
        offerPrice: _offerPrice,
        details: details,
        location: location,
      );

      // ✅ Push Notification
      try {
        await NotificationService.sendNotificationToUser(
          toUserId: finderId,
          title: "New hire request",
          body: "You have a new ${_selectedWorkType.toLowerCase()} hire request.",
          type: "hire_request",
          relatedPostId: result.requestId,
          data: {
            'requestId': result.requestId,
            'workType': _selectedWorkType,
            'offerPrice': _offerPrice.toInt(),
            'status': "pending",
          },
        );
      } catch (e) {
        debugPrint("Push notification failed: $e");
      }

      // ✅ Achievement Update
      try {
        await AchievementService.incrementProgress('daily_send_request');
        await AchievementService.incrementProgress('weekly_send_requests');
        await AchievementService.syncWeeklyChestFromServer();
      } catch (e) {
        debugPrint("Achievement update failed: $e");
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      // ✅ Show success with OTP
      _showSuccessBottomSheet(
        requestId: result.requestId,
        otp: result.otp,
      );
    } catch (e) {
      debugPrint('Send request error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackbar("Failed to send request.\n${e.toString()}", isError: true);
    }
  }

  Future<_RequestResult> _createHireRequestAndNotification({
    required String supporterId,
    required String finderId,
    required String workType,
    required double offerPrice,
    required String details,
    required String location,
  }) async {
    final db = FirebaseFirestore.instance;

    // Fetch supporter profile
    final userSnap = await db.collection('users').doc(supporterId).get();
    final u = userSnap.data() ?? <String, dynamic>{};

    final supporterName = (u['name'] ?? u['fullName'] ?? 'User').toString();
    final supporterImage = (u['imageUrl'] ?? u['image'] ?? '').toString();
    final supporterRole = (u['userRole'] ?? 'supporter').toString();
    final supporterRating = (u['rating'] is num)
        ? (u['rating'] as num).toDouble()
        : 0.0;

    // ✅ Generate 4-digit OTP
    final String secretOtp = (1000 + Random().nextInt(9000)).toString();

    // ✅ Create Hire Request
    final reqRef = db.collection('hire_requests').doc();

    await reqRef.set({
      'requestId': reqRef.id,

      // Sender (Supporter/Employer)
      'senderId': supporterId,
      'senderName': supporterName,
      'senderRole': supporterRole,
      'senderImage': supporterImage,
      'senderRating': supporterRating,

      // Receiver (Finder/Worker)
      'receiverId': finderId,
      'receiverName': widget.worker.name,
      'receiverImage': widget.worker.image,
      'receiverRole': widget.worker.userRole,

      // Job Details
      'jobTitle': '${widget.worker.userRole} Work Request',
      'workType': workType,
      'details': details,
      'location': location,
      'offerPrice': offerPrice.toInt(),
      'price': widget.worker.price ?? offerPrice.toInt(),

      // Status
      'status': 'pending',

      // ✅ Verification Data
      'secret_otp': secretOtp,
      'verification_type': 'otp',
      'is_verified': false,

      // Timestamps
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ✅ Create In-App Notification
    await db.collection('notifications').add({
      'toUserId': finderId,
      'fromUserId': supporterId,
      'type': 'hire_request',
      'title': 'New hire request',
      'body': 'WorkType: $workType, Offer: ৳${offerPrice.toInt()}',
      'relatedPostId': reqRef.id,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return _RequestResult(requestId: reqRef.id, otp: secretOtp);
  }

  void _showSuccessBottomSheet({
    required String requestId,
    required String otp,
  }) {
    final rootNav = Navigator.of(context, rootNavigator: true);
    final worker = widget.worker;
    final otherUid = worker.uid.trim();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetCtx) => Container(
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
              "Request Sent!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),

            const SizedBox(height: 10),

            // Message
            Text(
              "Your request has been sent to ${worker.name}.\nPlease wait for approval.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                          ScaffoldMessenger.of(sheetCtx).showSnackBar(
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
                    "Share this code with the worker when they arrive",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx); // Close sheet
                      if (rootNav.canPop()) rootNav.pop(); // Close Request Screen
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Close'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetCtx); // Close sheet

                      if (otherUid.isEmpty) return;

                      final cid = await FirestoreChatService.getOrCreateConversation(
                        otherUserId: otherUid,
                      );

                      if (rootNav.canPop()) rootNav.pop(); // Close Request Screen

                      if (!rootNav.context.mounted) return;
                      rootNav.push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: cid,
                            userName: worker.name,
                            userRole: worker.userRole,
                            userImage: worker.image,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Chat Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandMain,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingScaffold(
      title: "Hire Details",
      backgroundColor: AppColors.brandLight,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: Container(
        color: AppColors.brandLight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Worker Info Card
              _buildWorkerInfoCard(),

              const SizedBox(height: 25),

              // ✅ Location Input
              const Text(
                "Work Location",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: "Ex: House 123, Road 5, Dhanmondi, Dhaka",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Problem Description
              const Text(
                "Describe the issue",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _detailsController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: "Ex: My kitchen tap is leaking, need urgent fix...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // When needed
              const Text(
                "When do you need it?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildChip("Urgent (Now)", "Urgent"),
                  const SizedBox(width: 15),
                  _buildChip("Schedule Later", "Scheduled"),
                ],
              ),

              const SizedBox(height: 25),

              // Price Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Your Offer Price",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandDark,
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
              const SizedBox(height: 10),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.brandMain,
                  inactiveTrackColor: Colors.grey.shade300,
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
                  label: _offerPrice.round().toString(),
                  onChanged: (v) => setState(() => _offerPrice = v),
                ),
              ),
              Center(
                child: Text(
                  "Base Charge starts from ${widget.worker.priceText}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

              const SizedBox(height: 40),

              // Send Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
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
                        "Send Request",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.send_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: widget.worker.image,
              height: 60,
              width: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.person, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hiring ${widget.worker.name}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                Text(
                  widget.worker.userRole.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _selectedWorkType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedWorkType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandMain : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.brandMain : Colors.grey.shade300,
              width: isSelected ? 0 : 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: AppColors.brandMain.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ Helper class for return value
class _RequestResult {
  final String requestId;
  final String otp;

  _RequestResult({
    required this.requestId,
    required this.otp,
  });
}