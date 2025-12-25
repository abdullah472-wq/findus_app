import 'dart:io';
import 'package:flutter/material.dart';
import 'package:findus_app/services/app_config_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:findus_app/constants/app_colors.dart';

// 🔹 NEW: notification + auth
import 'package:findus_app/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EarnPostScreen extends StatefulWidget {
  const EarnPostScreen({super.key});

  @override
  State<EarnPostScreen> createState() => _EarnPostScreenState();
}

class _EarnPostScreenState extends State<EarnPostScreen> {
  final TextEditingController _serviceTypeController =
  TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _mediaFiles = [];   // ছবি / ভিডিও
  final List<String> _voiceNotes = [];  // ডেমো voice note লেখা

  bool _useCurrentLocation = true;
  String _selectedLocation = "Uttara, Sector 10";

  bool _isRecording = false;
  DateTime? _recordStartTime;

  double _expectedCharge = 800.0;

  // ক্যাটাগরি লিস্ট (UI তে দেখানোর জন্য)
  final List<Map<String, dynamic>> _categories = const [
    {"icon": Icons.electric_bolt, "name": "Electrician"},
    {"icon": Icons.plumbing, "name": "Plumber"},
    {"icon": Icons.directions_car, "name": "Driver"},
    {"icon": Icons.cleaning_services, "name": "Cleaner"},
    {"icon": Icons.format_paint, "name": "Painter"},
    {"icon": Icons.person, "name": "Helper"},
  ];
  String _selectedCategory = "Electrician";

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ----------------- Ad dialog (DROP PIN এর আগে) -----------------
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
                  "Showing short ad to drop your job offer pin...",
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
    final title = _serviceTypeController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter job title / service type."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await _showAdDialog();

    if (!mounted) return;

    // TODO: backend এ worker job offer পিন হিসেবে পোস্ট করবে

    // 🔹 job_post টাইপ notification → current worker (owner) এর জন্য
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await NotificationService.sendNotificationToUser(
        toUserId: currentUser.uid,
        title: "Your job offer has been posted",
        body: "“$title” is now visible to nearby supporters.",
        type: "job_post",
        // এখানে worker-এর job offer সংক্রান্ত extra data
        data: {
          'roleLabel': _selectedCategory,       // Electrician / Plumber ...
          'expectedCharge': _expectedCharge,    // daily charge
          'useCurrentLocation': _useCurrentLocation,
          'locationLabel': _selectedLocation,
        },
        // relatedPostId এখন নেই (TODO backend), তাই পাঠাচ্ছি না
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
        Text("Pin dropped & your job offer posted successfully."),
        backgroundColor: AppColors.brandMain,
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

  // ----------------- Location select (demo) -----------------
  Future<void> _selectLocationOnMap() async {
    // TODO: আলাদা map picker পেজ করলে এখানে যাবে
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Map picker coming soon."),
      ),
    );
  }

  // ----------------- Voice রেকর্ড (simple demo) -----------------
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
          "Post a Job Offer",
          style: TextStyle(
              color: AppColors.brandDark, fontWeight: FontWeight.bold),
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
          // উপরের স্ক্রলেবল UI
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ক্যাটাগরি নির্বাচন
                  const Text(
                    "Select Service Type",
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryItem(_categories[index]);
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Service Type (job title)
                  const Text(
                    "Job Title",
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _serviceTypeController,
                    decoration: InputDecoration(
                      hintText:
                      "e.g. Full day driver, Part-time cleaner...",
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

                  // Problem / Job Description
                  const Text(
                    "Job Description",
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                      "Describe your skills, experience, and what work you can do...",
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

                  // Drop pin in current location + select on map
                  Row(
                    children: [
                      Checkbox(
                        value: _useCurrentLocation,
                        activeColor: AppColors.brandMain,
                        onChanged: (v) =>
                            setState(() => _useCurrentLocation = v ?? true),
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

                  // Media + Audio row
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

                  // Media + voice তালিকা (delete সহ)
                  _buildAttachmentsSection(),

                  const SizedBox(height: 20),

                  // Expected charge slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Expected Daily Charge",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        "৳ ${_expectedCharge.toInt()}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _expectedCharge,
                    min: 300,
                    max: 5000,
                    divisions: 47,
                    activeColor: AppColors.brandMain,
                    inactiveColor: AppColors.brandLight,
                    onChanged: (val) =>
                        setState(() => _expectedCharge = val),
                  ),
                ],
              ),
            ),
          ),

          // নিচে Drop pin বাটন
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color:
                  Colors.black.withOpacity(0.05),
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
                  "DROP PIN & POST JOB OFFER",
                  style: TextStyle(
                    fontSize: 14,
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

  // Attachments with delete
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
                final isVideo = file.path.toLowerCase().endsWith(".mp4") ||
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

  // Category chip
  Widget _buildCategoryItem(Map<String, dynamic> item) {
    final bool isSelected = _selectedCategory == item['name'];
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = item['name']),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color:
          isSelected ? AppColors.brandMain.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? AppColors.brandMain : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item['icon'],
              size: 30,
              color: isSelected ? AppColors.brandMain : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              item['name'],
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
                color:
                isSelected ? AppColors.brandDark : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}