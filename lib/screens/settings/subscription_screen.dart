import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:findus_app/wallet/payment_screen.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PlanType { free, pro, business }
enum BillingCycle { monthly, threeMonths, sixMonths, yearly }

// টেস্টিমোনিয়াল মডেল
class Testimonial {
  final String text;
  final String name;
  final String role;

  Testimonial(this.text, this.name, this.role);
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BillingCycle _currentCycle = BillingCycle.monthly;
  bool _hasPromoCode = false;
  TextEditingController _promoController = TextEditingController();
  int _currentStep = 0;
  String? _promoError;

  // প্রতি billing cycle-এর জন্য প্ল্যান অনুযায়ী দাম
  final Map<BillingCycle, Map<PlanType, int>> _prices = {
    BillingCycle.monthly: {
      PlanType.free: 0,
      PlanType.pro: 199,
      PlanType.business: 499,
    },
    BillingCycle.threeMonths: {
      PlanType.free: 0,
      PlanType.pro: 549,
      PlanType.business: 1399,
    },
    BillingCycle.sixMonths: {
      PlanType.free: 0,
      PlanType.pro: 999,
      PlanType.business: 2599,
    },
    BillingCycle.yearly: {
      PlanType.free: 0,
      PlanType.pro: 1799,
      PlanType.business: 4599,
    },
  };

  // টেস্টিমোনিয়াল ডেটা
  final List<Testimonial> _testimonials = [
    Testimonial(
      "FINDUS Pro helped me get 3x more jobs. Best investment for my business!",
      "Abdul Karim",
      "Electrician",
    ),
    Testimonial(
      "As a team leader, the Business Plan dashboard saves me hours every week.",
      "Rahima Akter",
      "Cleaning Service",
    ),
    Testimonial(
      "The priority support is amazing. They solve issues within minutes!",
      "Sajid Hossain",
      "Delivery Rider",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: 0,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _currentCycle = BillingCycle.values[_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromoCode() {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _promoError = "Please enter a promo code";
      });
      return;
    }

    if (code == "FINDUS25") {
      setState(() {
        _hasPromoCode = true;
        _promoError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎉 25% discount applied successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _promoError = "Invalid promo code";
        _hasPromoCode = false;
      });
    }
  }

  // ডিসকাউন্ট প্রাইস ক্যালকুলেশন
  int _getDiscountedPrice(int originalPrice) {
    if (_hasPromoCode) {
      return (originalPrice * 0.75).round(); // 25% discount
    }
    return originalPrice;
  }

  // সেভিংস ক্যালকুলেশন
  int _calculateSavings(PlanType plan, BillingCycle cycle) {
    if (cycle == BillingCycle.yearly) {
      final monthlyPrice = _prices[BillingCycle.monthly]![plan]! * 12;
      final yearlyPrice = _prices[BillingCycle.yearly]![plan]!;
      return monthlyPrice - yearlyPrice;
    } else if (cycle == BillingCycle.sixMonths) {
      final monthlyPrice = _prices[BillingCycle.monthly]![plan]! * 6;
      final sixMonthPrice = _prices[BillingCycle.sixMonths]![plan]!;
      return monthlyPrice - sixMonthPrice;
    } else if (cycle == BillingCycle.threeMonths) {
      final monthlyPrice = _prices[BillingCycle.monthly]![plan]! * 3;
      final threeMonthPrice = _prices[BillingCycle.threeMonths]![plan]!;
      return monthlyPrice - threeMonthPrice;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Indicator
                _buildStepIndicator(),
                const SizedBox(height: 20),

                // Header
                Text(
                  'Upgrade your FINDUS experience',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select your billing cycle and pick a plan that fits your work.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.brandDark.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),

                // Social Proof
                _buildSocialProof(),
                const SizedBox(height: 20),

                // Billing Tabs
                _buildBillingTabs(theme),
                const SizedBox(height: 16),

                // Promo Code Section
                _buildPromoCodeSection(),
                const SizedBox(height: 16),

                // All Plan Cards
                _buildAllPlanCards(context),
                const SizedBox(height: 24),

                // Testimonials
                _buildTestimonialsSection(),
                const SizedBox(height: 24),

                // FAQ Section
                _buildFaqSection(),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Floating AppBar (KYC-style)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          // Back Button
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.brandDark,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),

                          // Title
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: const Text(
                                  "FINDUS Subscription",
                                  style: TextStyle(
                                    color: AppColors.brandDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Step Indicator ----------
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStepCircle(1, "Select Plan", true),
        Container(
          height: 2,
          width: 40,
          color: AppColors.brandMain,
        ),
        _buildStepCircle(2, "Payment", false),
        Container(
          height: 2,
          width: 40,
          color: Colors.grey[300],
        ),
        _buildStepCircle(3, "Activate", false),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? AppColors.brandMain : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.brandMain : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ---------- Social Proof ----------
  Widget _buildSocialProof() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.brandLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.people_alt_outlined, color: AppColors.brandMain, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.brandDark,
                  fontSize: 12,
                ),
                children: [
                  const TextSpan(
                    text: "1000+ ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: "active subscribers • "),
                  TextSpan(
                    text: "12 ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandMain,
                    ),
                  ),
                  const TextSpan(text: "upgraded today"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Billing Tabs ----------
  Widget _buildBillingTabs(ThemeData theme) {
    final labels = ['Monthly', '3 Months', '6 Months', 'Yearly'];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = _tabController.index == index;
          final cycle = BillingCycle.values[index];
          final hasSavings = _calculateSavings(PlanType.pro, cycle) > 0;

          return Expanded(
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.brandMain : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.brandMain
                          : AppColors.brandMain.withOpacity(0.3),
                      width: 1.3,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      _tabController.animateTo(index);
                      setState(() {
                        _currentCycle = cycle;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              labels[index],
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.brandDark,
                              ),
                            ),
                            if (hasSavings)
                              Text(
                                "Save ${_calculateSavings(PlanType.pro, cycle)}৳",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isSelected ? Colors.white : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ---------- Promo Code Section ----------
  Widget _buildPromoCodeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandMain.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer_outlined, color: AppColors.brandMain),
              const SizedBox(width: 8),
              const Text(
                "Have a promo code?",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    hintText: "Enter promo code",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    errorText: _promoError,
                    suffixIcon: _hasPromoCode
                        ? Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _applyPromoCode,
                child: const Text(
                  "Apply",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          if (_hasPromoCode)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "✅ 25% discount applied to all plans!",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------- All Plan Cards ----------
  Widget _buildAllPlanCards(BuildContext context) {
    final pricesForCycle = _prices[_currentCycle]!;

    return Column(
      children: [
        // Free
        _buildPlanCard(
          context: context,
          planType: PlanType.free,
          title: 'Free Plan',
          subtitle: 'Perfect for getting started',
          price: pricesForCycle[PlanType.free]!,
          cycle: _currentCycle,
          features: const [
            'Basic listing in local search',
            'Ratings and reviews on profile',
            'Up to 5 active job posts',
            'Standard customer support',
          ],
          backgroundColor: Colors.white,
          onPurchase: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You are already on the Free Plan.'),
                backgroundColor: Colors.blue,
              ),
            );
          },
          isCurrentPlan: true,
        ),
        const SizedBox(height: 16),

        // Pro
        _buildPlanCard(
          context: context,
          planType: PlanType.pro,
          title: 'FINDUS Pro',
          subtitle: 'Best for serious professionals',
          price: pricesForCycle[PlanType.pro]!,
          cycle: _currentCycle,
          features: const [
            'Higher ranking in search results',
            '"Suggested for you" priority',
            'Unlimited job posts',
            'Advanced analytics dashboard',
            'Pro badge on profile',
            'Priority email & chat support',
          ],
          backgroundColor: AppColors.brandLight,
          highlightBorder: AppColors.brandMain,
          isPopular: true,
          onPurchase: () {
            final planId = _buildPlanId(PlanType.pro, _currentCycle);
            final durationInMonths = _cycleToMonths(_currentCycle);
            final discountedPrice = _getDiscountedPrice(pricesForCycle[PlanType.pro]!);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentScreen(
                  planId: planId,
                  amount: discountedPrice,
                  duration: durationInMonths,
                  purpose: PaymentPurpose.subscription,
                  description: 'FINDUS Pro subscription',
                  onPaymentSuccess: () {
                    // Payment সফল হলে Activation পেজে যাবে
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActivationScreen(
                          planType: PlanType.pro,
                          durationInMonths: durationInMonths,
                          amount: discountedPrice,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Business
        _buildPlanCard(
          context: context,
          planType: PlanType.business,
          title: 'Business Plan',
          subtitle: 'For teams and agencies',
          price: pricesForCycle[PlanType.business]!,
          cycle: _currentCycle,
          features: const [
            'Manage up to 10 team members',
            'Team performance dashboard',
            'Bulk job posting tools',
            'Custom reporting & analytics',
            'Dedicated account manager',
            '24/7 priority phone support',
          ],
          backgroundColor: Color(0xFFE8F5E9),
          highlightBorder: AppColors.brandDark,
          onPurchase: () {
            final planId = _buildPlanId(PlanType.business, _currentCycle);
            final durationInMonths = _cycleToMonths(_currentCycle);
            final discountedPrice = _getDiscountedPrice(pricesForCycle[PlanType.business]!);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentScreen(
                  planId: planId,
                  amount: discountedPrice,
                  duration: durationInMonths,
                  purpose: PaymentPurpose.subscription,
                  description: 'FINDUS Business subscription',
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------- Single Plan Card ----------
  Widget _buildPlanCard({
    required BuildContext context,
    required PlanType planType,
    required String title,
    required String subtitle,
    required int price,
    required BillingCycle cycle,
    required List<String> features,
    required Color backgroundColor,
    Color? highlightBorder,
    bool isPopular = false,
    bool isCurrentPlan = false,
    required VoidCallback onPurchase,
  }) {
    final theme = Theme.of(context);
    final String durationLabel = _cycleLabel(cycle);
    final int savings = _calculateSavings(planType, cycle);
    final int discountedPrice = _getDiscountedPrice(price);
    final String priceLabel = _hasPromoCode
        ? '৳${discountedPrice} / $durationLabel'
        : '৳$price / $durationLabel';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      constraints: BoxConstraints(minHeight: 520), // Height আরও বাড়ানো হয়েছে
      child: Stack(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: backgroundColor,
            elevation: isPopular ? 6 : 3,
            shadowColor: isPopular ? AppColors.brandMain.withOpacity(0.3) : Colors.black12,
            child: Container(
              height: 500, // কার্ডের height বাড়ানো হয়েছে
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: highlightBorder ?? Colors.transparent,
                  width: highlightBorder != null ? 2 : 0,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title + Badges
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brandDark,
                                    fontSize: 22,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.brandDark.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isPopular)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.brandMain, Color(0xFFFF6B6B)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '🔥 MOST POPULAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Price & Savings
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            priceLabel,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                              color: planType == PlanType.free
                                  ? AppColors.brandDark
                                  : AppColors.brandMain,
                            ),
                          ),
                          SizedBox(height: 8),
                          if (_hasPromoCode && planType != PlanType.free)
                            Row(
                              children: [
                                Text(
                                  '৳$price',
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '25% OFF',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (savings > 0 && planType != PlanType.free && !_hasPromoCode)
                            Text(
                              'Save ৳$savings compared to monthly',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Features - Expandable container
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: features.map(
                              (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: AppColors.brandMain,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    f,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.brandDark,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).toList(),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Purchase Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCurrentPlan
                            ? Colors.grey[400]
                            : AppColors.brandMain,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onPurchase,
                      child: Text(
                        isCurrentPlan ? 'Current Plan' : 'Choose Plan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 30-day guarantee badge - এখন ভিতরে থাকবে
          if (planType != PlanType.free)
            Positioned(
              top: 15, // top: -8 থেকে 15 করা হয়েছে
              right: 15, // right: 16 থেকে 15 করা হয়েছে
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  '30-day money-back',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------- Testimonials ----------
  Widget _buildTestimonialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "What our subscribers say",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.brandDark,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _testimonials.length,
            itemBuilder: (context, index) {
              final testimonial = _testimonials[index];
              return Container(
                width: 280,
                margin: EdgeInsets.only(right: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: AppColors.brandMain.withOpacity(0.5),
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        testimonial.text,
                        style: TextStyle(
                          color: AppColors.brandDark,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.brandMain,
                          child: Text(
                            testimonial.name[0],
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              testimonial.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              testimonial.role,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  // ---------- FAQ Section ----------
  Widget _buildFaqSection() {
    final faqs = [
      {
        'q': 'Can I cancel anytime?',
        'a': 'Yes, you can cancel your subscription anytime. Your plan will remain active until the end of your billing period.'
      },
      {
        'q': 'Do you offer refunds?',
        'a': 'We offer a 30-day money-back guarantee. If you\'re not satisfied, contact us within 30 days for a full refund.'
      },
      {
        'q': 'Will my price increase later?',
        'a': 'The price you sign up for is guaranteed for the duration of your subscription term. Any price changes will only apply to renewals.'
      },
      {
        'q': 'Can I switch between plans?',
        'a': 'Yes, you can upgrade or downgrade your plan anytime. The change will be prorated based on your remaining subscription period.'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Frequently Asked Questions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.brandDark,
          ),
        ),
        const SizedBox(height: 12),
        ...faqs.map((faq) {
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                faq['q']!,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    faq['a']!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------- Helper Functions ----------

  String _cycleLabel(BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.monthly:
        return 'month';
      case BillingCycle.threeMonths:
        return '3 months';
      case BillingCycle.sixMonths:
        return '6 months';
      case BillingCycle.yearly:
        return 'year';
    }
  }

  int _cycleToMonths(BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.monthly:
        return 1;
      case BillingCycle.threeMonths:
        return 3;
      case BillingCycle.sixMonths:
        return 6;
      case BillingCycle.yearly:
        return 12;
    }
  }

  String _buildPlanId(PlanType plan, BillingCycle cycle) {
    String planStr;
    String durStr;

    // Plan string
    switch (plan) {
      case PlanType.free:
        planStr = 'FREE';
        break;
      case PlanType.pro:
        planStr = 'PRO';
        break;
      case PlanType.business:
        planStr = 'BUSINESS';
        break;
    }

    // Duration string
    switch (cycle) {
      case BillingCycle.monthly:
        durStr = '1M';
        break;
      case BillingCycle.threeMonths:
        durStr = '3M';
        break;
      case BillingCycle.sixMonths:
        durStr = '6M';
        break;
      case BillingCycle.yearly:
        durStr = '12M';
        break;
    }

    return '${planStr}_$durStr';
  }
}

// ফাইলের নিচে এই class টি যোগ করুন
class ActivationScreen extends StatefulWidget {
  final PlanType planType;
  final int durationInMonths;
  final int amount;

  const ActivationScreen({
    super.key,
    required this.planType,
    required this.durationInMonths,
    required this.amount,
  });

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  bool _isActivating = false;
  bool _isActivated = false;

  @override
  void initState() {
    super.initState();
    // 2 সেকেন্ড পর অ্যাক্টিভেট হবে (এটা আসলে Backend API কল হবে)
    _activateSubscription();
  }

  Future<void> _activateSubscription() async {
    setState(() {
      _isActivating = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    try {
      // TODO: এখানে তোমার Backend API call হবে
      // Firebase/Firestore এ subscription activate করবে

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'subscription_plan': widget.planType.toString(),
          'subscription_start_date': FieldValue.serverTimestamp(),
          'subscription_end_date': _calculateEndDate(),
          'subscription_amount': widget.amount,
          'subscription_status': 'active',
        }, SetOptions(merge: true));
      }

      // SharedPreferences এও সেভ করতে পারো
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscription_plan', widget.planType.toString());
      await prefs.setBool('has_active_subscription', true);

      setState(() {
        _isActivating = false;
        _isActivated = true;
      });

    } catch (e) {
      setState(() {
        _isActivating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  DateTime _calculateEndDate() {
    final now = DateTime.now();
    return now.add(Duration(days: widget.durationInMonths * 30));
  }

  String _getPlanName() {
    switch (widget.planType) {
      case PlanType.free:
        return 'Free Plan';
      case PlanType.pro:
        return 'FINDUS Pro';
      case PlanType.business:
        return 'Business Plan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),

                // Success Icon/Lottie Animation
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandMain.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Colors.green,
                  ),
                ),

                SizedBox(height: 30),

                Text(
                  _isActivated ? 'Activated Successfully!' : 'Activating Your Plan...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  _getPlanName(),
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.brandMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Duration: ${widget.durationInMonths} month${widget.durationInMonths > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Amount: ৳${widget.amount}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),

                SizedBox(height: 40),

                if (_isActivating)
                  Column(
                    children: [
                      CircularProgressIndicator(
                        color: AppColors.brandMain,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Please wait while we activate your subscription...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                if (_isActivated)
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.celebration, color: Colors.green, size: 30),
                            SizedBox(height: 12),
                            Text(
                              'Congratulations!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your subscription is now active. You can enjoy all premium features.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      // Next Steps
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What\'s Next?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.brandDark,
                              ),
                            ),
                            SizedBox(height: 12),
                            _buildNextStep(
                              icon: Icons.rocket_launch,
                              title: 'Explore Premium Features',
                              description: 'Check out your new dashboard',
                            ),
                            _buildNextStep(
                              icon: Icons.settings,
                              title: 'Configure Preferences',
                              description: 'Set up your account settings',
                            ),
                            _buildNextStep(
                              icon: Icons.help_center,
                              title: 'Need Help?',
                              description: 'Visit our help center',
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      // Action Buttons
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandMain,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                // হোম স্ক্রিনে ফিরে যাবে
                                Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/home',
                                        (route) => false
                                );
                              },
                              child: Text(
                                'Go to Dashboard',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.brandMain),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context); // Back to subscription screen
                              },
                              child: Text(
                                'Back to Plans',
                                style: TextStyle(
                                  color: AppColors.brandMain,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Floating AppBar
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.brandDark,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: const Text(
                                  "Activation",
                                  style: TextStyle(
                                    color: AppColors.brandDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brandMain, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
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