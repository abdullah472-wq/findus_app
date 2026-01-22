// lib/screens/cv_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart'; // ✅ আপনার কাস্টম স্ক্যাফোল্ড

class CvViewerScreen extends StatefulWidget {
  final String pdfUrl;

  const CvViewerScreen({
    super.key,
    required this.pdfUrl,
  });

  @override
  State<CvViewerScreen> createState() => _CvViewerScreenState();
}

class _CvViewerScreenState extends State<CvViewerScreen> {
  bool _isLoading = true;
  bool _hasError = false;

  Future<void> _downloadPdf(BuildContext context) async {
    final uri = Uri.parse(widget.pdfUrl);

    try {
      if (!await canLaunchUrl(uri)) {
        _showSnack('Could not start download.', Colors.redAccent);
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _showSnack('Could not start download.', Colors.redAccent);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingScaffold(
      title: 'Curriculum Vitae',
      backgroundColor: Colors.white,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      showBack: true,
      scrollable: false, // PDF নিজেই স্ক্রলেবল
      bodyPadding: EdgeInsets.zero,

      actions: [
        IconButton(
          tooltip: 'Download / Save',
          icon: const Icon(Icons.download_rounded, color: AppColors.brandMain),
          onPressed: () => _downloadPdf(context),
        ),
      ],

      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.pdfUrl,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _isLoading = false;
                _hasError = false;
              });
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
              debugPrint("PDF Load Error: ${details.error}");
            },
          ),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.brandMain),
            ),

          if (_hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text(
                    "Failed to load PDF",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _hasError = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandMain,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Retry", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}