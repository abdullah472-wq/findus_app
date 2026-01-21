import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../constants/app_colors.dart';
import '../main_nav_screen.dart';
import 'role_selection_screen.dart';
import 'signup_screen.dart'; // ✅ আপনার প্রজেক্টে যে নাম আছে সেটাই দিন (signup_screen.dart / sign_up_screen.dart)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<UserCredential> _signInWithGoogle() async {
    final auth = FirebaseAuth.instance;

    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('https://www.googleapis.com/auth/userinfo.email');
      return auth.signInWithPopup(provider);
    }

    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('CANCELLED');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return auth.signInWithCredential(credential);
  }

  String _coreRoleToMakerFinder(String coreRole) {
    // Firestore userRole: supporter/worker -> UI role: maker/finder
    return coreRole == 'supporter' ? 'maker' : 'finder';
  }

  Future<void> _routeAfterLogin(User user) async {
    final uid = user.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!mounted) return;

    // ইউজার ডক নেই → নতুন ইউজার → আগে রোল সিলেক্ট
    if (!userDoc.exists) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
            (route) => false,
      );
      return;
    }

    final data = userDoc.data() ?? <String, dynamic>{};

    // ব্লকড হলে এখানে আটকে দিন (আপনি চাইলে আলাদা BlockedScreen দিতে পারেন)
    if (data['isBlocked'] == true) {
      _showMsg("আপনার অ্যাকাউন্টটি ব্লক করা আছে।");
      return;
    }

    final completed = data['profileCompleted'] == true;

    if (completed) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
            (route) => false,
      );
      return;
    }

    // প্রোফাইল কমপ্লিট না → Complete Profile স্ক্রিনে যান
    final coreRole = (data['userRole'] ?? '').toString(); // supporter/worker
    if (coreRole != 'supporter' && coreRole != 'worker') {
      // role সেট নাই/ভুল → Role selection
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
            (route) => false,
      );
      return;
    }

    final makerFinder = _coreRoleToMakerFinder(coreRole);
    final phone = (data['phone'] ?? user.phoneNumber ?? '').toString();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => SignUpScreen(
          phoneNumber: phone, // OTP বাদ, তাই ফাঁকা হলেও সমস্যা নেই
          userRole: makerFinder,
        ),
      ),
          (route) => false,
    );
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      final cred = await _signInWithGoogle();
      final user = cred.user;

      if (user == null) {
        _showMsg("Google লগইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।");
        return;
      }

      await _routeAfterLogin(user);
    } catch (e) {
      // ইউজার ক্যান্সেল করলে চুপ থাকাও ঠিক আছে
      if (!e.toString().contains('CANCELLED')) {
        _showMsg("কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.brandLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle,
                  size: 80, color: AppColors.brandDark),
              const SizedBox(height: 10),
              const Text(
                "FINDUS",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.brandDark,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "Connect | Support | Earn",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.cardPink,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // ⚠️ এই ইউজারনেম/পাসওয়ার্ড ফিল্ড এখন ব্যবহার হচ্ছে না (শুধু UI রাখতে দিলাম)
                    TextField(
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: "Username (Google login only)",
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.person_outline,
                            color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      enabled: false,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Password (Google login only)",
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Colors.grey),
                        suffixIcon: const Icon(Icons.visibility_off,
                            color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),

                    const Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: null,
                        child: Text(
                          "Forgot Password? (later)",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ✅ Sign in বাটন এখন Google login করবে
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF64B5F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          "Sign in with Google",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),
                    const Text(
                      "Or continue with",
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialButton(
                          icon: Icons.g_mobiledata,
                          color: Colors.red,
                          onTap: _isLoading ? null : _handleGoogleLogin,
                        ),
                        const SizedBox(width: 20),
                        _socialButton(
                          icon: Icons.facebook,
                          color: Colors.blue,
                          onTap: () => _showMsg("Facebook পরে যোগ করবেন।"),
                        ),
                        const SizedBox(width: 20),
                        _socialButton(
                          icon: Icons.info,
                          color: Colors.blueAccent,
                          onTap: () => _showMsg("এই বাটনটা পরে ব্যবহার করবেন।"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RoleSelectionScreen(),
                          ),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: "Don’t have an account? ",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: "Sign up",
                              style: TextStyle(
                                color: Colors.redAccent,
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

              SizedBox(height: size.height * 0.01),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}