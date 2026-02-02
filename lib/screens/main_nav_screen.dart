import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/constants/app_colors.dart';

// Screens ও অন্যান্য ইম্পোর্ট (আপনার ফাইল পাথ অনুযায়ী ঠিক রাখুন)
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
  int unreadMessagesCount = 0; // এটি সার্ভিস থেকে আপডেট করবেন

  @override
  void initState() {
    super.initState();
    _handleDailyCheckIn();
  }

  Future<void> _handleDailyCheckIn() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await AchievementService.incrementProgress('daily_open_app');
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
                _NavItem(index: 0, currentIndex: _currentIndex, activeIcon: Icons.home_rounded, inactiveIcon: Icons.home_outlined, label: 'Home', onTap: _goToTab),
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

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final Function(int) onTap;
  final int badgeCount;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    const activeColor = AppColors.brandMain; // হাইলাইট কালার
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ইন-অ্যাক্টিভ কালার সেট করা হয়েছে (ডার্ক মোডে হালকা সাদাটে, লাইট মোডে হালকা কালোটে)
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
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // টেক্সট এখন সবসময় দেখা যাবে, শুধু কালার পরিবর্তন হবে
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            // সিলেক্টেড ট্যাবের নিচে ছোট ডট ইন্ডিকেটর
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