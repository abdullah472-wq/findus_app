// lib/screens/profile/support_post_screen.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/profile/location_picker_screen.dart';
import 'package:findus_app/services/app_config_service.dart';
import 'package:findus_app/services/cloudinary_service.dart';
import 'package:findus_app/services/notification_service.dart';
import 'package:findus_app/services/post_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class SupportPostScreen extends StatefulWidget {
  const SupportPostScreen({super.key});

  @override
  State<SupportPostScreen> createState() => _SupportPostScreenState();
}

class _SupportPostScreenState extends State<SupportPostScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  final _picker = ImagePicker();
  final List<XFile> _mediaFiles = [];

  bool _isSaving = false;

  bool _useCurrentLocation = true;
  String _locationName = "Detecting location...";
  LatLng? _selectedLatLng;

  double _budget = 1200.0;

  final List<Map<String, dynamic>> _categories = const [
    {"icon": Icons.electric_bolt, "name": "Electrician"},
    {"icon": Icons.plumbing, "name": "Plumber"},
    {"icon": Icons.directions_car, "name": "Driver"},
    {"icon": Icons.cleaning_services, "name": "Cleaner"},
    {"icon": Icons.format_paint, "name": "Painter"},
    {"icon": Icons.construction, "name": "Carpenter"},
    {"icon": Icons.person, "name": "Helper"},
    {"icon": Icons.more_horiz, "name": "Other"},
  ];

  String _selectedCategory = "Electrician";

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- Location ---

  Future<void> _initLocation() async {
    if (!_useCurrentLocation) return;
    await _determineInitialPosition();
  }

  Future<bool> _ensureLocationReady() async {
    if (!_useCurrentLocation && _selectedLatLng != null) return true;

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _showSnack("Please enable Location service to use current location.", Colors.redAccent);
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showSnack("Location permission denied. Please allow location.", Colors.redAccent);
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnack("Location permission permanently denied. Enable from Settings.", Colors.redAccent);
      return false;
    }

    return true;
  }

  Future<void> _determineInitialPosition() async {
    try {
      final ok = await _ensureLocationReady();
      if (!ok) {
        if (!mounted) return;
        setState(() => _locationName = "Location not available");
        return;
      }

      final p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      if (!mounted) return;
      setState(() {
        _selectedLatLng = LatLng(p.latitude, p.longitude);
        _locationName = "Current Location Detected";
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationName = "Location not found");
    }
  }

  Future<void> _selectLocationOnMap() async {
    final picked = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );

    if (!mounted) return;

    if (picked != null && picked is LatLng) {
      setState(() {
        _selectedLatLng = picked;
        _useCurrentLocation = false;
        _locationName = "Custom Pin Set";
      });
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  List<String> _generateLocationKeys(String input) {
    return input
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  bool _isVideoFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.mp4') || p.endsWith('.mov') || p.endsWith('.m4v') || p.endsWith('.webm');
  }

  Future<Map<String, dynamic>> _getCurrentUserProfileMeta(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snap.data() ?? <String, dynamic>{};

      final role = (data['userRole'] ?? 'maker').toString().toLowerCase().trim();
      final gender = (data['gender'] ?? 'Any').toString();

      final rating = (data['rating'] is num)
          ? (data['rating'] as num).toDouble()
          : double.tryParse('${data['rating']}') ?? 0.0;

      final verified = data['kyc_completed'] == true;

      final completed = (data['completedCount'] is num)
          ? (data['completedCount'] as num).toInt()
          : int.tryParse('${data['completedCount']}') ?? 0;

      final trusted = completed >= 50 && rating >= 4.5;

      return {
        // Support post is normally by maker; if user doc says finder, keep it but
        // you can force maker if your business logic requires.
        'userRole': (role == 'finder') ? 'finder' : 'maker',
        'gender': gender,
        'rating': rating,
        'verified': verified,
        'trusted': trusted,
      };
    } catch (_) {
      return {
        'userRole': 'maker',
        'gender': 'Any',
        'rating': 0.0,
        'verified': false,
        'trusted': false,
      };
    }
  }

  Future<List<String>> _uploadMedia() async {
    if (_mediaFiles.isEmpty) return const <String>[];

    final urls = <String>[];
    for (final f in _mediaFiles) {
      try {
        final isVideo = _isVideoFile(f.path);

        final res = await CloudinaryService.uploadXFile(
          f,
          folder: 'findus/posts/media',
          resourceType: isVideo ? 'video' : 'image',
          tags: const ['post', 'support'],
        );

        final url = res['secure_url']?.toString();
        if (url != null && url.isNotEmpty) urls.add(url);
      } catch (e) {
        debugPrint("Media upload failed: $e");
      }
    }
    return urls;
  }

  Future<void> _handlePost() async {
    if (_isSaving) return;

    if (AppConfigService.isPostingDisabled) {
      _showSnack("Posting is temporarily disabled. Please try again later.", Colors.redAccent);
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnack("Please enter job title.", Colors.redAccent);
      return;
    }

    if (_useCurrentLocation) {
      final ok = await _ensureLocationReady();
      if (!ok) return;

      if (_selectedLatLng == null) {
        await _determineInitialPosition();
      }
    }

    if (_selectedLatLng == null) {
      _showSnack("Location not available. Please pick a location on map.", Colors.redAccent);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack("Not logged in.", Colors.redAccent);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final meta = await _getCurrentUserProfileMeta(user.uid);

      // Support post should be visible to workers (finder),
      // so ownerRole should be 'maker' in normal flow.
      final ownerRole = (meta['userRole'] ?? 'maker').toString() == 'finder'
          ? 'maker' // ✅ enforce maker for SupportPostScreen
          : (meta['userRole'] ?? 'maker').toString();

      final uploadedUrls = await _uploadMedia();

      await PostService.createPost(
        ownerId: user.uid,
        ownerRole: ownerRole,
        title: title,
        description: _descController.text.trim(),
        roleLabel: _selectedCategory.toUpperCase(),
        roleKey: _selectedCategory.toLowerCase().replaceAll(' ', '_'),
        lat: _selectedLatLng!.latitude,
        lng: _selectedLatLng!.longitude,
        address: _locationName,
        locationKeys: _generateLocationKeys(_locationName),
        price: _budget,
        priceLabel: '৳ ${_budget.toInt()} / job',
        images: uploadedUrls,
        isLive: true,
        createdAt: FieldValue.serverTimestamp(),

        // optional meta for Explore filters
        gender: (meta['gender'] ?? 'Any').toString(),
        experience: 0,
        rating: (meta['rating'] is num) ? (meta['rating'] as num).toDouble() : 0.0,
        trusted: meta['trusted'] == true,
        verified: meta['verified'] == true,
        isPromoted: false,
        status: 'open',
      );

      await NotificationService.sendNotificationToUser(
        toUserId: user.uid,
        title: "Your job request has been posted",
        body: "“$title” is now visible to nearby workers.",
        type: "support_post",
        data: {
          'roleLabel': _selectedCategory,
          'budget': _budget,
          'useCurrentLocation': _useCurrentLocation,
          'locationLabel': _locationName,
        },
      );

      if (!mounted) return;
      _showSnack("Job request posted successfully.", AppColors.brandMain);
      Navigator.pop(context);
    } catch (e) {
      _showSnack("Failed to post: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
              margin: const EdgeInsets.only(bottom: 16),
            ),
            const Text("Attach Photo / Video", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _mediaOption(
                  icon: Icons.camera_alt,
                  label: "Camera",
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                    if (!mounted) return;
                    if (file != null) setState(() => _mediaFiles.add(file));
                  },
                ),
                _mediaOption(
                  icon: Icons.photo_library,
                  label: "Gallery",
                  onTap: () async {
                    Navigator.pop(context);
                    final files = await _picker.pickMultiImage(imageQuality: 80);
                    if (!mounted) return;
                    if (files.isNotEmpty) setState(() => _mediaFiles.addAll(files));
                  },
                ),
                _mediaOption(
                  icon: Icons.videocam,
                  label: "Video",
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? file = await _picker.pickVideo(source: ImageSource.camera);
                    if (!mounted) return;
                    if (file != null) setState(() => _mediaFiles.add(file));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 24, backgroundColor: AppColors.brandLight, child: Icon(icon, color: AppColors.brandDark)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingScaffold(
      title: "Post a Job Request",
      backgroundColor: AppColors.brandLight,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      scrollable: true,
      bodyPadding: EdgeInsets.zero,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: _isSaving ? null : _handlePost,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text("POST", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark)),
          ),
        ),
      ],
      body: Container(
        color: AppColors.brandLight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Worker Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) => _buildCategoryItem(_categories[index]),
                ),
              ),
              const SizedBox(height: 18),
              const Text("Job Title", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _cardField(
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: "e.g. Need a full day cleaner, Driver for tomorrow..."),
                ),
              ),
              const SizedBox(height: 18),
              const Text("Job Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _cardField(
                child: TextField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: "Describe the work, time, requirements, and any details..."),
                ),
              ),
              const SizedBox(height: 18),
              _cardField(
                child: Row(
                  children: [
                    Checkbox(
                      value: _useCurrentLocation,
                      activeColor: AppColors.brandMain,
                      onChanged: (v) async {
                        final val = v ?? true;
                        setState(() => _useCurrentLocation = val);
                        if (val) await _determineInitialPosition();
                      },
                    ),
                    const Expanded(child: Text("Drop pin in current location", style: TextStyle(fontSize: 12))),
                    TextButton.icon(
                      onPressed: _selectLocationOnMap,
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text("Select on map"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_locationName, style: const TextStyle(fontSize: 12))),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _showMediaOptions,
                icon: const Icon(Icons.camera_alt, color: AppColors.brandMain),
                label: const Text("Add Photo / Video", style: TextStyle(color: AppColors.brandMain)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.brandMain),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _buildAttachmentsSection(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Budget (per job)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("৳ ${_budget.toInt()}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
              Slider(
                value: _budget,
                min: 300,
                max: 10000,
                divisions: 97,
                activeColor: AppColors.brandMain,
                inactiveColor: Colors.white,
                onChanged: (val) => setState(() => _budget = val),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handlePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandMain,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Text("POST JOB REQUEST", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardField({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: child,
    );
  }

  Widget _buildAttachmentsSection() {
    if (_mediaFiles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Photos / Videos", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _mediaFiles.length,
            itemBuilder: (context, index) {
              final file = _mediaFiles[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                  image: DecorationImage(image: FileImage(File(file.path)), fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> item) {
    final bool isSelected = _selectedCategory == item['name'];
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = item['name'] as String),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandMain.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? AppColors.brandMain : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item['icon'] as IconData, size: 30, color: isSelected ? AppColors.brandMain : Colors.grey),
            const SizedBox(height: 8),
            Text(item['name'].toString(), style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.brandDark : Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}