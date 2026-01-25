import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

// ট্যাব পেজ ইম্পোর্ট
import 'package:findus_app/screens/tabs/work_in_progress_tab.dart';
import 'package:findus_app/screens/tabs/completed_work_tab.dart';
import 'package:findus_app/screens/tabs/achievements_tab.dart';
import 'package:findus_app/screens/tabs/leaderboard_screen.dart';

import 'dashboard/dashboard_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  static final GlobalKey<_HomeFeedScreenState> feedKey = GlobalKey<_HomeFeedScreenState>();

  static void goToTab(int index) => feedKey.currentState?._onTabTapped(index);

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen>
    with TickerProviderStateMixin {
  int _selectedTopIndex = 0;

  late PageController _pageController;
  late AnimationController _spinController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // ✅ ৫টি ট্যাবের লিস্ট (Message সরিয়ে Dashboard যুক্ত করা হয়েছে)
  final List<Widget> _tabViews = const [
    DashboardScreen(), // ✅ মেসেজের বদলে ড্যাশবোর্ড ট্যাব
    WorkInProgressTab(),
    CompletedWorkTab(),
    AchievementsTab(),
    LeaderboardScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedTopIndex);

    _spinController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _bounceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _bounceController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _spinController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_selectedTopIndex != index) {
      setState(() {
        _selectedTopIndex = index;
      });
      _bounceController.forward();
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final navBgColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- উপরের মেনু বার ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: navBgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Dashboard বাটন (Messages এর বদলে)
                  _buildTopIcon(Icons.dashboard_rounded, "Dashboard", 0, isDark),

                  _buildTopIcon(
                    Icons.settings_outlined,
                    "Working",
                    1,
                    isDark,
                    isSpinning: true,
                  ),

                  _buildTopIcon(
                    Icons.assignment_turned_in_outlined,
                    "Completed",
                    2,
                    isDark,
                  ),

                  _buildTopIcon(Icons.bar_chart_rounded, "Progress", 3, isDark),

                  _buildTopIcon(Icons.emoji_events_outlined, "Rank", 4, isDark),
                ],
              ),
            ),

            // --- বডি পার্ট (PageView) ---
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedTopIndex = index;
                  });
                  _bounceController.forward();
                },
                children: _tabViews,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIcon(
      IconData icon,
      String label,
      int index,
      bool isDark, {
        bool isSpinning = false,
      }) {
    final bool isActive = _selectedTopIndex == index;
    final activeColor = AppColors.brandMain;
    final inactiveColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    Widget iconWidget = Icon(
      icon,
      size: 24,
      color: isActive ? activeColor : inactiveColor,
    );

    if (isSpinning && isActive) {
      iconWidget = RotationTransition(
        turns: _spinController,
        child: iconWidget,
      );
    } else if (isActive) {
      iconWidget = ScaleTransition(
        scale: _bounceAnimation,
        child: iconWidget,
      );
    }

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? activeColor.withOpacity(0.3) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: iconWidget,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 65,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: isActive ? activeColor : inactiveColor,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}