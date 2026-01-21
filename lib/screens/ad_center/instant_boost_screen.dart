// lib/screens/ad_center/instant_boost_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/wallet/payment_screen.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class InstantBoostScreen extends StatefulWidget {
  const InstantBoostScreen({super.key});

  @override
  State<InstantBoostScreen> createState() => _InstantBoostScreenState();
}

class _InstantBoostScreenState extends State<InstantBoostScreen> {
  final int _hours = 24;
  final int _cost = 120;
  final int _extraViews = 250;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FloatingScaffold(
      title: "INSTANT BOOST",
      backgroundColor: AppColors.brandLight,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ১. ফিচার এনিমেশন/আইকন কার্ড
          _buildBoltHeader(isDark),

          const SizedBox(height: 25),

          // ২. বেনিফিট কার্ড
          _buildBenefitCard(isDark),

          const SizedBox(height: 20),

          // ৩. প্রাইসিং ও সামারি কার্ড
          _buildPricingSummary(isDark),

          const SizedBox(height: 30),

          // ৪. কনফার্ম বাটন
          _buildConfirmButton(context),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBoltHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade700, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 60),
          const SizedBox(height: 15),
          const Text(
            "Get Instant Visibility",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            "Push your profile to the top for the next $_hours hours!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Why Boost Now?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _benefitRow(Icons.rocket_launch_rounded, "Top position in search results"),
          _benefitRow(Icons.visibility_rounded, "Reach up to $_extraViews+ extra clients"),
          _benefitRow(Icons.chat_bubble_rounded, "Higher chance of getting hired instantly"),
        ],
      ),
    );
  }

  Widget _benefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildPricingSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Boost Duration", style: TextStyle(color: Colors.grey, fontSize: 14)),
              Text("$_hours Hours", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Cost", style: TextStyle(color: Colors.grey, fontSize: 14)),
              Text("৳$_cost", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.brandMain)),
            ],
          ),
          const Divider(height: 30),
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "This is a one-time non-recurring payment.",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManualPaymentScreen(
                    planId: 'INSTANT_BOOST_24H',
                    amount: 120,
                    duration: 0,
                    purpose: PaymentPurpose.profileBoost,
                    description: 'Profile visibility for 24 hours',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 5,
            ),
            child: const Text(
              "CONFIRM & ACTIVATE",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          "Boost starts immediately after payment",
          style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 50),
        content: const Text(
          "Boost Activated! 🚀\nYour profile is now being promoted to more people around you.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Close Boost Screen
              },
              child: const Text("AWESOME!"),
            ),
          )
        ],
      ),
    );
  }
}