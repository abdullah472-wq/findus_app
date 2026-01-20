import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class CvViewerScreen extends StatelessWidget {
  final String pdfUrl;

  const CvViewerScreen({
    super.key,
    required this.pdfUrl,
  });

  Future<void> _downloadPdf(BuildContext context) async {
    final uri = Uri.parse(pdfUrl);

    try {
      if (!await canLaunchUrl(uri)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start download.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // ব্রাউজার / সিস্টেম PDF ভিউয়ার এ ওপেন হবে → সেখান থেকে save/ডাউনলোড করা যাবে
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start download.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Curriculum Vitae',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Download / Save',
            icon: const Icon(Icons.download),
            onPressed: () => _downloadPdf(context),
          ),
        ],
      ),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}