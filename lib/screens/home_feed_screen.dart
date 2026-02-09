import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';

// ট্যাব পেজ ইম্পোর্ট
import 'package:findus_app/screens/tabs/work_in_progress_tab.dart';
import 'package:findus_app/screens/tabs/completed_work_tab.dart';
import 'package:findus_app/screens/tabs/achievements_tab.dart';
import 'package:findus_app/screens/tabs/leaderboard_screen.dart';
import 'package:findus_app/screens/dashboard/dashboard_screen.dart';
import 'package:findus_app/achievement/achievement_service.dart'; // Achievement

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  static final GlobalKey<_HomeFeedScreenState> feedKey = GlobalKey<_HomeFeedScreenState>();

  static void goToTab(int index) => feedKey.currentState?._onTabTapped(index);

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> with TickerProviderStateMixin {
  int _selectedTopIndex = 0;

  late PageController _pageController;
  late AnimationController _spinController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // 🔴 Badge Counts
  int _claimableQuestCount = 0;
  int _ongoingActionCount = 0; // Jobs needing completion
  int _pendingReviewCount = 0;

  final List<Widget> _tabViews = const [
    DashboardScreen(),
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

    // ✅ Listeners Init
    AchievementService.achievementsNotifier.addListener(_updateQuestBadge);
    _listenToJobStatus();
    _updateQuestBadge(); // Initial Load
  }

  @override
  void dispose() {
    AchievementService.achievementsNotifier.removeListener(_updateQuestBadge);
    _pageController.dispose();
    _spinController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  // ✅ 1. Quest Badge Logic
  void _updateQuestBadge() {
    final count = AchievementService.achievementsNotifier.value
        .where((st) => st.isCompleted && !st.claimed)
        .length;
    if (mounted && count != _claimableQuestCount) {
      setState(() => _claimableQuestCount = count);
    }
  }

  // ✅ 2. Job Status Listener (Ongoing & Review)
  void _listenToJobStatus() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // A. Ongoing Jobs (Check if user needs to mark complete)
    FirebaseFirestore.instance
        .collection('ongoing_jobs')
        .where('participants', arrayContains: uid)
        .where('status', isEqualTo: 'ongoing')
        .snapshots()
        .listen((snap) {
      int actionCount = 0;
      for (var doc in snap.docs) {
        // যদি আমি রিসিভার (Finder) হই, তবে আমাকে কমপ্লিট করতে হবে
        if (doc['receiverId'] == uid) {
          actionCount++;
        }
      }
      if (mounted) setState(() => _ongoingActionCount = actionCount);
    });

    // B. Pending Reviews (Completed Jobs)
    // Note: This logic assumes if I haven't reviewed yet.
    // To do this perfectly, you need a subcollection check.
    // For simplicity, we can just check 'user_stats' -> 'reviewsGiven' vs 'jobsCompleted' count logic
    // OR just leave it manual.
    // Here using a simplified placeholder logic:
    /*
    FirebaseFirestore.instance
        .collection('completed_jobs')
        .where('participants', arrayContains: uid)
        .orderBy('completedAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snap) {
           // Logic to check if review given... (skipping complex query for now)
           // You can implement this later.
    });
    */
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
                  _buildTopIcon(Icons.dashboard_rounded, "Dashboard", 0, isDark),

                  _buildTopIcon(
                    Icons.settings_outlined,
                    "Working",
                    1,
                    isDark,
                    isSpinning: true,
                    badgeCount: _ongoingActionCount, // 🔴 Badge
                  ),

                  _buildTopIcon(
                    Icons.assignment_turned_in_outlined,
                    "Completed",
                    2,
                    isDark,
                    badgeCount: _pendingReviewCount, // 🔴 Badge (Future impl)
                  ),

                  _buildTopIcon(
                    Icons.bar_chart_rounded,
                    "Progress",
                    3,
                    isDark,
                    badgeCount: _claimableQuestCount, // 🔴 Badge
                  ),

                  _buildTopIcon(Icons.emoji_events_outlined, "Rank", 4, isDark),
                ],
              ),
            ),

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
        int badgeCount = 0, // ✅ New Parameter
      }) {
    final bool isActive = _selectedTopIndex == index;
    const activeColor = AppColors.brandMain;
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
          Stack(
            clipBehavior: Clip.none,
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

              // ✅ Badge UI Logic
              if (badgeCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? Colors.black : Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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