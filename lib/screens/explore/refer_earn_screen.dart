import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:findus_app/services/referral_service.dart';
import 'package:findus_app/achievement/achievement_service.dart';

class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _downloadBaseUrl = "https://findus.app/download";

  final TextEditingController _enterCodeController = TextEditingController();

  bool _isLoading = true;
  String _referralCode = "";
  int _invited = 0;
  int _joined = 0;
  int _totalRewards = 0;
  int _pendingRewards = 0;
  bool _hasReferrer = false;
  String? _error;

  String get _referralLink => _referralCode.isNotEmpty ? "$_downloadBaseUrl?ref=$_referralCode" : "";

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  @override
  void dispose() {
    _enterCodeController.dispose();
    super.dispose();
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
      if (snap.exists) data = snap.data() as Map<String, dynamic>;

      String code = (data['referralCode'] ?? "") as String;

      if (code.trim().isEmpty) {
        code = _generateReferralCode(user.uid);
        await userDocRef.set({
          'referralCode': code,
          'referralInvitedCount': data['referralInvitedCount'] ?? 0,
          'referralJoinedCount': data['referralJoinedCount'] ?? 0,
          'referralTotalRewards': data['referralTotalRewards'] ?? 0,
          'referralPendingRewards': data['referralPendingRewards'] ?? 0,
          'referralLastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      setState(() {
        _referralCode = code;
        _invited = (data['referralInvitedCount'] ?? 0) is int ? (data['referralInvitedCount'] ?? 0) as int : (data['referralInvitedCount'] ?? 0 as num).toInt();
        _joined = (data['referralJoinedCount'] ?? 0) is int ? (data['referralJoinedCount'] ?? 0) as int : (data['referralJoinedCount'] ?? 0 as num).toInt();
        _totalRewards = (data['referralTotalRewards'] ?? 0) is int ? (data['referralTotalRewards'] ?? 0) as int : (data['referralTotalRewards'] ?? 0 as num).toInt();
        _pendingRewards = (data['referralPendingRewards'] ?? 0) is int ? (data['referralPendingRewards'] ?? 0) as int : (data['referralPendingRewards'] ?? 0 as num).toInt();

        _hasReferrer = data['referredBy'] != null && data['referredBy'].toString().isNotEmpty;

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

  String _generateReferralCode(String uid) {
    final short = uid.length >= 6 ? uid.substring(0, 6) : uid;
    return "FD${short.toUpperCase()}";
  }

  Future<void> _copyText(BuildContext context, String text, {String successMessage = "Copied to clipboard."}) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
  }

  Future<void> _applyCode() async {
    final code = _enterCodeController.text.trim();
    if (code.isEmpty) return;

    if (code == _referralCode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You cannot use your own code!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    await ReferralService.applyReferralCode(
        newUserId: _auth.currentUser!.uid,
        code: code
    );

    await _loadReferralData();

    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Referral code applied successfully!"), backgroundColor: Colors.green));
      setState(() => _isLoading = false);
    }
  }

  // 💰 Payout Request Logic (Minimum 100 BDT)
  Future<void> _requestPayout() async {
    if (_totalRewards < 100) {
      _showErrorDialog("You need minimum 100 BDT to withdraw. Keep inviting!");
      return;
    }

    try {
      setState(() => _isLoading = true);
      final uid = _auth.currentUser!.uid;

      // ১. রিকোয়েস্ট তৈরি করা
      await _db.collection('payout_requests').add({
        'userId': uid,
        'amount': _totalRewards,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'method': 'Manual Review',
      });

      setState(() => _isLoading = false);
      _showSuccessDialog("Payout request sent! We will review and transfer the amount shortly.");
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog("Failed to send request. Try again later.");
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Notice"),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ),
    );
  }

  void _showSuccessDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Success"),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("GREAT"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.black87;

    final qrUrl = _referralCode.isNotEmpty ? "https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=$_referralLink" : null;

    return FloatingScaffold(
      title: "REFER & EARN",
      backgroundColor: bgColor,
      titleColor: textColor,
      iconColor: textColor,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandMain))
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_hasReferrer)
            _buildEnterCodeCard(context, cardColor, textColor, isDark),

          if (!_hasReferrer)
            const SizedBox(height: 16),

          _buildHeaderCard(context, cardColor, textColor, subTextColor),
          const SizedBox(height: 16),

          // 🔥 Stats & Withdraw Button
          _buildStatsCard(isDark),

          const SizedBox(height: 16),
          _buildReferralCodeCard(context, cardColor, textColor, subTextColor, isDark),
          const SizedBox(height: 16),
          _buildShareActionsRow(context, textColor),
          const SizedBox(height: 16),
          if (qrUrl != null) _buildQrShareCard(context, qrUrl, cardColor, textColor, subTextColor),
          const SizedBox(height: 20),
          _buildHowItWorksSection(cardColor, textColor, subTextColor),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // ✅ New Widget: Enter Code Card
  Widget _buildEnterCodeCard(BuildContext context, Color cardColor, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.brandMain.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism, color: AppColors.brandMain, size: 20),
              const SizedBox(width: 8),
              Text("Have a referral code?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _enterCodeController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "Enter code here",
                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _applyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                child: const Text("APPLY"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 6))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Invite friends, earn rewards", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 6),
          Text("Share FINDUS with your friends. Get ৳5 for every successful referral!", style: TextStyle(fontSize: 13, color: subTextColor, height: 1.4)),
        ],
      ),
    );
  }

  // 🔥 Stats & Withdraw Card
  Widget _buildStatsCard(bool isDark) {
    final canWithdraw = _totalRewards >= 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : AppColors.brandLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Your referral stats", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.brandDark)),
          const SizedBox(height: 10),
          Row(children: [_statItem("Invited", _invited.toString(), Icons.person_add_alt, isDark), _statItem("Joined", _joined.toString(), Icons.group_outlined, isDark)]),
          const SizedBox(height: 8),
          Row(children: [_statItem("Total Earned", "৳$_totalRewards", Icons.account_balance_wallet, isDark), _statItem("Pending", "৳$_pendingRewards", Icons.hourglass_bottom_outlined, isDark)]),

          const SizedBox(height: 16),

          // 💸 Withdraw Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _requestPayout,
              style: ElevatedButton.styleFrom(
                backgroundColor: canWithdraw ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: canWithdraw ? 2 : 0,
              ),
              icon: const Icon(Icons.money),
              label: const Text("REQUEST PAYOUT", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),

          if (!canWithdraw)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  "Reach ৳100 to withdraw",
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.brandDark;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.white, shape: BoxShape.circle, border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300)),
              child: Icon(icon, size: 18, color: textColor),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey : Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCodeCard(BuildContext context, Color cardColor, Color textColor, Color subTextColor, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Your referral code", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: isDark ? Colors.black26 : AppColors.bgBlue, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300)),
                  child: Text(_referralCode.isNotEmpty ? _referralCode : "Generating...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2, color: textColor)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _referralCode.isEmpty ? null : () => _copyText(context, _referralCode, successMessage: "Referral code copied."), icon: const Icon(Icons.copy, color: AppColors.brandMain), tooltip: "Copy code"),
            ],
          ),
          const SizedBox(height: 12),
          Text("Referral link", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: isDark ? Colors.black26 : Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300)),
            child: Row(
              children: [
                const Icon(Icons.link, size: 18, color: AppColors.brandMain),
                const SizedBox(width: 6),
                Expanded(child: Text(_referralLink.isNotEmpty ? _referralLink : "Link will appear here", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor))),
                const SizedBox(width: 6),
                TextButton(onPressed: _referralLink.isEmpty ? null : () => _copyText(context, _referralLink, successMessage: "Link copied."), child: const Text("COPY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.brandMain))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareActionsRow(BuildContext context, Color textColor) {
    // ✅ রিয়েল শেয়ার ফাংশন (Quest Update সহ)
    Future<void> shareLink(String platformName) async {
      if (_referralLink.isEmpty) return;

      final String message = "Join FindUs using my referral code: $_referralCode\nDownload now: $_referralLink";

      // 1. Share UI Open
      await Share.share(message);

      // ==================================================
      // ✅ REFERRAL QUEST UPDATE
      // ==================================================
      // 1. Long Term Invite Chain
      await AchievementService.incrementProgress('lt_invite_s1');
      await AchievementService.incrementProgress('lt_invite_s2');
      await AchievementService.incrementProgress('lt_invite_s3');

      // 2. Daily Share
      await AchievementService.incrementProgress('daily_share');

      // 3. Sync
      await AchievementService.syncWeeklyChestFromServer();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Shared via $platformName! Quest updated.")),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick share", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _shareIconButton(icon: Icons.chat, label: "WhatsApp", onTap: () => shareLink("WhatsApp"), textColor: textColor),
            _shareIconButton(icon: Icons.facebook, label: "Facebook", onTap: () => shareLink("Facebook"), textColor: textColor),
            _shareIconButton(icon: Icons.message_outlined, label: "SMS", onTap: () => shareLink("SMS"), textColor: textColor),
            _shareIconButton(icon: Icons.share, label: "More", onTap: () => shareLink("Other Apps"), textColor: textColor),
          ],
        ),
      ],
    );
  }

  Widget _shareIconButton({required IconData icon, required String label, required VoidCallback onTap, required Color textColor}) {
    return Column(children: [
      GestureDetector(onTap: onTap, child: Container(width: 48, height: 48, decoration: BoxDecoration(color: textColor == Colors.white ? Colors.grey.shade800 : Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3))]), child: Icon(icon, color: textColor, size: 22))),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 11, color: textColor)),
    ]);
  }

  Widget _buildQrShareCard(BuildContext context, String qrUrl, Color cardColor, Color textColor, Color subTextColor) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 6))]), child: Column(children: [
      Text("Share with QR code", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
      const SizedBox(height: 6),
      Text("Your friends can scan this QR code to download FINDUS with your referral.", style: TextStyle(fontSize: 12, color: subTextColor), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Container(height: 200, width: 200, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(qrUrl), fit: BoxFit.cover))),
    ]));
  }

  Widget _buildHowItWorksSection(Color cardColor, Color textColor, Color subTextColor) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 5))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("How it works", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
      const SizedBox(height: 8),
      _HowItWorksItem(step: "1", text: "Share your referral link or QR code with your friends.", color: subTextColor),
      _HowItWorksItem(step: "2", text: "They sign up using your link or code.", color: subTextColor),
      _HowItWorksItem(step: "3", text: "When they complete their first job, you get ৳5 reward!", color: subTextColor),
    ]));
  }
}

class _HowItWorksItem extends StatelessWidget {
  final String step;
  final String text;
  final Color color;
  const _HowItWorksItem({required this.step, required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(radius: 10, backgroundColor: AppColors.brandMain, child: Text(step, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))), const SizedBox(width: 8), Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color)))]));
  }
}