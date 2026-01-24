import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // ✅ Lottie ইমপোর্ট

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/main_nav_screen.dart';
import 'package:findus_app/screens/auth/login_screen.dart';
import 'package:findus_app/screens/auth/role_selection_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandLight,
      body: Column(
        children: [
          // ১. উপরের অ্যানিমেশন ও লোগো সেকশন
          Expanded(
            flex: 5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ ইমেজের বদলে Lottie Animation বসানো হয়েছে
                  Lottie.asset(
                    "assets/animations/welcome.json",
                    height: 250, // সাইজ প্রয়োজন অনুযায়ী ছোট/বড় করতে পারেন
                    width: 250,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // ফাইল না পেলে ডিফল্ট আইকন দেখাবে
                      return const Icon(
                          Icons.location_on,
                          size: 100,
                          color: AppColors.brandMain
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "FINDUS",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandDark,
                      letterSpacing: 2,
                      fontFamily: 'Poppins', // আপনার ফন্ট ফ্যামিলি
                    ),
                  ),
                  Text(
                    "Connect | Support | Earn",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandDark.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ২. নিচের কার্ড সেকশন (অপরিবর্তিত)
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              decoration: const BoxDecoration(
                color: Color(0xFFFCE4EC), // অথবা AppColors.cardPink
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Hi there!", style: TextStyle(fontSize: 18, color: Colors.black54)),
                  const SizedBox(height: 5),
                  const Text(
                    "Welcome to FINDUS",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "50+ local jobs open today in your area\nDriver • Shop • Factory • Guard • Helper",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                  ),

                  const SizedBox(height: 20),

                  // Skip Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MainNavScreen())
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "See jobs now",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brandDark),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward, size: 18, color: AppColors.brandDark),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Buttons Row
                  Row(
                    children: [
                      // Sign In Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen())
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandMain,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text("Sign in", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(width: 15),

                      // Sign Up Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RoleSelectionScreen())
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandMain.withOpacity(0.2),
                            foregroundColor: AppColors.brandDark,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text("Sign up", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}