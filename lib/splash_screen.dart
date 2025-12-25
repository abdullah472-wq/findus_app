import 'dart:async';
import 'package:flutter/material.dart';

// প্রয়োজনীয় ইমপোর্টগুলো আপনার প্রজেক্ট অনুযায়ী রাখুন
import 'package:findus_app/screens/main_nav_screen.dart';
import 'package:findus_app/services/app_config_service.dart';
import 'constants/app_colors.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({super.key});

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    try {
      // ৩ সেকেন্ড সপ্ল্যাশ দেখাবে এবং কনফিগ লোড হবে
      await Future.wait([
        AppConfigService.init(),
        Future.delayed(const Duration(seconds: 3)),
      ]);

      if (!mounted) return;

      // ১. মেইনটেন্যান্স চেক (কনফিগ থেকে আসবে)
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

      // ২. সরাসরি মেইন অ্যাপে পাঠিয়ে দেওয়া (লগইন/সাইনআপ বাইপাস)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );

    } catch (e) {
      // কোনো এরর হলেও যেন অ্যাপ স্টাক না থাকে, সরাসরি ভেতরে যাবে
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/splash.png', // ইমেজ আগেরটাই আছে
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// --- মেইনটেন্যান্স স্ক্রিন (অপরিবর্তিত) ---
class MaintenanceScreen extends StatelessWidget {
  final String note;
  const MaintenanceScreen({super.key, this.note = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.build, size: 64, color: AppColors.brandDark),
              const SizedBox(height: 16),
              const Text(
                'We are under maintenance',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                note.isNotEmpty ? note : 'Please try again later.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}