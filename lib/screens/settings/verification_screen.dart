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

class _VerificationScreenState extends State<VerificationScreen>
    with SingleTickerProviderStateMixin {
  KycStatus _status = KycStatus.notSubmitted;
  bool _isLoadingStatus = true;
  String? _rejectionReason;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadKycStatus();
  }

  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadKycStatus() async {
    setState(() => _isLoadingStatus = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

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
      if (mounted) {
        setState(() => _isLoadingStatus = false);
        _animController.forward();
      }
    }
  }

  KycStatus _parseKycStatus(String status) {
    switch (status) {
      case 'pending':
        return KycStatus.pending;
      case 'approved':
        return KycStatus.approved;
      case 'rejected':
        return KycStatus.rejected;
      default:
        return KycStatus.notSubmitted;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final textColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: 'Verification',
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: false,
      bodyPadding: EdgeInsets.zero,
      body: _isLoadingStatus
          ? _buildLoadingState(isDark)
          : FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _VerificationContent(
            isDark: isDark,
            status: _status,
            rejectionReason: _rejectionReason,
            onKycUpload: _openKycUpload,
            onDrivingLicenseUpload: _openDrivingLicenseUpload,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.brandMain.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: AppColors.brandMain,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Loading verification status...",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationContent extends StatelessWidget {
  final bool isDark;
  final KycStatus status;
  final String? rejectionReason;
  final VoidCallback onKycUpload;
  final VoidCallback onDrivingLicenseUpload;

  const _VerificationContent({
    required this.isDark,
    required this.status,
    required this.rejectionReason,
    required this.onKycUpload,
    required this.onDrivingLicenseUpload,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 Status Card
          _buildStatusCard(textColor, cardBg, subtitleColor),

          const SizedBox(height: 24),

          // 📊 Progress Indicator
          _buildProgressSection(textColor, cardBg),

          const SizedBox(height: 24),

          // ✅ Verified Badge (if approved)
          if (status == KycStatus.approved) ...[
            _buildVerifiedBadge(),
            const SizedBox(height: 20),
          ],

          // 📝 Actions Section
          _buildActionsSection(textColor, cardBg, subtitleColor),

          const SizedBox(height: 24),

          // ℹ️ Info Section
          _buildInfoSection(textColor, cardBg),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 🎯 Status Card
  Widget _buildStatusCard(Color textColor, Color cardBg, Color subtitleColor) {
    final statusData = _getStatusData();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusData.color.withOpacity(isDark ? 0.2 : 0.1),
            statusData.color.withOpacity(isDark ? 0.1 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusData.color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusData.color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with icon
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Animated Icon Container
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: statusData.color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusData.color.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      statusData.icon,
                      color: statusData.color,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  statusData.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: statusData.color,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black26
                        : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusData.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withOpacity(0.8),
                      height: 1.5,
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

  // 📊 Progress Section
  Widget _buildProgressSection(Color textColor, Color cardBg) {
    final steps = [
      _ProgressStep(
        title: "Account Created",
        isCompleted: true,
        icon: Icons.person_add_rounded,
      ),
      _ProgressStep(
        title: "Documents Uploaded",
        isCompleted: status != KycStatus.notSubmitted,
        icon: Icons.upload_file_rounded,
      ),
      _ProgressStep(
        title: "Under Review",
        isCompleted: status == KycStatus.approved,
        isActive: status == KycStatus.pending,
        icon: Icons.hourglass_top_rounded,
      ),
      _ProgressStep(
        title: "Verified",
        isCompleted: status == KycStatus.approved,
        icon: Icons.verified_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline_rounded,
                color: AppColors.brandMain,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                "Verification Progress",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isLast = index == steps.length - 1;
            return _buildProgressStep(step, isLast, textColor);
          }),
        ],
      ),
    );
  }

  Widget _buildProgressStep(_ProgressStep step, bool isLast, Color textColor) {
    Color stepColor;
    if (step.isCompleted) {
      stepColor = Colors.green;
    } else if (step.isActive) {
      stepColor = Colors.orange;
    } else {
      stepColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: stepColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: stepColor, width: 2),
              ),
              child: Icon(
                step.isCompleted
                    ? Icons.check_rounded
                    : step.isActive
                    ? Icons.more_horiz_rounded
                    : step.icon,
                color: stepColor,
                size: 18,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [stepColor, stepColor.withOpacity(0.3)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                    step.isCompleted || step.isActive ? FontWeight.w600 : FontWeight.normal,
                    color: step.isCompleted || step.isActive
                        ? textColor
                        : textColor.withOpacity(0.5),
                  ),
                ),
                if (step.isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "In progress...",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ✅ Verified Badge
  Widget _buildVerifiedBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade500, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Trusted Member",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "VERIFIED",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "You have full access to all features",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📝 Actions Section
  Widget _buildActionsSection(
      Color textColor, Color cardBg, Color subtitleColor) {
    final showKycUpload =
        status == KycStatus.notSubmitted || status == KycStatus.rejected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.touch_app_rounded,
              color: AppColors.brandMain,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              showKycUpload ? "Required Actions" : "Additional Options",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // KYC Upload Button
        if (showKycUpload)
          _buildActionCard(
            icon: Icons.upload_file_rounded,
            title: status == KycStatus.rejected
                ? "Re-upload KYC Documents"
                : "Upload KYC Documents",
            subtitle: "NID / Passport / Birth Certificate",
            onTap: onKycUpload,
            cardBg: cardBg,
            textColor: textColor,
            isPrimary: true,
            badgeText: status == KycStatus.rejected ? "RETRY" : "REQUIRED",
            badgeColor:
            status == KycStatus.rejected ? Colors.orange : Colors.blue,
          ),

        if (showKycUpload) const SizedBox(height: 12),

        // Driving License Button
        _buildActionCard(
          icon: Icons.drive_eta_rounded,
          title: "Upload Driving License",
          subtitle: "Optional - For additional verification",
          onTap: onDrivingLicenseUpload,
          cardBg: cardBg,
          textColor: textColor,
          isPrimary: false,
          badgeText: "OPTIONAL",
          badgeColor: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color cardBg,
    required Color textColor,
    required bool isPrimary,
    String? badgeText,
    Color? badgeColor,
  }) {
    final accentColor = isPrimary ? AppColors.brandMain : Colors.grey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPrimary
                  ? AppColors.brandMain.withOpacity(0.4)
                  : (isDark ? Colors.white10 : Colors.grey.shade200),
              width: isPrimary ? 2 : 1,
            ),
            boxShadow: isPrimary
                ? [
              BoxShadow(
                color: AppColors.brandMain.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: isPrimary
                      ? LinearGradient(
                    colors: [
                      AppColors.brandMain.withOpacity(0.15),
                      AppColors.brandMain.withOpacity(0.05),
                    ],
                  )
                      : null,
                  color: isPrimary
                      ? null
                      : (isDark ? Colors.white10 : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isPrimary
                      ? AppColors.brandMain
                      : (isDark ? Colors.white70 : Colors.grey.shade600),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (badgeText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor?.withOpacity(0.15) ??
                                  Colors.grey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeColor ?? Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: accentColor.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ℹ️ Info Section
  Widget _buildInfoSection(Color textColor, Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.blue.withOpacity(0.1)
            : Colors.blue.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Colors.blue.shade400,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Why verify?",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Verified users get more job opportunities, higher trust badges, and priority support.",
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📊 Status Data Helper
  _StatusData _getStatusData() {
    switch (status) {
      case KycStatus.notSubmitted:
        return _StatusData(
          icon: Icons.upload_file_rounded,
          title: "Not Submitted",
          description:
          "Please upload your documents to verify your identity and unlock all features.",
          color: Colors.grey,
        );
      case KycStatus.pending:
        return _StatusData(
          icon: Icons.hourglass_top_rounded,
          title: "Under Review",
          description:
          "Your documents are being reviewed. This usually takes 24-48 hours.",
          color: Colors.orange,
        );
      case KycStatus.approved:
        return _StatusData(
          icon: Icons.check_circle_rounded,
          title: "Verified",
          description:
          "Congratulations! Your identity has been successfully verified.",
          color: Colors.green,
        );
      case KycStatus.rejected:
        return _StatusData(
          icon: Icons.error_outline_rounded,
          title: "Rejected",
          description: rejectionReason ??
              "Your documents were not clear or valid. Please upload again.",
          color: Colors.red,
        );
    }
  }
}

class _StatusData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _StatusData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _ProgressStep {
  final String title;
  final bool isCompleted;
  final bool isActive;
  final IconData icon;

  _ProgressStep({
    required this.title,
    required this.isCompleted,
    this.isActive = false,
    required this.icon,
  });
}