import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Auth চেক করার জন্য

import 'package:findus_app/screens/main_nav_screen.dart';
import 'package:findus_app/screens/auth/onboarding_screen.dart'; // (অপশনাল) যদি অনবোর্ডিং দেখাতে চান
import 'package:findus_app/services/app_config_service.dart';
import 'package:findus_app/constants/app_colors.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({super.key});

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkStatusAndNavigate();
  }

  Future<void> _checkStatusAndNavigate() async {
    // ১. স্প্ল্যাশ দেখানোর জন্য ৩ সেকেন্ড অপেক্ষা
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // ২. মেইনটেন্যান্স চেক
    if (AppConfigService.isAppInMaintenance) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MaintenanceScreen(
            note: AppConfigService.maintenanceNote,
          ),
        ),
      );
      return;
    }

    // ৩. লগইন স্ট্যাটাস চেক (User Logged In Check)
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // ✅ ইউজার লগইন করা আছে -> সরাসরি Explore (Main Nav) এ যাবে
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
    } else {
      // ❌ ইউজার লগইন করা নেই -> Welcome Screen এ যাবে
      // (আপনি চাইলে এখানে OnboardingScreen-ও দিতে পারেন, যদি অ্যাপে প্রথমবার হয়)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splash.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// 👇 Maintenance Screen (আপনার আগের কোড অনুযায়ী) 👇
class MaintenanceScreen extends StatelessWidget {
  final String note;
  const MaintenanceScreen({super.key, this.note = ''});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.brandLight,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/maintenance_app.json',
                  width: 280,
                  height: 280,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                        Icons.build_circle_outlined,
                        size: 100,
                        color: AppColors.brandMain
                    );
                  },
                ),
                const SizedBox(height: 40),
                const Text(
                  'Under Maintenance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  note.isNotEmpty
                      ? note
                      : 'We are currently improving our services.\nPlease check back later.',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandMain,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Close App",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}