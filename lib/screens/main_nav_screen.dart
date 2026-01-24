import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'home_feed_screen.dart';
import 'explore/explore_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/auth/login_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  // যদি বাইরে থেকে static ভাবে ট্যাব বদলাতে চাও, তাহলে
  // MainNavScreen বানানোর সময় key: MainNavScreen.navKey দেবে
  static final GlobalKey<_MainNavScreenState> navKey =
  GlobalKey<_MainNavScreenState>();

  static void goToHomeTab() => navKey.currentState?._goToTab(0);
  static void goToExploreTab() => navKey.currentState?._goToTab(1);
  static void goToDashboardTab() => navKey.currentState?._goToTab(2);
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
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
    isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;

    return PopScope(
      canPop: _currentIndex == 1,
      onPopInvoked: (didPop) {
        if (!didPop && _currentIndex != 1) {
          _goToTab(1);
        }
      },
      child: Scaffold(
        extendBody: true, // nav bar-এর নিচেও body extend হবে
        backgroundColor: bgColor,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // ✅ Home Tab (login required)
            uid != null
                ? HomeFeedScreen(key: HomeFeedScreen.feedKey)
                : const _ProfileNotLoggedIn(title: "Home Feed"),

            // ✅ Explore Tab (public)
            const ExploreScreen(),

            // ✅ Dashboard Tab (এখানেও login check বসানো হলো)
            uid != null
                ? const DashboardScreen()
                : const _ProfileNotLoggedIn(title: "Dashboard"),

            // ✅ Profile Tab (login required)
            uid != null
                ? UnifiedProfileScreen(
              uid: uid,
              isOwner: true,
              showBack: false,
            )
                : const _ProfileNotLoggedIn(title: "Your Profile"),
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
            activeIcon: Icons.home_rounded,
            inactiveIcon: Icons.home_outlined,
            label: 'HOME',
          ),
          _NavItem(
            index: 1,
            activeIcon: Icons.explore_rounded,
            inactiveIcon: Icons.explore_outlined,
            label: 'EXPLORE',
          ),
          _NavItem(
            index: 2,
            activeIcon: Icons.dashboard_rounded,
            inactiveIcon: Icons.dashboard_outlined,
            label: 'DASHBOARD',
          ),
          _NavItem(
            index: 3,
            activeIcon: Icons.person_rounded,
            inactiveIcon: Icons.person_outline,
            label: 'PROFILE',
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  const _NavItem({
    required this.index,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final state =
    context.findAncestorStateOfType<_MainNavScreenState>()!;
    final isSelected = state._currentIndex == index;
    const activeColor = Color(0xFF00695C);

    return Expanded(
      child: InkWell(
        onTap: () => state._goToTab(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color:
              isSelected ? activeColor : Colors.grey.shade400,
              size: isSelected ? 26 : 22,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(top: 4),
              height: 4,
              width: isSelected ? 4 : 0,
              decoration: const BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected
                    ? activeColor
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileNotLoggedIn extends StatelessWidget {
  final String title;
  const _ProfileNotLoggedIn({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      color:
      isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 80,
                  color: isDark
                      ? Colors.white54
                      : AppColors.brandDark
                      .withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Login Required",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white
                      : AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Please login to access $title features and your personalized feed.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                      const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "LOGIN NOW",
                  style: TextStyle(
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
