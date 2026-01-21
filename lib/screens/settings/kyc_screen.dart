import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:findus_app/constants/app_colors.dart';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({super.key});

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends State<KycUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _nidFront;
  File? _nidBack;
  File? _selfie;
  bool _isSubmitting = false;

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

  // ---------- Submit KYC ----------
  Future<void> _submitKyc() async {
    if (_nidFront == null || _nidBack == null || _selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload all required photos first."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // TODO: এখানে তোমার আসল Backend API URL দিও
      final uri = Uri.parse('https://your-api.com/kyc/submit');

      final request = http.MultipartRequest('POST', uri);

      // TODO: ব্যাকএন্ড অনুযায়ী ফিল্ড কাস্টমাইজ করো
      request.fields['user_id'] = '123';        // logged in user ID
      request.fields['document_type'] = 'nid';  // nid / passport / license ইত্যাদি

      request.files.add(
        await http.MultipartFile.fromPath(
          'nid_front',
          _nidFront!.path,
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'nid_back',
          _nidBack!.path,
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'selfie',
          _selfie!.path,
        ),
      );

      final response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("KYC submitted successfully. Pending review."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // আগের স্ক্রিনে ফিরে যাবে (VerificationScreen)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit KYC (${response.statusCode})."),
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                color: AppColors.brandLight.withOpacity(0.4),
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
                borderRadius: BorderRadius.circular(12),
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
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text("Camera"),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onGalleryTap,
                icon: const Icon(Icons.photo_library_outlined),
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Main Content
          Column(
            children: [
              // উপরের অংশ: ফর্ম (with adjusted padding for floating AppBar)
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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

                      _buildPhotoBox(
                        label: "NID Front Side",
                        file: _nidFront,
                        onCameraTap: () =>
                            _pickImage('nidFront', ImageSource.camera),
                        onGalleryTap: () =>
                            _pickImage('nidFront', ImageSource.gallery),
                      ),

                      _buildPhotoBox(
                        label: "NID Back Side",
                        file: _nidBack,
                        onCameraTap: () =>
                            _pickImage('nidBack', ImageSource.camera),
                        onGalleryTap: () =>
                            _pickImage('nidBack', ImageSource.gallery),
                      ),

                      _buildPhotoBox(
                        label: "Selfie with NID",
                        file: _selfie,
                        onCameraTap: () =>
                            _pickImage('selfie', ImageSource.camera),
                        onGalleryTap: () =>
                            _pickImage('selfie', ImageSource.gallery),
                      ),
                    ],
                  ),
                ),
              ),

              // নিচের অংশ: Submit বাটন
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitKyc,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandMain,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
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

          // Floating AppBar (KYC-style)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          // Back Button
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.brandDark,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),

                          // Title
                          const Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Text(
                                  "KYC Verification",
                                  style: TextStyle(
                                    color: AppColors.brandDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
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
          ),
        ],
      ),
    );
  }
}