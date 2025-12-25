import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

// ট্যাব পেজ ইম্পোর্ট
import 'package:findus_app/screens/tabs/conversation_tab.dart';
import 'package:findus_app/screens/tabs/work_in_progress_tab.dart';
import 'package:findus_app/screens/tabs/completed_work_tab.dart';
import 'package:findus_app/screens/tabs/achievements_tab.dart';
import 'package:findus_app/screens/tabs/save_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen>
    with TickerProviderStateMixin {
  int _selectedTopIndex = 0;

  // নিচের PageView এর জন্য controller – swipe এ tab change হবে
  late PageController _pageController;

  // স্পিনিং কন্ট্রোলার (Working আইকনের জন্য)
  late AnimationController _spinController;

  // বাউন্স কন্ট্রোলার (অন্যান্য আইকনের জন্য)
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // ৫টি ট্যাবের লিস্ট
  final List<Widget> _tabViews = const [
    ConversationTab(),
    WorkInProgressTab(),
    CompletedWorkTab(),
    AchievementsTab(),
    SaveScreen(),
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: _selectedTopIndex);

    // ১. স্পিনিং অ্যানিমেশন (Working আইকনের জন্য)
    _spinController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // ২. বাউন্স অ্যানিমেশন (ক্লিক ইফেক্টের জন্য)
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
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

  // ট্যাব চেঞ্জ হ্যান্ডলার (উপরের আইকনে tap করলে)
  void _onTabTapped(int index) {
    if (_selectedTopIndex != index) {
      setState(() {
        _selectedTopIndex = index;
      });
      _bounceController.forward();

      // নিচের PageView কে animate করে ওই পেজে নিয়ে যাবে
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
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
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
                  _buildTopIcon(Icons.chat_bubble_outline, "Massage", 0),

                  // Working আইকন (Spinning)
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
                  _buildTopIcon(Icons.bar_chart, "Progress", 3),
                  _buildTopIcon(Icons.bookmark_border, "Saved", 4),
                ],
              ),
            ),

            // --- বডি পার্ট (PageView দিয়ে swipeable tabs) ---
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  // swipe করলে index change হবে
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

  // আইকন বিল্ডার
  Widget _buildTopIcon(
      IconData icon,
      String label,
      int index, {
        bool isSpinning = false,
      }) {
    final bool isActive = _selectedTopIndex == index;

    // বেস আইকন উইজেট
    Widget iconWidget = Icon(
      icon,
      size: 26,
      color: isActive ? Colors.cyan[800] : Colors.grey[600],
    );

    // স্পিনিং লজিক (Working Tab)
    if (isSpinning) {
      iconWidget = RotationTransition(
        turns: _spinController,
        child: iconWidget,
      );
    }
    // বাউন্স লজিক (অন্যান্য Tab - যদি সিলেক্টেড হয়)
    else if (isActive) {
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? Colors.cyan.shade50 : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isActive ? Colors.cyan : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: iconWidget,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 65,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color:
                isActive ? Colors.cyan[900] : Colors.grey[600],
                fontWeight:
                isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}