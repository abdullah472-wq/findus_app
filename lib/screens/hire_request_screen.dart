// lib/screens/hire_request_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/tabs/chat_screen.dart';
import 'package:findus_app/services/firestore_chat_service.dart';
import 'package:findus_app/services/notification_service.dart'; // optional push
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please describe your problem briefly")),
      );
      return;
    }

    final finderId = widget.worker.uid.trim(); // receiver
    if (finderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Worker user ID missing")),
      );
      return;
    }

    final supporter = FirebaseAuth.instance.currentUser;
    if (supporter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login again")),
      );
      return;
    }

    if (supporter.uid == finderId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot send request to yourself")),
      );
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

      // Optional: Push/FCM (যদি আপনার NotificationService push পাঠায়)
      // Firestore notification already created above, তাই এটা fail হলেও request success থাকবে।
      try {
        await NotificationService.sendNotificationToUser(
          toUserId: finderId,
          title: "New hire request",
          body: "You have a new ${_selectedWorkType.toLowerCase()} hire request.",
          type: "hire_request",
          status: "pending",
          data: {
            'requestId': requestId,
            'workType': _selectedWorkType,
            'offerPrice': _offerPrice.toInt(),
          },
        );
      } catch (_) {}

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccessBottomSheet(requestId: requestId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send request.\n$e")),
      );
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

    // ✅ supporter profile data (denormalize)
    final userSnap = await db.collection('users').doc(supporterId).get();
    final u = userSnap.data() ?? <String, dynamic>{};

    final supporterName =
    (u['name'] ?? u['fullName'] ?? u['displayName'] ?? 'User').toString();
    final supporterImage =
    (u['imageUrl'] ?? u['photoUrl'] ?? u['image'] ?? '').toString();
    final supporterRole =
    (u['userRole'] ?? u['role'] ?? 'supporter').toString();
    final supporterRating = (u['rating'] is num) ? (u['rating'] as num).toDouble() : 0.0;

    // ✅ 1) hire_requests create
    final reqRef = db.collection('hire_requests').doc(); // auto id
    await reqRef.set({
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

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ✅ 2) notifications create (rules অনুযায়ী fromUserId must be auth.uid)
    await db.collection('notifications').add({
      'toUserId': finderId,
      'fromUserId': supporterId,
      'type': 'hire_request',
      'title': 'New hire request',
      'body': 'WorkType: $workType, Offer: ৳${offerPrice.toInt()}',
      'requestId': reqRef.id,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return reqRef.id;
  }

  void _showSuccessBottomSheet({required String requestId}) {
    final rootNav = Navigator.of(context, rootNavigator: true);
    final worker = widget.worker; // capture before pops
    final otherUid = worker.uid.trim();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 80),
            ),
            const SizedBox(height: 20),
            const Text(
              "Request Sent!",
              style: TextStyle(
                fontSize: 24,
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
            const SizedBox(height: 10),
            Text(
              "Request ID: $requestId",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    // close sheet first
                    Navigator.pop(sheetCtx);

                    if (otherUid.isEmpty) return;

                    final cid = await FirestoreChatService.getOrCreateConversation(
                      otherUserId: otherUid,
                    );

                    // close HireRequestScreen (optional)
                    if (rootNav.canPop()) rootNav.pop();

                    // push chat from root navigator
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text(
                    "Go to Chat",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImg = widget.worker.image.trim().isNotEmpty;

    return FloatingScaffold(
      title: "Hire Details",
      backgroundColor: AppColors.brandLight,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      scrollable: false, // ✅ avoid double scroll
      bodyPadding: EdgeInsets.zero,
      body: Container(
        color: AppColors.brandLight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Worker info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: hasImg
                        ? Image.network(
                      widget.worker.image,
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackAvatar(),
                    )
                        : _fallbackAvatar(),
                  ),
                  title: Text(
                    "Hiring ${widget.worker.name}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandDark,
                    ),
                  ),
                  subtitle: Text(
                    widget.worker.userRole,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ),

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
              const SizedBox(height: 5),

              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.brandMain,
                  inactiveTrackColor: AppColors.brandLight,
                  thumbColor: AppColors.brandDark,
                  overlayColor: AppColors.brandMain.withOpacity(0.2),
                ),
                child: Slider(
                  value: _offerPrice,
                  min: 50,
                  max: 2000,
                  divisions: 39, // step ~50
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
                      ? const CircularProgressIndicator(color: Colors.white)
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      height: 60,
      width: 60,
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, color: Colors.grey, size: 32),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _selectedWorkType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedWorkType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandMain : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.brandMain : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}