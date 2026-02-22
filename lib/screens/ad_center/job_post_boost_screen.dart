// lib/screens/ad_center/job_post_boost_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/wallet/payment_screen.dart';

class JobPostBoostScreen extends StatefulWidget {
  const JobPostBoostScreen({super.key});

  @override
  State<JobPostBoostScreen> createState() => _JobPostBoostScreenState();
}

class _JobPostBoostScreenState extends State<JobPostBoostScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _days = 3;
  double _dailyBudget = 80;

  int get _totalBudget => (_days * _dailyBudget).round();
  int get _estimatedReach => (_days * 200).round();
  int get _estimatedApplications => (_days * 15).round();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: "Promote Jobs",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _JobBoostContent(
            isDark: isDark,
            days: _days,
            dailyBudget: _dailyBudget,
            totalBudget: _totalBudget,
            estimatedReach: _estimatedReach,
            estimatedApplications: _estimatedApplications,
            onDaysChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _days = value.round());
            },
            onBudgetChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _dailyBudget = value);
            },
          ),
        ),
      ),
    );
  }
}

class _JobBoostContent extends StatelessWidget {
  final bool isDark;
  final int days;
  final double dailyBudget;
  final int totalBudget;
  final int estimatedReach;
  final int estimatedApplications;
  final Function(double) onDaysChanged;
  final Function(double) onBudgetChanged;

  const _JobBoostContent({
    required this.isDark,
    required this.days,
    required this.dailyBudget,
    required this.totalBudget,
    required this.estimatedReach,
    required this.estimatedApplications,
    required this.onDaysChanged,
    required this.onBudgetChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📢 Header Banner
          _buildInfoBanner(),

          const SizedBox(height: 24),

          // 📊 Quick Stats
          _buildQuickStats(textColor, cardBg, subtitleColor),

          const SizedBox(height: 24),

          // ⚙️ Customization Section
          _buildCustomizationCard(textColor, cardBg, subtitleColor),

          const SizedBox(height: 24),

          // 📈 Impact Estimator
          _buildImpactEstimator(textColor, cardBg, subtitleColor),

          const SizedBox(height: 24),

          // 💰 Summary Card
          _buildSummaryCard(textColor, cardBg, subtitleColor),

          const SizedBox(height: 24),

          // 🚀 Confirm Button
          _buildConfirmButton(context, textColor),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // 📢 Header Banner
  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade600,
            Colors.green.shade500,
            Colors.teal.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "🚀 Boost Your Jobs",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Get 5x more responses from local workers",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📊 Quick Stats
  Widget _buildQuickStats(
      Color textColor, Color cardBg, Color subtitleColor) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up_rounded,
            label: "Reach",
            value: "${(days * 200)}+",
            color: Colors.blue,
            textColor: textColor,
            cardBg: cardBg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.person_add_rounded,
            label: "Applicants",
            value: "${(days * 15)}+",
            color: Colors.green,
            textColor: textColor,
            cardBg: cardBg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.speed_rounded,
            label: "Response",
            value: "2-4h",
            color: Colors.orange,
            textColor: textColor,
            cardBg: cardBg,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color textColor,
    required Color cardBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ⚙️ Customization Card
  Widget _buildCustomizationCard(
      Color textColor, Color cardBg, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandMain.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.brandMain,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Customize Promotion",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Duration Slider
          _buildSliderSection(
            label: "Duration",
            value: "$days Days",
            sliderValue: days.toDouble(),
            min: 1,
            max: 14,
            divisions: 13,
            onChanged: onDaysChanged,
            icon: Icons.calendar_today_rounded,
            color: AppColors.brandMain,
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),

          const SizedBox(height: 24),

          // Budget Slider
          _buildSliderSection(
            label: "Daily Budget",
            value: "৳${dailyBudget.round()}",
            sliderValue: dailyBudget,
            min: 50,
            max: 500,
            divisions: 9,
            onChanged: onBudgetChanged,
            icon: Icons.account_balance_wallet_rounded,
            color: Colors.green,
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSection({
    required String label,
    required String value,
    required double sliderValue,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: textColor,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: sliderValue,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // 📈 Impact Estimator
  Widget _buildImpactEstimator(
      Color textColor, Color cardBg, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A3A2A), const Color(0xFF1F2F1F)]
              : [Colors.green.shade50, Colors.teal.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Expected Impact",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildImpactRow(
            icon: Icons.visibility_rounded,
            label: "Total Reach",
            value: "$estimatedReach+ people",
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
          const SizedBox(height: 12),
          _buildImpactRow(
            icon: Icons.person_search_rounded,
            label: "Applications",
            value: "$estimatedApplications+ applicants",
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
          const SizedBox(height: 12),
          _buildImpactRow(
            icon: Icons.timer_rounded,
            label: "Avg. Response Time",
            value: "2-4 hours",
            textColor: textColor,
            subtitleColor: subtitleColor,
          ),
        ],
      ),
    );
  }

  Widget _buildImpactRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.green.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: subtitleColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // 💰 Summary Card
  Widget _buildSummaryCard(
      Color textColor, Color cardBg, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Campaign Summary",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildSummaryRow(
            "Promotion Type",
            "All Active Posts",
            subtitleColor,
            textColor,
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            "Daily Budget",
            "৳${dailyBudget.round()}",
            subtitleColor,
            textColor,
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            "Total Duration",
            "$days Days",
            subtitleColor,
            textColor,
          ),
          Divider(
            height: 30,
            color: Colors.green.withOpacity(0.3),
            thickness: 1.5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Investment",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "৳$totalBudget",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black12 : Colors.green.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: subtitleColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Budget will be spent gradually over $days days",
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      String label,
      String value,
      Color subtitleColor,
      Color textColor,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: subtitleColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // 🚀 Confirm Button
  Widget _buildConfirmButton(BuildContext context, Color textColor) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManualPaymentScreen(
                    planId: 'JOB_BOOST_${days}D',
                    amount: totalBudget,
                    duration: days,
                    purpose: PaymentPurpose.profileBoost,
                    description: 'Boosting all job posts for $days days',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.rocket_launch_rounded, size: 22),
                SizedBox(width: 10),
                Text(
                  "START PROMOTION",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_rounded,
              size: 14,
              color: Colors.green.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              "Applied to all active posts • Cancel anytime",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}