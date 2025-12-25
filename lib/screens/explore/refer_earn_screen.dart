import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen> {
  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Referral base URL
  static const String _downloadBaseUrl = "https://findus.app/download";

  // State
  bool _isLoading = true;
  String _referralCode = "";
  int _invited = 0;
  int _joined = 0;
  int _totalRewards = 0;
  int _pendingRewards = 0;
  String? _error;

  String get _referralLink =>
      _referralCode.isNotEmpty ? "$_downloadBaseUrl?ref=$_referralCode" : "";

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _error = "Please log in to see referral details.";
          _isLoading = false;
        });
        return;
      }

      final userDocRef = _db.collection('users').doc(user.uid);
      final snap = await userDocRef.get();

      Map<String, dynamic> data = {};
      if (snap.exists) {
        data = snap.data() as Map<String, dynamic>;
      }

      // Referral code না থাকলে নতুন করে বানিয়ে সেভ করব
      String code = (data['referralCode'] ?? "") as String;
      if (code.trim().isEmpty) {
        code = _generateReferralCode(user.uid);
        await userDocRef.set(
          {
            'referralCode': code,
            'referralInvitedCount': data['referralInvitedCount'] ?? 0,
            'referralJoinedCount': data['referralJoinedCount'] ?? 0,
            'referralTotalRewards': data['referralTotalRewards'] ?? 0,
            'referralPendingRewards': data['referralPendingRewards'] ?? 0,
            'referralLastUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      setState(() {
        _referralCode = code;
        _invited = (data['referralInvitedCount'] ?? 0) is int
            ? (data['referralInvitedCount'] ?? 0) as int
            : (data['referralInvitedCount'] ?? 0 as num).toInt();
        _joined = (data['referralJoinedCount'] ?? 0) is int
            ? (data['referralJoinedCount'] ?? 0) as int
            : (data['referralJoinedCount'] ?? 0 as num).toInt();
        _totalRewards = (data['referralTotalRewards'] ?? 0) is int
            ? (data['referralTotalRewards'] ?? 0) as int
            : (data['referralTotalRewards'] ?? 0 as num).toInt();
        _pendingRewards = (data['referralPendingRewards'] ?? 0) is int
            ? (data['referralPendingRewards'] ?? 0) as int
            : (data['referralPendingRewards'] ?? 0 as num).toInt();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Failed to load referral data.";
        _isLoading = false;
      });
    }
  }

  /// খুব simple একটা deterministic code generator (uid থেকে)
  String _generateReferralCode(String uid) {
    final short = uid.length >= 6 ? uid.substring(0, 6) : uid;
    return "FD${short.toUpperCase()}";
  }

  Future<void> _copyText(
      BuildContext context,
      String text, {
        String successMessage = "Copied to clipboard.",
      }) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl = _referralCode.isNotEmpty
        ? "https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=$_referralLink"
        : null;

    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        backgroundColor: AppColors.bgBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
        centerTitle: true,
        title: const Text(
          "Refer & Earn",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: AppColors.brandMain,
          ),
        )
            : _error != null
            ? Center(
          child: Text(
            _error!,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 14,
            ),
          ),
        )
            : SingleChildScrollView(
          padding:
          const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(context),
              const SizedBox(height: 16),
              _buildStatsCard(),
              const SizedBox(height: 16),
              _buildReferralCodeCard(context),
              const SizedBox(height: 16),
              _buildShareActionsRow(context),
              const SizedBox(height: 16),
              if (qrUrl != null)
                _buildQrShareCard(context, qrUrl),
              const SizedBox(height: 20),
              _buildHowItWorksSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Header Card ----------------

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Invite friends, earn rewards",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.brandDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Share FINDUS with your friends. When they join and start using the app, "
                "both of you can get rewards (demo).",
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Referral Stats ----------------

  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your referral stats",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statItem(
                "Invited",
                _invited.toString(),
                Icons.person_add_alt,
              ),
              _statItem(
                "Joined",
                _joined.toString(),
                Icons.group_outlined,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statItem(
                "Total rewards",
                "৳$_totalRewards",
                Icons.card_giftcard_outlined,
              ),
              _statItem(
                "Pending",
                "৳$_pendingRewards",
                Icons.hourglass_bottom_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(icon, size: 18, color: AppColors.brandDark),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Referral Code + Link ----------------

  Widget _buildReferralCodeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your referral code",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _referralCode.isNotEmpty ? _referralCode : "Generating...",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AppColors.brandDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _referralCode.isEmpty
                    ? null
                    : () => _copyText(
                  context,
                  _referralCode,
                  successMessage: "Referral code copied.",
                ),
                icon: const Icon(Icons.copy, color: AppColors.brandMain),
                tooltip: "Copy code",
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Referral link",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.link,
                    size: 18, color: AppColors.brandMain),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _referralLink.isNotEmpty
                        ? _referralLink
                        : "Referral link will appear here",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.brandDark,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: _referralLink.isEmpty
                      ? null
                      : () => _copyText(
                    context,
                    _referralLink,
                    successMessage: "Referral link copied.",
                  ),
                  child: const Text(
                    "COPY",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandMain,
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

  // ---------------- Quick Share Row ----------------

  Widget _buildShareActionsRow(BuildContext context) {
    void showComingSoon(String where) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Share to $where coming soon (demo)."),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick share",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.brandDark,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _shareIconButton(
              icon: Icons.chat,
              label: "WhatsApp",
              onTap: () => showComingSoon("WhatsApp"),
            ),
            _shareIconButton(
              icon: Icons.facebook,
              label: "Facebook",
              onTap: () => showComingSoon("Facebook"),
            ),
            _shareIconButton(
              icon: Icons.message_outlined,
              label: "SMS",
              onTap: () => showComingSoon("SMS"),
            ),
            _shareIconButton(
              icon: Icons.more_horiz,
              label: "More",
              onTap: () => showComingSoon("other apps"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _shareIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.brandDark, size: 22),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ---------------- QR Share Card ----------------

  Widget _buildQrShareCard(BuildContext context, String qrUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Share with QR code",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Your friends can scan this QR code to download FINDUS with your referral.",
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(qrUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- How it works ----------------

  Widget _buildHowItWorksSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "How it works (demo)",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          SizedBox(height: 8),
          _HowItWorksItem(
            step: "1",
            text: "Share your referral link or QR code with your friends.",
          ),
          _HowItWorksItem(
            step: "2",
            text: "They download FINDUS and sign up using your link.",
          ),
          _HowItWorksItem(
            step: "3",
            text:
            "When they complete their first job / hiring, both of you get rewards (coins or credits).",
          ),
        ],
      ),
    );
  }
}

class _HowItWorksItem extends StatelessWidget {
  final String step;
  final String text;

  const _HowItWorksItem({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.brandMain,
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}