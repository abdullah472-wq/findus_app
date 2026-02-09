import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

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
      _snack("Please describe briefly", isError: true);
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

      // 1) Load post
      final postSnap = await db.collection('posts').doc(widget.postId).get();
      if (!postSnap.exists) {
        throw Exception("Post not found");
      }
      final post = postSnap.data() ?? {};

      final String ownerId = (post['ownerId'] ?? '').toString();
      if (ownerId.isEmpty) throw Exception("Post owner missing");
      if (ownerId == me.uid) throw Exception("You cannot apply to your own post");

      final int slots = (post['slots'] is num) ? (post['slots'] as num).toInt() : 1;

      // 2) Load applicant profile
      final userSnap = await db.collection('users').doc(me.uid).get();
      final u = userSnap.data() ?? {};

      final applicantName = (u['name'] ?? u['fullName'] ?? 'User').toString();
      final applicantImage = (u['imageUrl'] ?? u['image'] ?? '').toString();
      final applicantRole = (u['userRole'] ?? 'maker').toString(); // finder/maker
      final applicantRating = (u['rating'] is num) ? (u['rating'] as num).toDouble() : 0.0;

      final otp = _generateOtp();

      // 3) Create application (hire_requests)
      final reqRef = db.collection('hire_requests').doc();

      await reqRef.set({
        'requestId': reqRef.id,

        // applicant (sender)
        'senderId': me.uid,
        'senderName': applicantName,
        'senderRole': applicantRole,
        'senderImage': applicantImage,
        'senderRating': applicantRating,

        // owner (receiver)
        'receiverId': ownerId,

        // post context
        'postId': widget.postId,
        'postTitle': (post['title'] ?? '').toString(),
        'postAddress': (post['address'] ?? '').toString(),
        'postPriceLabel': (post['priceLabel'] ?? '').toString(),
        'postOwnerRole': (post['ownerRole'] ?? '').toString(), // legacy; optional
        'postSlots': slots,

        // application info
        'status': 'pending',
        'workType': _selectedWorkType,
        'offerPrice': _offerPrice.toInt(),
        'details': details,

        // verification
        'secret_otp': otp,
        'verification_type': 'otp',
        'is_verified': false,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      _showSuccessSheet();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack("Failed: $e", isError: true);
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
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
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 16),
            const Text("Applied Successfully!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              "Your request is pending approval.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
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
    return FloatingScaffold(
      title: "Apply Details",
      backgroundColor: AppColors.brandLight,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Describe your offer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Ex: I can do this job tomorrow, have 3 years experience...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            const Text("When can you do it?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                _chip("Urgent (Now)", "Urgent"),
                const SizedBox(width: 12),
                _chip("Schedule Later", "Scheduled"),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Your Offer Price", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("৳ ${_offerPrice.toInt()}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.brandMain)),
              ],
            ),
            Slider(
              value: _offerPrice,
              min: 50,
              max: 5000,
              divisions: 99,
              onChanged: (v) => setState(() => _offerPrice = v),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text("Send Request", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
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
            border: Border.all(color: isSelected ? AppColors.brandMain : Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}