import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

// ট্যাব পেজ ইম্পোর্ট
import 'package:findus_app/screens/tabs/conversation_tab.dart';
import 'package:findus_app/screens/tabs/work_in_progress_tab.dart';
import 'package:findus_app/screens/tabs/completed_work_tab.dart';
import 'package:findus_app/screens/tabs/achievements_tab.dart';
import 'package:findus_app/screens/tabs/leaderboard_screen.dart'; // ✅ নতুন ইম্পোর্ট

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

  // ✅ ৫টি ট্যাবের লিস্ট (Save সরিয়ে Leaderboard যুক্ত করা হয়েছে)
  final List<Widget> _tabViews = const [
    ConversationTab(),
    WorkInProgressTab(),
    CompletedWorkTab(),
    AchievementsTab(),
    LeaderboardScreen(), // ✅ নতুন ট্যাব
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
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      body: SafeArea(
        child: Column(
          children: [
            // --- উপরের মেনু বার ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.bgBlue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopIcon(Icons.chat_bubble_outline, "Messages", 0), // ✅ Typo fixed

                  _buildTopIcon(
                    Icons.settings_outlined,
                    "Working",
                    1,
                    isSpinning: true,
                  ),

                  _buildTopIcon(
                    Icons.assignment_turned_in_outlined,
                    "Completed",
                    2,
                  ),

                  _buildTopIcon(Icons.bar_chart_rounded, "Progress", 3),

                  // ✅ Leaderboard বাটন যুক্ত করা হলো
                  _buildTopIcon(Icons.emoji_events_outlined, "Rank", 4),
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
      int index, {
        bool isSpinning = false,
      }) {
    final bool isActive = _selectedTopIndex == index;

    Widget iconWidget = Icon(
      icon,
      size: 24, // ✅ আইকন সাইজ একটু ছোট করা হয়েছে যাতে ৫টি ঠিকমতো ধরে
      color: isActive ? Colors.cyan[800] : Colors.grey[600],
    );

    if (isSpinning) {
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
            padding: const EdgeInsets.all(8), // ✅ প্যাডিং ১০ থেকে ৮ করা হয়েছে
            decoration: BoxDecoration(
              color: isActive ? Colors.cyan.shade50 : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? Colors.cyan : Colors.transparent,
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
                fontSize: 9, // ✅ ফন্ট সাইজ ১০ থেকে ৯ করা হয়েছে
                color: isActive ? Colors.cyan[900] : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}