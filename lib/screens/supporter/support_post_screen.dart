import 'dart:io';
import 'package:flutter/material.dart';
import 'package:findus_app/services/app_config_service.dart';
import 'package:findus_app/services/post_service.dart';

import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/supporter/location_picker_screen.dart';

// 🔹 NEW: notification + auth
import 'package:findus_app/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportPostScreen extends StatefulWidget {
  const SupportPostScreen({super.key});

  @override
  State<SupportPostScreen> createState() => _SupportPostScreenState();
}

class _SupportPostScreenState extends State<SupportPostScreen> {
  final TextEditingController _serviceTypeController =
  TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _mediaFiles = []; // image / video
  final List<String> _voiceNotes = []; // demo text (audio info)

  // নতুন: প্রি-ডিফাইনড সার্ভিস টাইপ লিস্ট + সিলেক্টেড ভ্যালু
  final List<String> _serviceTypeOptions = const [
    'AC Repair',
    'Plumbing',
    'Electrician',
    'Cleaning',
    'Carpenter',
    'Painter',
    'Computer Repair',
    'Vehicle Repair',
    'Driver',
    'Other', // Other নিলে নিচে কাস্টম টেক্সট বক্স আসবে
  ];
  String? _selectedServiceType;

  bool _useCurrentLocation = true;
  String _selectedLocation = "Uttara, Sector 10";
  LatLng? _selectedLatLng; // ম্যাপ থেকে সিলেক্ট করা লোকেশন

  bool _isRecording = false;
  DateTime? _recordStartTime;

  double _budget = 500.0;

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ----------------- Ad dialog (Drop pin এর আগে) -----------------
  Future<void> _showAdDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: const [
              CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.brandMain),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Showing short ad to drop your pin...",
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleDropPin() async {
    // config check – posting disabled হলে এখানেই থামিয়ে দাও
    if (AppConfigService.isPostingDisabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text("Posting is temporarily disabled. Please try again later."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    // -------- ১) Service type validation --------
    String serviceType = '';

    if (_selectedServiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a service type."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    } else if (_selectedServiceType == 'Other') {
      serviceType = _serviceTypeController.text.trim();
      if (serviceType.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please write your service name."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    } else {
      serviceType = _selectedServiceType!;
    }

    // -------- ২) Location validation --------
    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a location on map."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await _showAdDialog();

    if (!mounted) return;

    await _showAdDialog();
    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must be logged in to post a request."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 🔹 এখানে Firestore এ আসল পোস্ট তৈরি করছি
    await PostService.createPost(
      ownerId: currentUser.uid,
      ownerRole: 'supporter',          // কারণ এটা SupportPostScreen
      title: serviceType,
      roleLabel: serviceType.toUpperCase(), // চাইলে mapping করতে পারো
      lat: _selectedLatLng!.latitude,
      lng: _selectedLatLng!.longitude,
      address: _selectedLocation,
      priceLabel: '৳ ${_budget.toInt()}',
      // নিচেরগুলো এখন demo/default
      isLive: true,
      verified: false,
      phone: currentUser.phoneNumber ?? '',
      gender: 'Any',
      experience: 0,
      rating: 4.5,
      language: 'Any',
      trusted: false,
      isPromoted: false,
    );

    final locationDesc =
        "Lat: ${_selectedLatLng!.latitude.toStringAsFixed(5)}, "
        "Lng: ${_selectedLatLng!.longitude.toStringAsFixed(5)}";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Pin dropped at $locationDesc\nService: $serviceType.",
        ),
        backgroundColor: AppColors.brandMain,
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.pop(context); // চাইলে পোস্টের পর পেজটা বন্ধও করতে পারো

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Pin dropped at $locationDesc\nService: $serviceType (demo).",
        ),
        backgroundColor: AppColors.brandMain,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ----------------- Media attach -----------------
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
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.only(bottom: 16),
            ),
            const Text(
              "Attach Photo / Video",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _mediaOption(
                  icon: Icons.camera_alt,
                  label: "Camera",
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? file =
                    await _picker.pickImage(source: ImageSource.camera);
                    if (file != null) {
                      setState(() => _mediaFiles.add(file));
                    }
                  },
                ),
                _mediaOption(
                  icon: Icons.photo_library,
                  label: "Gallery",
                  onTap: () async {
                    Navigator.pop(context);
                    final List<XFile> files =
                    await _picker.pickMultiImage();
                    if (files.isNotEmpty) {
                      setState(() => _mediaFiles.addAll(files));
                    }
                  },
                ),
                _mediaOption(
                  icon: Icons.videocam,
                  label: "Video",
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? file =
                    await _picker.pickVideo(source: ImageSource.camera);
                    if (file != null) {
                      setState(() => _mediaFiles.add(file));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.brandLight,
            child: Icon(icon, color: AppColors.brandDark),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // ----------------- Location select (map picker) -----------------
  Future<void> _selectLocationOnMap() async {
    final LatLng? picked = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(),
      ),
    );

    if (picked != null) {
      setState(() {
        _useCurrentLocation = false; // custom pin ব্যবহার হচ্ছে
        _selectedLatLng = picked;
        _selectedLocation =
        "Pin: ${picked.latitude.toStringAsFixed(5)}, ${picked.longitude.toStringAsFixed(5)}";
      });
    }
  }

  // ----------------- Voice recording (simple demo) -----------------
  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordStartTime = DateTime.now();
    });
  }

  void _stopRecording() {
    if (!_isRecording || _recordStartTime == null) return;

    final duration = DateTime.now().difference(_recordStartTime!);
    final seconds = duration.inSeconds.clamp(1, 300);

    setState(() {
      _isRecording = false;
      _voiceNotes.add("Voice note ${_voiceNotes.length + 1} - ${seconds}s");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Post a Request",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // উপরের স্ক্রলেবল অংশ
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ১. Service Type (dropdown + optional other text)
                  const Text(
                    "Service Type",
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedServiceType,
                    items: _serviceTypeOptions.map((s) {
                      return DropdownMenuItem<String>(
                        value: s,
                        child: Text(s),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedServiceType = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Select a service",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                  ),
                  if (_selectedServiceType == 'Other') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _serviceTypeController,
                      decoration: InputDecoration(
                        hintText: "Write your service name...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // ২. Problem Description
                  const Text(
                    "Problem Description",
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Describe what help you need...",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ৩. Drop pin in current location + Select on map
                  Row(
                    children: [
                      Checkbox(
                        value: _useCurrentLocation,
                        activeColor: AppColors.brandMain,
                        onChanged: (v) {
                          setState(() {
                            _useCurrentLocation = v ?? true;
                            if (_useCurrentLocation) {
                              _selectedLocation = "Current location";
                            }
                          });
                        },
                      ),
                      const Flexible(
                        child: Text(
                          "Drop pin in current location",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _selectLocationOnMap,
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text("Select on map"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _selectedLocation,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ৪. Audio / Media section
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showMediaOptions,
                          icon: const Icon(Icons.camera_alt,
                              color: AppColors.brandMain),
                          label: const Text(
                            "Add Photo / Video",
                            style: TextStyle(color: AppColors.brandMain),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(
                                color: AppColors.brandMain),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTapDown: (_) => _startRecording(),
                          onTapUp: (_) => _stopRecording(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            decoration: BoxDecoration(
                              color: _isRecording
                                  ? Colors.redAccent
                                  : AppColors.brandDark,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isRecording
                                      ? Icons.mic
                                      : Icons.mic_none,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isRecording
                                      ? "Recording..."
                                      : "Hold to Record",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ৫. Attached image/video + voice notes (delete সহ)
                  _buildAttachmentsSection(),

                  const SizedBox(height: 20),

                  // ৬. Budget slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Your Offer",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        "৳ ${_budget.toInt()}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _budget,
                    min: 100,
                    max: 5000,
                    divisions: 49,
                    activeColor: AppColors.brandMain,
                    inactiveColor: AppColors.brandLight,
                    onChanged: (val) => setState(() => _budget = val),
                  ),
                ],
              ),
            ),
          ),

          // নিচে DROP PIN বাটন
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _handleDropPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "DROP PIN & POST REQUEST",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  Attachments UI + delete অপশন
  Widget _buildAttachmentsSection() {
    if (_mediaFiles.isEmpty && _voiceNotes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_mediaFiles.isNotEmpty) ...[
          const Text(
            "Photos / Videos",
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _mediaFiles.length,
              itemBuilder: (context, index) {
                final file = _mediaFiles[index];
                final isVideo =
                    file.path.toLowerCase().endsWith(".mp4") ||
                        file.path.toLowerCase().endsWith(".mov");

                return Stack(
                  children: [
                    Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border:
                        Border.all(color: Colors.grey.shade300),
                        image: !isVideo
                            ? DecorationImage(
                          image: FileImage(File(file.path)),
                          fit: BoxFit.cover,
                        )
                            : null,
                        color: isVideo ? Colors.black12 : null,
                      ),
                      child: isVideo
                          ? const Center(
                        child: Icon(Icons.videocam,
                            color: Colors.black54),
                      )
                          : null,
                    ),
                    Positioned(
                      top: 2,
                      right: 10,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _mediaFiles.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_voiceNotes.isNotEmpty) ...[
          const Text(
            "Voice notes",
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey),
          ),
          const SizedBox(height: 4),
          ..._voiceNotes.asMap().entries.map(
                (e) {
              final index = e.key;
              final text = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _voiceNotes.removeAt(index)),
                      child: const Icon(Icons.delete,
                          size: 16, color: Colors.redAccent),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}