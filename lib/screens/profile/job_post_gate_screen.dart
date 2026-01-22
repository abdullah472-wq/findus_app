// lib/screens/job_post_gate_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
// ✅ UnifiedProfileScreen ইম্পোর্ট করা হয়েছে
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/profile/support_post_screen.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class JobPostGateScreen extends StatefulWidget {
  final Worker worker;

  const JobPostGateScreen({super.key, required this.worker});

  @override
  State<JobPostGateScreen> createState() => _JobPostGateScreenState();
}

class _JobPostGateScreenState extends State<JobPostGateScreen> {
  // TODO: Replace with real subscription status
  final bool _isSubscriber = false;
  bool _isWatchingAd = false;

  Future<void> _goToSupportPost() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SupportPostScreen()),
    );
  }

  Future<void> _handleWatchAdAndPost() async {
    setState(() => _isWatchingAd = true);
    // Simulate Ad watching
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isWatchingAd = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ad watched successfully! Posting job...")),
    );
    await _goToSupportPost();
  }

  // ✅ Unified Profile ওপেন করার ফাংশন
  void _openUserProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedProfileScreen(
          uid: widget.worker.uid, // Worker এর UID
          isOwner: false, // যেহেতু অন্য কেউ দেখছে
          showBack: true, // ব্যাক বাটন অন
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingScaffold(
      title: 'Post a Job',
      backgroundColor: const Color(0xFFF8F9FD),
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      showBack: true,

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Worker Summary Card
                  _buildWorkerHeader(widget.worker),

                  const SizedBox(height: 25),

                  if (_isSubscriber)
                    _buildPremiumUserView()
                  else
                    _buildFreeUserView(),
                ],
              ),
            ),
          ),

          _buildBottomAction(),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildPremiumUserView() {
    return Column(
      children: [
        Icon(Icons.workspace_premium, size: 80, color: Colors.amber.shade700),
        const SizedBox(height: 15),
        const Text(
          "You are a Premium Member!",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
        ),
        const SizedBox(height: 10),
        const Text(
          "No ads, no waiting. Post your job instantly.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildFreeUserView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              _buildFeatureRow("Post Job Instantly", isPremium: true, isFree: false),
              const Divider(height: 25),
              _buildFeatureRow("Remove Ads", isPremium: true, isFree: false),
              const Divider(height: 25),
              _buildFeatureRow("Priority Support", isPremium: true, isFree: false),
            ],
          ),
        ),

        const SizedBox(height: 30),

        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Go to Subscription Page")));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFA726), Color(0xFFFF5722)]),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Go Premium", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Unlock instant posting", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(String text, {required bool isPremium, required bool isFree}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        Row(
          children: [
            _statusIcon(isFree, isFree: true),
            const SizedBox(width: 40),
            _statusIcon(isPremium, isFree: false),
          ],
        ),
      ],
    );
  }

  Widget _statusIcon(bool active, {required bool isFree}) {
    if (active) {
      return Icon(Icons.check_circle, size: 22, color: Colors.green.shade600);
    }
    return Icon(Icons.cancel, size: 22, color: Colors.grey.shade300);
  }

  Widget _buildWorkerHeader(Worker w) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: CachedNetworkImage(
              imageUrl: w.image,
              width: 55,
              height: 55,
              fit: BoxFit.cover,
              errorWidget: (_,__,___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.person)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hiring For", style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark)),
                Text(w.userRole.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.brandMain, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // ✅ Profile Button Updated
          TextButton(
            onPressed: _openUserProfile, // এখানে কল করা হয়েছে
            style: TextButton.styleFrom(
              backgroundColor: AppColors.brandLight.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Profile", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brandMain)),
          )
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isSubscriber)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                "Watch a short ad to continue for free",
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSubscriber ? _goToSupportPost : _handleWatchAdAndPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
                shadowColor: AppColors.brandDark.withOpacity(0.3),
              ),
              child: _isWatchingAd
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isSubscriber) const Icon(Icons.play_circle_filled_rounded, color: Colors.white),
                  if (!_isSubscriber) const SizedBox(width: 10),
                  Text(
                    _isSubscriber ? "POST JOB NOW" : "WATCH AD & POST",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}