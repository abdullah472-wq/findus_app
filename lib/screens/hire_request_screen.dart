// lib/screens/hire_request_screen.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/services/notification_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class HireRequestScreen extends StatefulWidget {
  final Worker worker; // finder (receiver)

  const HireRequestScreen({super.key, required this.worker});

  @override
  State<HireRequestScreen> createState() => _HireRequestScreenState();
}

class _HireRequestScreenState extends State<HireRequestScreen> {
  String _selectedWorkType = 'Urgent';
  double _offerPrice = 100.0;
  final TextEditingController _detailsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final details = _detailsController.text.trim();
    if (details.isEmpty) {
      _showSnackbar("Please describe your problem briefly", isError: true);
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
      final requestId = await _createHireRequestAndNotification(
        supporterId: supporter.uid,
        finderId: finderId,
        workType: _selectedWorkType,
        offerPrice: _offerPrice,
        details: details,
      );

      // ✅ Notification with correct parameters
      try {
        await NotificationService.sendNotificationToUser(
          toUserId: finderId,
          title: "New hire request",
          body: "You have a new ${_selectedWorkType.toLowerCase()} hire request.",
          type: "hire_request",
          relatedPostId: requestId, // Linking request ID
          data: {
            'requestId': requestId,
            'workType': _selectedWorkType,
            'offerPrice': _offerPrice.toInt(),
            'status': "pending", // ✅ Moved status inside data map
          },
        );
      } catch (e) {
        debugPrint("Push notification failed: $e");
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccessBottomSheet(requestId: requestId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackbar("Failed to send request.\n$e", isError: true);
    }
  }

  Future<String> _createHireRequestAndNotification({
    required String supporterId,
    required String finderId,
    required String workType,
    required double offerPrice,
    required String details,
  }) async {
    final db = FirebaseFirestore.instance;

    // Fetch supporter profile data
    final userSnap = await db.collection('users').doc(supporterId).get();
    final u = userSnap.data() ?? <String, dynamic>{};

    final supporterName = (u['name'] ?? u['fullName'] ?? 'User').toString();
    final supporterImage = (u['imageUrl'] ?? u['image'] ?? '').toString();
    final supporterRole = (u['userRole'] ?? 'supporter').toString();
    final supporterRating = (u['rating'] is num) ? (u['rating'] as num).toDouble() : 0.0;

    // 🔥 NEW: ৪ সংখ্যার OTP জেনারেট করা
    String generateOTP() {
      return (1000 + Random().nextInt(9000)).toString();
    }
    final String secretOtp = generateOTP();

    // 1) Create Hire Request
    final reqRef = db.collection('hire_requests').doc();
    await reqRef.set({
      'requestId': reqRef.id,
      'senderId': supporterId,
      'senderName': supporterName,
      'senderRole': supporterRole,
      'senderImage': supporterImage,
      'rating': supporterRating,
      'receiverId': finderId,
      'status': 'pending',
      'workType': workType,
      'offerPrice': offerPrice.toInt(),
      'details': details,

      // 🔥 NEW: ভেরিফিকেশন ডাটা সেভ করা হচ্ছে
      'secret_otp': secretOtp,       // এই কোডটি শুধু Hirer দেখবে
      'verification_type': 'otp',    // ভেরিফিকেশন টাইপ সেট করা হলো
      'is_verified': false,          // ডিফল্ট হিসেবে ভেরিফাইড না

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2) Create In-App Notification
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

    return reqRef.id;
  }

  void _showSuccessBottomSheet({required String requestId}) {
    final rootNav = Navigator.of(context, rootNavigator: true);
    final worker = widget.worker;
    final otherUid = worker.uid.trim();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 20),
            const Text(
              "Request Sent!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Your request has been sent to ${worker.name}.\nPlease wait for approval.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Go to Chat",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
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
      scrollable: false, // Prevent double scroll
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

              const Text(
                "Describe the issue",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brandDark),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _detailsController,
                maxLines: 4,
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

              const Text(
                "When do you need it?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brandDark),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brandDark),
                  ),
                  Text(
                    "৳ ${_offerPrice.toInt()}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.brandMain),
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
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Send Request", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
              placeholder: (context, url) => Container(color: Colors.grey[200]),
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
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
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
                ? [BoxShadow(color: AppColors.brandMain.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
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