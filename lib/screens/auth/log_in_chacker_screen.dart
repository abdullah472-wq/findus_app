import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/auth/login_screen.dart';
import 'package:findus_app/screens/auth/role_selection_screen.dart';
import 'package:findus_app/localization/localization_wrapper.dart';

class ProfileNotLoggedIn extends StatefulWidget {
  final String title;
  final bool showBackButton;

  const ProfileNotLoggedIn({
    super.key,
    required this.title,
    this.showBackButton = false,
  });

  @override
  State<ProfileNotLoggedIn> createState() => _ProfileNotLoggedInState();
}

class _ProfileNotLoggedInState extends State<ProfileNotLoggedIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBengali = context.watch<LocalizationWrapper>().isBengali;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue,
      appBar: widget.showBackButton
          ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : AppColors.brandDark,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔒 Icon/Animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildLockIcon(isDark),
                  ),

                  const SizedBox(height: 30),

                  // Title
                  SlideTransition(
                    position: _slideAnimation,
                    child: Text(
                      isBengali ? "লগইন প্রয়োজন" : "Login Required",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.brandDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Description
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildDescription(isDark, isBengali),
                  ),

                  const SizedBox(height: 30),

                  // Features List
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildFeaturesList(isDark, isBengali),
                  ),

                  const SizedBox(height: 35),

                  // Login Button
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildLoginButton(isDark, isBengali),
                  ),

                  const SizedBox(height: 16),

                  // Sign Up Link
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildSignUpLink(isDark, isBengali),
                  ),

                  const SizedBox(height: 20),

                  // Skip Link (Optional)
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildSkipLink(isDark, isBengali),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockIcon(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ]
              : [Colors.white, Colors.white.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.brandMain.withOpacity(0.2),
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.brandMain.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.lock_person_rounded,
          size: 55,
          color: AppColors.brandMain,
        ),
      ),
    );

    // Alternative: Use Lottie animation
    // return Lottie.asset(
    //   'assets/animations/lock.json',
    //   width: 150,
    //   height: 150,
    //   fit: BoxFit.contain,
    // );
  }

  Widget _buildDescription(bool isDark, bool isBengali) {
    final title = widget.title;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isBengali
            ? "$title ফিচার অ্যাক্সেস করতে, আপনার প্রোফাইল ম্যানেজ করতে এবং ব্যক্তিগতকৃত কন্টেন্ট দেখতে অনুগ্রহ করে লগইন করুন।"
            : "Please login to access $title features, manage your profile, and see personalized content.",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey.shade700,
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildFeaturesList(bool isDark, bool isBengali) {
    final features = isBengali
        ? [
      "আপনার প্রোফাইল ম্যানেজ করুন",
      "কাজ পোস্ট করুন বা আবেদন করুন",
      "মেসেজ পাঠান এবং রিসিভ করুন",
      "আয়ের ইতিহাস দেখুন",
    ]
        : [
      "Manage your profile",
      "Post jobs or apply for work",
      "Send and receive messages",
      "View your earnings history",
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.brandMain.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stars_rounded,
                color: AppColors.brandMain,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isBengali ? "লগইন করলে পাবেন" : "What you'll get",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.brandDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...features.map((feature) => _buildFeatureItem(feature, isDark)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.green,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(bool isDark, bool isBengali) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandMain,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.brandMain.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login_rounded, size: 22),
            const SizedBox(width: 10),
            Text(
              isBengali ? "এখনই লগইন করুন" : "LOGIN NOW",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpLink(bool isDark, bool isBengali) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : AppColors.brandMain.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBengali ? "অ্যাকাউন্ট নেই? " : "Don't have an account? ",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
            Text(
              isBengali ? "সাইন আপ করুন" : "Sign Up",
              style: const TextStyle(
                color: AppColors.brandMain,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward,
              size: 16,
              color: AppColors.brandMain,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipLink(bool isDark, bool isBengali) {
    return TextButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: Text(
        isBengali ? "পরে করব" : "Maybe later",
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.grey,
          fontSize: 13,
        ),
      ),
    );
  }
}