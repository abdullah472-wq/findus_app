import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/wallet/payment_screen.dart';

class ProfileBoostScreen extends StatefulWidget {
  const ProfileBoostScreen({super.key});

  @override
  State<ProfileBoostScreen> createState() => _ProfileBoostScreenState();
}

class _ProfileBoostScreenState extends State<ProfileBoostScreen> {
  int _selectedDays = 3; // 1 / 3 / 7
  String _targetArea = "nearby"; // nearby / city

  int get _basePerDayNearby => 30; // demo cost per day
  int get _basePerDayCity => 50;

  int get _totalCost {
    final perDay =
    _targetArea == "city" ? _basePerDayCity : _basePerDayNearby;
    return perDay * _selectedDays;
  }

  int get _estimatedViews {
    final baseViewsPerDay = 120;
    final multiplier = _targetArea == "city" ? 1.5 : 1.0;
    return (baseViewsPerDay * _selectedDays * multiplier).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        backgroundColor: AppColors.brandLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
        title: const Text(
          "Promote Profile",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDurationCard(),
                  const SizedBox(height: 16),
                  _buildTargetAreaCard(),
                  const SizedBox(height: 16),
                  _buildSummaryCard(),
                ],
              ),
            ),
          ),
          _buildBottomConfirmBar(context),
        ],
      ),
    );
  }

  Widget _buildDurationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select boost duration",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _durationChip(
                1,
                "1 day",
                "৳${_targetArea == 'city' ? _basePerDayCity : _basePerDayNearby}",
              ),
              const SizedBox(width: 8),
              _durationChip(3, "3 days", "Popular"),
              const SizedBox(width: 8),
              _durationChip(7, "7 days", "Best value"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _durationChip(int days, String label, String sub) {
    final bool selected = _selectedDays == days;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDays = days),
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandMain : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
              selected ? AppColors.brandMain : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetAreaCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Target area",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 8),
          RadioListTile<String>(
            value: "nearby",
            groupValue: _targetArea,
            activeColor: AppColors.brandMain,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _targetArea = v);
            },
            title: const Text(
              "Nearby only",
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              "Best for local workers & supporters around your current area.",
              style: TextStyle(fontSize: 11),
            ),
          ),
          RadioListTile<String>(
            value: "city",
            groupValue: _targetArea,
            activeColor: AppColors.brandMain,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _targetArea = v);
            },
            title: const Text(
              "All city (wider reach)",
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              "Show your profile across the whole city. Higher cost but more views.",
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Promotion summary",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 6),
          _summaryRow("Duration", "$_selectedDays days"),
          _summaryRow("Target",
              _targetArea == "city" ? "All city" : "Nearby only"),
          const Divider(height: 16),
          _summaryRow("Estimated cost", "৳$_totalCost", bold: true),
          _summaryRow("Estimated extra views",
              "$_estimatedViews+", bold: true),
          const SizedBox(height: 6),
          const Text(
            "This is a demo estimation. Actual performance may vary.",
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.brandDark,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomConfirmBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentScreen(
                  planId:
                  'profile_boost_${_selectedDays}d_${_targetArea}',
                  amount: _totalCost,
                  duration: 0,
                  purpose: PaymentPurpose.profileBoost,
                  description:
                  'Boost your profile for $_selectedDays days (${_targetArea == 'city' ? 'All city' : 'Nearby only'})',
                  referenceId: null,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "CONFIRM PROMOTION",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}