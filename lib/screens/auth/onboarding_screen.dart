import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/auth/welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardItem> _pages = const [
    _OnboardItem(
      title: "Find trusted local workers",
      description:
      "Quickly find nearby workers for your daily needs — from cleaners, drivers, technicians to many more.",
      icon: Icons.location_searching,
    ),
    _OnboardItem(
      title: "See workers around you",
      description:
      "View workers on map, compare prices, ratings and distance in a single screen.",
      icon: Icons.map,
    ),
    _OnboardItem(
      title: "Verified & rated by real users",
      description:
      "Workers are verified and reviewed by real users, so you can hire with confidence.",
      icon: Icons.verified_user,
    ),
  ];

  void _goToWelcome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _goToWelcome();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _goToWelcome,
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        color: AppColors.brandDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return _buildPage(item);
                },
              ),
            ),

            // Bottom: indicators + button
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Dot indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                          (index) => _buildDot(isActive: index == _currentPage),
                    ),
                  ),
                  const Spacer(),
                  // Next / Get Started button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandMain,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? "Get Started"
                          : "Next",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Icon / Illustration
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.bgBlue.withOpacity(0.6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              item.icon,
              size: 120,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(right: 6),
      height: 8,
      width: isActive ? 20 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.brandMain : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _OnboardItem {
  final String title;
  final String description;
  final IconData icon;

  const _OnboardItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}