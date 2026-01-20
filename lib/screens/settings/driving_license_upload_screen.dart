import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:findus_app/constants/app_colors.dart';

class DrivingLicenseUploadScreen extends StatefulWidget {
  const DrivingLicenseUploadScreen({super.key});

  @override
  State<DrivingLicenseUploadScreen> createState() =>
      _DrivingLicenseUploadScreenState();
}

class _DrivingLicenseUploadScreenState
    extends State<DrivingLicenseUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _frontImage;
  File? _backImage;

  bool _isSubmitting = false;

  Future<void> _pickFrontImage() async {
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _frontImage = File(picked.path);
    });
  }

  Future<void> _pickBackImage() async {
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _backImage = File(picked.path);
    });
  }

  Future<void> _submitLicense() async {
    if (_frontImage == null && _backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please upload at least front or back side."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // TODO: এখানে আসল ফাইলগুলো Firebase Storage এ আপলোড করে
      // URL Firestore এ সেভ করবে। এখন শুধু ফ্ল্যাগ সেভ করছি।

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('driving_license_uploaded', true);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(
          {
            'driving_license_uploaded': true,
            // ভবিষ্যতে এখানে 'driving_license_front_url', 'driving_license_back_url'
            // যোগ করতে পারবে।
          },
          SetOptions(merge: true),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Driving license info submitted."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to submit driving license. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildImageCard({
    required String title,
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: imageFile == null
                  ? const Icon(
                Icons.camera_alt_outlined,
                color: Colors.grey,
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandDark,
                ),
              ),
            ),
            const Icon(
              Icons.upload_file_outlined,
              color: AppColors.brandMain,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add your driving license",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Uploading your driving license helps build extra trust and may be required for some categories (e.g. driver, rider). "
                      "We will securely store this document and will not show it publicly.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                _buildImageCard(
                  title: "Upload front side of license",
                  imageFile: _frontImage,
                  onTap: _pickFrontImage,
                ),
                const SizedBox(height: 12),

                _buildImageCard(
                  title: "Upload back side of license (optional)",
                  imageFile: _backImage,
                  onTap: _pickBackImage,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Tips:",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "• Make sure the photo is clear and all text is readable.\n"
                      "• Avoid glare or reflections.\n"
                      "• Your document will be used only for verification purposes.",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitLicense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandMain,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      "SUBMIT LICENSE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: const Text(
                                  "Driving License Upload",
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