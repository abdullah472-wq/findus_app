// lib/screens/settings/subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // ✅ NEW: Current subscription data
  Map<String, dynamic>? _currentSubscription;
  bool _loadingSubscription = true;

  final Map<BillingCycle, Map<PlanType, int>> _prices = {
    BillingCycle.monthly: {PlanType.free: 0, PlanType.pro: 199, PlanType.business: 499},
    BillingCycle.threeMonths: {PlanType.free: 0, PlanType.pro: 549, PlanType.business: 1399},
    BillingCycle.sixMonths: {PlanType.free: 0, PlanType.pro: 999, PlanType.business: 2599},
    BillingCycle.yearly: {PlanType.free: 0, PlanType.pro: 1799, PlanType.business: 4599},
  };

  // ✅ NEW: Feature comparison data
  final Map<PlanType, List<Map<String, dynamic>>> _planFeatures = {
    PlanType.free: [
      {'feature': 'Job Posts', 'value': '5/month', 'available': true},
      {'feature': 'Profile Views', 'value': 'Limited', 'available': true},
      {'feature': 'Analytics', 'value': 'Basic', 'available': true},
      {'feature': 'Profile Boost', 'value': '-', 'available': false},
      {'feature': 'Priority Support', 'value': '-', 'available': false},
      {'feature': 'Team Management', 'value': '-', 'available': false},
    ],
    PlanType.pro: [
      {'feature': 'Job Posts', 'value': 'Unlimited', 'available': true},
      {'feature': 'Profile Views', 'value': 'Unlimited', 'available': true},
      {'feature': 'Analytics', 'value': 'Advanced', 'available': true},
      {'feature': 'Profile Boost', 'value': '2x/month', 'available': true},
      {'feature': 'Priority Support', 'value': 'Email', 'available': true},
      {'feature': 'Team Management', 'value': '-', 'available': false},
    ],
    PlanType.business: [
      {'feature': 'Job Posts', 'value': 'Unlimited', 'available': true},
      {'feature': 'Profile Views', 'value': 'Unlimited', 'available': true},
      {'feature': 'Analytics', 'value': 'Premium', 'available': true},
      {'feature': 'Profile Boost', 'value': '5x/month', 'available': true},
      {'feature': 'Priority Support', 'value': '24/7 Phone', 'available': true},
      {'feature': 'Team Management', 'value': 'Up to 10', 'available': true},
    ],
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
    _loadCurrentSubscription();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  // ✅ NEW: Load current subscription from Firebase
  Future<void> _loadCurrentSubscription() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingSubscription = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(uid)
          .get();

      if (doc.exists) {
        setState(() {
          _currentSubscription = doc.data();
          _loadingSubscription = false;
        });
      } else {
        setState(() => _loadingSubscription = false);
      }
    } catch (e) {
      debugPrint('Load subscription error: $e');
      setState(() => _loadingSubscription = false);
    }
  }

  void _applyPromoCode() {
    HapticFeedback.mediumImpact();
    final code = _promoController.text.trim().toUpperCase();

    // ✅ Multiple promo codes support
    final promoCodes = {
      'FINDUS25': 25,
      'FINDUS50': 50,
      'WELCOME10': 10,
      'EARLYBIRD': 30,
    };

    if (promoCodes.containsKey(code)) {
      setState(() {
        _hasPromoCode = true;
        _promoError = null;
      });
      _showSnack("🎉 ${promoCodes[code]}% discount applied!", Colors.green);
    } else {
      setState(() {
        _promoError = "Invalid promo code";
        _hasPromoCode = false;
      });
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  int _getDisplayPrice(int original) => _hasPromoCode ? (original * 0.75).round() : original;

  // ✅ NEW: Get savings percentage
  String _getSavings(BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.monthly:
        return '';
      case BillingCycle.threeMonths:
        return 'Save 8%';
      case BillingCycle.sixMonths:
        return 'Save 16%';
      case BillingCycle.yearly:
        return 'Save 25%';
    }
  }

  // ✅ NEW: Check if user has active subscription
  bool _isCurrentPlan(PlanType plan) {
    if (_currentSubscription == null) return plan == PlanType.free;
    final currentPlan = _currentSubscription!['planType'] ?? 'free';
    return currentPlan.toString().toLowerCase() == plan.name.toLowerCase();
  }

  // ✅ NEW: Get subscription expiry
  String? _getExpiryDate() {
    if (_currentSubscription == null) return null;
    final expiresAt = _currentSubscription!['expiresAt'];
    if (expiresAt == null) return null;

    try {
      final date = (expiresAt as Timestamp).toDate();
      final daysLeft = date.difference(DateTime.now()).inDays;
      return '$daysLeft days left';
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // ✅ NEW: Current Subscription Banner
            if (_currentSubscription != null && !_loadingSubscription)
              _buildCurrentSubscriptionBanner(isDark, cardColor, textColor),

            _buildModernStepper(isDark, textColor),
            const SizedBox(height: 25),
            _buildHeaderContent(textColor, subTextColor),
            const SizedBox(height: 20),
            _buildBillingSwitcher(isDark, cardColor, textColor),

            // ✅ NEW: Savings indicator
            if (_getSavings(_currentCycle).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getSavings(_currentCycle),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
            _buildPromoField(isDark, cardColor, textColor),
            const SizedBox(height: 25),
            _buildPlanCards(context, isDark, cardColor, textColor),
            const SizedBox(height: 30),

            // ✅ NEW: Feature Comparison Table
            _buildComparisonTable(isDark, cardColor, textColor, subTextColor),
            const SizedBox(height: 30),

            _buildTestimonials(isDark, cardColor, textColor),
            const SizedBox(height: 30),
            _buildFAQ(isDark, cardColor, textColor, subTextColor),
            const SizedBox(height: 20),

            // ✅ NEW: Guarantee Badge
            _buildGuaranteeBadge(isDark, cardColor, textColor),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ NEW: Current Subscription Banner
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildCurrentSubscriptionBanner(bool isDark, Color cardColor, Color textColor) {
    final planType = _currentSubscription!['planType'] ?? 'free';
    final expiry = _getExpiryDate();
    final isPro = planType.toString().toLowerCase() == 'pro';
    final isBusiness = planType.toString().toLowerCase() == 'business';

    Color planColor = Colors.blueGrey;
    if (isPro) planColor = Colors.blue;
    if (isBusiness) planColor = Colors.deepPurple;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            planColor.withOpacity(0.2),
            planColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: planColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: planColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPro || isBusiness ? Icons.workspace_premium : Icons.person,
              color: planColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Current Plan: ",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey : Colors.grey[600],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: planColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        planType.toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                if (expiry != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    expiry,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isPro || isBusiness)
            TextButton(
              onPressed: () {
                // Navigate to manage subscription
                _showManageSubscriptionSheet();
              },
              child: const Text("Manage"),
            ),
        ],
      ),
    );
  }

  void _showManageSubscriptionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Manage Subscription",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.receipt_long, color: AppColors.brandMain),
                title: const Text("Payment History"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  // Navigate to payment history
                },
              ),

              ListTile(
                leading: const Icon(Icons.autorenew, color: Colors.blue),
                title: const Text("Auto-Renewal"),
                trailing: Switch(
                  value: _currentSubscription?['autoRenew'] ?? false,
                  onChanged: (val) {
                    // Toggle auto-renewal
                  },
                  activeColor: AppColors.brandMain,
                ),
              ),

              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                title: const Text("Cancel Subscription", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCancelDialog();
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Cancel Subscription?"),
        content: const Text(
          "Your premium features will remain active until the end of your billing period.\n\n"
              "Are you sure you want to cancel?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep Subscription"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Cancel subscription
              _showSnack("Subscription cancelled", Colors.orange);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Cancel Anyway"),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // EXISTING WIDGETS (Updated)
  // ════════════════════════════════════════════════════════════════════════════

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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? AppColors.brandMain : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            shape: BoxShape.circle,
            boxShadow: active
                ? [BoxShadow(color: AppColors.brandMain.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                : [],
          ),
          child: Center(
            child: Text(
              "$n",
              style: TextStyle(
                color: active ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? AppColors.brandMain : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool active, bool isDark) => Expanded(
    child: Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 15),
      color: active ? AppColors.brandMain : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
    ),
  );

  Widget _buildHeaderContent(Color textColor, Color subTextColor) {
    return Column(
      children: [
        Text(
          "Choose your growth",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5, color: textColor),
        ),
        const SizedBox(height: 8),
        Text(
          "Unlock premium features and boost your earnings.",
          textAlign: TextAlign.center,
          style: TextStyle(color: subTextColor, fontSize: 14),
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
          boxShadow: [
            BoxShadow(color: AppColors.brandMain.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: "Monthly"),
          Tab(text: "3 Months"),
          Tab(text: "6 Months"),
          Tab(text: "Yearly"),
        ],
      ),
    );
  }

  Widget _buildPromoField(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _hasPromoCode ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Icon(
            _hasPromoCode ? Icons.check_circle : Icons.local_offer_rounded,
            size: 20,
            color: _hasPromoCode ? Colors.green : AppColors.brandMain,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _promoController,
              style: TextStyle(color: textColor),
              enabled: !_hasPromoCode,
              decoration: InputDecoration(
                hintText: _hasPromoCode ? "Discount Applied!" : "Promo Code",
                border: InputBorder.none,
                errorText: _promoError,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: _hasPromoCode ? Colors.green : (isDark ? Colors.grey.shade500 : Colors.grey),
                ),
              ),
            ),
          ),
          if (_hasPromoCode)
            TextButton(
              onPressed: () {
                setState(() {
                  _hasPromoCode = false;
                  _promoController.clear();
                });
              },
              child: const Text("Remove", style: TextStyle(color: Colors.red)),
            )
          else
            ElevatedButton(
              onPressed: _applyPromoCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          type: PlanType.free,
          title: "Standard",
          price: curPrices[PlanType.free]!,
          color: Colors.blueGrey,
          features: ["Basic Listing", "5 Job Posts/month", "Standard Support"],
          isPopular: false,
          isCurrent: _isCurrentPlan(PlanType.free),
          onTap: () {},
          isDark: isDark,
          cardColor: cardColor,
          textColor: textColor,
        ),
        const SizedBox(height: 20),
        _singlePlanCard(
          type: PlanType.pro,
          title: "Professional",
          price: curPrices[PlanType.pro]!,
          color: Colors.blue,
          features: ["Unlimited Posts", "Profile Boost 2x", "Advanced Analytics", "Pro Badge", "Priority Email Support"],
          isPopular: true,
          isCurrent: _isCurrentPlan(PlanType.pro),
          onTap: () => _handlePurchase(PlanType.pro, _getDisplayPrice(curPrices[PlanType.pro]!)),
          isDark: isDark,
          cardColor: cardColor,
          textColor: textColor,
        ),
        const SizedBox(height: 20),
        _singlePlanCard(
          type: PlanType.business,
          title: "Business",
          price: curPrices[PlanType.business]!,
          color: Colors.deepPurple,
          features: ["Everything in Pro", "Team Management (10)", "Priority Leads", "Personal Manager", "24/7 Phone Support"],
          isPopular: false,
          isCurrent: _isCurrentPlan(PlanType.business),
          onTap: () => _handlePurchase(PlanType.business, _getDisplayPrice(curPrices[PlanType.business]!)),
          isDark: isDark,
          cardColor: cardColor,
          textColor: textColor,
        ),
      ],
    );
  }

  Widget _singlePlanCard({
    required PlanType type,
    required String title,
    required int price,
    required Color color,
    required List<String> features,
    required bool isPopular,
    required bool isCurrent,
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
        gradient: isPopular || isCurrent
            ? LinearGradient(colors: [color, color.withOpacity(0.5)])
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.1 : 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                Row(
                  children: [
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "CURRENT",
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (isPopular && !isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                        child: const Text(
                          "BEST VALUE",
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (price == 0)
                  Text("FREE", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textColor))
                else ...[
                  Text("৳$displayPrice", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textColor)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Text("/ ${_currentCycle.name}", style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey)),
                  ),
                ],
                if (_hasPromoCode && price > 0) ...[
                  const SizedBox(width: 10),
                  Text(
                    "৳$price",
                    style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.redAccent, fontSize: 16),
                  ),
                ]
              ],
            ),
            Divider(height: 30, color: isDark ? Colors.white10 : Colors.grey.shade200),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: color),
                  const SizedBox(width: 10),
                  Text(f, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.black87)),
                ],
              ),
            )),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: isCurrent ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? Colors.grey : color,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text(
                isCurrent
                    ? "Current Plan"
                    : (price == 0 ? "Downgrade" : "Get Started"),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ NEW: Feature Comparison Table
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildComparisonTable(bool isDark, Color cardColor, Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Compare Plans",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text("Feature", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    ),
                    Expanded(
                      child: Center(
                        child: Text("Free", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text("Pro", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text("Biz", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                      ),
                    ),
                  ],
                ),
              ),

              // Feature rows
              ..._planFeatures[PlanType.free]!.asMap().entries.map((entry) {
                final index = entry.key;
                final feature = entry.value['feature'] as String;
                final freeValue = _planFeatures[PlanType.free]![index];
                final proValue = _planFeatures[PlanType.pro]![index];
                final bizValue = _planFeatures[PlanType.business]![index];

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(feature, style: TextStyle(fontSize: 12, color: subTextColor)),
                      ),
                      Expanded(
                        child: Center(
                          child: _buildComparisonCell(freeValue, Colors.blueGrey),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _buildComparisonCell(proValue, Colors.blue),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _buildComparisonCell(bizValue, Colors.deepPurple),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonCell(Map<String, dynamic> data, Color color) {
    final available = data['available'] as bool;
    final value = data['value'] as String;

    if (!available) {
      return Icon(Icons.remove, size: 16, color: Colors.grey.shade400);
    }

    return Text(
      value,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      textAlign: TextAlign.center,
    );
  }

  void _handlePurchase(PlanType plan, int amount) {
    HapticFeedback.lightImpact();
    final planId = '${plan.name.toUpperCase()}_${_currentCycle.name.toUpperCase()}';
    int duration = _currentCycle == BillingCycle.monthly
        ? 1
        : _currentCycle == BillingCycle.threeMonths
        ? 3
        : _currentCycle == BillingCycle.sixMonths
        ? 6
        : 12;

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

  // ════════════════════════════════════════════════════════════════════════════
  // TESTIMONIALS (Enhanced)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildTestimonials(bool isDark, Color cardColor, Color textColor) {
    final testimonials = [
      {
        'quote': "FINDUS Pro changed my career! I get 3x more job requests now.",
        'name': "Karim",
        'role': "Electrician",
        'rating': 5,
      },
      {
        'quote': "The best platform for workers. Analytics helped me improve.",
        'name': "Rahim",
        'role': "Driver",
        'rating': 5,
      },
      {
        'quote': "Team management feature saved me so much time!",
        'name': "Alam",
        'role': "Business Owner",
        'rating': 5,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Trusted by thousands", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: testimonials.length,
            itemBuilder: (ctx, i) {
              final t = testimonials[i];
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        t['rating'] as int,
                            (_) => const Icon(Icons.star, color: Colors.amber, size: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        '"${t['quote']}"',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.grey.shade300 : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${t['name']}, ${t['role']}",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brandMain),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FAQ (Enhanced)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildFAQ(bool isDark, Color cardColor, Color textColor, Color subTextColor) {
    final faqs = [
      {
        'question': "Can I cancel anytime?",
        'answer': "Yes, you can cancel your subscription from settings at any time. Your premium features will remain active until the end of your billing period.",
      },
      {
        'question': "What happens after my subscription ends?",
        'answer': "You'll be downgraded to the free plan. All your data will be preserved, but you'll lose access to premium features.",
      },
      {
        'question': "Can I upgrade from Pro to Business?",
        'answer': "Absolutely! You can upgrade anytime. We'll prorate your remaining Pro subscription towards your Business plan.",
      },
      {
        'question': "Is there a refund policy?",
        'answer': "We offer a 7-day money-back guarantee for first-time subscribers. Contact support for assistance.",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Frequently Asked Questions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Column(
              children: faqs.asMap().entries.map((entry) {
                final i = entry.key;
                final faq = entry.value;
                return Column(
                  children: [
                    ExpansionTile(
                      title: Text(
                        faq['question']!,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                      ),
                      iconColor: AppColors.brandMain,
                      collapsedIconColor: isDark ? Colors.grey : Colors.grey.shade600,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            faq['answer']!,
                            style: TextStyle(color: subTextColor, fontSize: 13),
                          ),
                        )
                      ],
                    ),
                    if (i < faqs.length - 1)
                      Divider(
                        height: 1,
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ✅ NEW: Guarantee Badge
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildGuaranteeBadge(bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "7-Day Money Back Guarantee",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Not satisfied? Get a full refund within 7 days.",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}