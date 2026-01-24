import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'login_screen.dart';
import 'role_selection_screen.dart';

class ProfileNotLoggedIn extends StatelessWidget {
  final String title;
  final bool showBackButton;

  const ProfileNotLoggedIn({
    super.key,
    required this.title,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue,
      appBar: showBackButton
          ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : AppColors.brandDark),
          onPressed: () => Navigator.pop(context),
        ),
      )
          : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔒 আইকন
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock_person_rounded,
                  size: 60,
                  color: AppColors.brandMain.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 30),

              Text(
                "Login Required",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.brandDark,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                "Please login to access $title features, manage your profile, and see personalized content.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // 🔘 লগইন বাটন
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // ✅ pushReplacement ব্যবহার করা হয়েছে যাতে ব্যাক করলে এই পেজ আর না আসে
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen())
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandMain,
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: AppColors.brandMain.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded),
                      SizedBox(width: 10),
                      Text("LOGIN NOW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // সাইন আপ টেক্সট
              GestureDetector(
                onTap: () {
                  // ✅ সরাসরি RoleSelectionScreen এ পাঠানো হচ্ছে
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RoleSelectionScreen())
                  );
                },
                child: RichText(
                  text: TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                    children: const [
                      TextSpan(
                        text: "Sign Up",
                        style: TextStyle(
                          color: AppColors.brandMain,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}