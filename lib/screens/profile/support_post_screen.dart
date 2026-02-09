// lib/screens/profile/support_post_screen.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geo;

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/profile/location_picker_screen.dart';
import 'package:findus_app/services/app_config_service.dart';
import 'package:findus_app/services/cloudinary_service.dart';
import 'package:findus_app/services/notification_service.dart';
import 'package:findus_app/services/post_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/screens/ads/ad_display_screen.dart'; // ✅ অ্যাড স্ক্রিন ইমপোর্ট

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
  int _slots = 1;

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

  Future<void> _initLocation() async {
    if (!_useCurrentLocation) return;
    await _determineInitialPosition();
  }

  Future<bool> _ensureLocationReady() async {
    if (!_useCurrentLocation && _selectedLatLng != null) return true;
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    return permission != LocationPermission.denied && permission != LocationPermission.deniedForever;
  }

  Future<void> _determineInitialPosition() async {
    try {
      final ok = await _ensureLocationReady();
      if (!ok) {
        if (mounted) setState(() => _locationName = "Location not available");
        return;
      }

      final p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final latLng = LatLng(p.latitude, p.longitude);

      if (mounted) {
        setState(() {
          _selectedLatLng = latLng;
          _locationName = "Getting address...";
        });
      }
      await _updateLocationNameFromLatLng(latLng);
    } catch (_) {
      if (mounted) setState(() => _locationName = "Location not found");
    }
  }

  Future<void> _selectLocationOnMap() async {
    final picked = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );

    if (mounted && picked != null && picked is LatLng) {
      setState(() {
        _selectedLatLng = picked;
        _useCurrentLocation = false;
        _locationName = "Getting address...";
      });
      await _updateLocationNameFromLatLng(picked);
    }
  }

  Future<void> _updateLocationNameFromLatLng(LatLng latLng) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (!mounted) return;
      if (placemarks.isEmpty) {
        setState(() => _locationName = "Selected Location");
        return;
      }

      final place = placemarks.first;
      final parts = <String>[];
      if ((place.street ?? '').isNotEmpty) parts.add(place.street!);
      if ((place.subLocality ?? '').isNotEmpty) parts.add(place.subLocality!);
      if ((place.locality ?? '').isNotEmpty) parts.add(place.locality!);
      if ((place.administrativeArea ?? '').isNotEmpty) parts.add(place.administrativeArea!);

      final addressStr = parts.join(', ');
      setState(() => _locationName = addressStr.isNotEmpty ? addressStr : "Selected Location");
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationName = "Selected Location");
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  bool _isVideoFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.mp4') || p.endsWith('.mov') || p.endsWith('.m4v');
  }

  Future<List<String>> _uploadMedia() async {
    if (_mediaFiles.isEmpty) return const [];
    final urls = <String>[];
    for (final f in _mediaFiles) {
      try {
        final isVideo = _isVideoFile(f.path);
        final res = await CloudinaryService.uploadXFile(f, folder: 'findus/posts/media', resourceType: isVideo ? 'video' : 'image', tags: const ['post', 'support']);
        final url = res['secure_url']?.toString();
        if (url != null) urls.add(url);
      } catch (e) {
        debugPrint("Upload failed: $e");
      }
    }
    return urls;
  }

  Future<Map<String, dynamic>> _getCurrentUserProfileMeta(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snap.data() ?? {};
      return {
        'userRole': (data['userRole'] == 'finder') ? 'finder' : 'maker',
        'gender': (data['gender'] ?? 'Any').toString(),
        'rating': double.tryParse('${data['rating']}') ?? 0.0,
        'verified': data['kyc_completed'] == true,
        'trusted': (int.tryParse('${data['completedCount']}') ?? 0) >= 50 && (double.tryParse('${data['rating']}') ?? 0) >= 4.5,
      };
    } catch (_) {
      return {'userRole': 'maker', 'gender': 'Any', 'rating': 0.0, 'verified': false, 'trusted': false};
    }
  }

  // ✅ আপডেটেড পোস্ট লজিক (অ্যাড সিস্টেম ইন্টিগ্রেটেড)
  Future<void> _handlePost() async {
    if (_isSaving) return;
    if (AppConfigService.isPostingDisabled) {
      _showSnack("Posting disabled", Colors.redAccent);
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showSnack("Enter title", Colors.redAccent);
      return;
    }
    if (_selectedLatLng == null) {
      _showSnack("Pick location", Colors.redAccent);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack("Not logged in", Colors.redAccent);
      return;
    }

    // --- অ্যাড লজিক শুরু ---
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final subscription = (userDoc.data()?['subscription_type'] ?? 'free').toString();
      final bool isPremium = subscription == 'pro' || subscription == 'business';

      if (!isPremium && mounted) {
        // ফ্রি ইউজার হলে অ্যাড পেজে পাঠাবে
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdDisplayScreen(
              onAdDismissed: () {
                // অ্যাড শেষ হওয়ার পর নিচের কোড রান হবে
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Ad check error: $e");
    }
    // --- অ্যাড লজিক শেষ ---

    setState(() => _isSaving = true);

    try {
      final meta = await _getCurrentUserProfileMeta(user.uid);
      final uploadedUrls = await _uploadMedia();

      await PostService.createPost(
        ownerId: user.uid,
        ownerRole: meta['userRole'],
        slots: _slots,
        approvedCount: 0,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        roleLabel: _selectedCategory.toUpperCase(),
        roleKey: _selectedCategory.toLowerCase().replaceAll(' ', '_'),
        lat: _selectedLatLng!.latitude,
        lng: _selectedLatLng!.longitude,
        address: _locationName,
        locationKeys: _locationName.toLowerCase().split(RegExp(r'[^a-z0-9]+')).where((s) => s.isNotEmpty).toList(),
        price: _budget,
        priceLabel: '৳ ${_budget.toInt()} / job',
        images: uploadedUrls,
        isLive: true,
        createdAt: FieldValue.serverTimestamp(),
        gender: meta['gender'],
        experience: 0,
        rating: meta['rating'],
        trusted: meta['trusted'],
        verified: meta['verified'],
        isPromoted: false,
        status: 'open',
      );

      await NotificationService.sendNotificationToUser(
        toUserId: user.uid,
        title: "Job request posted",
        body: "Your request is now live.",
        type: "support_post",
        data: {'roleLabel': _selectedCategory},
      );

      if (mounted) {
        _showSnack("Posted successfully", AppColors.brandMain);
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnack("Failed: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Attach Media", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _mediaOption(Icons.camera_alt, "Camera", () => _pickMedia(ImageSource.camera)),
                _mediaOption(Icons.photo_library, "Gallery", () => _pickMedia(ImageSource.gallery, multi: true)),
                _mediaOption(Icons.videocam, "Video", () => _pickMedia(ImageSource.camera, video: true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source, {bool multi = false, bool video = false}) async {
    Navigator.pop(context);
    if (video) {
      final file = await _picker.pickVideo(source: source);
      if (file != null) setState(() => _mediaFiles.add(file));
    } else if (multi) {
      final files = await _picker.pickMultiImage(imageQuality: 80);
      if (files.isNotEmpty) setState(() => _mediaFiles.addAll(files));
    } else {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file != null) setState(() => _mediaFiles.add(file));
    }
  }

  Widget _mediaOption(IconData icon, String label, VoidCallback onTap) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.brandLight;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final hintColor = isDark ? Colors.grey : Colors.grey.shade600;

    return FloatingScaffold(
      title: "POST A JOB REQUEST",
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
            onPressed: _isSaving ? null : _handlePost,
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text("POST", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          ),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Worker Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) => _buildCategoryItem(_categories[index], isDark),
              ),
            ),
            const SizedBox(height: 20),

            Text("Job Title", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            const SizedBox(height: 8),
            _buildTextField(_titleController, "e.g. Need a full day cleaner...", isDark, cardColor, textColor, hintColor),

            const SizedBox(height: 20),
            Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            const SizedBox(height: 8),
            _buildTextField(_descController, "Describe the work details...", isDark, cardColor, textColor, hintColor, maxLines: 4),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _useCurrentLocation,
                        activeColor: AppColors.brandMain,
                        onChanged: (v) async {
                          setState(() => _useCurrentLocation = v ?? true);
                          if (v == true) await _determineInitialPosition();
                        },
                      ),
                      Expanded(child: Text("Use current location", style: TextStyle(color: textColor))),
                      TextButton.icon(
                        onPressed: _selectLocationOnMap,
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text("Pick on Map"),
                      ),
                    ],
                  ),
                  if (_locationName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 8),
                      child: Text(_locationName, style: TextStyle(fontSize: 12, color: hintColor)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showMediaOptions,
                icon: const Icon(Icons.camera_alt, color: AppColors.brandMain),
                label: const Text("Add Photo / Video", style: TextStyle(color: AppColors.brandMain)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.brandMain),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: cardColor,
                ),
              ),
            ),
            _buildAttachmentsSection(),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Budget (per job)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                Text("৳ ${_budget.toInt()}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
            Slider(
              value: _budget,
              min: 300, max: 10000, divisions: 97,
              activeColor: AppColors.brandMain,
              inactiveColor: isDark ? Colors.grey : Colors.grey.shade300,
              onChanged: (val) => setState(() => _budget = val),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handlePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("POST JOB REQUEST", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isDark, Color fillColor, Color textColor, Color hintColor, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    if (_mediaFiles.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 80,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _mediaFiles.length,
        itemBuilder: (context, index) {
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(image: FileImage(File(_mediaFiles[index].path)), fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> item, bool isDark) {
    final bool isSelected = _selectedCategory == item['name'];
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = item['name']),
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandMain.withOpacity(0.2) : cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? AppColors.brandMain : Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item['icon'], size: 28, color: isSelected ? AppColors.brandMain : Colors.grey),
            const SizedBox(height: 6),
            Text(item['name'], textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.brandMain : textColor)),
          ],
        ),
      ),
    );
  }
}