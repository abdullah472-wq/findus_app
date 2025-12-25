import 'package:flutter/material.dart';
import 'package:findus_app/wallet/payment_screen.dart';
import 'package:findus_app/constants/app_colors.dart';

enum PlanType { free, pro, business }
enum BillingCycle { monthly, threeMonths, sixMonths, yearly }

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BillingCycle _currentCycle = BillingCycle.monthly;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.brandLight,
        title: const Text('FINDUS Subscription'),
      ),
      backgroundColor: AppColors.bgBlue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // উপরে ছোট টেক্সট: Upgrade your FINDUS
            Text(
              'Upgrade your FINDUS experience',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select your billing cycle and pick a plan that fits your work.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.brandDark.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),

            _buildBillingTabs(theme),       // ট্যাব
            const SizedBox(height: 16),
            _buildAllPlanCards(context),    // ৩টা প্ল্যান কার্ড
          ],
        ),
      ),
    );
  }

  // ---------- সুন্দর styled Billing Tabs ----------

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
          return Expanded(
            child: AnimatedContainer(
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
                    _currentCycle = BillingCycle.values[index];
                  });
                },
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Center(
                    child: Text(
                      labels[index],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                        color:
                        isSelected ? Colors.white : AppColors.brandDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------- ৩টা প্ল্যান কার্ড ----------

  Widget _buildAllPlanCards(BuildContext context) {
    final pricesForCycle = _prices[_currentCycle]!;

    return Column(
      children: [
        // Free
        _buildPlanCard(
          context: context,
          planType: PlanType.free,
          title: 'Free Plan',
          subtitle: 'Basic visibility for individual workers.',
          price: pricesForCycle[PlanType.free]!,
          cycle: _currentCycle,
          features: const [
            'Basic listing in local search.',
            'Ratings and reviews on your profile.',
            'No subscription fee.',
          ],
          backgroundColor: Colors.white38,
          onPurchase: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You are using the Free Plan.'),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Pro
        _buildPlanCard(
          context: context,
          planType: PlanType.pro,
          title: 'FINDUS Pro',
          subtitle: 'Higher visibility and priority for workers.',
          price: pricesForCycle[PlanType.pro]!,
          cycle: _currentCycle,
          features: const [
            'Higher ranking in local search results.',
            '"Suggested for you" priority.',
            'Advanced search filter.',
            'Unlimited job requests.',
            'Pro badge on your profile.',
            'Priority support.',
          ],
          backgroundColor: AppColors.brandLight,
          highlightBorder: AppColors.brandMain,
          isPopular: true,
          onPurchase: () {
            final planId = _buildPlanId(PlanType.pro, _currentCycle);
            final durationInMonths = _cycleToMonths(_currentCycle);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentScreen(
                  planId: planId,
                  amount: pricesForCycle[PlanType.pro]!,
                  duration: durationInMonths,
                  purpose: PaymentPurpose.subscription,          // <<< এটা নতুন
                  description: 'FINDUS Pro subscription',       // optional
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
          subtitle: 'For teams, agencies and businesses.',
          price: pricesForCycle[PlanType.business]!,
          cycle: _currentCycle,
          features: const [
            'Manage multiple workers in one account.',
            'Assign jobs to specific team members.',
            'Team dashboard (jobs & earnings).',
            'Custom reporting & analytics.',
            'Highest support priority.',
          ],
          backgroundColor: AppColors.cardPink,
          highlightBorder: AppColors.brandDark,
          onPurchase: () {
            final planId = _buildPlanId(PlanType.business, _currentCycle);
            final durationInMonths = _cycleToMonths(_currentCycle);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentScreen(
                  planId: planId,
                  amount: pricesForCycle[PlanType.business]!,
                  duration: durationInMonths,
                  purpose: PaymentPurpose.subscription,          // <<< এটা নতুন
                  description: 'FINDUS Pro subscription',       // optional
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ---------- সিঙ্গেল প্ল্যান কার্ড ----------

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
    required VoidCallback onPurchase,
  }) {
    final theme = Theme.of(context);
    final String durationLabel = _cycleLabel(cycle);
    final String priceLabel = '৳$price / $durationLabel';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: backgroundColor,
      elevation: 3,
      shadowColor: Colors.black12,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlightBorder ?? Colors.transparent,
            width: highlightBorder != null ? 2 : 0,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Popular badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandDark,
                    ),
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandMain.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Popular',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.brandMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 12),

            // Price
            Text(
              priceLabel,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: planType == PlanType.free
                    ? AppColors.brandDark
                    : AppColors.brandMain,
              ),
            ),
            const SizedBox(height: 12),

            // Features
            ...features.map(
                  (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.brandDark,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        f,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.brandDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Purchase Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onPurchase,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('Purchase'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Helpers ----------

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