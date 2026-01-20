// screens/settings/activation_screen.dart
import 'dart:async'; // ✅ Timer এর জন্য
import 'dart:convert'; // ✅ jsonEncode এর জন্য
import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivationScreen extends StatefulWidget {
  final String planId;
  final int amount;
  final int duration;
  final String paymentMethod;
  final String? transactionId;

  const ActivationScreen({
    super.key,
    required this.planId,
    required this.amount,
    required this.duration,
    required this.paymentMethod,
    this.transactionId,
  });

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  bool _isActivated = false;
  int _countdown = 5;
  Timer? _timer;
  bool _hasRedirected = false;

  @override
  void initState() {
    super.initState();
    _activateSubscription();
    _startCountdown();
    _saveSubscriptionToPrefs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _saveSubscriptionToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final subscriptionKey = 'subscription_${user.uid}';

        final subscriptionData = {
          'planId': widget.planId,
          'amount': widget.amount,
          'duration': widget.duration,
          'paymentMethod': widget.paymentMethod,
          'activatedAt': DateTime.now().toIso8601String(),
          'expiresAt': DateTime.now()
              .add(Duration(days: widget.duration * 30))
              .toIso8601String(),
          'transactionId': widget.transactionId ?? '',
          'status': 'active',
        };

        await prefs.setString(subscriptionKey, jsonEncode(subscriptionData));

        // Also save in user-specific key
        await prefs.setBool('${user.uid}_has_subscription', true);
        await prefs.setString('${user.uid}_current_plan', widget.planId);
      }
    } catch (e) {
      print('Error saving subscription to prefs: $e');
    }
  }

  void _activateSubscription() async {
    // Simulate activation delay
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isActivated = true;
    });

    // Send activation notification
    _sendActivationNotification();
  }

  void _sendActivationNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // You can call your notification service here
      // Example:
      // await NotificationService.sendNotificationToUser(
      //   toUserId: user.uid, // ✅ user.uid ব্যবহার করুন
      //   title: 'Subscription Activated!',
      //   body: 'Your ${widget.planId} plan is now active for ${widget.duration} months.',
      //   type: 'subscription',
      //   status: 'activated',
      // );
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _goToDashboard();
      }
    });
  }

  void _goToDashboard() {
    if (_hasRedirected) return;
    _hasRedirected = true;

    // Navigate to profile screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(), // তোমার ProfileScreen widget
      ),
          (route) => false,
    );
  }

  String _getPlanName(String planId) {
    if (planId.contains('PRO')) return 'FINDUS Pro';
    if (planId.contains('BUSINESS')) return 'Business Plan';
    if (planId.contains('FREE')) return 'Free Plan';
    return 'Premium Plan';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button (optional)
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.close, color: AppColors.brandDark),
                  onPressed: _goToDashboard,
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success Animation
                      _buildSuccessAnimation(),
                      const SizedBox(height: 32),

                      // Activation Status
                      _buildActivationStatus(),
                      const SizedBox(height: 24),

                      // Subscription Details
                      _buildSubscriptionDetails(),
                      const SizedBox(height: 32),

                      // Features Unlocked
                      _buildFeaturesUnlocked(),
                      const SizedBox(height: 32),

                      // Next Steps
                      _buildNextSteps(),
                    ],
                  ),
                ),
              ),

              // Countdown and Action Buttons
              _buildActionSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.brandMain.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!_isActivated)
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.brandMain,
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 40,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivationStatus() {
    return Column(
      children: [
        Text(
          _isActivated ? "Subscription Activated!" : "Activating Subscription...",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.brandDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _isActivated
              ? "🎉 Welcome to FINDUS Premium!"
              : "Please wait while we activate your subscription...",
          style: TextStyle(
            fontSize: 16,
            color: AppColors.brandDark.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubscriptionDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.brandMain),
              SizedBox(width: 8),
              Text(
                "Subscription Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.brandDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow("Plan", _getPlanName(widget.planId)),
          _buildDetailRow("Plan ID", widget.planId),
          _buildDetailRow("Duration", "${widget.duration} months"),
          _buildDetailRow("Amount Paid", "৳${widget.amount}"),
          _buildDetailRow("Payment Method", widget.paymentMethod),
          if (widget.transactionId != null)
            _buildDetailRow("Transaction ID", widget.transactionId!),
          _buildDetailRow("Activation Date", "${DateTime.now().toString().split(' ')[0]}"),
          _buildDetailRow(
            "Valid Until",
            "${DateTime.now().add(Duration(days: widget.duration * 30)).toString().split(' ')[0]}",
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.brandDark,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesUnlocked() {
    List<String> features = [];

    if (widget.planId.contains('PRO')) {
      features = [
        "✓ Higher ranking in search results",
        "✓ Unlimited job posts",
        "✓ Advanced analytics dashboard",
        "✓ Pro badge on profile",
        "✓ Priority email & chat support",
        "✓ Early access to new features",
      ];
    } else if (widget.planId.contains('BUSINESS')) {
      features = [
        "✓ Manage up to 10 team members",
        "✓ Team performance dashboard",
        "✓ Bulk job posting tools",
        "✓ Custom reporting & analytics",
        "✓ Dedicated account manager",
        "✓ 24/7 priority phone support",
      ];
    }

    if (features.isEmpty) return SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandMain.withOpacity(0.1),
            AppColors.brandLight.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandMain.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🎁 Features Unlocked",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.brandMain,
            ),
          ),
          const SizedBox(height: 12),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              feature,
              style: TextStyle(
                color: AppColors.brandDark.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNextSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "🚀 Next Steps",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.brandDark,
          ),
        ),
        const SizedBox(height: 12),
        _buildNextStepItem(
          "1",
          "Complete Your Profile",
          "Add photos, skills, and portfolio to attract more clients",
        ),
        _buildNextStepItem(
          "2",
          "Create Job Posts",
          "Post your services and start getting bookings",
        ),
        _buildNextStepItem(
          "3",
          "Explore Analytics",
          "Track your performance and earnings in dashboard",
        ),
        _buildNextStepItem(
          "4",
          "Invite Friends",
          "Earn rewards for inviting other professionals",
        ),
      ],
    );
  }

  Widget _buildNextStepItem(String number, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.brandMain.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandMain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Column(
      children: [
        if (_isActivated)
          Column(
            children: [
              Text(
                "Going to Dashboard in $_countdown...",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: (5 - _countdown) / 5,
                  backgroundColor: Colors.grey[200],
                  color: AppColors.brandMain,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _goToDashboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              "Go to Profile",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        TextButton(
          onPressed: () {
            // View subscription details
          },
          child: Text(
            "View Subscription Details",
            style: TextStyle(
              color: AppColors.brandMain,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}