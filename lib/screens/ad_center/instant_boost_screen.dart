// lib/screens/ad_center/instant_boost_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/wallet/payment_screen.dart';

class InstantBoostScreen extends StatefulWidget {
  const InstantBoostScreen({super.key});

  @override
  State<InstantBoostScreen> createState() => _InstantBoostScreenState();
}

class _InstantBoostScreenState extends State<InstantBoostScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Selected plan
  int _selectedPlanIndex = 1; // Default: 24 hours

  // Boost plans
  final List<_BoostPlan> _plans = [
    _BoostPlan(
      hours: 6,
      cost: 49,
      extraViews: 80,
      label: "Quick",
      discount: null,
    ),
    _BoostPlan(
      hours: 24,
      cost: 120,
      extraViews: 250,
      label: "Popular",
      discount: null,
    ),
    _BoostPlan(
      hours: 72,
      cost: 299,
      extraViews: 600,
      label: "Best Value",
      discount: "17% OFF",
    ),
  ];

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

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  _BoostPlan get _selectedPlan => _plans[_selectedPlanIndex];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: "Instant Boost",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: _InstantBoostContent(
            isDark: isDark,
            plans: _plans,
            selectedPlanIndex: _selectedPlanIndex,
            onPlanSelected: (index) {
              HapticFeedback.selectionClick();
              setState(() => _selectedPlanIndex = index);
            },
            selectedPlan: _selectedPlan,
          ),
        ),
      ),
    );
  }
}

class _InstantBoostContent extends StatelessWidget {
  final bool isDark;
  final List<_BoostPlan> plans;
  final int selectedPlanIndex;
  final Function(int) onPlanSelected;
  final _BoostPlan selectedPlan;

  const _InstantBoostContent({
    required this.isDark,
    required this.plans,
    required this.selectedPlanIndex,
    required this.onPlanSelected,
    required this.selectedPlan,
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
          // 🔥 Header Banner
          _buildBoltHeader(),

          const SizedBox(height: 24),

          // ⏱️ Plan Selection
          _buildPlanSelector(textColor, cardBg, subtitleColor),

          const SizedBox(height: 24),

          // ✨ Benefits Section
          _buildBenefitsCard(textColor, cardBg, subtitleColor),

          const SizedBox(height: 24),

          // 💰 Pricing Summary
          _buildPricingSummary(textColor, cardBg, subtitleColor),

          const SizedBox(height: 24),

          // 🚀 Confirm Button
          _buildConfirmButton(context, textColor, cardBg),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // 🔥 Header Banner
  Widget _buildBoltHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade600,
            Colors.deepOrange.shade400,
            Colors.amber.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated bolt icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(20),
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
                Icons.bolt_rounded,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "⚡ Instant Visibility",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
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
              "Push your profile to the top and get hired faster!",
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

  // ⏱️ Plan Selector
  Widget _buildPlanSelector(
      Color textColor, Color cardBg, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule_rounded, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              "Choose Duration",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(plans.length, (index) {
            final plan = plans[index];
            final isSelected = index == selectedPlanIndex;

            return Expanded(
              child: GestureDetector(
                onTap: () => onPlanSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 6,
                    right: index == plans.length - 1 ? 0 : 6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.orange.withOpacity(isDark ? 0.2 : 0.1)
                        : cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.orange
                          : (isDark ? Colors.white12 : Colors.grey.shade200),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      // Discount badge
                      if (plan.discount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            plan.discount!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 20),
                      // Hours
                      Text(
                        "${plan.hours}H",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.orange : textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Label
                      Text(
                        plan.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.orange
                              : subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Price
                      Text(
                        "৳${plan.cost}",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.orange
                              : textColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ✨ Benefits Card
  Widget _buildBenefitsCard(
      Color textColor, Color cardBg, Color subtitleColor) {
    final benefits = [
      _Benefit(
        icon: Icons.rocket_launch_rounded,
        title: "Top Position",
        subtitle: "Appear first in search results",
      ),
      _Benefit(
        icon: Icons.visibility_rounded,
        title: "${selectedPlan.extraViews}+ Extra Views",
        subtitle: "Reach more potential clients",
      ),
      _Benefit(
        icon: Icons.flash_on_rounded,
        title: "Instant Activation",
        subtitle: "Starts immediately after payment",
      ),
      _Benefit(
        icon: Icons.workspace_premium_rounded,
        title: "Boost Badge",
        subtitle: "Stand out with special badge",
      ),
    ];

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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "What You Get",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...benefits.map((benefit) => _buildBenefitItem(
            benefit,
            textColor,
            subtitleColor,
            benefit == benefits.last,
          )),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
      _Benefit benefit,
      Color textColor,
      Color subtitleColor,
      bool isLast,
      ) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.15),
                  Colors.deepOrange.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              benefit.icon,
              size: 20,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  benefit.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: Colors.green.shade400,
          ),
        ],
      ),
    );
  }

  // 💰 Pricing Summary
  Widget _buildPricingSummary(
      Color textColor, Color cardBg, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A2A2A), const Color(0xFF242424)]
              : [Colors.orange.shade50, Colors.amber.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Summary header
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Order Summary",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Duration row
          _buildSummaryRow(
            "Boost Duration",
            "${selectedPlan.hours} Hours",
            textColor,
            subtitleColor,
          ),
          const SizedBox(height: 12),

          // Views row
          _buildSummaryRow(
            "Expected Views",
            "Up to ${selectedPlan.extraViews}+",
            textColor,
            subtitleColor,
          ),

          Divider(
            height: 30,
            color: Colors.orange.withOpacity(0.3),
          ),

          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "৳${selectedPlan.cost}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black12 : Colors.white.withOpacity(0.5),
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
                    "One-time payment. No auto-renewal.",
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
      Color textColor,
      Color subtitleColor,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: subtitleColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // 🚀 Confirm Button
  Widget _buildConfirmButton(
      BuildContext context, Color textColor, Color cardBg) {
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
                    planId: 'INSTANT_BOOST_${selectedPlan.hours}H',
                    amount: selectedPlan.cost,
                    duration: 0,
                    purpose: PaymentPurpose.profileBoost,
                    description:
                    'Profile visibility for ${selectedPlan.hours} hours',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: Colors.orange.withOpacity(0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.bolt_rounded, size: 24),
                SizedBox(width: 10),
                Text(
                  "ACTIVATE BOOST",
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

        // Security badge
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
              "Secure payment • Instant activation",
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

// 📦 Data Models
class _BoostPlan {
  final int hours;
  final int cost;
  final int extraViews;
  final String label;
  final String? discount;

  _BoostPlan({
    required this.hours,
    required this.cost,
    required this.extraViews,
    required this.label,
    this.discount,
  });
}

class _Benefit {
  final IconData icon;
  final String title;
  final String subtitle;

  _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}