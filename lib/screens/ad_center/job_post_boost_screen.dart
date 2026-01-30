// lib/screens/ad_center/job_post_boost_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

import '../../wallet/payment_screen.dart';

class JobPostBoostScreen extends StatefulWidget {
  const JobPostBoostScreen({super.key});

  @override
  State<JobPostBoostScreen> createState() => _JobPostBoostScreenState();
}

class _JobPostBoostScreenState extends State<JobPostBoostScreen> {
  int _days = 3;
  double _dailyBudget = 80;

  int get _totalBudget => (_days * _dailyBudget).round();

  @override
  Widget build(BuildContext context) {
    // ✅ ডার্ক মোড চেক
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return FloatingScaffold(
      title: "PROMOTE JOBS",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(),

          const SizedBox(height: 25),

          _buildBudgetControlCard(isDark, cardColor, textColor),

          const SizedBox(height: 25),

          _buildSummaryCard(isDark, cardColor, textColor),

          const SizedBox(height: 30),

          _buildConfirmButton(context),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.campaign_rounded, color: Colors.white, size: 50),
          const SizedBox(height: 15),
          const Text(
            "Get Faster Responses",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            "Promoted jobs are shown 5x more to local workers.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetControlCard(bool isDark, Color cardColor, Color textColor) {
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
          Text("Customize Promotion", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 20),

          // দিন সিলেক্টর
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Duration", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
              Text("$_days Days", style: const TextStyle(color: AppColors.brandMain, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _days.toDouble(),
            min: 1, max: 14,
            divisions: 13,
            activeColor: AppColors.brandMain,
            inactiveColor: isDark ? Colors.grey : Colors.grey.shade300,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _days = v.round());
            },
          ),

          const SizedBox(height: 15),

          // বাজেট সিলেক্টর
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Daily Budget", style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
              Text("৳${_dailyBudget.round()}", style: const TextStyle(color: AppColors.brandMain, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _dailyBudget,
            min: 50, max: 500,
            divisions: 9,
            activeColor: AppColors.brandMain,
            inactiveColor: isDark ? Colors.grey : Colors.grey.shade300,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _dailyBudget = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          _row("Promotion Type", "All Active Posts", isDark),
          _row("Daily Reach", "Est. 150-300 people", isDark),
          _row("Total Duration", "$_days Days", isDark),
          Divider(height: 30, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Investment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
              Text("৳$_totalBudget", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String val, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(val, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
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
                  builder: (_) => ManualPaymentScreen(
                    planId: 'JOB_BOOST_${_days}D',
                    amount: _totalBudget,
                    duration: _days,
                    purpose: PaymentPurpose.profileBoost, // Job post boost as profile boost variant
                    description: 'Boosting all job posts for $_days days',
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
              "CONFIRM & PROMOTE",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          "Promotion will be applied to all your active posts",
          style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}