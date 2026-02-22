import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

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
  int _currentPage = 1;
  int _totalPages = 0;

  final PdfViewerController _pdfController = PdfViewerController();

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final uri = Uri.parse(widget.pdfUrl);

    try {
      if (!await canLaunchUrl(uri)) {
        _showSnack('Could not start download.', Colors.redAccent);
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _showSnack('Opening download...', Colors.green);
    } catch (_) {
      _showSnack('Could not start download.', Colors.redAccent);
    }
  }

  void _sharePdf() {
    Share.share(
      'Check out my CV: ${widget.pdfUrl}',
      subject: 'Professional CV',
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return FloatingScaffold(
      title: 'Curriculum Vitae',
      backgroundColor: bgColor,
      titleColor: isDark ? Colors.white : AppColors.brandDark,
      iconColor: isDark ? Colors.white : AppColors.brandDark,
      showBack: true,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      actions: [
        // Zoom Out
        IconButton(
          tooltip: 'Zoom Out',
          icon: Icon(Icons.zoom_out, color: isDark ? Colors.white : AppColors.brandMain),
          onPressed: () {
            if (_pdfController.zoomLevel > 1.0) {
              _pdfController.zoomLevel -= 0.25;
            }
          },
        ),

        // Zoom In
        IconButton(
          tooltip: 'Zoom In',
          icon: Icon(Icons.zoom_in, color: isDark ? Colors.white : AppColors.brandMain),
          onPressed: () {
            if (_pdfController.zoomLevel < 3.0) {
              _pdfController.zoomLevel += 0.25;
            }
          },
        ),

        // Share
        IconButton(
          tooltip: 'Share',
          icon: Icon(Icons.share, color: isDark ? Colors.white : AppColors.brandMain),
          onPressed: _sharePdf,
        ),

        // Download
        IconButton(
          tooltip: 'Download',
          icon: Icon(Icons.download_rounded, color: isDark ? Colors.white : AppColors.brandMain),
          onPressed: () => _downloadPdf(context),
        ),
      ],
      body: Column(
        children: [
          // ✅ Page Indicator
          if (_totalPages > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.8) : Colors.grey[200],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description,
                    size: 16,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Page $_currentPage of $_totalPages",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

          // ✅ PDF Viewer
          Expanded(
            child: Stack(
              children: [
                SfPdfViewer.network(
                  widget.pdfUrl,
                  controller: _pdfController,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    setState(() {
                      _isLoading = false;
                      _hasError = false;
                      _totalPages = details.document.pages.count;
                    });
                  },
                  onPageChanged: (PdfPageChangedDetails details) {
                    setState(() {
                      _currentPage = details.newPageNumber;
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

                // Loading
                if (_isLoading)
                  Container(
                    color: isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.7),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.brandMain),
                          SizedBox(height: 16),
                          Text("Loading CV...", style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),

                // Error
                if (_hasError)
                  Container(
                    color: isDark ? Colors.black : Colors.white,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            "Failed to load CV",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Please check your internet connection",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _hasError = false;
                              });
                            },
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text("Retry", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandMain,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}