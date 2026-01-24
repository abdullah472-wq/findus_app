import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';

import 'kyc_screen.dart';
import 'driving_license_upload_screen.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

enum KycStatus { notSubmitted, pending, approved, rejected }

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  KycStatus _status = KycStatus.notSubmitted;
  bool _isLoadingStatus = true;
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    _loadKycStatus();
  }

  Future<void> _loadKycStatus() async {
    setState(() => _isLoadingStatus = true);

    try {
      // TODO: Backend থেকে আসল KYC status আনবে
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _status = KycStatus.notSubmitted;
        _rejectionReason = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingStatus = false);
      }
    }
  }

  Future<void> _openKycUpload() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KycUploadScreen()),
    );
    _loadKycStatus();
  }

  Future<void> _openDrivingLicenseUpload() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DrivingLicenseUploadScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingScaffold(
      title: 'Verification',
      backgroundColor: AppColors.bgBlue,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      showBack: true,
      scrollable: false, // নিজের ScrollView ব্যবহার করছি
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "KYC Verification",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Verify your identity to get a verified badge and build more trust.",
              style: TextStyle(
                color: Colors.black54,
                height: 1.4,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            _isLoadingStatus
                ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brandMain,
                ),
              ),
            )
                : _buildStatusCard(),

            const SizedBox(height: 24),

            ListTile(
              leading: const Icon(
                Icons.photo_camera_front,
                color: AppColors.brandMain,
              ),
              title: Text(
                _status == KycStatus.approved
                    ? "You are already verified"
                    : "Start KYC Verification",
              ),
              subtitle: Text(
                _status == KycStatus.approved
                    ? "Your documents are verified"
                    : "Capture and upload your KYC documents",
                style: const TextStyle(fontSize: 12),
              ),
              onTap: _status == KycStatus.approved ? null : _openKycUpload,
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
            ),

            const SizedBox(height: 12),

            ListTile(
              leading: const Icon(
                Icons.badge_outlined,
                color: AppColors.brandMain,
              ),
              title: const Text(
                "Upload Driving License",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                "Add your driving license as extra proof.",
                style: TextStyle(fontSize: 12),
              ),
              onTap: _openDrivingLicenseUpload,
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    late Color bgColor;
    late Color textColor;
    late IconData icon;
    late String title;
    String? subtitle;

    switch (_status) {
      case KycStatus.notSubmitted:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        icon = Icons.hourglass_empty;
        title = "KYC not submitted";
        subtitle = "Please submit your documents to get verified.";
        break;
      case KycStatus.pending:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        icon = Icons.access_time;
        title = "KYC under review";
        subtitle = "Our team is reviewing your documents.";
        break;
      case KycStatus.approved:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        icon = Icons.verified_rounded;
        title = "KYC approved";
        subtitle = "You are now a verified FINDUS user.";
        break;
      case KycStatus.rejected:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        icon = Icons.error_outline_rounded;
        title = "KYC rejected";
        subtitle = _rejectionReason ??
            "Your documents were not accepted. Please resubmit.";
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bgColor.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 12,
                    height: 1.3,
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