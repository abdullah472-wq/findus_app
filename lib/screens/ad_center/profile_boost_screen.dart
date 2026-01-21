// lib/screens/ad_center/profile_boost_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/wallet/payment_screen.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class ProfileBoostScreen extends StatefulWidget {
  const ProfileBoostScreen({super.key});

  @override
  State<ProfileBoostScreen> createState() => _ProfileBoostScreenState();
}

class _ProfileBoostScreenState extends State<ProfileBoostScreen> {
  int _selectedDays = 3;
  String _targetArea = "nearby";

  // প্রাইসিং কনফিগ
  final Map<int, int> _pricesNearby = {1: 30, 3: 80, 7: 180};
  final Map<int, int> _pricesCity = {1: 50, 3: 130, 7: 280};

  int get _totalCost {
    return _targetArea == "city" ? _pricesCity[_selectedDays]! : _pricesNearby[_selectedDays]!;
  }

  int get _estimatedViews {
    final base = _selectedDays * 120;
    return _targetArea == "city" ? (base * 1.5).round() : base;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FloatingScaffold(
      title: "BOOST PROFILE",
      backgroundColor: AppColors.brandLight,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ১. টপ প্রোমো ব্যানার
          _buildPromoBanner(),

          const SizedBox(height: 25),

          // ২. ডিউরেশন সিলেকশন
          const Text("Select Duration", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildDurationOptions(isDark),

          const SizedBox(height: 25),

          // ৩. টার্গেট এরিয়া সিলেকশন
          const Text("Target Audience", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildTargetOptions(isDark),

          const SizedBox(height: 25),

          // ৪. ইমপ্যাক্ট ও সামারি কার্ড
          _buildSummaryCard(isDark),

          const SizedBox(height: 30),

          // ৫. একশন বাটন
          _buildConfirmButton(context),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF38B6FF), Color(0xFF003F67)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Get 3x More Leads", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 5),
                Text("Your profile will appear on top of search results and home feed.", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.trending_up_rounded, color: Colors.white, size: 40),
        ],
      ),
    );
  }

  Widget _buildDurationOptions(bool isDark) {
    return Row(
      children: [
        _durationCard(1, "1 Day", isDark, null),
        const SizedBox(width: 10),
        _durationCard(3, "3 Days", isDark, "POPULAR"),
        const SizedBox(width: 10),
        _durationCard(7, "7 Days", isDark, "BEST VALUE"),
      ],
    );
  }

  Widget _durationCard(int days, String label, bool isDark, String? tag) {
    final isSelected = _selectedDays == days;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedDays = days);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandMain : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isSelected ? AppColors.brandMain : Colors.grey.withOpacity(0.2), width: 2),
            boxShadow: isSelected ? [BoxShadow(color: AppColors.brandMain.withOpacity(0.3), blurRadius: 10)] : [],
          ),
          child: Column(
            children: [
              if (tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(bottom: 5),
                  decoration: BoxDecoration(color: isSelected ? Colors.white24 : AppColors.brandMain.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                  child: Text(tag, style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.brandMain)),
                ),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.brandDark)),
              Text("৳${_targetArea == 'city' ? _pricesCity[days] : _pricesNearby[days]}", style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetOptions(bool isDark) {
    return Column(
      children: [
        _targetTile("nearby", "Nearby Only", "Reach workers/clients within 10km", Icons.location_on_rounded, isDark),
        const SizedBox(height: 12),
        _targetTile("city", "Whole City", "Expand your visibility across the entire city", Icons.location_city_rounded, isDark), // ✅ 'location_city_rounded' ব্যবহার করুন
      ],
    );
  }

  Widget _targetTile(String val, String title, String sub, IconData icon, bool isDark) {
    final isSelected = _targetArea == val;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _targetArea = val);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandMain.withOpacity(0.05) : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.brandMain : Colors.grey.withOpacity(0.1), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.brandMain : Colors.grey),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded, color: isSelected ? AppColors.brandMain : Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brandMain.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Estimated Reach", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              Text("$_estimatedViews+ Views", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(value: _selectedDays / 7, backgroundColor: Colors.grey.shade100, color: AppColors.brandMain, minHeight: 8, borderRadius: BorderRadius.circular(10)),
          const Divider(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Investment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("৳$_totalCost", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.brandMain)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();

          // ✅ PaymentScreen এর বদলে ManualPaymentScreen কল করা হচ্ছে
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManualPaymentScreen(
                planId: 'PROFILE_BOOST_${_selectedDays}D_${_targetArea.toUpperCase()}',
                amount: _totalCost,
                duration: _selectedDays,
                purpose: PaymentPurpose.profileBoost,
                description: 'Boosting profile for $_selectedDays days.',
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 8,
          shadowColor: AppColors.brandDark.withOpacity(0.4),
        ),
        child: const Text(
          "ACTIVATE BOOST NOW",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
        ),
      ),
    );
  }

  void _showSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.verified_rounded, color: Colors.green, size: 60),
        content: const Text("Your profile is now being promoted! 🚀", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [Center(child: ElevatedButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text("DONE")))],
      ),
    );
  }
}