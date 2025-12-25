import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/auth/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpEntryScreen extends StatefulWidget {
  final String selectedRole;
  final String phoneNumber;
  final String verificationId;

  const OtpEntryScreen({
    super.key,
    required this.selectedRole,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OtpEntryScreen> createState() => _OtpEntryScreenState();
}

class _OtpEntryScreenState extends State<OtpEntryScreen> {
  final List<FocusNode> _focusNodes =
  List.generate(6, (index) => FocusNode());
  final List<TextEditingController> _controllers =
  List.generate(6, (index) => TextEditingController());

  Timer? _timer;
  int _secondsRemaining = 156; // ২ মিনিট ৩৬ সেকেন্ড
  bool _isVerifying = false;
  bool _isResending = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _currentVerificationId;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 156;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String _getEnteredOtp() {
    return _controllers.map((c) => c.text.trim()).join();
  }

  Future<void> _onVerifyPressed() async {
    final otp = _getEnteredOtp();

    if (otp.length != 6 || otp.contains('')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit OTP code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SignUpScreen(
            phoneNumber: widget.phoneNumber,
            userRole: widget.selectedRole,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'OTP verification failed. Please try again.';
      if (e.code == 'invalid-verification-code') {
        msg = 'Invalid OTP code. Please check and try again.';
      } else if (e.code == 'session-expired') {
        msg = 'OTP session expired. Please request a new code.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP verification failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _onResendPressed() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {},
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _isResending = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to resend OTP: ${e.message ?? e.code}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _currentVerificationId = verificationId;
            _isResending = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text('A new OTP has been sent to ${widget.phoneNumber}'),
              backgroundColor: Colors.green[600],
            ),
          );

          _startTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _currentVerificationId = verificationId;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResending = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to resend OTP. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int min = _secondsRemaining ~/ 60;
    final int sec = _secondsRemaining % 60;

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

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_clock,
                      size: 80,
                      color: AppColors.brandDark,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "FINDUS",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
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
                        children: [
                          const Text(
                            "OTP Verification",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Enter code sent to\n${widget.phoneNumber}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _secondsRemaining > 0
                                ? "$min : ${sec.toString().padLeft(2, '0')}"
                                : "Code expired. You can resend a new OTP.",
                            style: TextStyle(
                              color: _secondsRemaining > 0
                                  ? Colors.red
                                  : Colors.orange[800],
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) {
                              return SizedBox(
                                width: 42,
                                height: 55,
                                child: TextField(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onChanged: (val) {
                                    if (val.length == 1 && index < 5) {
                                      _focusNodes[index + 1]
                                          .requestFocus();
                                    }
                                    if (val.isEmpty && index > 0) {
                                      _focusNodes[index - 1]
                                          .requestFocus();
                                    }
                                  },
                                  decoration: InputDecoration(
                                    counterText: "",
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed:
                              _isVerifying ? null : _onVerifyPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandMain,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isVerifying
                                  ? const Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                      AlwaysStoppedAnimation<
                                          Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Verifying...",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                                  : const Text(
                                "Verify & Proceed",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: (_secondsRemaining == 0 &&
                                !_isResending)
                                ? _onResendPressed
                                : null,
                            child: _isResending
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              "Resend OTP",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.brandMain,
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