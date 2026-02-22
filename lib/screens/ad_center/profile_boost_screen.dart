// lib/screens/ad_center/profile_boost_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/wallet/payment_screen.dart';

class ProfileBoostScreen extends StatefulWidget {
  const ProfileBoostScreen({super.key});

  @override
  State<ProfileBoostScreen> createState() => _ProfileBoostScreenState();
}

class _ProfileBoostScreenState extends State<ProfileBoostScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedDays = 3;
  String _targetArea = "nearby";

  final Map<int, int> _pricesNearby = {1: 30, 3: 80, 7: 180};
  final Map<int, int> _pricesCity = {1: 50, 3: 130, 7: 280};

  int get _totalCost {
    return _targetArea == "city"
        ? _pricesCity[_selectedDays]!
        : _pricesNearby[_selectedDays]!;
  }

  int get _estimatedViews {
    final base = _selectedDays * 120;
    return _targetArea == "city" ? (base * 1.5).round() : base;
  }

  int get _estimatedLeads => (_estimatedViews * 0.12).round();

  double get _savingsPercentage {
    if (_selectedDays == 7) return 0.25;
    if (_selectedDays == 3) return 0.10;
    return 0.0;
  }

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
      title: "Boost Profile",
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
          child: _ProfileBoostContent(
            isDark: isDark,
            selectedDays: _selectedDays,
            targetArea: _targetArea,
            totalCost: _totalCost,
            estimatedViews: _estimatedViews,
            estimatedLeads: _estimatedLeads,
            savingsPercentage: _savingsPercentage,
            pricesNearby: _pricesNearby,
            pricesCity: _pricesCity,
            onDaysChanged: (days) {
              HapticFeedback.selectionClick();
              setState(() => _selectedDays = days);
            },
            onTargetChanged: (target) {
              HapticFeedback.selectionClick();
              setState(() => _targetArea = target);
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileBoostContent extends StatelessWidget {
  final bool isDark;
  final int selectedDays;
  final String targetArea;
  final int totalCost;
  final int estimatedViews;
  final int estimatedLeads;
  final double savingsPercentage;
  final Map<int, int> pricesNearby;
  final Map<int, int> pricesCity;
  final Function(int) onDaysChanged;
  final Function(String) onTargetChanged;

  const _ProfileBoostContent({
    required this.isDark,
    required this.selectedDays,
    required this.targetArea,
    required this.totalCost,
    required this.estimatedViews,
    required this.estimatedLeads,
    required this.savingsPercentage,
    required this.pricesNearby,
    required this.pricesCity,
    required this.onDaysChanged,
    required this.onTargetChanged,
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
          // 🎯 Promo Banner
          _buildPromoBanner(),

          const SizedBox(height: 24),

          // 📊 Stats Preview
          _buildStatsPreview(textColor, cardBg),

          const SizedBox(height: 24),

          // ⏱️ Duration Selection
          _buildDurationSection(textColor, cardBg, subtitleColor),

          const SizedBox(height: 24),

          // 🎯 Target Audience
          _buildTargetSection(textColor, cardBg, subtitleColor),

          const SizedBox(height: 24),

          // 💎 Benefits Section
          _buildBenefitsSection(textColor, cardBg),

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

  // 🎯 Promo Banner
  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF38B6FF),
            Color(0xFF0097D9),
            Color(0xFF003F67),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandMain.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "🔥 LIMITED OFFER",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Get 3x More Leads",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your profile appears at the top of search results and home feed",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.trending_up_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📊 Stats Preview
  Widget _buildStatsPreview(Color textColor, Color cardBg) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.visibility_rounded,
            label: "Views",
            value: "$estimatedViews+",
            color: Colors.blue,
            textColor: textColor,
            cardBg: cardBg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.people_rounded,
            label: "Leads",
            value: "$estimatedLeads+",
            color: Colors.green,
            textColor: textColor,
            cardBg: cardBg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.star_rounded,
            label: "Rating",
            value: "Top 5%",
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
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
            ),
          ),
        ],
      ),
    );
  }

  // ⏱️ Duration Section
  Widget _buildDurationSection(
      Color textColor, Color cardBg, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule_rounded, color: AppColors.brandMain, size: 20),
            const SizedBox(width: 8),
            Text(
              "Select Duration",
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
          children: [
            _buildDurationCard(1, "1 Day", null, textColor, cardBg),
            const SizedBox(width: 10),
            _buildDurationCard(3, "3 Days", "POPULAR", textColor, cardBg),
            const SizedBox(width: 10),
            _buildDurationCard(7, "7 Days", "SAVE 25%", textColor, cardBg),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationCard(
      int days,
      String label,
      String? tag,
      Color textColor,
      Color cardBg,
      ) {
    final isSelected = selectedDays == days;
    final price = targetArea == 'city' ? pricesCity[days]! : pricesNearby[days]!;

    return Expanded(
      child: GestureDetector(
        onTap: () => onDaysChanged(days),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
              colors: [AppColors.brandMain, Color(0xFF0097D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isSelected ? null : cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandMain
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: AppColors.brandMain.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ]
                : [],
          ),
          child: Column(
            children: [
              if (tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.25)
                        : Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.green,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              else
                const SizedBox(height: 20),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isSelected ? Colors.white : textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "৳$price",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white.withOpacity(0.9)
                      : textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 Target Section
  Widget _buildTargetSection(
      Color textColor, Color cardBg, Color subtitleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.my_location_rounded,
                color: AppColors.brandMain, size: 20),
            const SizedBox(width: 8),
            Text(
              "Target Audience",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildTargetTile(
          value: "nearby",
          title: "Nearby Only",
          subtitle: "Reach people within 10km radius",
          icon: Icons.location_on_rounded,
          badgeText: "Basic",
          textColor: textColor,
          cardBg: cardBg,
          subtitleColor: subtitleColor,
        ),
        const SizedBox(height: 12),
        _buildTargetTile(
          value: "city",
          title: "Whole City",
          subtitle: "Maximum visibility across entire city",
          icon: Icons.location_city_rounded,
          badgeText: "Premium",
          textColor: textColor,
          cardBg: cardBg,
          subtitleColor: subtitleColor,
        ),
      ],
    );
  }

  Widget _buildTargetTile({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required String badgeText,
    required Color textColor,
    required Color cardBg,
    required Color subtitleColor,
  }) {
    final isSelected = targetArea == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTargetChanged(value),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandMain.withOpacity(isDark ? 0.15 : 0.08)
                : cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.brandMain
                  : (isDark ? Colors.white10 : Colors.grey.shade200),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: AppColors.brandMain.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandMain.withOpacity(0.15)
                      : (isDark ? Colors.white10 : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.brandMain : subtitleColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brandMain.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.brandMain
                                  : subtitleColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? AppColors.brandMain : Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 💎 Benefits Section
  Widget _buildBenefitsSection(Color textColor, Color cardBg) {
    final benefits = [
      _Benefit(
        icon: Icons.workspace_premium_rounded,
        title: "Premium Badge",
        color: Colors.amber,
      ),
      _Benefit(
        icon: Icons.flash_on_rounded,
        title: "Priority Listing",
        color: Colors.orange,
      ),
      _Benefit(
        icon: Icons.analytics_rounded,
        title: "Real-time Stats",
        color: Colors.blue,
      ),
      _Benefit(
        icon: Icons.support_agent_rounded,
        title: "24/7 Support",
        color: Colors.green,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A2A3A), const Color(0xFF1F1F2F)]
              : [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.brandMain.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.brandMain,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "Premium Benefits",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: benefits.map((benefit) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(benefit.icon, size: 16, color: benefit.color),
                    const SizedBox(width: 6),
                    Text(
                      benefit.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
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
          color: AppColors.brandMain.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandMain.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  color: AppColors.brandMain, size: 20),
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

          // Estimated reach
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Estimated Reach",
                style: TextStyle(
                  fontSize: 13,
                  color: subtitleColor,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.trending_up_rounded,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    "$estimatedViews+ Views",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: selectedDays / 7,
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
              color: AppColors.brandMain,
              minHeight: 8,
            ),
          ),

          if (savingsPercentage > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.savings_rounded,
                      size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    "You're saving ${(savingsPercentage * 100).round()}% with this plan!",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          Divider(
            height: 30,
            color: AppColors.brandMain.withOpacity(0.3),
          ),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Investment",
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
                  gradient: const LinearGradient(
                    colors: [AppColors.brandMain, Color(0xFF0097D9)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "৳$totalCost",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
                    planId:
                    'PROFILE_BOOST_${selectedDays}D_${targetArea.toUpperCase()}',
                    amount: totalCost,
                    duration: selectedDays,
                    purpose: PaymentPurpose.profileBoost,
                    description: 'Boosting profile for $selectedDays days.',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: AppColors.brandMain.withOpacity(0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.rocket_launch_rounded, size: 22),
                SizedBox(width: 10),
                Text(
                  "ACTIVATE BOOST NOW",
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

class _Benefit {
  final IconData icon;
  final String title;
  final Color color;

  _Benefit({
    required this.icon,
    required this.title,
    required this.color,
  });
}