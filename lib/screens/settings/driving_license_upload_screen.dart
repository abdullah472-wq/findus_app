import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/services/cloudinary_service.dart'; // 🔹 Cloudinary import

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

  // Cloudinary helper
  Future<String> _uploadToCloudinary(File file, String tag) async {
    final res = await CloudinaryService.uploadFile(
      file,
      folder: 'driving_license',
      resourceType: 'image',
      tags: [tag],
    );

    final url = res['secure_url'] ?? res['url'];
    if (url == null || url.toString().isEmpty) {
      throw Exception('Cloudinary URL missing');
    }
    return url.toString();
  }

  Future<void> _pickFrontImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _frontImage = File(picked.path));
  }

  Future<void> _pickBackImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _backImage = File(picked.path));
  }

  Future<void> _submitLicense() async {
    if (_frontImage == null && _backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text("Please upload at least front or back side."),
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

      String? frontUrl;
      String? backUrl;

      if (_frontImage != null) {
        frontUrl =
        await _uploadToCloudinary(_frontImage!, 'dl_front_$uid');
      }
      if (_backImage != null) {
        backUrl =
        await _uploadToCloudinary(_backImage!, 'dl_back_$uid');
      }

      // Local flag (shared prefs)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('driving_license_uploaded', true);

      // Firestore এ flag + URL সেভ
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(
        {
          'driving_license_uploaded': true,
          'drivingLicenseFrontUrl': frontUrl ?? '',
          'drivingLicenseBackUrl': backUrl ?? '',
        },
        SetOptions(merge: true),
      );

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
        SnackBar(
          content: Text(
            "Failed to submit driving license. Please try again.\n$e",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final bgColor =
    isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor =
    isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor =
    isDark ? Colors.white : AppColors.brandDark;
    final subTextColor =
    isDark ? Colors.grey.shade400 : Colors.black87;

    return FloatingScaffold(
      title: "DRIVING LICENSE",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: true,
      bodyPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Add your driving license",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Uploading your driving license helps build extra trust and may be required for some categories (e.g. driver, rider). We will securely store this document and will not show it publicly.",
            style: TextStyle(
              fontSize: 12,
              color: subTextColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          _buildImageCard(
            title: "Upload front side",
            imageFile: _frontImage,
            onTap: _pickFrontImage,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
          ),
          const SizedBox(height: 12),

          _buildImageCard(
            title: "Upload back side (optional)",
            imageFile: _backImage,
            onTap: _pickBackImage,
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
          ),

          const SizedBox(height: 20),

          Text(
            "Tips:",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "• Make sure the photo is clear and all text is readable.\n• Avoid glare or reflections.\n• Your document will be used only for verification purposes.",
            style: TextStyle(
              fontSize: 11,
              color: subTextColor,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed:
              _isSubmitting ? null : _submitLicense,
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
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildImageCard({
    required String title,
    required File? imageFile,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.grey.withOpacity(0.1)
                : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? Colors.black54 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.grey.withOpacity(0.2)
                      : Colors.grey.shade300,
                ),
              ),
              child: imageFile == null
                  ? const Icon(
                Icons.camera_alt_outlined,
                color: Colors.grey,
              )
                  : ClipRRect(
                borderRadius:
                BorderRadius.circular(8),
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
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
}