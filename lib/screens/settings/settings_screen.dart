import 'package:findus_app/screens/settings/notification_control_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'subscription_screen.dart';
import 'kyc_screen.dart';
import 'privacy_policy_screen.dart';
import 'about_app_screen.dart';
import 'faq_screen.dart';
import 'language_settings_screen.dart';
import 'package:findus_app/screens/ad%20center/ad_center_screen.dart';
import 'package:findus_app/services/blocked_user_service.dart';
import 'driving_license_upload_screen.dart';
import 'package:findus_app/screens/settings/terms_conditions_screen.dart';

// নতুন: Analytics ও Community Standards এক্সটার্নাল পেজ
import 'package:findus_app/screens/ad%20center/analytics_screen.dart';
import 'community_standards_screen.dart';

// নিচের সব স্ক্রিন এই একই ফাইলে রাখছি; চাইলে আলাদা ফাইলে ভাগ করে নিতে পারো

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotificationOn = true;
  bool _isLocationEnabled = true;

  // Location setting persist করার key
  static const String _prefsLocationKey = 'settings_location_enabled';

  @override
  void initState() {
    super.initState();
    _loadLocationSetting();
  }

  Future<void> _loadLocationSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_prefsLocationKey);
      if (!mounted) return;
      if (saved != null) {
        setState(() {
          _isLocationEnabled = saved;
        });
      }
    } catch (_) {
      // ignore; default true থাকবে
    }
  }

  Future<void> _updateLocationSetting(bool enabled) async {

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsLocationKey, enabled);
    } catch (_) {
      // ignore storage error
    }
    if (!mounted) return;
    setState(() {
      _isLocationEnabled = enabled;
    });

    // TODO: এখানে প্রকৃত location permission / service enable/disable integrate করবে
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        backgroundColor: AppColors.brandLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon:
          const Icon(Icons.arrow_back_ios_new, color: AppColors.brandDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "SETTINGS",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- ১. অ্যাকাউন্ট ও সিকিউরিটি ---
          _buildSectionTitle("ACCOUNT & SECURITY"),

          _buildSettingsTile(
            icon: Icons.verified_user,
            title: "Verification",
            subtitle: "Get verified badge & features",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VerificationScreen()),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.block,
            title: "Block List",
            subtitle: "Manage blocked users",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlockListScreen()),
              );
            },
          ),

          const SizedBox(height: 25),

          // --- SUBSCRIPTION / PRO PLANS ---
          _buildSectionTitle("SUBSCRIPTION"),

          _buildSettingsTile(
            icon: Icons.workspace_premium_outlined,
            title: "Subscription & Plans",
            subtitle: "Upgrade to FINDUS Pro / Business",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
            },
          ),

          _buildSectionTitle("GROW & PROMOTE"),

          _buildSettingsTile(
            icon: Icons.campaign_outlined,
            title: "Ad Center",
            subtitle: "Boost profile & job visibility",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdCenterScreen()),
              );
            },
          ),

          // ✅ Analytics বাটন (external analytics_screen.dart)
          _buildSettingsTile(
            icon: Icons.analytics_outlined,
            title: "Analytics",
            subtitle: "View performance & insights",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AnalyticsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 25),

          // --- ২. জেনারেল সেটিংস ---
          _buildSectionTitle("GENERAL"),

          _buildSettingsTile(
            icon: Icons.analytics_outlined,
            title: "Notification",
            subtitle: "Control what you want",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationControlPage(),
                ),
              );
            },
          ),

          _buildSwitchTile(
            icon: Icons.location_on_outlined,
            title: "Location Services",
            subtitle: "Allow app to track location",
            value: _isLocationEnabled,
            onChanged: (val) => _updateLocationSetting(val),
          ),

          _buildSettingsTile(
            icon: Icons.language,
            title: "Language",
            subtitle: "English (US)",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LanguageSettingsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 25),

          // --- ৩. সাপোর্ট ও অন্যান্য ---
          _buildSectionTitle("SUPPORT & MORE"),

          _buildSettingsTile(
            icon: Icons.headset_mic_outlined,
            title: "Help Center",
            subtitle: "Chat with support team",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.policy_outlined,
            title: "Privacy Policy",
            subtitle: "Terms and conditions",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),

          // 🔹 Community Standards – নতুন বাটন
          _buildSettingsTile(
            icon: Icons.rule_folder_outlined,
            title: "Community Standards",
            subtitle: "Guidelines for safe usage",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CommunityStandardsScreen(),
                ),
              );
            },
          ),

          _buildSettingsTile(
            icon: Icons.article_outlined,
            title: "Terms & Conditions",
            subtitle: "Guidelines for safe usage",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TermsAndConditionsScreen(),
                ),
              );
            },
          ),


          _buildSettingsTile(
            icon: Icons.info_outline,
            title: "About App",
            subtitle: "Version 1.0.0",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutAppScreen()),
              );
            },
          ),

          const SizedBox(height: 30),

          // --- ৪. ডিলিট অ্যাকাউন্ট (ডেঞ্জার জোন) ---
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DeleteAccountScreen()),
                );
              },
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text(
                "Delete My Account",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- হেল্পার উইজেটস ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.brandMain,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: _buildIconBox(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.brandDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: SwitchListTile(
        value: value,
        activeColor: AppColors.brandMain,
        onChanged: onChanged,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        secondary: _buildIconBox(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.brandDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.brandLight.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.brandDark, size: 22),
    );
  }
}

/// --------------------------------------------------------
/// Verification Screen (with KYC Status)
/// --------------------------------------------------------

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
      MaterialPageRoute(
        builder: (_) => const KycUploadScreen(),
      ),
    );
    _loadKycStatus();
  }

  Future<void> _openDrivingLicenseUpload() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DrivingLicenseUploadScreen(),
      ),
    );
    // চাইলে এখানেও কোনো status refresh করতে পারো
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Verification",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.brandLight,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
        elevation: 0,
      ),
      backgroundColor: AppColors.bgBlue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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

            // KYC upload tile
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
              onTap:
              _status == KycStatus.approved ? null : _openKycUpload,
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
            ),

            const SizedBox(height: 12),

            // Driving License upload tile (optional)
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
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------
// Privacy & Locking Screen
// --------------------------------------------------------
class PrivacyLockingScreen extends StatefulWidget {
  const PrivacyLockingScreen({super.key});

  @override
  State<PrivacyLockingScreen> createState() =>
      _PrivacyLockingScreenState();
}

class _PrivacyLockingScreenState
    extends State<PrivacyLockingScreen> {
  bool _showProfilePublic = true;
  bool _showPhoneNumber = false;
  bool _enableAppLock = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy & Locking"),
        backgroundColor: AppColors.brandLight,
        iconTheme:
        const IconThemeData(color: AppColors.brandDark),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            title: const Text("Public Profile"),
            subtitle:
            const Text("Show your profile to everyone"),
            value: _showProfilePublic,
            activeColor: AppColors.brandMain,
            onChanged: (v) =>
                setState(() => _showProfilePublic = v),
          ),
          SwitchListTile(
            title: const Text("Show Phone Number"),
            subtitle: const Text(
              "Visible to hired/connected users",
            ),
            value: _showPhoneNumber,
            activeColor: AppColors.brandMain,
            onChanged: (v) =>
                setState(() => _showPhoneNumber = v),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("App Lock (PIN)"),
            subtitle: const Text("Require PIN to open app"),
            value: _enableAppLock,
            activeColor: AppColors.brandMain,
            onChanged: (v) =>
                setState(() => _enableAppLock = v),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------
// Change Password Screen
// --------------------------------------------------------
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleChangePassword(BuildContext context) {
    if (_newController.text !=
        _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "New passwords do not match."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    // TODO: API call করে password change করো
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
        Text("Password changed successfully (demo)."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: AppColors.brandLight,
        iconTheme:
        const IconThemeData(color: AppColors.brandDark),
      ),
      body: Padding(
        padding:
        const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPasswordField(
              label: "Current Password",
              controller: _currentController,
              obscure: _obscureCurrent,
              toggle: () => setState(() =>
              _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 15),
            _buildPasswordField(
              label: "New Password",
              controller: _newController,
              obscure: _obscureNew,
              toggle: () =>
                  setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 15),
            _buildPasswordField(
              label: "Confirm New Password",
              controller: _confirmController,
              obscure: _obscureConfirm,
              toggle: () => setState(
                      () => _obscureConfirm = !_obscureConfirm),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () =>
                    _handleChangePassword(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  AppColors.brandMain,
                ),
                child: const Text(
                  "UPDATE PASSWORD",
                  style: TextStyle(
                    fontWeight:
                    FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// --------------------------------------------------------
// Block List Screen (map ভিত্তিক BlockedUserService দিয়ে)
// --------------------------------------------------------
class BlockListScreen extends StatefulWidget {
  const BlockListScreen({super.key});

  @override
  State<BlockListScreen> createState() =>
      _BlockListScreenState();
}

class _BlockListScreenState extends State<BlockListScreen> {
  List<Map<String, String>> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    final users = await BlockedUserService().getBlockedUsers();
    if (!mounted) return;
    setState(() {
      _blockedUsers = users;
      _isLoading = false;
    });
  }

  Future<void> _unblockUser(String id, String name) async {
    await BlockedUserService().unblockUser(id);
    await _loadBlockedUsers();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$name has been unblocked."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text("Blocked Users"),
        backgroundColor: AppColors.brandLight,
        iconTheme:
        const IconThemeData(color: AppColors.brandDark),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppColors.brandMain,
        ),
      )
          : _blockedUsers.isEmpty
          ? const Center(
        child: Text(
          "No blocked users.",
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _blockedUsers.length,
        itemBuilder: (context, index) {
          final item = _blockedUsers[index];
          final id = item['id'] ?? '';
          final name = (item['name'] ?? '').isEmpty
              ? "User ($id)"
              : item['name']!;

          return ListTile(
            leading: const Icon(
              Icons.block,
              color: Colors.redAccent,
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "ID: $id",
              style:
              const TextStyle(fontSize: 12),
            ),
            trailing: TextButton(
              onPressed: () =>
                  _unblockUser(id, name),
              child: const Text("UNBLOCK"),
            ),
          );
        },
      ),
    );
  }
}


// --------------------------------------------------------
// Help Center Screen
// --------------------------------------------------------
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text(
          "Help Center",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight:
            FontWeight.bold,
          ),
        ),
        backgroundColor:
        AppColors.brandLight,
        iconTheme: const IconThemeData(
            color: AppColors.brandDark),
        elevation: 0,
      ),
      body: ListView(
        padding:
        const EdgeInsets.all(20),
        children: [
          const Text(
            "How can we help you?",
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(
              Icons
                  .question_answer_outlined,
              color: AppColors.brandDark,
            ),
            title: const Text("FAQ"),
            subtitle: const Text(
                "Common questions and answers"),
            trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const FaqScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat,
                color: AppColors.brandMain),
            title:
            const Text("Chat with Support"),
            subtitle: const Text(
                "Get help from our team"),
            trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const SupportChatScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
                Icons.email_outlined,
                color: AppColors.brandDark),
            title:
            const Text("Email Support"),
            subtitle: const Text(
                "support@findus.app"),
            trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const EmailSupportScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

//===================================================
// Support screen
//===================================================

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() =>
      _SupportChatScreenState();
}

class _SupportChatScreenState
    extends State<SupportChatScreen> {
  final TextEditingController _msgController =
  TextEditingController();
  final List<Map<String, dynamic>>
  _messages = [
    {
      "isMe": false,
      "text":
      "Hi! How can we help you today?",
      "time": "10:30 AM",
    },
  ];

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        "isMe": true,
        "text": text,
        "time": "Now",
      });
      _msgController.clear();
    });

    // TODO: backend এ integrate করবে
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text(
          "Support Chat",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight:
            FontWeight.bold,
          ),
        ),
        backgroundColor:
        AppColors.brandLight,
        iconTheme: const IconThemeData(
            color: AppColors.brandDark),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding:
              const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg =
                _messages[index];
                final bool isMe =
                msg["isMe"] as bool;
                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin:
                    const EdgeInsets.symmetric(
                        vertical: 4),
                    padding:
                    const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8),
                    decoration:
                    BoxDecoration(
                      color: isMe
                          ? AppColors.brandDark
                          : Colors.white,
                      borderRadius:
                      BorderRadius.circular(
                          10),
                    ),
                    child: Text(
                      msg["text"] as String,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white
                            : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:
                    _msgController,
                    decoration:
                    const InputDecoration(
                      hintText:
                      "Type your message...",
                      border:
                      InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color:
                    AppColors.brandMain,
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

//===================================================
// Email support
//===================================================

class EmailSupportScreen extends StatefulWidget {
  const EmailSupportScreen({super.key});

  @override
  State<EmailSupportScreen> createState() =>
      _EmailSupportScreenState();
}

class _EmailSupportScreenState
    extends State<EmailSupportScreen> {
  final TextEditingController
  _subjectController =
  TextEditingController();
  final TextEditingController
  _messageController =
  TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendEmail() {
    final subject =
    _subjectController.text.trim();
    final msg =
    _messageController.text.trim();

    if (subject.isEmpty || msg.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
              "Please enter subject and message."),
          backgroundColor:
          Colors.redAccent,
        ),
      );
      return;
    }

    // TODO: backend API
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
            "Support email sent."),
        backgroundColor:
        AppColors.brandMain,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text(
          "Email Support",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight:
            FontWeight.bold,
          ),
        ),
        backgroundColor:
        AppColors.brandLight,
        iconTheme:
        const IconThemeData(
            color:
            AppColors.brandDark),
        elevation: 0,
      ),
      body: Padding(
        padding:
        const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller:
              _subjectController,
              decoration:
              InputDecoration(
                labelText: "Subject",
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                      10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: TextField(
                controller:
                _messageController,
                maxLines: null,
                expands: true,
                decoration:
                InputDecoration(
                  labelText: "Message",
                  alignLabelWithHint:
                  true,
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                        10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: _sendEmail,
                style: ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  AppColors.brandMain,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                        10),
                  ),
                ),
                child: const Text(
                  "SEND",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}


// --------------------------------------------------------
// Delete Account Screen
// --------------------------------------------------------
class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});

  void _confirmDelete(BuildContext context) {
    // TODO: Backend এ account delete API কল
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
            "Account delete request sent."),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text("Delete Account"),
        backgroundColor:
        AppColors.brandLight,
        iconTheme:
        const IconThemeData(
            color:
            AppColors.brandDark),
      ),
      body: Padding(
        padding:
        const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              "Are you sure you want to delete your account?",
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              "This action is permanent and cannot be undone. Your profile, history and data will be removed.",
              style: TextStyle(
                  height: 1.5),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () =>
                    _confirmDelete(
                        context),
                style: ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  Colors.redAccent,
                ),
                child: const Text(
                  "YES, DELETE MY ACCOUNT",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}