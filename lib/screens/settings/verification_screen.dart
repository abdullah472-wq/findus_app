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
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _status = KycStatus.notSubmitted;
        _rejectionReason = null;
      });
    } finally {
      if (mounted) setState(() => _isLoadingStatus = false);
    }
  }

  Future<void> _openKycUpload() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const KycUploadScreen()));
    _loadKycStatus();
  }

  Future<void> _openDrivingLicenseUpload() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const DrivingLicenseUploadScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ডার্ক মোড চেক
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;

    return FloatingScaffold(
      title: 'VERIFICATION',
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: false,
      bodyPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "KYC Verification",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Verify your identity to get a verified badge and build more trust.",
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.black54,
                height: 1.4,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            _isLoadingStatus
                ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandMain)))
                : _buildStatusCard(isDark),

            const SizedBox(height: 24),

            _buildActionTile(
              icon: Icons.photo_camera_front,
              title: _status == KycStatus.approved ? "You are already verified" : "Start KYC Verification",
              subtitle: _status == KycStatus.approved ? "Your documents are verified" : "Capture and upload your KYC documents",
              onTap: _status == KycStatus.approved ? null : _openKycUpload,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
            ),

            const SizedBox(height: 12),

            _buildActionTile(
              icon: Icons.badge_outlined,
              title: "Upload Driving License",
              subtitle: "Add your driving license as extra proof.",
              onTap: _openDrivingLicenseUpload,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    late Color bgColor;
    late Color textColor;
    late IconData icon;
    late String title;
    String? subtitle;

    switch (_status) {
      case KycStatus.notSubmitted:
        bgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;
        textColor = isDark ? Colors.white70 : Colors.grey.shade800;
        icon = Icons.hourglass_empty;
        title = "KYC not submitted";
        subtitle = "Please submit your documents to get verified.";
        break;
      case KycStatus.pending:
        bgColor = isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.shade50;
        textColor = Colors.orange;
        icon = Icons.access_time;
        title = "KYC under review";
        subtitle = "Our team is reviewing your documents.";
        break;
      case KycStatus.approved:
        bgColor = isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50;
        textColor = Colors.green;
        icon = Icons.verified_rounded;
        title = "KYC approved";
        subtitle = "You are now a verified FINDUS user.";
        break;
      case KycStatus.rejected:
        bgColor = isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50;
        textColor = Colors.redAccent;
        icon = Icons.error_outline_rounded;
        title = "KYC rejected";
        subtitle = _rejectionReason ?? "Your documents were not accepted. Please resubmit.";
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
                Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle!, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.brandMain),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
      onTap: onTap,
      tileColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.grey.withOpacity(0.1) : Colors.grey.shade200),
      ),
    );
  }
}