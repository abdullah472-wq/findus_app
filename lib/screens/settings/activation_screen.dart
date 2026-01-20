// lib/screens/settings/activation_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';

class ActivationScreen extends StatefulWidget {
  final String planId;
  final int amount;
  final String trxId; // TrxID যা ইউজার ইনপুট দিয়েছে

  const ActivationScreen({
    super.key,
    required this.planId,
    required this.amount,
    required this.trxId,
  });

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  int _countdown = 5;
  Timer? _timer;
  bool _hasRedirected = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) setState(() => _countdown--);
      } else {
        timer.cancel();
        _goToProfile();
      }
    });
  }

  void _goToProfile() {
    if (_hasRedirected) return;
    _hasRedirected = true;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => UnifiedProfileScreen(uid: _uid, isOwner: true)),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FloatingScaffold(
      title: "VERIFICATION",
      showBack: true,
      backgroundColor: AppColors.brandLight,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        // ✅ রিয়েল-টাইম চেক: আপনি যখনই Firestore-এ স্ট্যাটাস 'active' করবেন, UI সাথে সাথে বদলে যাবে।
        stream: FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error checking status"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final userData = snapshot.data!.data() ?? {};
          final bool isApproved = userData['subStatus'] == 'active';

          // যদি অ্যাপ্রুভ হয়ে যায়, লোকাল প্রিফারেন্স আপডেট করুন
          if (isApproved) {
            _updateLocalPrefs(userData['subscription'] ?? 'free');
            _startCountdown();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildStatusIcon(isApproved),
                const SizedBox(height: 30),
                _buildStatusText(isApproved, isDark),
                const SizedBox(height: 32),
                _buildInfoCard(isApproved, isDark),
                const SizedBox(height: 40),
                if (isApproved) _buildSuccessAction() else _buildPendingAction(),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateLocalPrefs(String plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_plan', plan);
    await prefs.setBool('has_active_subscription', true);
  }

  Widget _buildStatusIcon(bool isApproved) {
    return Center(
      child: isApproved
          ? Lottie.network(
        'https://assets10.lottiefiles.com/packages/lf20_pqnfmone.json',
        width: 150, height: 150, repeat: false,
      )
          : const Icon(Icons.history_toggle_off_rounded, size: 100, color: Colors.orange),
    );
  }

  Widget _buildStatusText(bool isApproved, bool isDark) {
    return Column(
      children: [
        Text(
          isApproved ? "Verification Success!" : "Verification Pending",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isApproved ? Colors.green : Colors.orange),
        ),
        const SizedBox(height: 12),
        Text(
          isApproved
              ? "Your TrxID has been matched. Welcome to Premium!"
              : "আমরা আপনার দেওয়া TrxID মিলিয়ে দেখছি। সাধারণত ৩০-৬০ মিনিট সময় লাগতে পারে।",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildInfoCard(bool isApproved, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isApproved ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          _row("Selected Plan", widget.planId.toUpperCase()),
          _row("Amount to Pay", "৳${widget.amount}"),
          _row("Submitted TrxID", widget.trxId),
          const Divider(height: 30),
          _row("Verification Status", isApproved ? "APPROVED ✅" : "WAITING ⏳"),
        ],
      ),
    );
  }

  Widget _row(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPendingAction() {
    return Column(
      children: [
        const CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
        const SizedBox(height: 20),
        const Text("Don't worry, you can close this app.\nWe will notify you once approved.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          child: const Text("CLOSE & WAIT"),
        ),
      ],
    );
  }

  Widget _buildSuccessAction() {
    return Column(
      children: [
        Text("Redirecting in $_countdown seconds...", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: _goToProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandDark,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: const Text("GO TO PREMIUM PROFILE", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}