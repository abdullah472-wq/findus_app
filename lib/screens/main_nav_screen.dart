// lib/screens/tabs/main_nav_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'home_feed_screen.dart';
import 'explore/explore_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
// আপনার লগইন স্ক্রিনটি এখানে ইম্পোর্ট করুন (উদাহরণস্বরূপ):
// import 'package:findus_app/screens/auth/login_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  static final GlobalKey<_MainNavScreenState> navKey = GlobalKey<_MainNavScreenState>();

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
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;

    return PopScope(
      canPop: _currentIndex == 1,
      onPopInvoked: (didPop) {
        if (!didPop && _currentIndex != 1) {
          _goToTab(1);
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // ✅ Home Tab Login Check
            uid != null
                ? HomeFeedScreen(key: HomeFeedScreen.feedKey)
                : const _ProfileNotLoggedIn(title: "Home Feed"),

            // Explore Tab (Public - No Login Needed)
            const ExploreScreen(),

            // ✅ Dashboard Tab Login Check
            uid != null
                ? const DashboardScreen()
                : const _ProfileNotLoggedIn(title: "Dashboard"),

            // ✅ Profile Tab Login Check
            uid != null
                ? UnifiedProfileScreen(uid: uid, isOwner: true, showBack: false)
                : const _ProfileNotLoggedIn(title: "Your Profile"),
          ],
        ),
        bottomNavigationBar: Container(
          color: bgColor,
          child: _buildModernNavBar(isDark),
        ),
      ),
    );
  }

  Widget _buildModernNavBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 90,
      child: Container(
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
            _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'HOME'),
            _buildNavItem(1, Icons.explore_rounded, Icons.explore_outlined, 'EXPLORE'),
            _buildNavItem(2, Icons.dashboard_rounded, Icons.dashboard_outlined, 'DASHBOARD'),
            _buildNavItem(3, Icons.person_rounded, Icons.person_outline, 'PROFILE'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFF00695C);

    return Expanded(
      child: InkWell(
        onTap: () => _goToTab(index),
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
              decoration: const BoxDecoration(color: activeColor, shape: BoxShape.circle),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ ক্লাসটি এখানে যোগ করা হলো
class _ProfileNotLoggedIn extends StatelessWidget {
  final String title;
  const _ProfileNotLoggedIn({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                    color: isDark ? Colors.white54 : AppColors.brandDark.withOpacity(0.3)
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Login Required",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.brandDark
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Please login to access $title features and your personalized feed.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // আপনার লগইন স্ক্রিনে নেভিগেট করুন
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("LOGIN NOW", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}