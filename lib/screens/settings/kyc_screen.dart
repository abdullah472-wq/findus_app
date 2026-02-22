// lib/screens/settings/kyc_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/cloudinary_service.dart';
import 'package:findus_app/services/theme_service.dart';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({super.key});

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends State<KycUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _nidNumberController = TextEditingController();

  File? _nidFront;
  File? _nidBack;
  File? _selfie;

  bool _isSubmitting = false;
  bool _agreedToTerms = false;

  // API base URL
  static const String _apiBaseUrl = 'https://findus-admin-panel.onrender.com';

  @override
  void dispose() {
    _fullNameController.dispose();
    _nidNumberController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // IMAGE PICKER
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _showImageSourceDialog(String which) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildImageSourceSheet(ctx),
    );

    if (source != null) {
      await _pickImage(which, source);
    }
  }

  Widget _buildImageSourceSheet(BuildContext ctx) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, settings, _) {
        final colors = _KycColors(
          isDark: settings.isDarkMode,
          useAmoled: settings.useAmoledBlack,
        );

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.subTextColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Choose Image Source",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: "Camera",
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  colors: colors,
                ),
                const SizedBox(height: 12),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: "Gallery",
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  colors: colors,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required _KycColors colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: colors.isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.brandMain.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.brandMain),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(String which, ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (picked == null) return;

      final file = File(picked.path);
      final fileSize = await file.length();

      // Check file size (max 5MB)
      if (fileSize > 5 * 1024 * 1024) {
        if (mounted) {
          _showErrorSnackbar("Image size must be less than 5MB");
        }
        return;
      }

      setState(() {
        if (which == 'nidFront') {
          _nidFront = file;
        } else if (which == 'nidBack') {
          _nidBack = file;
        } else if (which == 'selfie') {
          _selfie = file;
        }
      });

      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar("Failed to pick image: $e");
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CLOUDINARY UPLOAD
  // ════════════════════════════════════════════════════════════════════════════

  Future<String> _uploadToCloudinary(File file, String tag) async {
    try {
      final res = await CloudinaryService.uploadFile(
        file,
        folder: 'kyc',
        resourceType: 'image',
        tags: [tag],
      );

      final url = res['secure_url'] ?? res['url'];
      if (url == null || url.toString().isEmpty) {
        throw Exception('Cloudinary URL missing');
      }
      return url.toString();
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SUBMIT KYC
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nidFront == null || _selfie == null) {
      _showErrorSnackbar("Please upload NID front and selfie");
      return;
    }

    if (!_agreedToTerms) {
      _showErrorSnackbar("Please agree to terms and conditions");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackbar("Please login first");
      return;
    }

    // Show confirmation dialog
    final confirm = await _showConfirmDialog();
    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final uid = user.uid;
      final idToken = await user.getIdToken();

      // Upload images to Cloudinary
      debugPrint('📤 Uploading NID front...');
      final frontUrl = await _uploadToCloudinary(_nidFront!, 'nid_front_$uid');

      String? backUrl;
      if (_nidBack != null) {
        debugPrint('📤 Uploading NID back...');
        backUrl = await _uploadToCloudinary(_nidBack!, 'nid_back_$uid');
      }

      debugPrint('📤 Uploading selfie...');
      final selfieUrl = await _uploadToCloudinary(_selfie!, 'selfie_$uid');

      // Submit to API
      debugPrint('📡 Submitting KYC to API...');
      final uri = Uri.parse('$_apiBaseUrl/api/kyc-submit');

      final resp = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'kycFullName': _fullNameController.text.trim(),
          'kycNidNumber': _nidNumberController.text.trim(),
          'kycFrontImageUrl': frontUrl,
          'kycBackImageUrl': backUrl ?? '',
          'kycSelfieImageUrl': selfieUrl,
          'documentType': 'nid',
        }),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (resp.statusCode == 200) {
        _showSuccessDialog();
      } else {
        final error = jsonDecode(resp.body);
        _showErrorSnackbar(
          error['message'] ?? "Failed to submit (${resp.statusCode})",
        );
      }
    } on TimeoutException {
      if (mounted) {
        _showErrorSnackbar("Request timeout. Please try again.");
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar("Error: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DIALOGS
  // ════════════════════════════════════════════════════════════════════════════

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: AppColors.brandMain),
            SizedBox(width: 10),
            Text("Confirm Submission"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "You are about to submit the following for KYC verification:",
            ),
            const SizedBox(height: 12),
            _buildConfirmItem("Full Name", _fullNameController.text.trim()),
            _buildConfirmItem("NID Number", _nidNumberController.text.trim()),
            _buildConfirmItem("NID Front", _nidFront != null ? "✓" : "✗"),
            _buildConfirmItem("NID Back", _nidBack != null ? "✓" : "Optional"),
            _buildConfirmItem("Selfie", _selfie != null ? "✓" : "✗"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Please ensure all information is correct. Verification may take 1-3 business days.",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
            ),
            child: const Text("Submit"),
          ),
        ],
      ),
    ) ??
        false;
  }

  Widget _buildConfirmItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "KYC Submitted!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your KYC documents have been submitted for review. "
                  "We'll notify you once verified (usually 1-3 business days).",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Close KYC screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD UI
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, settings, _) {
        final colors = _KycColors(
          isDark: settings.isDarkMode,
          useAmoled: settings.useAmoledBlack,
        );

        return Scaffold(
          backgroundColor: colors.bgColor,
          body: Stack(
            children: [
              // Main Content
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          MediaQuery.of(context).padding.top + kToolbarHeight + 20,
                          16,
                          16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Info Card
                            _buildInfoCard(colors),
                            const SizedBox(height: 20),

                            // Form Fields
                            _buildTextField(
                              controller: _fullNameController,
                              label: "Full Name (as per NID)",
                              icon: Icons.person_outline,
                              colors: colors,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return "Full name is required";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            _buildTextField(
                              controller: _nidNumberController,
                              label: "NID Number",
                              icon: Icons.badge_outlined,
                              keyboardType: TextInputType.number,
                              colors: colors,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return "NID number is required";
                                }
                                if (val.trim().length < 10) {
                                  return "Enter valid NID number";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Image Uploads
                            _buildPhotoBox(
                              label: "NID Front Side *",
                              file: _nidFront,
                              onTap: () => _showImageSourceDialog('nidFront'),
                              colors: colors,
                            ),

                            _buildPhotoBox(
                              label: "NID Back Side (optional)",
                              file: _nidBack,
                              onTap: () => _showImageSourceDialog('nidBack'),
                              colors: colors,
                            ),

                            _buildPhotoBox(
                              label: "Selfie with NID *",
                              file: _selfie,
                              onTap: () => _showImageSourceDialog('selfie'),
                              colors: colors,
                            ),

                            // Terms Checkbox
                            _buildTermsCheckbox(colors),

                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),

                    // Submit Button
                    _buildSubmitButton(colors),
                  ],
                ),
              ),

              // Floating AppBar
              _buildFloatingAppBar(colors),

              // Loading Overlay
              if (_isSubmitting) _buildLoadingOverlay(colors),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(_KycColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandMain.withOpacity(0.1),
            AppColors.brandMain.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandMain.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brandMain.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user,
              color: AppColors.brandMain,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Get Verified Badge",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Upload clear photos of your NID and a selfie. "
                      "Verification typically takes 1-3 business days.",
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.subTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required _KycColors colors,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: colors.textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.subTextColor),
        prefixIcon: Icon(icon, color: AppColors.brandMain),
        filled: true,
        fillColor: colors.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colors.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandMain, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPhotoBox({
    required String label,
    required File? file,
    required VoidCallback onTap,
    required _KycColors colors,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  file != null ? Icons.check_circle : Icons.upload_file,
                  color: file != null ? Colors.green : AppColors.brandMain,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                decoration: BoxDecoration(
                  color: colors.isDark
                      ? Colors.white.withOpacity(0.05)
                      : AppColors.brandLight.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: file == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 40,
                      color: colors.subTextColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap to upload",
                      style: TextStyle(
                        color: colors.subTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.file(file, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox(_KycColors colors) {
    return CheckboxListTile(
      value: _agreedToTerms,
      onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
      activeColor: AppColors.brandMain,
      title: Text.rich(
        TextSpan(
          text: "I agree that the information provided is accurate and I accept the ",
          style: TextStyle(fontSize: 12, color: colors.textColor),
          children: const [
            TextSpan(
              text: "Terms & Conditions",
              style: TextStyle(
                color: AppColors.brandMain,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildSubmitButton(_KycColors colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitKyc,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandMain,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, size: 20),
            SizedBox(width: 10),
            Text(
              "SUBMIT FOR VERIFICATION",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingAppBar(_KycColors colors) {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: SafeArea(
        child: Container(
          height: kToolbarHeight,
          decoration: BoxDecoration(
            color: colors.cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: colors.textColor,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  "KYC VERIFICATION",
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              if (!_isSubmitting)
                IconButton(
                  icon: Icon(Icons.info_outline, color: colors.subTextColor),
                  onPressed: () {
                    // Show help dialog
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(_KycColors colors) {
    return Positioned.fill(
      child: Container(
        color: colors.bgColor.withOpacity(0.9),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.brandMain),
              const SizedBox(height: 20),
              Text(
                "Uploading documents...",
                style: TextStyle(
                  color: colors.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please don't close the app",
                style: TextStyle(
                  color: colors.subTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ════════════════════════════════════════════════════════════════════════════

class _KycColors {
  final bool isDark;
  final bool useAmoled;

  _KycColors({required this.isDark, this.useAmoled = false});

  Color get bgColor {
    if (isDark && useAmoled) return Colors.black;
    if (isDark) return const Color(0xFF1A1A1A);
    return AppColors.bgBlue;
  }

  Color get cardColor {
    if (isDark && useAmoled) return const Color(0xFF0A0A0A);
    if (isDark) return const Color(0xFF2C2C2C);
    return Colors.white;
  }

  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.grey.shade400 : Colors.grey.shade600;
}