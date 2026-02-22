import 'dart:typed_data';
import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:findus_app/achievement/achievement_service.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/models/worker_model.dart';
import 'package:findus_app/services/cloudinary_service.dart';
import 'package:findus_app/screens/profile/worker_cv_create_screen.dart';
import 'package:findus_app/screens/profile/cv_viewer_screen.dart';
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

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.day}/${date.month}/${date.year}";
    }
    return 'N/A';
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD DATA
  // ═══════════════════════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════════════════════
  // URL LAUNCHER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Cannot open link');
      }
    } catch (_) {
      _showError('Cannot open link');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GALLERY
  // ═══════════════════════════════════════════════════════════════════════════

  void _openGallery(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PortfolioGalleryScreen(
          urls: _portfolioUrls,
          initialIndex: initialIndex,
          isOwner: widget.isOwner,
          onDelete: (url) => _deletePortfolioImage(url),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CV UPLOAD / DELETE
  // ═══════════════════════════════════════════════════════════════════════════

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

      // ✅ Show progress dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.brandMain),
                SizedBox(height: 20),
                Text(
                  "Uploading CV...",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  "Please wait",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }

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

      // ✅ Achievement sync
      await AchievementService.syncProfileChainFromUserDoc(uid: widget.uid);

      // ✅ Close progress dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;
      setState(() {
        _cvUrl = url;
      });

      _showSuccess('CV uploaded successfully!');
    } catch (e) {
      // ✅ Close progress dialog on error
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showError('CV upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploadingCv = false);
    }
  }

  Future<void> _deleteCv() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red[400]),
            const SizedBox(width: 10),
            Text(
              'Delete CV?',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove your CV? This action cannot be undone.',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
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

      _showSuccess('CV removed');
    } catch (e) {
      _showError('Failed to delete CV: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CV VIEWER
  // ═══════════════════════════════════════════════════════════════════════════

  void _openCvViewer() {
    if (_cvUrl.isEmpty) {
      _showError('No CV uploaded yet');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CvViewerScreen(pdfUrl: _cvUrl),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PORTFOLIO UPLOAD / DELETE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _pickAndUploadPortfolio() async {
    if (_isUploadingPortfolio) return;

    try {
      final List<XFile> files = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (files.isEmpty) return;

      setState(() => _isUploadingPortfolio = true);

      // ✅ Show progress dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.brandMain),
                const SizedBox(height: 20),
                Text(
                  "Uploading ${files.length} image${files.length > 1 ? 's' : ''}...",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Please wait",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }

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

      // ✅ Achievement sync
      await AchievementService.syncProfileChainFromUserDoc(uid: widget.uid);

      // ✅ Close progress dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;
      setState(() {
        _portfolioUrls.addAll(newUrls);
      });

      _showSuccess("${newUrls.length} image${newUrls.length > 1 ? 's' : ''} added to portfolio");
    } catch (e) {
      // ✅ Close progress dialog on error
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showError('Portfolio upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPortfolio = false);
    }
  }

  Future<void> _deletePortfolioImage(String url) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red[400]),
            const SizedBox(width: 10),
            Text(
              'Remove Image?',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'This image will be removed from your portfolio. This action cannot be undone.',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
            child: const Text('REMOVE'),
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

      _showSuccess('Image removed from portfolio');
    } catch (e) {
      _showError('Failed to delete image: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIGITAL CV EDITOR
  // ═══════════════════════════════════════════════════════════════════════════

  void _openDigitalCvEditor() async {
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

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkerCVCreateScreen(worker: worker),
      ),
    );

    // ফিরে আসার পর ডাটা রিফ্রেশ করুন
    _loadDocuments();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════════════════

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
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.brandMain),
            SizedBox(height: 16),
            Text("Loading documents..."),
          ],
        ),
      )
          : _error != null
          ? _buildError(isDark)
          : _buildContent(isDark),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              "Failed to load documents",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? "Unknown error",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadDocuments();
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("Retry", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
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
        _buildSectionTitle('Uploaded CV', textColor),
        const SizedBox(height: 8),
        _buildCvSection(isDark),
        const SizedBox(height: 24),

        // ----- Digital CV Section -----
        _buildSectionTitle('Digital CV', textColor),
        const SizedBox(height: 8),
        _buildDigitalCvSection(isDark),
        const SizedBox(height: 24),

        // ----- Portfolio Section -----
        _buildSectionTitle('Portfolio (${_portfolioUrls.length})', textColor),
        const SizedBox(height: 8),
        _buildPortfolioSection(isDark),
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.brandMain,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CV SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCvSection(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Card(
      color: cardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _cvUrl.isNotEmpty
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _cvUrl.isNotEmpty ? Icons.description : Icons.upload_file,
                    color: _cvUrl.isNotEmpty ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _cvUrl.isNotEmpty ? 'CV / Resume Uploaded' : 'No CV Uploaded',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _cvUrl.isNotEmpty
                            ? 'Tap to view your CV'
                            : 'Upload your CV in PDF/DOC format',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // View Button
                if (_cvUrl.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.visibility, color: AppColors.brandMain),
                    tooltip: "View CV",
                    onPressed: _openCvViewer,
                  ),
              ],
            ),

            if (widget.isOwner) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              Row(
                children: [
                  // Upload / Replace Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingCv ? null : _pickAndUploadCv,
                      icon: _isUploadingCv
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.upload_file),
                      label: Text(_cvUrl.isEmpty ? 'Upload CV' : 'Replace CV'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandMain,
                        side: const BorderSide(color: AppColors.brandMain),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  // Download Button
                  if (_cvUrl.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => _launchUrl(_cvUrl),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text("Download"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],

                  // Delete Button
                  if (_cvUrl.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _deleteCv,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: "Delete CV",
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

  // ═══════════════════════════════════════════════════════════════════════════
  // DIGITAL CV SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDigitalCvSection(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    final bool hasDigitalCv = (_userData['has_created_cv'] ?? false) == true;
    final String? templateName = _userData['cv_template']?.toString();

    return Card(
      color: cardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasDigitalCv
                        ? Colors.green.withOpacity(0.1)
                        : AppColors.brandMain.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasDigitalCv ? Icons.check_circle : Icons.edit_document,
                    color: hasDigitalCv ? Colors.green : AppColors.brandMain,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasDigitalCv ? 'Digital CV Created' : 'Create Digital CV',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasDigitalCv
                            ? 'Template: ${templateName ?? 'Modern'} • Updated: ${_formatDate(_userData['cv_updated_at'])}'
                            : 'Create a professional CV within the app',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Preview Button
                if (hasDigitalCv && _cvUrl.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.visibility, color: AppColors.brandMain),
                    tooltip: "Preview CV",
                    onPressed: _openCvViewer,
                  ),
              ],
            ),

            if (widget.isOwner) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openDigitalCvEditor,
                  icon: Icon(
                    hasDigitalCv ? Icons.edit : Icons.add,
                    color: Colors.white,
                  ),
                  label: Text(
                    hasDigitalCv ? 'Edit Digital CV' : 'Create Digital CV',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandMain,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PORTFOLIO SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPortfolioSection(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Card(
      color: cardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Empty State
            if (_portfolioUrls.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 60,
                      color: isDark ? Colors.white38 : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No portfolio images yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Showcase your work by adding images',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey[500],
                      ),
                    ),
                    if (widget.isOwner) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isUploadingPortfolio ? null : _pickAndUploadPortfolio,
                        icon: _isUploadingPortfolio
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.add_photo_alternate, color: Colors.white),
                        label: const Text(
                          'Add Images',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandMain,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )

            // ✅ Portfolio Grid
            else ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _portfolioUrls.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final url = _portfolioUrls[index];
                  return GestureDetector(
                    onTap: () => _openGallery(index),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (ctx, _) => Container(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (ctx, _, __) => Container(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),

                        // Delete Button
                        if (widget.isOwner)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => _deletePortfolioImage(url),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
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

              // Add More Button
              if (widget.isOwner) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingPortfolio ? null : _pickAndUploadPortfolio,
                    icon: _isUploadingPortfolio
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.add_photo_alternate),
                    label: const Text('Add More Images'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandMain,
                      side: const BorderSide(color: AppColors.brandMain),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PORTFOLIO GALLERY SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class _PortfolioGalleryScreen extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final bool isOwner;
  final Function(String)? onDelete;

  const _PortfolioGalleryScreen({
    required this.urls,
    this.initialIndex = 0,
    this.isOwner = false,
    this.onDelete,
  });

  @override
  State<_PortfolioGalleryScreen> createState() => _PortfolioGalleryScreenState();
}

class _PortfolioGalleryScreenState extends State<_PortfolioGalleryScreen> {
  late PageController _pageController;
  late int _index;
  late List<String> _urls;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _urls = List.from(widget.urls);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _shareImage() {
    if (_urls.isEmpty) return;
    Share.share(
      'Check out my work: ${_urls[_index]}',
      subject: 'Portfolio Image',
    );
  }

  void _deleteImage() async {
    if (_urls.isEmpty || widget.onDelete == null) return;

    final url = _urls[_index];

    // Call parent delete
    widget.onDelete!(url);

    // Update local list
    setState(() {
      _urls.removeAt(_index);
      if (_index >= _urls.length && _index > 0) {
        _index = _urls.length - 1;
      }
    });

    // If no images left, go back
    if (_urls.isEmpty) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_index + 1} / ${_urls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          // Share Button
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: "Share",
            onPressed: _shareImage,
          ),

          // Delete Button (Owner only)
          if (widget.isOwner && widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: "Delete",
              onPressed: _deleteImage,
            ),
        ],
      ),
      body: _urls.isEmpty
          ? const Center(
        child: Text(
          "No images",
          style: TextStyle(color: Colors.white),
        ),
      )
          : PageView.builder(
        controller: _pageController,
        itemCount: _urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (ctx, i) {
          return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: _urls[i],
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white54, size: 60),
                      SizedBox(height: 16),
                      Text(
                        "Failed to load image",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}