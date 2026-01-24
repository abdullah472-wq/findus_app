import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:findus_app/services/app_config_service.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/main_nav_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:findus_app/services/cloudinary_service.dart';

const String _termsUrl = 'https://findus.odditybd.shop/#policies';
const String _privacyUrl = 'https://findus.odditybd.shop/#policies';

class SignUpScreen extends StatefulWidget {
  final String phoneNumber;
  final String userRole; // 'maker' or 'finder'

  const SignUpScreen({
    super.key,
    required this.phoneNumber,
    required this.userRole,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _agreed = true;

  late TapGestureRecognizer _termsRecognizer;
  late TapGestureRecognizer _privacyRecognizer;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final ImagePicker _imagePicker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = () => _openUrl(_termsUrl);
    _privacyRecognizer = TapGestureRecognizer()..onTap = () => _openUrl(_privacyUrl);

    final dn = _auth.currentUser?.displayName?.trim() ?? '';
    if (dn.isNotEmpty) _nameController.text = dn;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('লিংক খোলা যাচ্ছে না।');
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _pickedImage = picked;
        _pickedImageBytes = bytes;
      });
    } catch (_) {
      _showError("ছবি সিলেক্ট করা যায়নি। আবার চেষ্টা করুন।");
    }
  }

  String _coreRole() => widget.userRole == 'maker' ? 'supporter' : 'worker';

  Future<UserCredential> _signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('https://www.googleapis.com/auth/userinfo.email');
      return _auth.signInWithPopup(provider);
    } else {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) throw Exception('CANCELLED');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return _auth.signInWithCredential(credential);
    }
  }

  Future<String?> _uploadProfileImageIfAny(String uid) async {
    if (_pickedImage == null) return null;

    final res = await CloudinaryService.uploadFile(
      _pickedImage!,
      folder: 'findus/profile_images/$uid',
      resourceType: 'image',
      publicId: '${uid}_${DateTime.now().millisecondsSinceEpoch}',
      tags: const ['profile'],
    );

    final url = (res['secure_url'] ?? '').toString().trim();
    if (url.isEmpty) throw Exception('Cloudinary secure_url খালি এসেছে');
    return url;
  }

  Future<void> _continue() async {
    if (_isLoading) return;

    if (AppConfigService.isSignupDisabled) {
      _showError("এখন সাইন‑আপ বন্ধ আছে। পরে আবার চেষ্টা করুন।");
      return;
    }

    if (!_agreed) {
      _showError("Terms ও Privacy Policy‑তে সম্মতি দিতে হবে।");
      return;
    }

    final name = _nameController.text.trim();
    if (name.length < 3) {
      _showError("পূর্ণ নাম দিন (কমপক্ষে ৩ অক্ষর)।");
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = _auth.currentUser;
      if (user == null) {
        final cred = await _signInWithGoogle();
        user = cred.user;
      }
      if (user == null) {
        _showError("Google লগইন ব্যর্থ হয়েছে।");
        return;
      }

      final uid = user.uid;

      // নাম আপডেট (Auth Profile)
      await user.updateDisplayName(name);

      // ইমেজ আপলোড
      final imageUrl = await _uploadProfileImageIfAny(uid);

      final userRef = _db.collection('users').doc(uid);

      final role = _coreRole();
      final phone = widget.phoneNumber.trim();

      // ✅ ফিক্স: ফোন এবং রোল ডাটা আপডেট করার জন্য Map তৈরি
      final data = <String, dynamic>{
        'name': name,
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),

        // রোল পুনরায় নিশ্চিত করা হচ্ছে
        'userRole': role,
        'roles': FieldValue.arrayUnion([role]), // অ্যারেতে রোল যোগ করা (যাতে আগের রোল না মুছে যায় যদি থাকে)
        'isSupporter': role == 'supporter',
        'isWorker': role == 'worker',
      };

      // ✅ ফিক্স: ফোন নম্বর থাকলে ম্যাপে যোগ হবে
      if (phone.isNotEmpty) {
        data['phone'] = phone;
      }

      // ইমেজ থাকলে ম্যাপে যোগ হবে
      if (imageUrl != null) {
        data['image'] = imageUrl;
      }

      // ✅ ফিক্স: merge: true দিয়ে ডাটা সেভ করা হচ্ছে (আগের ডাটা থাকবে, নতুনগুলো আপডেট হবে)
      await userRef.set(data, SetOptions(merge: true));

      // SharedPreferences আপডেট
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', widget.userRole);
      await prefs.setString('user_name', name);
      if (phone.isNotEmpty) await prefs.setString('user_phone', phone);
      if (imageUrl != null) {
        await prefs.setString('user_profile_image', imageUrl);
      }

      if (!mounted) return;

      // মেইন স্ক্রিনে নেভিগেশন
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
            (route) => false,
      );

    } on FirebaseException catch (e) {
      debugPrint('FirebaseException code=${e.code} message=${e.message}');
      _showError("Firebase সমস্যা: ${e.message}");
    } catch (e) {
      debugPrint('Error: $e');
      if (!e.toString().contains('CANCELLED')) {
        _showError("ব্যর্থ হয়েছে: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildProfileImage() {
    if (_pickedImageBytes == null) {
      return const Icon(Icons.person, size: 60, color: Colors.grey);
    }
    return Image.memory(_pickedImageBytes!, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final displayRole = widget.userRole == 'maker' ? "Job Maker" : "Job Finder";

    return Scaffold(
      backgroundColor: AppColors.brandLight,
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _isLoading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                const Text(
                  "Complete Profile",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Create your account as a $displayRole",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 30),

                // Image Picker Widget
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    children: [
                      Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.brandMain, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 10)
                          ],
                        ),
                        child: ClipOval(child: _buildProfileImage()),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          height: 35,
                          width: 35,
                          decoration: BoxDecoration(
                            color: AppColors.brandDark,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Full Name"),
                      _buildTextField(
                        controller: _nameController,
                        hint: "Enter your full name",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Checkbox(
                            value: _agreed,
                            onChanged: (v) => setState(() => _agreed = v ?? false),
                            activeColor: AppColors.brandMain,
                          ),
                          const Expanded(
                            child: Text(
                              "I agree with Terms & Privacy Policy",
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandMain,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            "Complete Profile",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text.rich(
                    TextSpan(
                      text: "By continuing, you agree to our ",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      children: [
                        TextSpan(
                          text: "Terms of Service",
                          style: const TextStyle(
                            color: AppColors.brandMain,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: _termsRecognizer,
                        ),
                        const TextSpan(text: " and "),
                        TextSpan(
                          text: "Privacy Policy",
                          style: const TextStyle(
                            color: AppColors.brandMain,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: _privacyRecognizer,
                        ),
                        const TextSpan(text: "."),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.brandDark,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: AppColors.brandMain),
        filled: true,
        fillColor: AppColors.brandLight.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}