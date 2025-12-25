import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/auth/otp_entry_screen.dart';
import 'package:findus_app/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔹 NEW

class PhoneVerificationScreen extends StatefulWidget {
  final String selectedRole;
  const PhoneVerificationScreen({super.key, required this.selectedRole});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isSendingOtp = false;

  // 🔹 Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidBangladeshiPhone(String input) {
    // এখানে আমরা ধরছি যে ইউজার শুধু "1712345678" টাইপের ১০ ডিজিট লিখবে
    final cleaned = input.trim();
    final regex = RegExp(r'^[0-9]{10}$');
    return regex.hasMatch(cleaned);
  }

  Future<void> _onGetOtpPressed() async {
    final raw = _phoneController.text;

    // ১) ইনপুট ভ্যালিডেশন
    if (!_isValidBangladeshiPhone(raw)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit Bangladeshi number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final fullPhone = '+880${raw.trim()}';

    // ২) ডাবল-ট্যাপ বন্ধ ও লোডিং স্টেট
    setState(() {
      _isSendingOtp = true;
    });

    try {
      // ৩) Firebase Phone Auth দিয়ে OTP পাঠানো
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android এ auto-verify হলে এখানে credential চলে আসে।
          // চাইলে এখানে সরাসরি signInWithCredential করেও দিতে পারো,
          // কিন্তু এখন আমরা ম্যানুয়াল OTP ফ্লো রাখছি, তাই কিছু করলাম না।
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _isSendingOtp = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to send OTP: ${e.message ?? e.code}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          // OTP সফলভাবে পাঠানো হয়েছে → OTP screen এ যাই
          if (!mounted) return;
          setState(() => _isSendingOtp = false);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpEntryScreen(
                selectedRole: widget.selectedRole,
                phoneNumber: fullPhone,
                verificationId:
                verificationId, // 🔹 OTP verify করার জন্য প্রয়োজন
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout; চাইলে verificationId stash করে রাখতে পারো
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingOtp = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send OTP. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
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
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // কন্টেন্ট সেন্টারে আনা হয়েছে
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.phonelink_lock,
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

                    const SizedBox(height: 40),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 25),
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: AppColors.cardPink,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Verify your phone",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "We will send you a One Time Password (OTP) on this mobile number",
                            style: TextStyle(
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: const Text(
                                  "+880",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "1712345678",
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                      vertical: 15,
                                      horizontal: 15,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed:
                              _isSendingOtp ? null : _onGetOtpPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandMain,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isSendingOtp
                                  ? const Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Sending OTP...",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                                  : const Text(
                                "Get OTP",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: RichText(
                                text: const TextSpan(
                                  text: "Already have an account? ",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Sign in",
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
}