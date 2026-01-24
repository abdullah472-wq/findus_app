// lib/screens/settings/settings_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/services/user_service.dart';
import 'package:findus_app/services/blocked_user_service.dart';

// Screens
import '../auth/login_screen.dart';
import 'subscription_screen.dart';
import 'language_settings_screen.dart';
import 'notification_control_page.dart';
import 'theme_settings_screen.dart';
import 'help_center_screen.dart';
import 'verification_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';
import 'community_standards_screen.dart';
import 'about_app_screen.dart';
import 'package:findus_app/screens/ad_center/ad_center_screen.dart';
import 'package:findus_app/screens/ad_center/analytics_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLocationEnabled = true;
  static const String _prefsLocationKey = 'settings_location_enabled';

  @override
  void initState() {
    super.initState();
    _loadLocationSetting();
  }

  Future<void> _loadLocationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _isLocationEnabled = prefs.getBool(_prefsLocationKey) ?? true);
  }

  Future<void> _updateLocationSetting(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsLocationKey, enabled);
    setState(() => _isLocationEnabled = enabled);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FloatingScaffold(
      title: "SETTINGS",
      // ✅ ব্যাকগ্রাউন্ড কালার পরিবর্তন করা হয়েছে
      backgroundColor: AppColors.bgBlue,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ১. অ্যাকাউন্ট ও সিকিউরিটি ---
          _buildSectionHeader("ACCOUNT & SECURITY"),
          _buildSettingsGroup([
            _buildSettingsTile(Icons.verified_user_rounded, "Verification", "Identity & badges", () => _push(const VerificationScreen()), Colors.blueAccent),
            _buildSettingsTile(Icons.block_flipped, "Block List", "Manage blocked users", () => _push(const _BlockListScreen()), Colors.redAccent),
          ], isDark),

          // --- ২. সাবস্ক্রিপশন ও প্রমোশন ---
          _buildSectionHeader("GROW & PROMOTE"),
          _buildSettingsGroup([
            _buildSettingsTile(Icons.workspace_premium_rounded, "Subscription Plans", "Upgrade to Pro/Business", () => _push(const SubscriptionScreen()), Colors.amber),
            _buildSettingsTile(Icons.campaign_rounded, "Ad Center", "Boost profile & posts", () => _push(const AdCenterScreen()), Colors.green),
            _buildSettingsTile(Icons.analytics_rounded, "Analytics", "View your performance", () => _push(const AnalyticsScreen()), Colors.purpleAccent),
          ], isDark),

          // --- ৩. জেনারেল সেটিংস ---
          _buildSectionHeader("PREFERENCES"),
          _buildSettingsGroup([
            _buildSettingsTile(Icons.notifications_active_rounded, "Notifications", "Control alerts & sounds", () => _push(const NotificationControlPage()), Colors.orange),
            _buildSettingsTile(Icons.palette_rounded, "Theme Settings", "Custom colors & dark mode", () async {
              final userId = await UserService.getCurrentUserId();
              final isPremium = await UserService.isPremiumUser();
              final subscriptionType = await UserService.getSubscriptionType();
              _push(ThemeSettingsScreen(workerKey: userId, isfree: !isPremium, subscriptionType: subscriptionType));
            }, Colors.cyan),
            _buildSwitchTile(Icons.location_on_rounded, "Location Services", "Enable real-time tracking", _isLocationEnabled, _updateLocationSetting, Colors.teal),
            _buildSettingsTile(Icons.translate_rounded, "Language", "App display language", () => _push(const LanguageSettingsScreen()), Colors.indigoAccent),
          ], isDark),

          // --- ৪. সাপোর্ট ও লিগ্যাল (✅ এখানে সব আইকন রঙিন করা হয়েছে) ---
          _buildSectionHeader("SUPPORT & LEGAL"),
          _buildSettingsGroup([
            _buildSettingsTile(Icons.headset_mic_rounded, "Help Center", "Get support from experts", () => _push(const HelpCenterScreen()), Colors.pinkAccent),
            _buildSettingsTile(Icons.policy_rounded, "Privacy Policy", "Data usage & privacy", () => _push(const PrivacyPolicyScreen()), Colors.deepPurpleAccent),
            _buildSettingsTile(Icons.rule_folder_rounded, "Community Standards", "Safe usage guidelines", () => _push(const CommunityStandardsScreen()), Colors.deepOrangeAccent),
            _buildSettingsTile(Icons.description_rounded, "Terms & Conditions", "Rules of the platform", () => _push(const TermsAndConditionsScreen()), Colors.blueGrey),
            _buildSettingsTile(Icons.info_outline_rounded, "About FINDUS", "Version 1.0.0", () => _push(const AboutAppScreen()), Colors.lightBlue),
          ], isDark),

          const SizedBox(height: 30),

          // --- ৫. ডেঞ্জার জোন ---
          _buildDangerZone(isDark),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 0, 10),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildSettingsGroup(List<Widget> tiles, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        // ✅ হালকা শ্যাডো দেওয়া হয়েছে যাতে ব্যাকগ্রাউন্ডের সাথে মিশে না যায়
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5)
          )
        ],
      ),
      child: Column(children: tiles),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String sub, VoidCallback onTap, Color color) {
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      // ✅ এখানে আইকনের ব্যাকগ্রাউন্ড কালার এবং মেইন কালার সেট হচ্ছে
      leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), // হালকা ব্যাকগ্রাউন্ড
              shape: BoxShape.circle
          ),
          child: Icon(icon, color: color, size: 22)
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, String sub, bool value, Function(bool) onChanged, Color color) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle
          ),
          child: Icon(icon, color: color, size: 22)
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      activeThumbColor: AppColors.brandMain,
    );
  }

  Widget _buildDangerZone(bool isDark) {
    return InkWell(
      onTap: () => _push(const _DeleteAccountScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.1)),
        ),
        child: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 15),
            Text("Delete My Account", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            Spacer(),
            Icon(Icons.chevron_right_rounded, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

// --- ফিক্সড ব্লক লিস্ট স্ক্রিন ---
class _BlockListScreen extends StatelessWidget {
  const _BlockListScreen();

  @override
  Widget build(BuildContext context) {
    return FloatingScaffold(
      title: "BLOCKED USERS",
      backgroundColor: AppColors.bgBlue, // এখানেও ব্যাকগ্রাউন্ড চেঞ্জ করা হলো
      showBack: true,
      body: FutureBuilder<List<Map<String, String>>>(
        future: BlockedUserService().getBlockedUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!;
          if (users.isEmpty) return const Center(child: Text("No blocked users."));
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (ctx, i) => ListTile(
              title: Text(users[i]['name'] ?? 'User'),
              trailing: TextButton(onPressed: () {}, child: const Text("UNBLOCK")),
            ),
          );
        },
      ),
    );
  }
}

// --- ফিক্সড ডিলিট অ্যাকাউন্ট স্ক্রিন ---
class _DeleteAccountScreen extends StatefulWidget {
  const _DeleteAccountScreen();

  @override
  State<_DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<_DeleteAccountScreen> {
  bool _isDeleting = false;

  Future<void> _deleteAccount() async {
    // ১. কনফার্মেশন ডায়ালগ
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Final Confirmation"),
        content: const Text(
          "This action cannot be undone. Are you absolutely sure?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("DELETE NOW", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // ২. ফায়ারস্টোর থেকে ইউজারের ডাটা ডিলিট (অপশনাল, যদি চান)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // ৩. অথেন্টিকেশন থেকে ডিলিট
      await user.delete();

      if (!mounted) return;

      // ৪. সফল হলে লগইন স্ক্রিনে যাওয়া
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account deleted successfully.")),
      );

    } on FirebaseAuthException catch (e) {
      // সেনসিটিভ অপারেশন: অনেক সময় ইউজারকে রি-লগইন করতে বলতে হয়
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login again to delete your account.")),
        );
        // রি-লগইন করার জন্য পাঠানো যেতে পারে
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete: $e")),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingScaffold(
      title: "DELETE ACCOUNT",
      backgroundColor: AppColors.bgBlue,
      showBack: true,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text(
                "Are you sure?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 10),
            const Text(
              "Deleting your account is permanent. All your history, badges, and points will be lost forever.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const Spacer(),

            // ডিলিট বাটন (লোডিং অবস্থায় ডিজিবল থাকবে)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isDeleting ? null : _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isDeleting
                    ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : const Text(
                  "CONFIRM DELETE",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}