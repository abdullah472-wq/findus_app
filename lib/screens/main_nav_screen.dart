// lib/screens/main_nav_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findus_app/constants/app_colors.dart';

// Imports
import 'home_feed_screen.dart';
import 'explore/explore_screen.dart';
import 'tabs/conversation_tab.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/auth/log_in_chacker_screen.dart';
import 'package:findus_app/achievement/achievement_service.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  static final GlobalKey<_MainNavScreenState> navKey = GlobalKey<_MainNavScreenState>();

  static void goToHomeTab() => navKey.currentState?._goToTab(0);
  static void goToExploreTab() => navKey.currentState?._goToTab(1);
  static void goToMessagesTab() => navKey.currentState?._goToTab(2);
  static void goToProfileTab() => navKey.currentState?._goToTab(3);

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 1;
  final PageController _pageController = PageController(initialPage: 1);

  // 🔴 ব্যাজ ভেরিয়েবলস
  int unreadMessagesCount = 0;
  bool showHomeRedDot = false; // শুধু ডট দেখানোর জন্য

  @override
  void initState() {
    super.initState();
    _handleDailyCheckIn();

    // ✅ ১. সব লিসেনার একসাথে শুরু
    AchievementService.achievementsNotifier.addListener(_checkHomeRedDot);
    _listenToJobStatus(); // জব এবং রিভিউ স্ট্যাটাস লিসেনার
  }

  @override
  void dispose() {
    AchievementService.achievementsNotifier.removeListener(_checkHomeRedDot);
    super.dispose();
  }

  // ✅ ২. জব এবং রিভিউ স্ট্যাটাস চেক করা (Firestore Stream)
  void _listenToJobStatus() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // A. Pending Completion (Work In Progress)
    FirebaseFirestore.instance
        .collection('ongoing_jobs')
        .where('participants', arrayContains: uid)
        .where('status', isEqualTo: 'ongoing')
        .snapshots()
        .listen((snap) {
      _checkHomeRedDot(); // ডাটা চেঞ্জ হলে চেক করবে
    });

    // B. Pending Review (Completed Jobs)
    FirebaseFirestore.instance
        .collection('completed_jobs')
        .where('participants', arrayContains: uid)
        .orderBy('completedAt', descending: true)
        .limit(10) // অপ্টিমাইজেশনের জন্য লিমিট
        .snapshots()
        .listen((snap) {
      _checkHomeRedDot();
    });
  }

  // ✅ ৩. হোম ট্যাবে লাল ডট দেখানোর লজিক
  Future<void> _checkHomeRedDot() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    bool hasClaimableQuest = false;
    bool hasPendingJobCompletion = false;
    bool hasPendingReview = false;

    // ১. কোয়েস্ট চেক
    final allAchievements = AchievementService.achievementsNotifier.value;
    hasClaimableQuest = allAchievements.any((st) => st.isCompleted && !st.claimed);

    // ২. জব কমপ্লিশন চেক (আপনি যদি রিসিভার হন এবং জবটি অনগোইং থাকে)
    // এটি স্ট্রিম থেকে চেক করা ভালো, তবে এখানে স্ন্যাপশট দিয়ে চেক করছি
    final ongoingSnap = await FirebaseFirestore.instance
        .collection('ongoing_jobs')
        .where('receiverId', isEqualTo: uid) // শুধু Finder কমপ্লিট করতে পারে
        .where('status', isEqualTo: 'ongoing')
        .get();

    if (ongoingSnap.docs.isNotEmpty) {
      // এখানে আরও লজিক থাকতে পারে (যেমন কাজ শেষ হয়েছে কি না), আপাতত ধরে নিচ্ছি অনগোইং থাকলেই এটেনশন দরকার
      // অথবা আপনি স্পেসিফিক ফিল্ড চেক করতে পারেন
      hasPendingJobCompletion = true;
    }

    // ৩. রিভিউ চেক (কমপ্লিট হয়েছে কিন্তু রিভিউ দেননি)
    // এটি চেক করা একটু জটিল কারণ রিভিউ কালেকশন আলাদা।
    // সহজ উপায়: user_stats এ 'pendingReviews' নামে ফিল্ড রাখা।
    // অথবা এখানে ম্যানুয়ালি চেক করা:
    /*
    final completedSnap = await FirebaseFirestore.instance
        .collection('completed_jobs')
        .where('participants', arrayContains: uid)
        .get();

    // রিভিউ দেওয়া হয়েছে কি না চেক করতে হবে (এটি সার্ভার সাইডে অপ্টিমাইজড হওয়া উচিত)
    */

    // সব লজিক মিলিয়ে
    if (mounted) {
      setState(() {
        showHomeRedDot = hasClaimableQuest || hasPendingJobCompletion; // || hasPendingReview
      });
    }
  }

  Future<void> _handleDailyCheckIn() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await AchievementService.incrementProgress('daily_login', amount: 1);
      await AchievementService.syncWeeklyChestFromServer();
    }
  }

  void _goToTab(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F0F) : AppColors.bgBlue;

    return PopScope(
      canPop: _currentIndex == 1,
      onPopInvoked: (didPop) {
        if (!didPop && _currentIndex != 1) {
          _goToTab(1);
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: bgColor,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            uid != null
                ? HomeFeedScreen(key: HomeFeedScreen.feedKey)
                : const ProfileNotLoggedIn(title: "Home Feed", showBackButton: false),
            const ExploreScreen(),
            const ConversationTab(),
            uid != null
                ? UnifiedProfileScreen(uid: uid, isOwner: true, showBack: false)
                : const ProfileNotLoggedIn(title: "Your Profile", showBackButton: false),
          ],
        ),
        bottomNavigationBar: _buildModernNavBar(isDark),
      ),
    );
  }

  Widget _buildModernNavBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 25),
      height: 75,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // ✅ Home Tab - Red Dot Only
                _NavItem(
                    index: 0,
                    currentIndex: _currentIndex,
                    activeIcon: Icons.home_rounded,
                    inactiveIcon: Icons.home_outlined,
                    label: 'Home',
                    showRedDot: showHomeRedDot, // 🔴 শুধু ডট পাঠানো হচ্ছে
                    onTap: _goToTab
                ),

                _NavItem(index: 1, currentIndex: _currentIndex, activeIcon: Icons.explore_rounded, inactiveIcon: Icons.explore_outlined, label: 'Explore', onTap: _goToTab),

                _NavItem(index: 2, currentIndex: _currentIndex, activeIcon: Icons.chat_bubble_rounded, inactiveIcon: Icons.chat_bubble_outline, label: 'Chat', badgeCount: unreadMessagesCount, onTap: _goToTab),

                _NavItem(index: 3, currentIndex: _currentIndex, activeIcon: Icons.person_rounded, inactiveIcon: Icons.person_outline, label: 'Profile', onTap: _goToTab),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ Updated _NavItem
class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final Function(int) onTap;
  final int badgeCount; // চ্যাটের জন্য সংখ্যা
  final bool showRedDot; // হোমের জন্য শুধু ডট

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
    this.showRedDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    const activeColor = AppColors.brandMain;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white54 : Colors.black45;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),
                // ✅ Badge Logic
                if (badgeCount > 0)
                  Positioned(
                    right: -4,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? Colors.black : Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
                else if (showRedDot) // 🔴 Red Dot Logic
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? Colors.black : Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: isSelected ? 3 : 0,
              decoration: const BoxDecoration(color: activeColor, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}