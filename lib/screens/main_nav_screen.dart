// lib/screens/tabs/main_nav_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';

// Screens
import 'home_feed_screen.dart';
import 'explore/explore_screen.dart';
import 'package:findus_app/screens/tabs/conversation_tab.dart'; // ✅ মেসেজ ট্যাব ইম্পোর্ট
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/auth/log_in_chacker_screen.dart'; // ✅ লগইন চেক স্ক্রিন

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  static final GlobalKey<_MainNavScreenState> navKey = GlobalKey<_MainNavScreenState>();

  static void goToHomeTab() => navKey.currentState?._goToTab(0);
  static void goToExploreTab() => navKey.currentState?._goToTab(1);
  static void goToMessagesTab() => navKey.currentState?._goToTab(2); // ✅ মেসেজ ট্যাব
  static void goToProfileTab() => navKey.currentState?._goToTab(3);

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 1;
  final PageController _pageController = PageController(initialPage: 1);

  void _goToTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index); // jumpToPage ব্যবহার করা ফাস্ট নেভিগেশনের জন্য ভালো
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;

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
            // 0. HOME TAB (Login Required)
            uid != null
                ? HomeFeedScreen(key: HomeFeedScreen.feedKey)
                : const ProfileNotLoggedIn(title: "Home Feed", showBackButton: false),

            // 1. EXPLORE TAB (Public)
            const ExploreScreen(),

            // 2. MESSAGES TAB (Login Required - ConversationTab handles checking or pass check here)
            // ConversationTab এর ভেতরেও চেক আছে, অথবা এখানেও দিতে পারেন
            const ConversationTab(),

            // 3. PROFILE TAB (Login Required)
            uid != null
                ? UnifiedProfileScreen(uid: uid, isOwner: true, showBack: false)
                : const ProfileNotLoggedIn(title: "Your Profile", showBackButton: false),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: _buildModernNavBar(isDark),
        ),
      ),
    );
  }

  Widget _buildModernNavBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            index: 0,
            currentIndex: _currentIndex,
            activeIcon: Icons.home_rounded,
            inactiveIcon: Icons.home_outlined,
            label: 'HOME',
            onTap: _goToTab,
          ),
          _NavItem(
            index: 1,
            currentIndex: _currentIndex,
            activeIcon: Icons.explore_rounded,
            inactiveIcon: Icons.explore_outlined,
            label: 'EXPLORE',
            onTap: _goToTab,
          ),
          _NavItem(
            index: 2,
            currentIndex: _currentIndex,
            // ✅ আইকন পরিবর্তন: ড্যাশবোর্ড -> মেসেজ
            activeIcon: Icons.chat_bubble_rounded,
            inactiveIcon: Icons.chat_bubble_outline,
            label: 'MESSAGES',
            onTap: _goToTab,
          ),
          _NavItem(
            index: 3,
            currentIndex: _currentIndex,
            activeIcon: Icons.person_rounded,
            inactiveIcon: Icons.person_outline,
            label: 'PROFILE',
            onTap: _goToTab,
          ),
        ],
      ),
    );
  }
}

// ✅ ছোট এবং রিইউজেবল উইজেট
class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final Function(int) onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    // ✅ ব্র্যান্ড কালার ব্যবহার করা হয়েছে
    final activeColor = AppColors.brandMain;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? activeColor : Colors.grey.shade400,
              size: isSelected ? 26 : 22,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(top: 4),
              height: 4,
              width: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 2),
            if (!isSelected) // সিলেক্টেড অবস্থায় টেক্সট হাইড করে আরও ক্লিন লুক দেওয়া যায় (অপশনাল)
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey.shade400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}