import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/services/cloudinary_service.dart';
import 'package:findus_app/screens/profile/worker_cv_create_screen.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';


class UnifiedProfileEditScreen extends StatefulWidget {
  final String uid;
  const UnifiedProfileEditScreen({super.key, required this.uid});

  @override
  State<UnifiedProfileEditScreen> createState() =>
      _UnifiedProfileEditScreenState();
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

  String? _selectedServiceType;
  bool _allOverBangladesh = true;

  final List<String> _serviceTypes = const [
    'Electrician',
    'Plumber',
    'AC Repair',
    'Cleaner',
    'Carpenter',
    'Painter',
    'Mechanic',
    'Other'
  ];

  // ===== SUPPORTER-SPECIFIC =====
  late final TextEditingController _companyNameController;
  late final TextEditingController _companyContactController;
  late final TextEditingController _companyAddressController;

  // ===== SHARED =====
  final ImagePicker _picker = ImagePicker();
  Uint8List? _profileImageBytes;
  String? _profileImageUrl;
  bool _isUploadingImage = false;
  bool _isSaving = false;
  bool _isLoading = true;

  String? _userRole; // 'finder' or 'maker'
  bool _showSecondPhone = false;

  String? _selectedGender;
  int? _selectedAge;
  final List<String> _genders = const ['Male', 'Female', 'Other'];

  // ===== file picker =====
  bool _isUploadingCv = false;
  bool _isUploadingPortfolio = false;

  String? _cvUrl;
  List<String> _portfolioUrls = [];

  TimeOfDay? _workStartTime;
  TimeOfDay? _workEndTime;

  @override
  void initState() {
    super.initState();

    // ✅ init all controllers first (avoid late init crash)
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

    _loadUserData();
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

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (!userDoc.exists) {
        _showError("User not found");
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final data = userDoc.data()!;
      _userRole = data['userRole']?.toString().toLowerCase().trim();
      if (_userRole != 'finder' && _userRole != 'maker') {
        // fallback
        _userRole = 'finder';
      }

      // COMMON
      _nameController.text = (data['name'] ?? '').toString();
      _locationController.text = (data['location'] ?? '').toString();
      _aboutController.text = (data['about'] ?? '').toString();
      _phoneController1.text = (data['phone'] ?? '').toString();
      _phoneController2.text = (data['phone_alt'] ?? '').toString();
      _emailController.text = (data['email'] ?? '').toString();
      _facebookController.text = (data['facebookUrl'] ?? '').toString();
      _instagramController.text = (data['instagramUrl'] ?? '').toString();
      _linkedinController.text = (data['linkedInUrl'] ?? '').toString();

      // WORKER
      final priceText = (data['priceText'] ?? '').toString();
      final numericPrice = RegExp(r'\d+').stringMatch(priceText) ?? '';
      _priceController.text = numericPrice;
      _experienceController.text = (data['experienceYears'] ?? '').toString();
      _languagesController.text = (data['languages'] ?? '').toString();
      _availabilityController.text = (data['availability'] ?? '').toString();
      _specificAreasController.text =
          (data['working_specific_areas'] ?? '').toString();

      // ✅ role/service type mapping
      // In your user doc you have:
      // role: "AC REPAIR" & roleKey: "ac repair"
      // service types list contains "AC Repair"
      final roleKey = (data['roleKey'] ?? '').toString();
      _selectedServiceType = _serviceTypes.firstWhere(
            (s) => s.toLowerCase() == roleKey.toLowerCase(),
        orElse: () => 'Other',
      );

      _allOverBangladesh = (data['working_all_over_bd'] ?? true) == true;

      // SUPPORTER
      _companyNameController.text = (data['companyName'] ?? '').toString();
      _companyContactController.text =
          (data['companyContact'] ?? '').toString();
      _companyAddressController.text =
          (data['companyAddress'] ?? '').toString();

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


  List<String> _generateLocationKeys(String location) {
    return location
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _pickAndUploadProfileImage() async {
    if (_isUploadingImage) return;

    final picked =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _profileImageBytes = bytes;
      _isUploadingImage = true;
    });

    try {
      // ✅ use XFile upload (consistent)
      final uploaded = await CloudinaryService.uploadXFile(
        picked,
        folder: 'findus/profile_images',
        resourceType: 'image',
        tags: const ['profile'],
      );

      final url = uploaded['secure_url']?.toString();
      if (url == null || url.isEmpty) throw Exception('No secure_url returned');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_image', url); // ✅ consistent key

      if (mounted) {
        setState(() {
          _profileImageUrl = url;
          _isUploadingImage = false;
        });
      }


    } catch (e) {
      if (mounted) setState(() => _isUploadingImage = false);
      _showError("Upload failed: $e");
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) {
      _showError("Not logged in");
      return;
    }

    if (currentUid != widget.uid) {
      _showError("Unauthorized");
      return;
    }

    if (name.isEmpty || location.isEmpty) {
      _showError("Name and location are required");
      return;
    }

    final role = (_userRole ?? 'finder').toLowerCase().trim();

    // ✅ worker validations
    if (role == 'finder') {
      if (_selectedServiceType == null || _selectedServiceType!.trim().isEmpty) {
        _showError('Please select your service type');
        return;
      }

      if (_workStartTime == null || _workEndTime == null) {
        _showError('Please select your working time (start & end)');
        return;
      }
      if (!_isEndAfterStart(_workStartTime!, _workEndTime!)) {
        _showError('End time must be after start time');
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
        final numericPrice = num.tryParse(
          _priceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
            0;

        // ✅ work time saved for worker
        updateData.addAll({
          'userRole': 'finder',
          'isWorker': true,
          'isSupporter': false,

          'price': numericPrice,
          'priceText': "৳$numericPrice / day",

          'role': _selectedServiceType!.toUpperCase(),
          'roleKey': _selectedServiceType!.toLowerCase(),

          'experienceYears': int.tryParse(
            _experienceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
              0,

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

      // Save to prefs (cache only)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      await prefs.setString('user_role', role);
      await prefs.setString('user_location', location);
      await prefs.setString('user_phone', _phoneController1.text.trim());
      await prefs.setString('user_image', _profileImageUrl ?? '');

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError("Save failed: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _pickAndUploadCv() async {
    if (_isUploadingCv) return;

    setState(() => _isUploadingCv = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryService.cloudName}/raw/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = CloudinaryService.uploadPreset
        ..fields['folder'] = 'findus/cv';

      if (file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path!,
            filename: file.name,
          ),
        );
      } else {
        throw Exception('File path/bytes পাওয়া যায়নি');
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('CV upload failed: ${res.statusCode} ${res.body}');
      }

      final cloudData = jsonDecode(res.body) as Map<String, dynamic>;
      final url = cloudData['secure_url']?.toString();
      if (url == null || url.isEmpty) throw Exception('secure_url পাওয়া যায়নি');

      if (mounted) setState(() => _cvUrl = url);

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'cvUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      _showError('CV upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploadingCv = false);
    }
  }

  Future<void> _pickAndUploadPortfolio() async {
    if (_isUploadingPortfolio) return;

    setState(() => _isUploadingPortfolio = true);
    try {
      final files = await _picker.pickMultiImage(imageQuality: 80);
      if (files.isEmpty) return;

      final newUrls = <String>[];
      for (final f in files) {
        final uploaded = await CloudinaryService.uploadXFile(
          f,
          folder: 'findus/portfolio',
          resourceType: 'image',
          tags: const ['portfolio'],
        );
        final url = uploaded['secure_url']?.toString();
        if (url != null && url.isNotEmpty) newUrls.add(url);
      }

      if (newUrls.isEmpty) throw Exception('No portfolio url returned');

      setState(() => _portfolioUrls.addAll(newUrls));

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'portfolioUrls': _portfolioUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      _showError('Portfolio upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPortfolio = false);
    }
  }

  TimeOfDay? _parseTimeOfDay(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final parts = s.split(':'); // expects "HH:mm"
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
      _showError('Please select start time first');
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: _workEndTime ?? _workStartTime!,
    );
    if (picked == null) return;

    if (!_isEndAfterStart(_workStartTime!, picked)) {
      _showError('End time must be after start time');
      return;
    }

    setState(() => _workEndTime = picked);
  }


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
            child: img == null
                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                : null,
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
                child: const Icon(Icons.camera_alt,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.brandDark,
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String hint,
      IconData icon, {
        int maxLines = 1,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.brandMain),
        filled: true,
        fillColor: Colors.white,
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
      ValueChanged<T?> onChanged, {
        String Function(T)? itemLabel,
      }) {
    final validItems = items.whereType<T>().toList();

    T? safeValue;
    if (value != null && validItems.contains(value)) {
      safeValue = value;
    }

    return DropdownButtonFormField<T>(
      initialValue: safeValue,
      hint: Text(hint),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.brandMain),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: validItems
          .map((item) => DropdownMenuItem<T>(
        value: item,
        child: Text(itemLabel?.call(item) ?? item.toString()),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isFinder = (_userRole ?? 'finder') == 'finder';

    return FloatingScaffold(
      title: 'Edit Profile',
      backgroundColor: AppColors.brandLight,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
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
                : const Text(
              "SAVE",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
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

            _buildLabel("Basic Information"),
            _buildTextField(_nameController, "Full Name", Icons.person),
            const SizedBox(height: 12),
            _buildTextField(_locationController, "Location", Icons.location_on),
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
                    itemLabel: (age) => age.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(_aboutController, "About Me", Icons.info, maxLines: 3),
            const SizedBox(height: 24),

            _buildLabel("Phone Number"),
            _buildTextField(_phoneController1, "Primary Phone", Icons.phone),
            const SizedBox(height: 8),
            if (_showSecondPhone)
              _buildTextField(_phoneController2, "Secondary Phone", Icons.phone_android)
            else
              TextButton.icon(
                onPressed: () => setState(() => _showSecondPhone = true),
                icon: const Icon(Icons.add),
                label: const Text("Add another phone"),
              ),

            const SizedBox(height: 24),

            if (isFinder) ...[
              _buildLabel("Worker Information"),
              _buildDropdownField<String>(
                _selectedServiceType,
                _serviceTypes,
                "Service Type",
                Icons.work,
                    (v) => setState(() => _selectedServiceType = v),
              ),
              const SizedBox(height: 12),

              _buildLabel("Working Time"),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickStartTime,
                      child: Text("Start: ${_formatDisplay(_workStartTime)}"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickEndTime,
                      child: Text("End: ${_formatDisplay(_workEndTime)}"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildTextField(_priceController, "Service Charge (Number only)", Icons.money),
              const SizedBox(height: 12),
              _buildTextField(_experienceController, "Experience (e.g. 5+ Years)", Icons.history),
              const SizedBox(height: 12),
              _buildTextField(_languagesController, "Languages", Icons.language),
              const SizedBox(height: 12),

              SwitchListTile(
                title: const Text("Work All Over Bangladesh"),
                value: _allOverBangladesh,
                onChanged: (v) => setState(() => _allOverBangladesh = v),
              ),
              if (!_allOverBangladesh)
                _buildTextField(_specificAreasController, "Specific Areas", Icons.place),

              const SizedBox(height: 24),

              _buildLabel("Portfolio & Documents"),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingCv ? null : _pickAndUploadCv,
                      icon: _isUploadingCv
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_file),
                      label: Text(_cvUrl == null ? "Upload CV" : "Re-upload CV"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingPortfolio ? null : _pickAndUploadPortfolio,
                      icon: _isUploadingPortfolio
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.photo_library),
                      label: Text("Portfolio (${_portfolioUrls.length})"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ✅ UnifiedProfileEditScreen এর "Create Digital CV" বাটনের ভেতরে Worker() constructor আপডেট করো
// নতুন Worker model অনুযায়ী:
// - uid (required)
// - userRole (required: finder/maker)
// - about (not message)
// - kycCompleted (not isVerified)
// - priceText (String) + price (num?) optional
// - id/role/message/medals/isVerified নেই

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // UI label (service type) আলাদা করে WorkerCVCreateScreen-এ পাঠাতে চাইলে
                    // WorkerCVCreateScreen/Worker model-এ আলাদা field লাগবে।
                    // এখন worker.userRole = 'finder' স্ট্যান্ডার্ড রাখছি।
                    final String priceText = _priceController.text.trim().isNotEmpty
                        ? "৳${_priceController.text.trim()} / day"
                        : "Negotiable";

                    final num? priceNum = num.tryParse(
                      _priceController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerCVCreateScreen(
                          worker: Worker(
                            uid: widget.uid,
                            userRole: 'finder', // ✅ worker role standard
                            name: _nameController.text.trim(),
                            image: _profileImageUrl ?? '',
                            about: _aboutController.text.trim(),
                            rating: 0.0,
                            location: _locationController.text.trim(),
                            priceText: priceText,
                            price: priceNum,
                            kycCompleted: false,
                            // optional company fields না লাগলে বাদ
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_document, color: AppColors.brandMain),
                  label: const Text("Create Digital CV"),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              _buildLabel("Company Information"),
              _buildTextField(_companyNameController, "Company Name", Icons.business),
              const SizedBox(height: 12),
              _buildTextField(_companyContactController, "Company Contact", Icons.contact_phone),
              const SizedBox(height: 12),
              _buildTextField(_companyAddressController, "Company Address", Icons.map, maxLines: 2),
              const SizedBox(height: 24),
            ],

            _buildLabel("Social Links"),
            _buildTextField(_emailController, "Email Address", Icons.email),
            const SizedBox(height: 12),
            _buildTextField(_facebookController, "Facebook URL", Icons.facebook),
            const SizedBox(height: 12),
            _buildTextField(_instagramController, "Instagram URL", Icons.camera_alt),
            const SizedBox(height: 12),
            _buildTextField(_linkedinController, "LinkedIn URL", Icons.link),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}