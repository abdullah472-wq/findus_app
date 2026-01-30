import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final statusStr = data['kyc_status'] ?? 'not_submitted';
        final reason = data['kyc_rejection_reason'];

        setState(() {
          _status = _parseKycStatus(statusStr);
          _rejectionReason = reason;
        });
      }
    } catch (e) {
      debugPrint("Error loading KYC status: $e");
    } finally {
      if (mounted) setState(() => _isLoadingStatus = false);
    }
  }

  KycStatus _parseKycStatus(String status) {
    switch (status) {
      case 'pending': return KycStatus.pending;
      case 'approved': return KycStatus.approved;
      case 'rejected': return KycStatus.rejected;
      default: return KycStatus.notSubmitted;
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
      body: _isLoadingStatus
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandMain))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Status Section
            _buildStatusOverview(isDark, cardColor, textColor),

            const SizedBox(height: 30),

            // 2. Action Buttons
            if (_status != KycStatus.approved && _status != KycStatus.pending) ...[
              Text(
                "Required Actions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 12),
              _buildActionTile(
                icon: Icons.upload_file,
                title: _status == KycStatus.rejected ? "Re-upload KYC Documents" : "Upload KYC Documents",
                subtitle: "NID / Passport / Birth Certificate",
                onTap: _openKycUpload,
                isDark: isDark,
                cardColor: cardColor,
                textColor: textColor,
                isPrimary: true,
              ),
            ],

            if (_status == KycStatus.approved) ...[
              _buildVerifiedBadge(isDark),
            ],

            const SizedBox(height: 12),

            _buildActionTile(
              icon: Icons.drive_eta_rounded,
              title: "Upload Driving License",
              subtitle: "Optional for extra verification",
              onTap: _openDrivingLicenseUpload,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildStatusOverview(bool isDark, Color cardColor, Color textColor) {
    Color statusColor;
    String statusText;
    String description;
    IconData statusIcon;

    switch (_status) {
      case KycStatus.notSubmitted:
        statusColor = Colors.grey;
        statusText = "Not Submitted";
        description = "Please upload your documents to verify your identity.";
        statusIcon = Icons.info_outline;
        break;
      case KycStatus.pending:
        statusColor = Colors.orange;
        statusText = "Verification Pending";
        description = "Your documents are under review. This usually takes 24-48 hours.";
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case KycStatus.approved:
        statusColor = Colors.green;
        statusText = "Verified";
        description = "Congratulations! Your identity has been verified.";
        statusIcon = Icons.check_circle_rounded;
        break;
      case KycStatus.rejected:
        statusColor = Colors.red;
        statusText = "Verification Rejected";
        description = _rejectionReason ?? "Documents were not clear or valid. Please try again.";
        statusIcon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadge(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user, color: Colors.white, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Trusted Member",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "You have full access to all features.",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
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
    required bool isPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isPrimary
            ? Border.all(color: AppColors.brandMain.withOpacity(0.5), width: 1.5)
            : Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: isPrimary
            ? [BoxShadow(color: AppColors.brandMain.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.brandMain.withOpacity(0.1) : (isDark ? Colors.white10 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: isPrimary ? AppColors.brandMain : (isDark ? Colors.white70 : Colors.grey.shade700)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}