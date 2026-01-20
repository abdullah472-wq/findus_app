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
import 'package:findus_app/screens/ad_center/ad_center_screen.dart';
import 'package:findus_app/services/blocked_user_service.dart';
import 'driving_license_upload_screen.dart';
import 'package:findus_app/screens/settings/terms_conditions_screen.dart';

// নতুন: Analytics ও Community Standards এক্সটার্নাল পেজ
import 'package:findus_app/screens/ad_center/analytics_screen.dart';
import 'package:findus_app/screens/settings/theme_settings_screen.dart';
import 'community_standards_screen.dart';
import 'package:findus_app/services/user_service.dart';
import 'help_center_screen.dart';
import 'verification_screen.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final bool _isNotificationOn = true;
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
      body: Stack(
        children: [
          // Main Content (ListView)
          ListView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
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
                    MaterialPageRoute(builder: (_) => const _BlockListScreen()),
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

              // নতুন: Theme টাইল যোগ করুন
              // SettingsScreen-এ Theme টাইল:
              _buildSettingsTile(
                icon: Icons.color_lens_outlined,
                title: "Theme Settings",
                subtitle: "Advanced theme customization",
                onTap: () async {
                  final userId = await UserService.getCurrentUserId();
                  final isPremium = await UserService.isPremiumUser();
                  final subscriptionType = await UserService.getSubscriptionType();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ThemeSettingsScreen(
                        workerKey: userId,
                        isfree: !isPremium,
                        subscriptionType: subscriptionType,
                      ),
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
                      MaterialPageRoute(builder: (_) => const _DeleteAccountScreen()),
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

          // Floating AppBar
          _buildFloatingAppBar(context),
        ],
      ),
    );
  }

  Widget _buildFloatingAppBar(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Container(
        height: kToolbarHeight + MediaQuery.of(context).padding.top,
        decoration: BoxDecoration(
          color: AppColors.brandLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
            topRight: Radius.circular(20),
            topLeft: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    // Back Button
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.brandDark,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),

                    // Title
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: const Text(
                            "SETTINGS",
                            style: TextStyle(
                              color: AppColors.brandDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        )
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
        activeThumbColor: AppColors.brandMain,
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

// --------------------------------------------------------
// Block List Screen
// --------------------------------------------------------
class _BlockListScreen extends StatefulWidget {
  const _BlockListScreen();

  @override
  State<_BlockListScreen> createState() => __BlockListScreenState();
}

class __BlockListScreenState extends State<_BlockListScreen> {
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
      backgroundColor: AppColors.bgBlue,
      body: Stack(
        children: [
          // Main Content
          _isLoading
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
              : ListView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            children: [
              for (final item in _blockedUsers)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.block,
                      color: Colors.redAccent,
                    ),
                    title: Text(
                      item['name'] ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "ID: ${item['id'] ?? ''}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: TextButton(
                      onPressed: () => _unblockUser(item['id'] ?? '', item['name'] ?? ''),
                      child: const Text("UNBLOCK"),
                    ),
                  ),
                ),
            ],
          ),

          // Floating AppBar
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          // Back Button
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.brandDark,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),

                          // Title
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: const Text(
                                  "Blocked Users",
                                  style: TextStyle(
                                    color: AppColors.brandDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------
// Delete Account Screen
// --------------------------------------------------------
class _DeleteAccountScreen extends StatelessWidget {
  const _DeleteAccountScreen();

  void _confirmDelete(BuildContext context) {
    // TODO: Backend এ account delete API কল
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Account delete request sent."),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      body: Stack(
        children: [
          // Main Content
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Are you sure you want to delete your account?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "This action is permanent and cannot be undone. Your profile, history and data will be removed.",
                  style: TextStyle(height: 1.5),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _confirmDelete(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Text(
                      "YES, DELETE MY ACCOUNT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // Floating AppBar
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(
                color: AppColors.brandLight,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          // Back Button
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.brandDark,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),

                          // Title
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: const Text(
                                  "Delete Account",
                                  style: TextStyle(
                                    color: AppColors.brandDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}