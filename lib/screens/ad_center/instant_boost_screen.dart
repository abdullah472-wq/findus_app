// lib/screens/ad_center/instant_boost_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import '../../wallet/payment_screen.dart'; // ✅ সঠিক ইম্পোর্ট

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
    // ✅ ডার্ক মোড চেক
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return FloatingScaffold(
      title: "INSTANT BOOST",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBoltHeader(),

          const SizedBox(height: 25),

          _buildBenefitCard(isDark, cardColor, textColor),

          const SizedBox(height: 20),

          _buildPricingSummary(isDark, cardColor, textColor),

          const SizedBox(height: 30),

          _buildConfirmButton(context),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBoltHeader() {
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

  Widget _buildBenefitCard(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Why Boost Now?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 15),
          _benefitRow(Icons.rocket_launch_rounded, "Top position in search results", isDark),
          _benefitRow(Icons.visibility_rounded, "Reach up to $_extraViews+ extra clients", isDark),
          _benefitRow(Icons.chat_bubble_rounded, "Higher chance of getting hired instantly", isDark),
        ],
      ),
    );
  }

  Widget _benefitRow(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildPricingSummary(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Boost Duration", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 14)),
              Text("$_hours Hours", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cost", style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 14)),
              Text("৳$_cost", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.brandMain)),
            ],
          ),
          Divider(height: 30, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: isDark ? Colors.white54 : Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "This is a one-time non-recurring payment.",
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey),
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
}