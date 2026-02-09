import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:findus_app/achievement/achievement_service.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/services/cloudinary_service.dart';
import 'package:findus_app/screens/profile/worker_cv_create_screen.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class UnifiedProfileEditScreen extends StatefulWidget {
  final String uid;
  const UnifiedProfileEditScreen({super.key, required this.uid});

  @override
  State<UnifiedProfileEditScreen> createState() => _UnifiedProfileEditScreenState();
}

class _UnifiedProfileEditScreenState extends State<UnifiedProfileEditScreen> {
  // ===== COMMON CONTROLLERS =====
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _aboutController;
  late final TextEditingController _phoneController1;
  late final TextEditingController _phoneController2;
  late final TextEditingController _emailController;
  late final TextEditingController _facebookController;
  late final TextEditingController _instagramController;
  late final TextEditingController _linkedinController;

  // ===== WORKER-SPECIFIC =====
  late final TextEditingController _priceController;
  late final TextEditingController _experienceController;
  late final TextEditingController _languagesController;
  late final TextEditingController _availabilityController;
  late final TextEditingController _specificAreasController;

  // ===== SUPPORTER-SPECIFIC =====
  late final TextEditingController _companyNameController;
  late final TextEditingController _companyContactController;
  late final TextEditingController _companyAddressController;

  String? _selectedServiceType;
  bool _allOverBangladesh = true;
  String? _userRole;
  bool _showSecondPhone = false;
  String? _selectedGender;
  int? _selectedAge;

  // Image & Files
  final ImagePicker _picker = ImagePicker();
  Uint8List? _profileImageBytes;
  String? _profileImageUrl;
  bool _isUploadingImage = false;
  bool _isSaving = false;
  bool _isLoading = true;
  bool _isUploadingCv = false;
  bool _isUploadingPortfolio = false;
  String? _cvUrl;
  List<String> _portfolioUrls = [];
  TimeOfDay? _workStartTime;
  TimeOfDay? _workEndTime;

  final List<String> _serviceTypes = const [
    'Electrician', 'Plumber', 'AC Repair', 'Cleaner', 'Carpenter', 'Painter', 'Mechanic', 'Other'
  ];
  final List<String> _genders = const ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadUserData();
  }

  void _initControllers() {
    _nameController = TextEditingController();
    _locationController = TextEditingController();
    _aboutController = TextEditingController();
    _phoneController1 = TextEditingController();
    _phoneController2 = TextEditingController();
    _emailController = TextEditingController();
    _facebookController = TextEditingController();
    _instagramController = TextEditingController();
    _linkedinController = TextEditingController();
    _priceController = TextEditingController();
    _experienceController = TextEditingController();
    _languagesController = TextEditingController();
    _availabilityController = TextEditingController();
    _specificAreasController = TextEditingController();
    _companyNameController = TextEditingController();
    _companyContactController = TextEditingController();
    _companyAddressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
    _phoneController1.dispose();
    _phoneController2.dispose();
    _emailController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _priceController.dispose();
    _experienceController.dispose();
    _languagesController.dispose();
    _availabilityController.dispose();
    _specificAreasController.dispose();
    _companyNameController.dispose();
    _companyContactController.dispose();
    _companyAddressController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // DATA LOAD
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (!userDoc.exists) {
        _showError("User not found");
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final data = userDoc.data()!;
      _userRole = data['userRole']?.toString().toLowerCase().trim() ?? 'finder';

      _nameController.text = (data['name'] ?? '').toString();
      _locationController.text = (data['location'] ?? '').toString();
      _aboutController.text = (data['about'] ?? '').toString();
      _phoneController1.text = (data['phone'] ?? '').toString();
      _phoneController2.text = (data['phone_alt'] ?? '').toString();
      _emailController.text = (data['email'] ?? '').toString();
      _facebookController.text = (data['facebookUrl'] ?? '').toString();
      _instagramController.text = (data['instagramUrl'] ?? '').toString();
      _linkedinController.text = (data['linkedInUrl'] ?? '').toString();

      final priceText = (data['priceText'] ?? '').toString();
      _priceController.text = RegExp(r'\d+').stringMatch(priceText) ?? '';
      _experienceController.text = (data['experienceYears'] ?? '').toString();
      _languagesController.text = (data['languages'] ?? '').toString();
      _availabilityController.text = (data['availability'] ?? '').toString();
      _specificAreasController.text = (data['working_specific_areas'] ?? '').toString();

      final roleKey = (data['roleKey'] ?? '').toString();
      _selectedServiceType = _serviceTypes.firstWhere(
            (s) => s.toLowerCase() == roleKey.toLowerCase(),
        orElse: () => 'Other',
      );

      _allOverBangladesh = (data['working_all_over_bd'] ?? true) == true;
      _companyNameController.text = (data['companyName'] ?? '').toString();
      _companyContactController.text = (data['companyContact'] ?? '').toString();
      _companyAddressController.text = (data['companyAddress'] ?? '').toString();

      _selectedGender = data['gender']?.toString();
      final ageRaw = data['age'];
      _selectedAge = ageRaw is int ? ageRaw : int.tryParse(ageRaw?.toString() ?? '');

      _profileImageUrl = data['image']?.toString();
      _showSecondPhone = _phoneController2.text.trim().isNotEmpty;
      _cvUrl = data['cvUrl']?.toString();
      _portfolioUrls = (data['portfolioUrls'] is List)
          ? (data['portfolioUrls'] as List).map((e) => e.toString()).toList()
          : <String>[];

      _workStartTime = _parseTimeOfDay(data['workStart']?.toString());
      _workEndTime = _parseTimeOfDay(data['workEnd']?.toString());
    } catch (e) {
      _showError("Failed to load profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  List<String> _generateLocationKeys(String location) {
    return location.toLowerCase().split(RegExp(r'[^a-z0-9]+')).where((s) => s.isNotEmpty).toList();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  TimeOfDay? _parseTimeOfDay(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String? _format24(TimeOfDay? t) {
    if (t == null) return null;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatDisplay(TimeOfDay? t) {
    if (t == null) return '--:--';
    return t.format(context);
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  bool _isEndAfterStart(TimeOfDay start, TimeOfDay end) {
    return _toMinutes(end) > _toMinutes(start);
  }

  // ═══════════════════════════════════════════════════════════════
  // TIME PICKERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _workStartTime ?? TimeOfDay.now(),
    );
    if (picked == null) return;

    setState(() => _workStartTime = picked);
    if (_workEndTime != null && !_isEndAfterStart(picked, _workEndTime!)) {
      setState(() => _workEndTime = null);
    }
  }

  Future<void> _pickEndTime() async {
    if (_workStartTime == null) {
      _showError('আগে Start Time সিলেক্ট করো');
      return;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: _workEndTime ?? _workStartTime!,
    );
    if (picked == null) return;

    if (!_isEndAfterStart(_workStartTime!, picked)) {
      _showError('End Time অবশ্যই Start Time এর পরে হতে হবে');
      return;
    }
    setState(() => _workEndTime = picked);
  }

  // ═══════════════════════════════════════════════════════════════
  // IMAGE COMPRESSION & UPLOAD
  // ═══════════════════════════════════════════════════════════════

  Future<XFile> _compressIfNeeded(XFile file, {required int maxSizeInBytes}) async {
    final originalBytes = await file.readAsBytes();

    // যদি আগে থেকেই ছোট হয়, তাহলে compress করার দরকার নেই
    if (originalBytes.lengthInBytes <= maxSizeInBytes) {
      return file;
    }

    int quality = 90;
    Uint8List compressedBytes = originalBytes;

    // ধাপে ধাপে quality কমিয়ে compress করবো
    while (quality >= 30) {
      compressedBytes = await FlutterImageCompress.compressWithList(
        originalBytes,
        quality: quality,
      );

      if (compressedBytes.lengthInBytes <= maxSizeInBytes) {
        break;
      }
      quality -= 10;
    }

    // যদি compression কাজ না করে, original ই return করো
    if (compressedBytes.lengthInBytes >= originalBytes.lengthInBytes) {
      return file;
    }

    return XFile.fromData(
      compressedBytes,
      name: file.name,
      mimeType: file.mimeType,
    );
  }

  Future<void> _pickAndUploadProfileImage() async {
    if (_isUploadingImage) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (picked == null) return;

    setState(() => _isUploadingImage = true);

    try {
      // ✅ Profile picture এর জন্য 300KB limit
      const int maxSize = 300 * 1024;
      final compressed = await _compressIfNeeded(picked, maxSizeInBytes: maxSize);

      final bytes = await compressed.readAsBytes();
      setState(() => _profileImageBytes = bytes);

      final uploaded = await CloudinaryService.uploadXFile(
        compressed,
        folder: 'findus/profile_images',
        resourceType: 'image',
        tags: const ['profile'],
      );

      final url = uploaded['secure_url']?.toString();
      if (url == null) throw Exception('No secure_url returned');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_image', url);

      if (mounted) {
        setState(() {
          _profileImageUrl = url;
          _isUploadingImage = false;
        });
        _showSuccess("প্রোফাইল ছবি আপলোড হয়েছে!");
      }
    } catch (e) {
      if (mounted) setState(() => _isUploadingImage = false);
      _showError("আপলোড ব্যর্থ: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CV UPLOAD
  // ═══════════════════════════════════════════════════════════════

  Future<void> _pickAndUploadCv() async {
    if (_isUploadingCv) return;

    setState(() => _isUploadingCv = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _isUploadingCv = false);
        return;
      }

      final file = result.files.single;

      if (file.size > 5 * 1024 * 1024) {
        _showError('ফাইল অনেক বড়। সর্বোচ্চ 5MB হতে হবে।');
        if (mounted) setState(() => _isUploadingCv = false);
        return;
      }

      // Raw file upload (PDF/Doc Cloudinary তে 'raw' হিসেবে যায়)
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryService.cloudName}/raw/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = CloudinaryService.uploadPreset
        ..fields['folder'] = 'findus/cv';

      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path!, filename: file.name),
        );
      } else {
        throw Exception("File data not found");
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception("Upload failed: ${response.body}");
      }

      final data = jsonDecode(response.body);
      final url = data['secure_url'];

      if (url != null) {
        await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
          'cvUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          setState(() => _cvUrl = url);
          _showSuccess("CV সফলভাবে আপলোড হয়েছে!");
        }
      }
    } catch (e) {
      _showError("CV আপলোড ব্যর্থ: $e");
    } finally {
      if (mounted) setState(() => _isUploadingCv = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PORTFOLIO UPLOAD
  // ═══════════════════════════════════════════════════════════════

  Future<void> _pickAndUploadPortfolio() async {
    if (_isUploadingPortfolio) return;

    try {
      final List<XFile> files = await _picker.pickMultiImage(imageQuality: 100);
      if (files.isEmpty) return;

      setState(() => _isUploadingPortfolio = true);

      final List<String> newUrls = [];

      for (final file in files) {
        try {
          // ✅ প্রতিটা portfolio image এর জন্য 1MB limit
          const int maxSize = 1024 * 1024;
          final compressed = await _compressIfNeeded(file, maxSizeInBytes: maxSize);

          final uploaded = await CloudinaryService.uploadXFile(
            compressed,
            folder: 'findus/portfolio',
            resourceType: 'image',
            tags: const ['portfolio'],
          );

          final url = uploaded['secure_url']?.toString();
          if (url != null && url.isNotEmpty) {
            newUrls.add(url);
          }
        } catch (e) {
          debugPrint("Single file upload failed: $e");
        }
      }

      if (newUrls.isEmpty) throw Exception('কোনো ছবি আপলোড হয়নি');

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'portfolioUrls': FieldValue.arrayUnion(newUrls),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _portfolioUrls.addAll(newUrls));
        _showSuccess("${newUrls.length}টি ছবি পোর্টফোলিওতে যোগ হয়েছে");
      }
    } catch (e) {
      _showError('পোর্টফোলিও আপলোড ব্যর্থ: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPortfolio = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SAVE PROFILE
  // ═══════════════════════════════════════════════════════════════

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null || currentUid != widget.uid) {
      _showError("Unauthorized - তুমি এই প্রোফাইল এডিট করতে পারবে না");
      return;
    }
    if (name.isEmpty || location.isEmpty) {
      _showError("নাম এবং লোকেশন দিতেই হবে");
      return;
    }

    final role = (_userRole ?? 'finder').toLowerCase().trim();
    if (role == 'finder') {
      if (_selectedServiceType == null) {
        _showError('সার্ভিস টাইপ সিলেক্ট করো');
        return;
      }
      if (_workStartTime == null || _workEndTime == null) {
        _showError('কাজের সময় সিলেক্ট করো');
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> updateData = {
        'name': name,
        'location': location,
        'locationKeys': _generateLocationKeys(location),
        'about': _aboutController.text.trim(),
        'phone': _phoneController1.text.trim(),
        'phone_alt': _phoneController2.text.trim(),
        'email': _emailController.text.trim(),
        'facebookUrl': _facebookController.text.trim(),
        'instagramUrl': _instagramController.text.trim(),
        'linkedInUrl': _linkedinController.text.trim(),
        'image': _profileImageUrl,
        'gender': _selectedGender,
        'age': _selectedAge,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (role == 'finder') {
        final numericPrice = num.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        updateData.addAll({
          'userRole': 'finder',
          'isWorker': true,
          'isSupporter': false,
          'price': numericPrice,
          'priceText': "৳$numericPrice / day",
          'role': _selectedServiceType!.toUpperCase(),
          'roleKey': _selectedServiceType!.toLowerCase(),
          'experienceYears': int.tryParse(_experienceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
          'languages': _languagesController.text.trim(),
          'working_all_over_bd': _allOverBangladesh,
          'working_specific_areas': _specificAreasController.text.trim(),
          'workStart': _format24(_workStartTime),
          'workEnd': _format24(_workEndTime),
          'availability': "${_formatDisplay(_workStartTime)} - ${_formatDisplay(_workEndTime)}",
        });
      } else {
        updateData.addAll({
          'userRole': 'maker',
          'isSupporter': true,
          'isWorker': false,
          'companyName': _companyNameController.text.trim(),
          'companyContact': _companyContactController.text.trim(),
          'companyAddress': _companyAddressController.text.trim(),
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .set(updateData, SetOptions(merge: true));

      // ✅ Achievement sync - এইখানে করতে হবে, save এর পরে
      await AchievementService.syncProfileChainFromUserDoc(uid: currentUid);

      if (mounted) {
        _showSuccess("প্রোফাইল সেভ হয়েছে!");
        Navigator.pop(context);
      }
    } catch (e) {
      _showError("সেভ করতে ব্যর্থ: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFinder = (_userRole ?? 'finder') == 'finder';
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: 'Edit Profile',
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: true,
      bodyPadding: EdgeInsets.zero,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(
              "SAVE",
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            // ✅ এখানে আর await নেই - সেটা _saveProfile() এর ভিতরে আছে
          ),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildProfileImage(),
            const SizedBox(height: 24),

            _buildLabel("Basic Information", textColor),
            _buildTextField(_nameController, "Full Name", Icons.person, isDark),
            const SizedBox(height: 12),
            _buildTextField(_locationController, "Location", Icons.location_on, isDark),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDropdownField<String>(
                    _selectedGender,
                    _genders,
                    "Gender",
                    Icons.wc,
                        (v) => setState(() => _selectedGender = v),
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdownField<int>(
                    _selectedAge,
                    List.generate(53, (i) => i + 18),
                    "Age",
                    Icons.cake,
                        (v) => setState(() => _selectedAge = v),
                    isDark,
                    itemLabel: (age) => age.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(_aboutController, "About Me", Icons.info, isDark, maxLines: 3),
            const SizedBox(height: 24),

            _buildLabel("Phone Number", textColor),
            _buildTextField(_phoneController1, "Primary Phone", Icons.phone, isDark),
            const SizedBox(height: 8),
            if (_showSecondPhone)
              _buildTextField(_phoneController2, "Secondary Phone", Icons.phone_android, isDark)
            else
              TextButton.icon(
                onPressed: () => setState(() => _showSecondPhone = true),
                icon: const Icon(Icons.add),
                label: const Text("Add another phone"),
              ),

            const SizedBox(height: 24),

            if (isFinder) ...[
              _buildLabel("Worker Information", textColor),
              _buildDropdownField<String>(
                _selectedServiceType,
                _serviceTypes,
                "Service Type",
                Icons.work,
                    (v) => setState(() => _selectedServiceType = v),
                isDark,
              ),
              const SizedBox(height: 12),

              _buildLabel("Working Time", textColor),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeButton(
                      "Start: ${_formatDisplay(_workStartTime)}",
                      _pickStartTime,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeButton(
                      "End: ${_formatDisplay(_workEndTime)}",
                      _pickEndTime,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildTextField(_priceController, "Service Charge (Number only)", Icons.money, isDark),
              const SizedBox(height: 12),
              _buildTextField(_experienceController, "Experience (e.g. 5+ Years)", Icons.history, isDark),
              const SizedBox(height: 12),
              _buildTextField(_languagesController, "Languages", Icons.language, isDark),
              const SizedBox(height: 12),

              SwitchListTile(
                title: Text("Work All Over Bangladesh", style: TextStyle(color: textColor)),
                value: _allOverBangladesh,
                activeThumbColor: AppColors.brandMain,
                onChanged: (v) => setState(() => _allOverBangladesh = v),
              ),
              if (!_allOverBangladesh)
                _buildTextField(_specificAreasController, "Specific Areas", Icons.place, isDark),

              const SizedBox(height: 24),

              _buildLabel("Portfolio & Documents", textColor),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingCv ? null : _pickAndUploadCv,
                      icon: _isUploadingCv
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.upload_file),
                      label: Text(_cvUrl == null ? "Upload CV" : "Re-upload CV"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(color: textColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingPortfolio ? null : _pickAndUploadPortfolio,
                      icon: _isUploadingPortfolio
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.photo_library),
                      label: Text("Portfolio (${_portfolioUrls.length})"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(color: textColor),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final String priceText = _priceController.text.trim().isNotEmpty
                        ? "৳${_priceController.text.trim()} / day"
                        : "Negotiable";
                    final num? priceNum =
                    num.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), ''));

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerCVCreateScreen(
                          worker: Worker(
                            uid: widget.uid,
                            userRole: 'finder',
                            name: _nameController.text.trim(),
                            image: _profileImageUrl ?? '',
                            about: _aboutController.text.trim(),
                            rating: 0.0,
                            location: _locationController.text.trim(),
                            priceText: priceText,
                            price: priceNum,
                            kycCompleted: false,
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_document, color: AppColors.brandMain),
                  label: const Text("Create Digital CV"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: textColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              _buildLabel("Company Information", textColor),
              _buildTextField(_companyNameController, "Company Name", Icons.business, isDark),
              const SizedBox(height: 12),
              _buildTextField(_companyContactController, "Company Contact", Icons.contact_phone, isDark),
              const SizedBox(height: 12),
              _buildTextField(_companyAddressController, "Company Address", Icons.map, isDark, maxLines: 2),
              const SizedBox(height: 24),
            ],

            _buildLabel("Social Links", textColor),
            _buildTextField(_emailController, "Email Address", Icons.email, isDark),
            const SizedBox(height: 12),
            _buildTextField(_facebookController, "Facebook URL", Icons.facebook, isDark),
            const SizedBox(height: 12),
            _buildTextField(_instagramController, "Instagram URL", Icons.camera_alt, isDark),
            const SizedBox(height: 12),
            _buildTextField(_linkedinController, "LinkedIn URL", Icons.link, isDark),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // UI WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProfileImage() {
    final ImageProvider<Object>? img = _profileImageBytes != null
        ? MemoryImage(_profileImageBytes!)
        : (_profileImageUrl != null && _profileImageUrl!.trim().isNotEmpty
        ? NetworkImage(_profileImageUrl!)
        : null);

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200]!,
            backgroundImage: img,
            child: img == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
          ),
          if (_isUploadingImage)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploadingImage ? null : _pickAndUploadProfileImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.brandMain,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String hint,
      IconData icon,
      bool isDark, {
        int maxLines = 1,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.black54),
        prefixIcon: Icon(icon, color: AppColors.brandMain),
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>(
      T? value,
      List<T> items,
      String hint,
      IconData icon,
      ValueChanged<T?> onChanged,
      bool isDark, {
        String Function(T)? itemLabel,
      }) {
    final validItems = items.whereType<T>().toList();
    T? safeValue = (value != null && validItems.contains(value)) ? value : null;

    return DropdownButtonFormField<T>(
      value: safeValue, // ✅ "value" ব্যবহার করতে হবে, "initialValue" নয়
      hint: Text(hint, style: TextStyle(color: isDark ? Colors.grey : Colors.black54)),
      dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.brandMain),
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: validItems
          .map((item) => DropdownMenuItem<T>(
        value: item,
        child: Text(
          itemLabel?.call(item) ?? item.toString(),
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTimeButton(String text, VoidCallback onPressed, bool isDark) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white : Colors.black,
        side: BorderSide(color: isDark ? Colors.white54 : Colors.grey),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(text),
    );
  }
}