import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/auth/signup_screen.dart'; // পাথ মিলিয়ে নিন
import 'package:findus_app/screens/main_nav_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// এখানে তোমার নিজের Terms & Privacy এর ওয়েব URL বসাও
const String _termsUrl = 'https://findus.odditybd.shop/#policies';
const String _privacyUrl = 'https://findus.odditybd.shop/#policies';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isAgreed = false;
  bool _isLoading = false;

  late TapGestureRecognizer _termsRecognizer;
  late TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = () => _openUrl(_termsUrl);
    _privacyRecognizer =
    TapGestureRecognizer()..onTap = () => _openUrl(_privacyUrl);
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('লিংক খোলা যায়নি। পরে আবার চেষ্টা করুন।'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _mapMakerFinderToCoreRole(String makerFinder) {
    // maker/finder → supporter/worker
    return makerFinder == 'maker' ? 'supporter' : 'worker';
  }

  String _mapCoreRoleToMakerFinder(String coreRole) {
    // supporter/worker → maker/finder
    return coreRole == 'supporter' ? 'maker' : 'finder';
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

  Future<void> _handleSelection(String selectedRole) async {
    // selectedRole: "maker" বা "finder"
    if (_isLoading) return;

    if (!_isAgreed) {
      _showError("এগোতে হলে আগে Terms ও Privacy Policy-তে সম্মতি দিতে হবে।");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ১) Google সাইন-ইন
      final userCred = await _signInWithGoogle();
      final user = userCred.user;

      if (user == null) {
        _showError("Google সাইন-ইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।");
        setState(() => _isLoading = false);
        return;
      }

      final uid = user.uid;
      final db = FirebaseFirestore.instance;

      // ২) users ডক লোড
      final userRef = db.collection('users').doc(uid);
      final snap = await userRef.get();

      String roleForUi = selectedRole; // শেষে SignUpScreen-এ পাঠানোর জন্য

      if (!snap.exists) {
        // নতুন ইউজার → রোল সেট করে ডক তৈরি
        final coreRole = _mapMakerFinderToCoreRole(selectedRole);

        await userRef.set({
          'userRole': coreRole,
          'roles': [coreRole],
          'isSupporter': coreRole == 'supporter',
          'isWorker': coreRole == 'worker',
          'profileCompleted': false,
          'isBlocked': false,
          'kycStatus': 'none',
          'termsAcceptedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        roleForUi = selectedRole;
      } else {
        // পুরোনো ইউজার → রোল ওভাররাইট নয়
        final data = snap.data() ?? <String, dynamic>{};

        if (data['isBlocked'] == true) {
          _showError("আপনার অ্যাকাউন্টটি ব্লক করা আছে।");
          setState(() => _isLoading = false);
          return;
        }

        final coreRole = (data['userRole'] ?? '').toString();
        if (coreRole == 'supporter' || coreRole == 'worker') {
          roleForUi = _mapCoreRoleToMakerFinder(coreRole);
        }

        // Terms সম্মতি অন্তত একবার সেট করা (থাকলে ওভাররাইট হবে না)
        if (data['termsAcceptedAt'] == null) {
          await userRef.set({
            'termsAcceptedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      // ৩) এবার কোথায় যাবে?
      final fresh = await userRef.get();
      final freshData = fresh.data() ?? <String, dynamic>{};
      final completed = freshData['profileCompleted'] == true;

      if (!mounted) return;

      if (completed) {
        // প্রোফাইল কমপ্লিট → মেইন অ্যাপ
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavScreen()),
              (route) => false,
        );
      } else {
        // প্রোফাইল কমপ্লিট না → Complete Profile স্ক্রিন
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SignUpScreen(
              phoneNumber: '', // OTP বাদ, তাই ফাঁকা
              userRole: roleForUi, // maker/finder
            ),
          ),
        );
      }
    } catch (e) {
      if (e.toString().contains('CANCELLED')) {
        // ইউজার বাতিল করলে এরর দেখানো জরুরি না
      } else {
        _showError("কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandLight,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.brandDark,
                ),
                onPressed: _isLoading ? null : () => Navigator.pop(context),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.verified_user,
                      size: 80,
                      color: AppColors.brandDark,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "FINDUS",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Choose your role to continue",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 50),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardPink,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildRoleButton(
                            "I am a Job Maker",
                            "Hire skilled workers",
                            Icons.work_outline,
                            _isLoading ? null : () => _handleSelection("maker"),
                          ),
                          const SizedBox(height: 20),
                          _buildRoleButton(
                            "I am a Job Finder",
                            "Find work & earn money",
                            Icons.person_search_outlined,
                            _isLoading ? null : () => _handleSelection("finder"),
                          ),
                          const SizedBox(height: 30),

                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: CircularProgressIndicator(),
                            ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.scale(
                                scale: 1.2,
                                child: Checkbox(
                                  value: _isAgreed,
                                  activeColor: AppColors.brandMain,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: _isLoading
                                      ? null
                                      : (val) => setState(() => _isAgreed = val ?? false),
                                ),
                              ),
                              const Flexible(
                                child: Text(
                                  "I agree with the terms\nand conditions",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.brandDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text.rich(
                            TextSpan(
                              text: 'Read our ',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: AppColors.brandMain,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  recognizer: _termsRecognizer,
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: AppColors.brandMain,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  recognizer: _privacyRecognizer,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButton(
      String title,
      String subtitle,
      IconData icon,
      VoidCallback? onTap,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.brandDark,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.brandLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.brandMain,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}