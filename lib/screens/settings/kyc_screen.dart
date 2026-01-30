import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/cloudinary_service.dart'; // ← নিজের path অনুযায়ী ঠিক করো

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({super.key});

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends State<KycUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _fullNameController =
  TextEditingController();
  final TextEditingController _nidNumberController =
  TextEditingController();

  File? _nidFront;
  File? _nidBack;
  File? _selfie;

  bool _isSubmitting = false;

  // 👉 এখানে তোমার API base URL (Render সার্ভিস URL)
  static const String _apiBaseUrl =
      'https://findus-admin-panel.onrender.com';

  @override
  void dispose() {
    _fullNameController.dispose();
    _nidNumberController.dispose();
    super.dispose();
  }

  // ---------- Image Pick ----------
  Future<void> _pickImage(String which, ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() {
      final file = File(picked.path);
      if (which == 'nidFront') {
        _nidFront = file;
      } else if (which == 'nidBack') {
        _nidBack = file;
      } else if (which == 'selfie') {
        _selfie = file;
      }
    });
  }

  // ---------- Helper: Cloudinary upload ----------
  Future<String> _uploadToCloudinary(File file, String tag) async {
    final res = await CloudinaryService.uploadFile(
      file,
      folder: 'kyc', // চাইলে 'kyc/$uid' করবে
      resourceType: 'image',
      tags: [tag],
    );

    final url = res['secure_url'] ?? res['url'];
    if (url == null || url.toString().isEmpty) {
      throw Exception('Cloudinary URL missing');
    }
    return url.toString();
  }

  // ---------- Submit KYC ----------
  Future<void> _submitKyc() async {
    final fullName = _fullNameController.text.trim();
    final nidNumber = _nidNumberController.text.trim();

    if (fullName.isEmpty || nidNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Full name এবং NID number দিন।"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_nidFront == null || _selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text("কমপক্ষে NID front এবং Selfie আপলোড করতে হবে।"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please login first."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uid = user.uid;
      final idToken = await user.getIdToken(); // Firebase ID token

      // 1) Cloudinary তে upload
      final frontUrl =
      await _uploadToCloudinary(_nidFront!, 'nid_front_$uid');

      String? backUrl;
      if (_nidBack != null) {
        backUrl =
        await _uploadToCloudinary(_nidBack!, 'nid_back_$uid');
      }

      final selfieUrl =
      await _uploadToCloudinary(_selfie!, 'selfie_$uid');

      // 2) KYC API তে JSON পাঠাও
      final uri = Uri.parse('$_apiBaseUrl/api/kyc-submit');

      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'kycFullName': fullName,
          'kycNidNumber': nidNumber,
          'kycFrontImageUrl': frontUrl,
          'kycBackImageUrl': backUrl ?? '',
          'kycSelfieImageUrl': selfieUrl,
          'documentType': 'nid',
        }),
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text("KYC submitted successfully. Pending review."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to submit KYC (${resp.statusCode}).",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ---------- UI Helper: Photo Box ----------
  Widget _buildPhotoBox({
    required String label,
    required File? file,
    required VoidCallback onCameraTap,
    required VoidCallback onGalleryTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.brandDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color:
                AppColors.brandLight.withOpacity(isDark ? 0.2 : 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: file == null
                  ? const Center(
                child: Text(
                  "No image selected",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              )
                  : ClipRRect(
                borderRadius:
                BorderRadius.circular(12),
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: onCameraTap,
                icon:
                const Icon(Icons.photo_camera_outlined),
                label: const Text("Camera"),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onGalleryTap,
                icon: const Icon(
                    Icons.photo_library_outlined),
                label: const Text("Gallery"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final bgColor =
    isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final appBarColor =
    isDark ? const Color(0xFF2C2C2C) : AppColors.brandLight;
    final appBarTextColor =
    isDark ? Colors.white : AppColors.brandDark;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Main Content
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                  const EdgeInsets.fromLTRB(16, 90, 16, 16),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Upload your NID and a selfie",
                        style: TextStyle(
                          color: AppColors.brandDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "We will verify your identity to give you a verified badge. "
                            "Make sure the photos are clear and readable.",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Full name
                      TextField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: "Full name (as per NID)",
                          labelStyle: const TextStyle(
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: AppColors.brandMain,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // NID number
                      TextField(
                        controller: _nidNumberController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "NID Number",
                          labelStyle: const TextStyle(
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            color: AppColors.brandMain,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildPhotoBox(
                        label: "NID Front Side",
                        file: _nidFront,
                        onCameraTap: () =>
                            _pickImage('nidFront', ImageSource.camera),
                        onGalleryTap: () =>
                            _pickImage('nidFront', ImageSource.gallery),
                        isDark: isDark,
                      ),

                      _buildPhotoBox(
                        label: "NID Back Side (optional)",
                        file: _nidBack,
                        onCameraTap: () =>
                            _pickImage('nidBack', ImageSource.camera),
                        onGalleryTap: () =>
                            _pickImage('nidBack', ImageSource.gallery),
                        isDark: isDark,
                      ),

                      _buildPhotoBox(
                        label: "Selfie with NID",
                        file: _selfie,
                        onCameraTap: () =>
                            _pickImage('selfie', ImageSource.camera),
                        onGalleryTap: () =>
                            _pickImage('selfie', ImageSource.gallery),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom submit bar
              Container(
                padding:
                const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2C)
                      : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color:
                      Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                    _isSubmitting ? null : _submitKyc,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandMain,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      "SUBMIT FOR REVIEW",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Floating AppBar (upper)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: SafeArea(
              top: true,
              bottom: false,
              child: Container(
                height: kToolbarHeight,
                decoration: BoxDecoration(
                  color: appBarColor,
                  boxShadow: [
                    BoxShadow(
                      color:
                      Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: appBarTextColor,
                        size: 20,
                      ),
                      onPressed: () =>
                          Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "KYC VERIFICATION",
                        style: TextStyle(
                          color: appBarTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}