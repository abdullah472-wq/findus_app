// lib/screens/settings/subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:findus_app/wallet/payment_screen.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

enum PlanType { free, pro, business }
enum BillingCycle { monthly, threeMonths, sixMonths, yearly }

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BillingCycle _currentCycle = BillingCycle.monthly;
  bool _hasPromoCode = false;
  final TextEditingController _promoController = TextEditingController();
  String? _promoError;

  final Map<BillingCycle, Map<PlanType, int>> _prices = {
    BillingCycle.monthly: {PlanType.free: 0, PlanType.pro: 199, PlanType.business: 499},
    BillingCycle.threeMonths: {PlanType.free: 0, PlanType.pro: 549, PlanType.business: 1399},
    BillingCycle.sixMonths: {PlanType.free: 0, PlanType.pro: 999, PlanType.business: 2599},
    BillingCycle.yearly: {PlanType.free: 0, PlanType.pro: 1799, PlanType.business: 4599},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentCycle = BillingCycle.values[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromoCode() {
    HapticFeedback.mediumImpact();
    final code = _promoController.text.trim().toUpperCase();
    if (code == "FINDUS25") {
      setState(() {
        _hasPromoCode = true;
        _promoError = null;
      });
      _showSnack("🎉 25% discount applied!", Colors.green);
    } else {
      setState(() {
        _promoError = "Invalid code";
        _hasPromoCode = false;
      });
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  int _getDisplayPrice(int original) => _hasPromoCode ? (original * 0.75).round() : original;

  @override
  Widget build(BuildContext context) {
    // ✅ Dark Mode Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final titleColor = isDark ? Colors.white : AppColors.brandDark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return FloatingScaffold(
      title: "UPGRADE PLAN",
      backgroundColor: bgColor,
      titleColor: titleColor,
      iconColor: titleColor,
      showBack: true,
      bodyPadding: EdgeInsets.zero,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildModernStepper(isDark, textColor),
            const SizedBox(height: 25),
            _buildHeaderContent(textColor, subTextColor),
            const SizedBox(height: 20),
            _buildBillingSwitcher(isDark, cardColor, textColor),
            const SizedBox(height: 20),
            _buildPromoField(isDark, cardColor, textColor),
            const SizedBox(height: 25),
            _buildPlanCards(context, isDark, cardColor, textColor),
            const SizedBox(height: 30),
            _buildTestimonials(isDark, cardColor, textColor),
            const SizedBox(height: 30),
            _buildFAQ(isDark, textColor, subTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStepper(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Row(
        children: [
          _stepCircle(1, "Plan", true, isDark, textColor),
          _stepLine(false, isDark),
          _stepCircle(2, "Pay", false, isDark, textColor),
          _stepLine(false, isDark),
          _stepCircle(3, "Go", false, isDark, textColor),
        ],
      ),
    );
  }

  Widget _stepCircle(int n, String label, bool active, bool isDark, Color textColor) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: active ? AppColors.brandMain : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            shape: BoxShape.circle,
            boxShadow: active ? [BoxShadow(color: AppColors.brandMain.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Center(
            child: Text(
                "$n",
                style: TextStyle(
                    color: active ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    fontWeight: FontWeight.bold
                )
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
            label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? AppColors.brandMain : Colors.grey
            )
        ),
      ],
    );
  }

  Widget _stepLine(bool active, bool isDark) => Expanded(
      child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 15),
          color: active ? AppColors.brandMain : (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
      )
  );

  Widget _buildHeaderContent(Color textColor, Color subTextColor) {
    return Column(
      children: [
        Text(
            "Choose your growth",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: textColor)
        ),
        const SizedBox(height: 8),
        Text(
            "Unlock premium features and boost your earnings.",
            textAlign: TextAlign.center,
            style: TextStyle(color: subTextColor, fontSize: 14)
        ),
      ],
    );
  }

  Widget _buildBillingSwitcher(bool isDark, Color cardColor, Color textColor) {
    return Container(
      height: 55,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
            color: AppColors.brandMain,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [BoxShadow(color: AppColors.brandMain.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        dividerColor: Colors.transparent,
        tabs: const [Tab(text: "Monthly"), Tab(text: "3 Months"), Tab(text: "6 Months"), Tab(text: "Yearly")],
      ),
    );
  }

  Widget _buildPromoField(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _hasPromoCode ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200))
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          const Icon(Icons.local_offer_rounded, size: 20, color: AppColors.brandMain),
          const SizedBox(width: 10),
          Expanded(
              child: TextField(
                  controller: _promoController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                      hintText: "Promo Code (FINDUS25)",
                      border: InputBorder.none,
                      errorText: _promoError,
                      hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade500 : Colors.grey)
                  )
              )
          ),
          ElevatedButton(
            onPressed: _applyPromoCode,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            child: const Text("Apply", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCards(BuildContext context, bool isDark, Color cardColor, Color textColor) {
    final curPrices = _prices[_currentCycle]!;
    return Column(
      children: [
        _singlePlanCard(
          title: "Standard",
          price: curPrices[PlanType.free]!,
          color: Colors.blueGrey,
          features: ["Basic Listing", "5 Job Posts", "Standard Support"],
          isPopular: false,
          onTap: () {},
          isDark: isDark,
          cardColor: cardColor,
          textColor: textColor,
        ),
        const SizedBox(height: 20),
        _singlePlanCard(
          title: "Professional",
          price: curPrices[PlanType.pro]!,
          color: Colors.blue,
          features: ["Unlimited Posts", "Profile Boost", "Advanced Analytics", "Pro Badge"],
          isPopular: true,
          onTap: () => _handlePurchase(PlanType.pro, _getDisplayPrice(curPrices[PlanType.pro]!)),
          isDark: isDark,
          cardColor: cardColor,
          textColor: textColor,
        ),
        const SizedBox(height: 20),
        _singlePlanCard(
          title: "Business",
          price: curPrices[PlanType.business]!,
          color: Colors.deepPurple,
          features: ["Team Management", "Priority Leads", "Personal Manager", "24/7 Phone Support"],
          isPopular: false,
          onTap: () => _handlePurchase(PlanType.business, _getDisplayPrice(curPrices[PlanType.business]!)),
          isDark: isDark,
          cardColor: cardColor,
          textColor: textColor,
        ),
      ],
    );
  }

  Widget _singlePlanCard({
    required String title,
    required int price,
    required Color color,
    required List<String> features,
    required bool isPopular,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
  }) {
    final displayPrice = _getDisplayPrice(price);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isPopular ? LinearGradient(colors: [color, color.withOpacity(0.5)]) : null,
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(isDark ? 0.1 : 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10)
          )
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                if (isPopular) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                    child: const Text("BEST VALUE", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("৳$displayPrice", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textColor)),
                Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Text("/ ${_currentCycle.name}", style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey))
                ),
                if (_hasPromoCode && price > 0) ...[
                  const SizedBox(width: 10),
                  Text("৳$price", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.redAccent, fontSize: 16)),
                ]
              ],
            ),
            Divider(height: 30, color: isDark ? Colors.white10 : Colors.grey.shade200),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [Icon(Icons.check_circle_rounded, size: 18, color: color), const SizedBox(width: 10), Text(f, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.black87))]),
            )),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              child: Text(
                  price == 0 ? "Current Plan" : "Get Started",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePurchase(PlanType plan, int amount) {
    HapticFeedback.lightImpact();
    final planId = '${plan.name.toUpperCase()}_${_currentCycle.name.toUpperCase()}';
    int duration = _currentCycle == BillingCycle.monthly ? 1 :
    _currentCycle == BillingCycle.threeMonths ? 3 :
    _currentCycle == BillingCycle.sixMonths ? 6 : 12;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualPaymentScreen(
          planId: planId,
          amount: amount,
          duration: duration,
          purpose: PaymentPurpose.subscription,
          description: 'Upgrade to ${plan == PlanType.pro ? 'Pro' : 'Business'} Plan (${_currentCycle.name})',
        ),
      ),
    );
  }

  // --- Placeholder Sections (Themed) ---
  Widget _buildTestimonials(bool isDark, Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Trust by thousands", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _testiBubble("FINDS Pro changed my career!", "Karim, Electrician", isDark, cardColor, textColor),
              _testiBubble("The best platform for workers.", "Rahim, Driver", isDark, cardColor, textColor),
            ],
          ),
        )
      ],
    );
  }

  Widget _testiBubble(String msg, String user, bool isDark, Color cardColor, Color textColor) => Container(
      width: 200,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1))
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? Colors.grey.shade300 : Colors.black87)),
            const Spacer(),
            Text(user, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brandMain))
          ]
      )
  );

  Widget _buildFAQ(bool isDark, Color textColor, Color subTextColor) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("FAQ", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
              title: Text("Can I cancel anytime?", style: TextStyle(fontSize: 13, color: textColor)),
              iconColor: AppColors.brandMain,
              children: [
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text("Yes, you can cancel your subscription from settings at any time.", style: TextStyle(color: subTextColor, fontSize: 12))
                )
              ]
          ),
        )
      ]
  );
}