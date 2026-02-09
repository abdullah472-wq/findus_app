import 'dart:typed_data';
import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:findus_app/achievement/achievement_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/services/cloudinary_service.dart';
import 'package:findus_app/screens/profile/worker_cv_create_screen.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class WorkerDocumentsScreen extends StatefulWidget {
  final String uid;
  final bool isOwner;

  const WorkerDocumentsScreen({
    super.key,
    required this.uid,
    this.isOwner = false,
  });

  @override
  State<WorkerDocumentsScreen> createState() => _WorkerDocumentsScreenState();
}

class _WorkerDocumentsScreenState extends State<WorkerDocumentsScreen> {
  bool _loading = true;
  String _cvUrl = '';
  List<String> _portfolioUrls = [];
  String? _error;

  bool _isUploadingCv = false;
  bool _isUploadingPortfolio = false;

  Map<String, dynamic> _userData = {};

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  List<String> _safeStringList(dynamic value) {
    if (value is Iterable) {
      try {
        return value
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      } catch (_) {
        return <String>[];
      }
    }
    return <String>[];
  }

  Future<void> _loadDocuments() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      final data = snap.data() ?? {};

      final cvUrl = data['cvUrl']?.toString() ?? '';
      final portfolioUrls = _safeStringList(data['portfolioUrls']);

      if (!mounted) return;
      setState(() {
        _userData = data;
        _cvUrl = cvUrl;
        _portfolioUrls = portfolioUrls;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load documents: $e';
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open link')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open link')),
      );
    }
  }

  void _openGallery(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PortfolioGalleryScreen(
          urls: _portfolioUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // ---------- CV Upload / Delete ----------

  Future<void> _pickAndUploadCv() async {
    if (_isUploadingCv) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isUploadingCv = true);

      final file = result.files.single;
      Uint8List? bytes = file.bytes;

      if (bytes == null && file.path != null && file.path!.isNotEmpty) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) {
        throw Exception('Cannot read file bytes');
      }

      final uploadRes = await CloudinaryService.uploadBytes(
        bytes,
        fileName: file.name,
        folder: 'findus/cv',
        resourceType: 'raw',
        tags: const ['cv'],
      );

      final url = uploadRes['secure_url']?.toString();
      if (url == null || url.isEmpty) {
        throw Exception('No secure_url returned from Cloudinary');
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set(
        {
          'cvUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

// ✅ add this
      await AchievementService.syncProfileChainFromUserDoc(uid: widget.uid);

      if (!mounted) return;
      setState(() {
        _cvUrl = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CV uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CV upload failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingCv = false);
    }
  }

  Future<void> _deleteCv() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete CV'),
        content: const Text('Are you sure you want to remove your CV link?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set(
        {
          'cvUrl': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() {
        _cvUrl = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CV removed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete CV: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ---------- Portfolio Upload / Delete ----------

  Future<void> _pickAndUploadPortfolio() async {
    if (_isUploadingPortfolio) return;

    try {
      final List<XFile> files = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (files.isEmpty) return;

      setState(() => _isUploadingPortfolio = true);

      final List<String> newUrls = [];

      for (final file in files) {
        try {
          final uploaded = await CloudinaryService.uploadXFile(
            file,
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

      if (newUrls.isEmpty) {
        throw Exception('No images uploaded');
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'portfolioUrls': FieldValue.arrayUnion(newUrls),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // ✅ Sync profile long-term chain (stage-3) after CV upload
      await AchievementService.syncProfileChainFromUserDoc(uid: widget.uid);

      if (!mounted) return;
      setState(() {
        _portfolioUrls.addAll(newUrls);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${newUrls.length} images added to portfolio"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Portfolio upload failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingPortfolio = false);
    }
  }

  Future<void> _deletePortfolioImage(String url) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove image'),
        content: const Text('Remove this image from your portfolio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'REMOVE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({
        'portfolioUrls': FieldValue.arrayRemove([url]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _portfolioUrls.remove(url);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image removed from portfolio'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete image: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ---------- Digital CV ----------

  void _openDigitalCvEditor() {
    final name = (_userData['name'] ?? 'User').toString();
    final image = (_userData['image'] ?? '').toString();
    final about = (_userData['about'] ?? '').toString();
    final location = (_userData['location'] ?? '').toString();
    final priceText =
    (_userData['priceText'] ?? _userData['priceLabel'] ?? 'Negotiable')
        .toString();

    num? priceNum;
    final rawPrice = _userData['price'];
    if (rawPrice is num) {
      priceNum = rawPrice;
    } else if (rawPrice != null) {
      priceNum = num.tryParse(rawPrice.toString());
    }

    final ratingRaw = _userData['rating'];
    double rating = 0.0;
    if (ratingRaw is num) {
      rating = ratingRaw.toDouble();
    } else if (ratingRaw != null) {
      rating = double.tryParse(ratingRaw.toString()) ?? 0.0;
    }

    final worker = Worker(
      uid: widget.uid,
      userRole: 'finder',
      name: name,
      image: image,
      about: about,
      rating: rating,
      location: location,
      priceText: priceText,
      price: priceNum,
      kycCompleted: (_userData['kyc_completed'] ?? false) == true,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerCVCreateScreen(worker: worker),
      ),
    );
    // ফিরে আসার পর ডাটা রিফ্রেশ করুন
    _loadDocuments();
  }

  // ---------- BUILD (FloatingScaffold) ----------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : AppColors.bgBlue;
    final titleColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: 'Documents & Portfolio',
      backgroundColor: bgColor,
      titleColor: titleColor,
      iconColor: titleColor,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError(isDark)
          : _buildContent(isDark),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ----- CV Section -----
        Text(
          'Uploaded CV',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        _buildCvSection(isDark),
        const SizedBox(height: 24),

        // ----- Digital CV Section -----
        Text(
          'Digital CV',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        _buildDigitalCvSection(isDark),
        const SizedBox(height: 24),

        // ----- Portfolio Section -----
        Text(
          'Portfolio',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        _buildPortfolioSection(isDark),
      ],
    );
  }

  Widget _buildCvSection(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(
                Icons.description_outlined,
                color: AppColors.brandMain,
              ),
              title: Text(
                _cvUrl.isNotEmpty ? 'CV / Resume' : 'No CV uploaded',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              subtitle: Text(
                _cvUrl.isNotEmpty
                    ? 'Tap to open your CV'
                    : 'Upload your CV in PDF/DOC format',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
              trailing: _cvUrl.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.open_in_new),
                color: AppColors.brandMain,
                onPressed: () => _launchUrl(_cvUrl),
              )
                  : null,
            ),
            if (widget.isOwner) ...[
              const Divider(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _isUploadingCv ? null : _pickAndUploadCv,
                      icon: _isUploadingCv
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.upload_file),
                      label: Text(
                        _cvUrl.isEmpty ? 'Upload CV' : 'Replace CV',
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ),
                  if (_cvUrl.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _deleteCv,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalCvSection(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    // চেক করুন সিভি আছে কি না (ফায়ারবেস ডাটা থেকে)
    final bool hasDigitalCv = (_userData['has_created_cv'] ?? false) == true;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                hasDigitalCv ? Icons.check_circle : Icons.edit_document,
                color: hasDigitalCv ? Colors.green : AppColors.brandMain,
              ),
              title: Text(
                hasDigitalCv ? 'Digital CV Created' : 'Create Digital CV',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              subtitle: Text(
                hasDigitalCv
                    ? 'Last updated: ${_formatDate(_userData['cv_updated_at'])}'
                    : 'Create a professional CV within the app.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
              // প্রিভিউ বাটন (যদি সিভি থাকে)
              trailing: hasDigitalCv
                  ? IconButton(
                icon: const Icon(Icons.visibility, color: AppColors.brandMain),
                onPressed: () {
                  // TODO: ডিজিটাল সিভি ভিউয়ার পেজ ওপেন করুন
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => DigitalCvViewerScreen(uid: widget.uid)));
                },
              )
                  : null,
            ),
            if (widget.isOwner)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _openDigitalCvEditor,
                  icon: const Icon(Icons.edit, size: 18, color: AppColors.brandMain),
                  label: Text(
                    hasDigitalCv ? 'Edit CV' : 'Create Now',
                    style: const TextStyle(color: AppColors.brandMain),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildPortfolioSection(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_portfolioUrls.isEmpty)
              Text(
                'No portfolio images yet.',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _portfolioUrls.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final url = _portfolioUrls[index];
                  return GestureDetector(
                    onTap: () => _openGallery(index),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (ctx, _) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                            errorWidget: (ctx, _, __) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        if (widget.isOwner)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _deletePortfolioImage(url),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            if (widget.isOwner) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed:
                  _isUploadingPortfolio ? null : _pickAndUploadPortfolio,
                  icon: _isUploadingPortfolio
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.add_photo_alternate,
                      color: AppColors.brandMain),
                  label: const Text(
                    'Add Images',
                    style: TextStyle(color: AppColors.brandMain),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------- Portfolio Gallery Screen (আগের মতই রাখা) ----------

class _PortfolioGalleryScreen extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _PortfolioGalleryScreen({
    required this.urls,
    this.initialIndex = 0,
  });

  @override
  State<_PortfolioGalleryScreen> createState() =>
      _PortfolioGalleryScreenState();
}

class _PortfolioGalleryScreenState extends State<_PortfolioGalleryScreen> {
  late PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_index + 1}/${widget.urls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (ctx, i) {
          return Center(
            child: CachedNetworkImage(
              imageUrl: widget.urls[i],
              fit: BoxFit.contain,
              placeholder: (context, url) =>
              const CircularProgressIndicator(color: Colors.white),
              errorWidget: (context, url, error) => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.white, size: 50),
                  SizedBox(height: 10),
                  Text(
                    "Failed to load image",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}