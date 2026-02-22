import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/auth/signup_screen.dart';
import 'package:findus_app/screens/main_nav_screen.dart';
import 'package:findus_app/localization/localization_wrapper.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

const String _termsUrl = 'https://findus.odditybd.shop/#policies';
const String _privacyUrl = 'https://findus.odditybd.shop/#policies';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  bool _isAgreed = false;
  bool _isLoading = false;
  String? _selectedRole;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  late TapGestureRecognizer _termsRecognizer;
  late TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupGestureRecognizers();
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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  void _setupGestureRecognizers() {
    _termsRecognizer = TapGestureRecognizer()..onTap = () => _openUrl(_termsUrl);
    _privacyRecognizer = TapGestureRecognizer()..onTap = () => _openUrl(_privacyUrl);
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      final isBengali = context.read<LocalizationWrapper>().isBengali;
      _showError(
        isBengali
            ? 'লিংক খোলা যায়নি। পরে আবার চেষ্টা করুন।'
            : 'Could not open link. Please try again later.',
      );
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _mapMakerFinderToCoreRole(String makerFinder) {
    return makerFinder == 'maker' ? 'supporter' : 'worker';
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
    if (_isLoading) return;

    final isBengali = context.read<LocalizationWrapper>().isBengali;

    if (!_isAgreed) {
      _showError(
        isBengali
            ? "এগোতে হলে আগে Terms ও Privacy Policy-তে সম্মতি দিতে হবে।"
            : "Please agree to Terms & Privacy Policy to continue.",
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedRole = selectedRole;
    });

    try {
      final auth = FirebaseAuth.instance;
      User? user = auth.currentUser;

      if (user == null) {
        final userCred = await _signInWithGoogle();
        user = userCred.user;
      }

      if (user == null) {
        _showError(
          isBengali
              ? "Google সাইন-ইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।"
              : "Google sign-in failed. Please try again.",
        );
        setState(() => _isLoading = false);
        return;
      }

      final uid = user.uid;
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(uid);
      final snap = await userRef.get();

      final String coreRole = _mapMakerFinderToCoreRole(selectedRole);

      if (!snap.exists) {
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
      } else {
        final data = snap.data() ?? <String, dynamic>{};

        if (data['isBlocked'] == true) {
          _showError(
            isBengali
                ? "আপনার অ্যাকাউন্টটি ব্লক করা আছে।"
                : "Your account is blocked.",
          );
          setState(() => _isLoading = false);
          return;
        }

        List<dynamic> rolesRaw = (data['roles'] as List?) ?? [];
        final List<String> roles = rolesRaw.map((e) => e.toString()).toList();

        if (!roles.contains(coreRole)) {
          roles.add(coreRole);
        }

        final Map<String, dynamic> updateData = {
          'userRole': coreRole,
          'roles': roles,
          'isSupporter': coreRole == 'supporter',
          'isWorker': coreRole == 'worker',
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (data['termsAcceptedAt'] == null) {
          updateData['termsAcceptedAt'] = FieldValue.serverTimestamp();
        }

        await userRef.set(updateData, SetOptions(merge: true));
      }

      final fresh = await userRef.get();
      final freshData = fresh.data() ?? <String, dynamic>{};
      final completed = freshData['profileCompleted'] == true;

      if (!mounted) return;

      if (completed) {
        _showSuccess(
          isBengali
              ? "সফলভাবে লগইন হয়েছে!"
              : "Successfully logged in!",
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavScreen()),
              (route) => false,
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SignUpScreen(
              phoneNumber: '',
              userRole: selectedRole,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("ROLE SELECTION ERROR: $e");

      if (!e.toString().contains('CANCELLED')) {
        final isBengali = context.read<LocalizationWrapper>().isBengali;
        _showError(
          isBengali
              ? "কিছু একটা সমস্যা হয়েছে। আবার চেষ্টা করুন।"
              : "Something went wrong. Please try again.",
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedRole = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBengali = context.watch<LocalizationWrapper>().isBengali;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue,
      body: SafeArea(
        child: Stack(
          children: [
            // Back Button
            Positioned(
              top: 10,
              left: 10,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: IconButton(
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
                      size: 20,
                    ),
                  ),
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                ),
              ),
            ),

            // Language Toggle
            Positioned(
              top: 10,
              right: 10,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: IconButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                    context.read<LocalizationWrapper>().toggleLanguage();
                  },
                  icon: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.language,
                          size: 16,
                          color: isDark ? Colors.white : AppColors.brandDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isBengali ? 'EN' : 'বাং',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.brandDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main Content
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon & Title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.white.withOpacity(0.5),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.brandMain.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.verified_user_rounded,
                                size: 60,
                                color: AppColors.brandMain,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  AppColors.brandMain,
                                  AppColors.brandDark,
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                "FINDUS",
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isBengali
                                  ? "চালিয়ে যেতে আপনার ভূমিকা নির্বাচন করুন"
                                  : "Choose your role to continue",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Role Selection Card
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                const Color(0xFF2A2A2A),
                                const Color(0xFF1F1F1F),
                              ]
                                  : [
                                AppColors.cardPink,
                                AppColors.cardPink.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDark ? 0.3 : 0.08,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildRoleButton(
                                title: isBengali
                                    ? "আমি একজন Job Maker"
                                    : "I am a Job Maker",
                                subtitle: isBengali
                                    ? "দক্ষ কর্মী নিয়োগ করুন"
                                    : "Hire skilled workers",
                                icon: Icons.business_center_rounded,
                                roleId: "maker",
                                isDark: isDark,
                              ),

                              const SizedBox(height: 16),

                              _buildRoleButton(
                                title: isBengali
                                    ? "আমি একজন Job Finder"
                                    : "I am a Job Finder",
                                subtitle: isBengali
                                    ? "কাজ খুঁজুন এবং অর্থ উপার্জন করুন"
                                    : "Find work & earn money",
                                icon: Icons.handyman_rounded,
                                roleId: "finder",
                                isDark: isDark,
                              ),

                              const SizedBox(height: 24),

                              if (_isLoading)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Column(
                                    children: [
                                      const CircularProgressIndicator(
                                        color: AppColors.brandMain,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        isBengali
                                            ? "সাইন ইন হচ্ছে..."
                                            : "Signing in...",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Terms Checkbox
                              _buildTermsCheckbox(isBengali, isDark),

                              const SizedBox(height: 12),

                              // Terms Links
                              _buildTermsLinks(isBengali, isDark),
                            ],
                          ),
                        ),
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

  Widget _buildRoleButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required String roleId,
    required bool isDark,
  }) {
    final isSelected = _selectedRole == roleId;
    final isDisabled = _isLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : () => _handleSelection(roleId),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? (isSelected
                  ? AppColors.brandMain.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05))
                  : (isSelected
                  ? AppColors.brandMain.withOpacity(0.1)
                  : Colors.white),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? AppColors.brandMain
                    : (isDark
                    ? Colors.white12
                    : Colors.grey.shade200),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: AppColors.brandMain.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.brandMain.withOpacity(0.2)
                        : AppColors.brandLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.brandMain,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.brandDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white60
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 20,
                  color: isSelected
                      ? AppColors.brandMain
                      : (isDark ? Colors.white30 : Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox(bool isBengali, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.scale(
          scale: 1.1,
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
        Flexible(
          child: Text(
            isBengali
                ? "আমি শর্তাবলী ও নীতিমালার সাথে সম্মত"
                : "I agree with the terms\nand conditions",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : AppColors.brandDark,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsLinks(bool isBengali, bool isDark) {
    return Text.rich(
      TextSpan(
        text: isBengali ? 'আমাদের পড়ুন ' : 'Read our ',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white60 : Colors.black54,
        ),
        children: [
          TextSpan(
            text: isBengali ? 'শর্তাবলী' : 'Terms & Conditions',
            style: const TextStyle(
              decoration: TextDecoration.underline,
              color: AppColors.brandMain,
              fontWeight: FontWeight.w600,
            ),
            recognizer: _termsRecognizer,
          ),
          TextSpan(text: isBengali ? ' এবং ' : ' and '),
          TextSpan(
            text: isBengali ? 'গোপনীয়তা নীতি' : 'Privacy Policy',
            style: const TextStyle(
              decoration: TextDecoration.underline,
              color: AppColors.brandMain,
              fontWeight: FontWeight.w600,
            ),
            recognizer: _privacyRecognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}