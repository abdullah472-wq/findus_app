import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/settings/settings_screen.dart'; // VerificationScreen
import 'package:findus_app/services/profile_completion_service.dart';
import 'package:findus_app/services/cloudinary_service.dart';

class SupporterProfileEditScreen extends StatefulWidget {
  const SupporterProfileEditScreen({super.key});

  @override
  State<SupporterProfileEditScreen> createState() => _SupporterProfileEditScreenState();
}

class _SupporterProfileEditScreenState extends State<SupporterProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Keys
  static const _kName = 'user_name';
  static const _kPhone = 'user_phone';
  static const _kPhone2 = 'user_phone2';
  static const _kLocation = 'user_location';
  static const _kEmail = 'user_email';
  static const _kFacebook = 'user_facebook';
  static const _kInstagram = 'user_instagram';
  static const _kLinkedin = 'user_linkedin';

  static const _kCompanyName = 'company_name';
  static const _kCompanyContact = 'company_contact';
  static const _kCompanyAddress = 'company_address';

  static const _kGender = 'user_gender';
  static const _kAge = 'user_age';
  static const _kImage = 'user_profile_image';
  static const _kKycCompleted = 'kyc_completed';

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _locationController = TextEditingController();

  final _emailController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _linkedinController = TextEditingController();

  final _companyNameController = TextEditingController();
  final _companyContactController = TextEditingController();
  final _companyAddressController = TextEditingController();

  // Selections
  String _selectedGender = 'Male';
  int? _selectedAge;
  String? _profileImageUrl;

  bool _showSecondPhone = false;
  bool _isSaving = false;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _kycCompleted = false;

  double _completion = 0.0;
  final int _totalFields = 11; // name, phone, location, email, gender, age, image, companyName, companyContact, companyAddress, kyc

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose(); _phoneController.dispose(); _phone2Controller.dispose();
    _locationController.dispose(); _emailController.dispose(); _facebookController.dispose();
    _instagramController.dispose(); _linkedinController.dispose();
    _companyNameController.dispose(); _companyContactController.dispose(); _companyAddressController.dispose();
    super.dispose();
  }

  void _recalculateCompletion() {
    int filled = 0;
    bool notEmpty(TextEditingController c) => c.text.trim().isNotEmpty;

    if (notEmpty(_nameController)) filled++;
    if (notEmpty(_phoneController)) filled++;
    if (notEmpty(_locationController)) filled++;
    if (notEmpty(_emailController)) filled++;
    if (notEmpty(_companyNameController)) filled++;
    if (notEmpty(_companyContactController)) filled++;
    if (notEmpty(_companyAddressController)) filled++;
    if (_selectedAge != null) filled++;
    if (_profileImageUrl != null) filled++;
    if (_kycCompleted) filled++;
    filled++; // Gender has default

    setState(() => _completion = filled / _totalFields);
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString(_kName) ?? '';
      _phoneController.text = prefs.getString(_kPhone) ?? '';
      _phone2Controller.text = prefs.getString(_kPhone2) ?? '';
      _showSecondPhone = _phone2Controller.text.trim().isNotEmpty;
      _locationController.text = prefs.getString(_kLocation) ?? '';
      _emailController.text = prefs.getString(_kEmail) ?? '';
      _facebookController.text = prefs.getString(_kFacebook) ?? '';
      _instagramController.text = prefs.getString(_kInstagram) ?? '';
      _linkedinController.text = prefs.getString(_kLinkedin) ?? '';
      _companyNameController.text = prefs.getString(_kCompanyName) ?? '';
      _companyContactController.text = prefs.getString(_kCompanyContact) ?? '';
      _companyAddressController.text = prefs.getString(_kCompanyAddress) ?? '';
      _selectedGender = prefs.getString(_kGender) ?? 'Male';
      _selectedAge = prefs.getInt(_kAge);
      _profileImageUrl = prefs.getString(_kImage);
      _kycCompleted = prefs.getBool(_kKycCompleted) ?? false;
      _isLoading = false;
    });
    _recalculateCompletion();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final res = await CloudinaryService.uploadFile(File(pickedFile.path), folder: 'profiles/supporters');
      final url = res['secure_url'].toString();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kImage, url);

      setState(() {
        _profileImageUrl = url;
        _isUploadingImage = false;
      });
      _recalculateCompletion();
    } catch (e) {
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image upload failed")));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kName, _nameController.text.trim());
      await prefs.setString(_kPhone, _phoneController.text.trim());
      await prefs.setString(_kLocation, _locationController.text.trim());
      await prefs.setString(_kEmail, _emailController.text.trim());
      await prefs.setString(_kFacebook, _facebookController.text.trim());
      await prefs.setString(_kInstagram, _instagramController.text.trim());
      await prefs.setString(_kLinkedin, _linkedinController.text.trim());
      await prefs.setString(_kCompanyName, _companyNameController.text.trim());
      await prefs.setString(_kCompanyContact, _companyContactController.text.trim());
      await prefs.setString(_kCompanyAddress, _companyAddressController.text.trim());
      await prefs.setString(_kGender, _selectedGender);
      if (_selectedAge != null) await prefs.setInt(_kAge, _selectedAge!);

      // Sync to Firebase if needed
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': _nameController.text.trim(),
          'companyName': _companyNameController.text.trim(),
          'image': _profileImageUrl,
        }, SetOptions(merge: true));
      }

      await ProfileCompletionService.forceSyncFromLocal();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Save failed")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: AppColors.brandDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0.5, iconTheme: const IconThemeData(color: AppColors.brandDark),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SafeArea(
        child: Column(
          children: [
            _buildProgressHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageSection(),
                      const SizedBox(height: 24),
                      _buildLabel("Basic Information"),
                      _buildTextField("Full Name", _nameController, Icons.person),
                      const SizedBox(height: 12),
                      _buildTextField("Phone Number", _phoneController, Icons.phone, keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildGenderDropdown()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildAgeDropdown()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField("Personal Address", _locationController, Icons.location_on),

                      const SizedBox(height: 24),
                      _buildLabel("Company Information"),
                      _buildTextField("Company Name", _companyNameController, Icons.business),
                      const SizedBox(height: 12),
                      _buildTextField("Company Contact", _companyContactController, Icons.contact_phone, keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      _buildTextField("Company Address", _companyAddressController, Icons.map, maxLines: 2),

                      const SizedBox(height: 24),
                      _buildLabel("Social Links"),
                      _buildTextField("Email Address", _emailController, Icons.email),
                      const SizedBox(height: 12),
                      _buildTextField("Facebook URL", _facebookController, Icons.link),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.brandLight.withOpacity(0.3),
      child: Column(
        children: [
          Row(children: [
            Text("Profile Completion: ${( _completion * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Icon(Icons.stars, color: _completion >= 1 ? Colors.orange : Colors.grey),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _completion, backgroundColor: Colors.white, valueColor: const AlwaysStoppedAnimation(AppColors.brandMain)),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
            child: _profileImageUrl == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
          ),
          if (_isUploadingImage)
            const Positioned.fill(child: CircularProgressIndicator(strokeWidth: 2)),
          Positioned(
            bottom: 0, right: 0,
            child: GestureDetector(
              onTap: _pickAndUploadImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: AppColors.brandMain, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brandDark)));

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) => _recalculateCompletion(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.brandMain, size: 20),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(labelText: "Gender", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      onChanged: (v) => setState(() => _selectedGender = v!),
    );
  }

  Widget _buildAgeDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedAge,
      hint: const Text("Age"),
      decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      items: List.generate(53, (index) => index + 18).map((age) => DropdownMenuItem(value: age, child: Text(age.toString()))).toList(),
      onChanged: (v) {
        setState(() => _selectedAge = v);
        _recalculateCompletion();
      },
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
      child: SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandMain, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}