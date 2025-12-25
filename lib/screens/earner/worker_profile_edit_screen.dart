import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/screens/settings/kyc_screen.dart';
import 'package:findus_app/screens/earner/worker_cv_create_screen.dart';

import 'package:findus_app/services/portfolio_service.dart';
import 'package:findus_app/services/profile_completion_service.dart';
import 'package:findus_app/services/cloudinary_service.dart';

class WorkerProfileEditScreen extends StatefulWidget {
  final Worker worker;

  const WorkerProfileEditScreen({
    super.key,
    required this.worker,
  });

  @override
  State<WorkerProfileEditScreen> createState() => _WorkerProfileEditScreenState();
}

class _WorkerProfileEditScreenState extends State<WorkerProfileEditScreen> {
  // Basic info
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _aboutController;

  // Extra fields
  late TextEditingController _experienceController;
  late TextEditingController _languagesController;
  late TextEditingController _availabilityController;

  // Phones
  late TextEditingController _phoneController1;
  late TextEditingController _phoneController2;
  bool _showSecondPhone = false;

  // Social/contact
  late TextEditingController _emailController;
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;
  late TextEditingController _linkedinController;

  // Selects
  final List<String> _serviceTypes = const [
    'Electrician',
    'Plumber',
    'AC Repair',
    'Cleaner',
    'Carpenter',
    'Painter',
    'Mechanic',
    'Other',
  ];

  final List<String> _genders = const [
    'Male',
    'Female',
    'Other',
  ];

  String? _selectedServiceType;
  String? _selectedGender;
  int? _selectedAge;

  // Working area
  bool _allOverBangladesh = true;
  final TextEditingController _specificAreasController = TextEditingController();

  // Profile image (Web + Mobile safe)
  final ImagePicker _picker = ImagePicker();
  Uint8List? _profileImageBytes; // preview bytes
  XFile? _pickedProfileXFile; // upload handle
  String? _profileImageUrl;
  bool _isUploadingImage = false;

  // Completion + saving
  double _completionPercent = 0.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.worker.name);
    _locationController = TextEditingController(text: widget.worker.location);
    _priceController = TextEditingController(text: widget.worker.price);
    _aboutController = TextEditingController(text: widget.worker.message);

    _experienceController = TextEditingController();
    _languagesController = TextEditingController();
    _availabilityController = TextEditingController();

    _phoneController1 = TextEditingController();
    _phoneController2 = TextEditingController();

    _emailController = TextEditingController();
    _facebookController = TextEditingController();
    _instagramController = TextEditingController();
    _linkedinController = TextEditingController();

    _loadInitialFromPrefs();
    _loadProfileCompletion();
  }

  Future<void> _loadInitialFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _phoneController1.text = prefs.getString('user_phone') ?? '';
      _phoneController2.text = prefs.getString('user_phone2') ?? '';
      _showSecondPhone = _phoneController2.text.trim().isNotEmpty;

      _emailController.text = prefs.getString('user_email') ?? '';
      _facebookController.text = prefs.getString('user_facebook') ?? '';
      _instagramController.text = prefs.getString('user_instagram') ?? '';
      _linkedinController.text = prefs.getString('user_linkedin') ?? '';

      _experienceController.text = prefs.getString('worker_experience') ?? '';
      _languagesController.text = prefs.getString('worker_languages') ?? '';
      _availabilityController.text = prefs.getString('worker_availability') ?? '';

      _allOverBangladesh = prefs.getBool('worker_all_over_bd') ?? true;
      _specificAreasController.text =
          prefs.getString('worker_specific_areas') ?? '';

      _selectedServiceType = prefs.getString('worker_service_type');
      _selectedGender = prefs.getString('worker_gender');
      _selectedAge = prefs.getInt('worker_age');

      _profileImageUrl = prefs.getString('user_profile_image');

      if (!mounted) return;
      setState(() {});
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadProfileCompletion() async {
    try {
      final pct = await ProfileCompletionService.completionPercent();
      if (!mounted) return;
      setState(() {
        _completionPercent = pct.clamp(0.0, 1.0);
      });
    } catch (_) {
      // ignore
    }
  }

  ImageProvider? _getProfileImageProvider() {
    if (_profileImageBytes != null) return MemoryImage(_profileImageBytes!);

    final url = (_profileImageUrl ?? widget.worker.image).toString().trim();
    if (url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      return NetworkImage(url);
    }
    return null;
  }

  Future<void> _pickAndUploadProfileImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1080,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    if (!mounted) return;
    setState(() {
      _pickedProfileXFile = picked;
      _profileImageBytes = bytes; // সাথে সাথে প্রিভিউ
      _isUploadingImage = true;
    });

    try {
      final data = await CloudinaryService.uploadFile(
        picked, // ✅ XFile পাঠাচ্ছি (File নয়)
        folder: 'findus/profile_images',
        resourceType: 'image',
        tags: const ['profile'],
      );

      final url = (data['secure_url'] ?? '').toString().trim();
      if (url.isEmpty) {
        throw Exception('Cloudinary secure_url empty');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile_image', url);

      if (!mounted) return;
      setState(() {
        _profileImageUrl = url;
        _isUploadingImage = false;
      });

      _loadProfileCompletion();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image uploaded'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image upload failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pickAndUploadPortfolioImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;

    try {
      await PortfolioService.uploadPortfolioImages(picked); // ✅ List<XFile>

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Portfolio images uploaded'),
          backgroundColor: Colors.green,
        ),
      );
      _loadProfileCompletion();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload portfolio images: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // CV upload (এখানে এখনো গ্যালারি থেকে নেয়া—PDF চাইলে পরে file_picker লাগবে)
  Future<void> _pickAndUploadCv() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      await PortfolioService.uploadCv(picked); // ✅ XFile

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CV uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadProfileCompletion();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload CV: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Certificates upload
  Future<void> _pickAndUploadCertificates() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;

    try {
      await PortfolioService.uploadCertificates(picked); // ✅ List<XFile>

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certificates uploaded'),
          backgroundColor: Colors.green,
        ),
      );
      _loadProfileCompletion();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload certificates: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _aboutController.dispose();

    _phoneController1.dispose();
    _phoneController2.dispose();

    _experienceController.dispose();
    _languagesController.dispose();
    _availabilityController.dispose();

    _emailController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();

    _specificAreasController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final price = _priceController.text.trim();
    final about = _aboutController.text.trim();

    final phone1 = _phoneController1.text.trim();
    final phone2 = _phoneController2.text.trim();

    final experience = _experienceController.text.trim();
    final languages = _languagesController.text.trim();
    final availability = _availabilityController.text.trim();

    final email = _emailController.text.trim();
    final facebook = _facebookController.text.trim();
    final instagram = _instagramController.text.trim();
    final linkedin = _linkedinController.text.trim();

    final specificAreas = _specificAreasController.text.trim();

    if (name.isEmpty || name.length < 3) {
      _showError("Please enter your full name (at least 3 characters)");
      return;
    }
    if (_selectedServiceType == null || _selectedServiceType!.trim().isEmpty) {
      _showError("Please select your service type");
      return;
    }
    if (_selectedGender == null || _selectedGender!.trim().isEmpty) {
      _showError("Please select your gender");
      return;
    }
    if (_selectedAge == null) {
      _showError("Please select your age");
      return;
    }
    if (phone1.isEmpty) {
      _showError("Please enter your main phone number");
      return;
    }
    if (location.isEmpty) {
      _showError("Please enter your main working location");
      return;
    }
    if (price.isEmpty) {
      _showError("Please enter your service charge or 'Negotiable'");
      return;
    }
    if (!_allOverBangladesh && specificAreas.isEmpty) {
      _showError(
          "Please enter specific area names or select All over Bangladesh");
      return;
    }
    if (_isUploadingImage) {
      _showError("Please wait for image upload to finish");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('user_name', name);
      await prefs.setString('user_location', location);
      await prefs.setString('worker_price', price);
      await prefs.setString('user_about', about);

      await prefs.setString('user_phone', phone1);
      if (phone2.isNotEmpty) {
        await prefs.setString('user_phone2', phone2);
      } else {
        await prefs.remove('user_phone2');
      }

      if (experience.isNotEmpty) {
        await prefs.setString('worker_experience', experience);
      } else {
        await prefs.remove('worker_experience');
      }

      if (languages.isNotEmpty) {
        await prefs.setString('worker_languages', languages);
      } else {
        await prefs.remove('worker_languages');
      }

      if (availability.isNotEmpty) {
        await prefs.setString('worker_availability', availability);
      } else {
        await prefs.remove('worker_availability');
      }

      await prefs.setString('worker_service_type', _selectedServiceType!);
      await prefs.setString('worker_gender', _selectedGender!);
      await prefs.setInt('worker_age', _selectedAge!);

      if (email.isNotEmpty) {
        await prefs.setString('user_email', email);
      } else {
        await prefs.remove('user_email');
      }
      if (facebook.isNotEmpty) {
        await prefs.setString('user_facebook', facebook);
      } else {
        await prefs.remove('user_facebook');
      }
      if (instagram.isNotEmpty) {
        await prefs.setString('user_instagram', instagram);
      } else {
        await prefs.remove('user_instagram');
      }
      if (linkedin.isNotEmpty) {
        await prefs.setString('user_linkedin', linkedin);
      } else {
        await prefs.remove('user_linkedin');
      }

      await prefs.setBool('worker_all_over_bd', _allOverBangladesh);
      if (_allOverBangladesh) {
        await prefs.remove('worker_specific_areas');
      } else {
        await prefs.setString('worker_specific_areas', specificAreas);
      }

      final cleanedProfileUrl = (_profileImageUrl ?? '').trim();
      if (cleanedProfileUrl.isNotEmpty) {
        await prefs.setString('user_profile_image', cleanedProfileUrl);
      } else {
        await prefs.remove('user_profile_image');
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final data = <String, dynamic>{
          'name': name,
          'location': location,
          'price': price,

          'about': about.isEmpty ? FieldValue.delete() : about,

          'service_type': _selectedServiceType,
          'gender': _selectedGender,
          'age': _selectedAge,

          'experience': experience.isEmpty ? FieldValue.delete() : experience,
          'languages': languages.isEmpty ? FieldValue.delete() : languages,
          'availability': availability.isEmpty ? FieldValue.delete() : availability,

          'phone': phone1,
          'phone_alt': phone2.isEmpty ? FieldValue.delete() : phone2,

          'email': email.isEmpty ? FieldValue.delete() : email,
          'facebook': facebook.isEmpty ? FieldValue.delete() : facebook,
          'instagram': instagram.isEmpty ? FieldValue.delete() : instagram,
          'linkedin': linkedin.isEmpty ? FieldValue.delete() : linkedin,

          'working_all_over_bd': _allOverBangladesh,
          'working_specific_areas': _allOverBangladesh
              ? FieldValue.delete()
              : (specificAreas.isEmpty ? FieldValue.delete() : specificAreas),

          'image': cleanedProfileUrl.isEmpty ? FieldValue.delete() : cleanedProfileUrl,
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(data, SetOptions(merge: true));
      }

      await ProfileCompletionService.forceSyncFromLocal();

      final updatedImage = (cleanedProfileUrl.isNotEmpty)
          ? cleanedProfileUrl
          : widget.worker.image;

      final updatedWorker = Worker(
        id: widget.worker.id,
        name: name,
        role: widget.worker.role,
        image: updatedImage,
        message: about,
        medals: widget.worker.medals,
        isVerified: widget.worker.isVerified,
        rating: widget.worker.rating,
        location: location,
        price: price,
      );

      if (!mounted) return;
      Navigator.pop(context, updatedWorker);
    } catch (_) {
      if (!mounted) return;
      _showError("Could not save profile. Please try again.");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openKycScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KycUploadScreen()),
    );
    _loadProfileCompletion();
  }

  Future<void> _openCvCreateScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerCVCreateScreen(worker: widget.worker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double pct = (_completionPercent * 100).clamp(0, 100).toDouble();
    final imgProvider = _getProfileImageProvider();

    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        backgroundColor: AppColors.brandLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile completion overview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person_pin_circle,
                          size: 18,
                          color: AppColors.brandDark,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Profile Completion",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandDark,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${pct.toInt()}%",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: _completionPercent,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.brandMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Profile Photo (Cloudinary)
              _buildLabel("Profile Photo"),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: AppColors.brandLight,
                          backgroundImage: imgProvider,
                          child: imgProvider == null
                              ? const Icon(Icons.person, size: 34, color: Colors.grey)
                              : null,
                        ),
                        InkWell(
                          onTap: (_isUploadingImage || _isSaving)
                              ? null
                              : _pickAndUploadProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: _isUploadingImage
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: AppColors.brandDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Upload a clear profile photo.\nThis will be shown publicly.",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Name
              _buildLabel("Full Name"),
              _buildTextField(
                controller: _nameController,
                hint: "e.g. Karim Electrician",
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 16),

              // Service Type (select)
              _buildLabel("Service Type"),
              _buildDropdownField<String>(
                value: _selectedServiceType,
                items: _serviceTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                hint: "Select your service type",
                icon: Icons.design_services_outlined,
                onChanged: (v) => setState(() => _selectedServiceType = v),
              ),

              const SizedBox(height: 16),

              // Gender (select)
              _buildLabel("Gender"),
              _buildDropdownField<String>(
                value: _selectedGender,
                items: _genders
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                hint: "Select gender",
                icon: Icons.wc_outlined,
                onChanged: (v) => setState(() => _selectedGender = v),
              ),

              const SizedBox(height: 16),

              // Age (select)
              _buildLabel("Age"),
              _buildDropdownField<int>(
                value: _selectedAge,
                items: List.generate(53, (i) => i + 18) // 18..70
                    .map((age) =>
                    DropdownMenuItem(value: age, child: Text('$age')))
                    .toList(),
                hint: "Select age",
                icon: Icons.cake_outlined,
                onChanged: (v) => setState(() => _selectedAge = v),
              ),

              const SizedBox(height: 16),

              // Location
              _buildLabel("Main Location"),
              _buildTextField(
                controller: _locationController,
                hint: "e.g. Mirpur, Dhaka",
                icon: Icons.location_on_outlined,
              ),

              const SizedBox(height: 16),

              // Service Charge
              _buildLabel("Service Charge"),
              _buildTextField(
                controller: _priceController,
                hint: "e.g. ৳800 / day or Negotiable",
                icon: Icons.attach_money,
              ),

              const SizedBox(height: 16),

              // About Me
              _buildLabel("About Me"),
              TextField(
                controller: _aboutController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Short description about your experience, skills...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Experience
              _buildLabel("Experience"),
              _buildTextField(
                controller: _experienceController,
                hint: "e.g. 5+ Years",
                icon: Icons.work_history,
              ),

              const SizedBox(height: 16),

              // Languages
              _buildLabel("Languages"),
              _buildTextField(
                controller: _languagesController,
                hint: "e.g. Bangla, English",
                icon: Icons.translate,
              ),

              const SizedBox(height: 16),

              // Availability
              _buildLabel("Availability"),
              _buildTextField(
                controller: _availabilityController,
                hint: "e.g. 9 AM - 8 PM",
                icon: Icons.schedule,
              ),

              const SizedBox(height: 20),

              // Contact Info
              _buildLabel("Contact Info"),

              _buildTextField(
                controller: _phoneController1,
                hint: "Primary phone number",
                icon: Icons.phone,
              ),
              const SizedBox(height: 10),

              if (_showSecondPhone)
                _buildTextField(
                  controller: _phoneController2,
                  hint: "Secondary phone number (optional)",
                  icon: Icons.phone_in_talk,
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _showSecondPhone = true),
                    icon: const Icon(
                      Icons.add,
                      size: 18,
                      color: AppColors.brandMain,
                    ),
                    label: const Text(
                      "Add another number",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.brandMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              _buildTextField(
                controller: _emailController,
                hint: "Email address",
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _facebookController,
                hint: "Facebook profile/page link",
                icon: Icons.facebook,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _instagramController,
                hint: "Instagram profile link",
                icon: Icons.camera_alt_outlined,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _linkedinController,
                hint: "LinkedIn profile link",
                icon: Icons.business_center_outlined,
              ),

              const SizedBox(height: 20),

              // KYC & CV Section
              _buildLabel("Verification & CV"),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openKycScreen,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.brandMain),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.verified_user,
                        color: AppColors.brandMain,
                        size: 18,
                      ),
                      label: const Text(
                        "KYC Verification",
                        style: TextStyle(
                          color: AppColors.brandMain,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openCvCreateScreen,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.brandMain),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.description_outlined,
                        color: AppColors.brandMain,
                        size: 18,
                      ),
                      label: const Text(
                        "Create CV",
                        style: TextStyle(
                          color: AppColors.brandMain,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickAndUploadCv,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.upload_file_outlined,
                    color: Colors.grey,
                    size: 18,
                  ),
                  label: const Text(
                    "Upload existing CV (PDF/Image)",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickAndUploadCertificates,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.badge_outlined,
                    color: Colors.grey,
                    size: 18,
                  ),
                  label: const Text(
                    "Upload Certificates / ID (Image)",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickAndUploadPortfolioImages,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.grey,
                    size: 18,
                  ),
                  label: const Text(
                    "Upload Portfolio / Previous Work",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _buildLabel("Where do you want to work?"),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _allOverBangladesh,
                    activeColor: AppColors.brandMain,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _allOverBangladesh = v);
                    },
                  ),
                  const Text("All over Bangladesh", style: TextStyle(fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  Radio<bool>(
                    value: false,
                    groupValue: _allOverBangladesh,
                    activeColor: AppColors.brandMain,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _allOverBangladesh = v);
                    },
                  ),
                  const Text("Specific areas", style: TextStyle(fontSize: 13)),
                ],
              ),
              if (!_allOverBangladesh)
                Padding(
                  padding: const EdgeInsets.only(left: 32, bottom: 8),
                  child: TextField(
                    controller: _specificAreasController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "e.g. Mirpur, Uttara, Dhanmondi",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isSaving || _isUploadingImage) ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandMain,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Save Changes",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Helpers ----------

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
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
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required String hint,
    required IconData icon,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: AppColors.brandMain),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}