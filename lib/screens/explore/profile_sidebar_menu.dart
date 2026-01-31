// lib/screens/tabs/explore/profile_sidebar_menu.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/theme_service.dart';
import 'package:findus_app/badge/badge_service.dart';
import 'package:findus_app/badge/badge_model.dart';
import 'package:findus_app/badge/badge_theme.dart';

// Screens
import 'package:findus_app/screens/auth/login_screen.dart';
import 'package:findus_app/screens/auth/role_selection_screen.dart';
import 'package:findus_app/screens/settings/settings_screen.dart';
import 'package:findus_app/screens/explore/refer_earn_screen.dart';
import 'package:findus_app/screens/settings/subscription_screen.dart';
import 'package:findus_app/screens/report/report_screen.dart';
import 'package:findus_app/screens/settings/language_settings_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/auth/log_in_chacker_screen.dart';
import 'package:findus_app/screens/dashboard/dashboard_screen.dart';

class ProfileSideBar extends StatefulWidget {
  const ProfileSideBar({super.key});

  @override
  State<ProfileSideBar> createState() => _ProfileSideBarState();
}

class _ProfileSideBarState extends State<ProfileSideBar> {
  String _userName = 'FINDUS User';
  String? _userRole;
  String? _profileImage;
  int _followersCount = 0;
  String _subscriptionPlan = 'free';
  bool _isVerified = false; // ✅ ভেরিফাইড স্ট্যাটাস
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mounted) return;

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _userName = data['name'] ?? 'User';
          final rawRole = (data['userRole'] ?? 'worker').toString().toLowerCase();
// পুরোনো ডাটা থেকে আসলে finder/maker থাকলেও map করে নিচ্ছি
          String mappedRole;
          if (rawRole == 'finder') {
            mappedRole = 'worker';
          } else if (rawRole == 'maker') {
            mappedRole = 'supporter';
          } else {
            mappedRole = rawRole; // worker/supporter
          }
          _userRole = mappedRole;
          _profileImage = data['image'] ?? data['imageUrl'];
          _followersCount = data['followersCount'] ?? 0;
          _subscriptionPlan = (data['subscription'] ?? 'free').toLowerCase();
          _isVerified = data['kyc_completed'] == true; // ✅ KYC চেক
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateProtected({required Widget targetScreen, required String featureName}) {
    Navigator.pop(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileNotLoggedIn(title: featureName, showBackButton: true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final uid = user?.uid ?? '';
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: Colors.transparent, // ✅ ট্রান্সপারেন্ট যাতে সেইফ এরিয়া বা প্যাডিং দেখা যায়
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100), // ✅ নিচ থেকে ৮০ পিক্সেল উপরে (মেইন বারের জন্য)
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20), // নিচের দিকে রাউন্ডেড কর্নার
            ),
          ),
          child: Column(
            children: [
              _buildHeader(isDark, isLoggedIn),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), // ✅ প্যাডিং কমানো হয়েছে
                  children: [
                    _buildMenuSection("ACCOUNT"),
                    _buildSettingsGroup([
                      _buildSettingsTile(Icons.person_outline_rounded, "My Profile", "View and edit profile", () => _navigateProtected(targetScreen: UnifiedProfileScreen(uid: uid, isOwner: true, showBack: true), featureName: "Profile"), Colors.blueAccent),
                      if (isLoggedIn) _buildSettingsTile(Icons.dashboard_rounded, "My Dashboard", "Earnings, stats & job history", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen())); }, Colors.teal),
                      _buildSettingsTile(Icons.workspace_premium_rounded, "Subscription", "Manage your plan", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())); }, Colors.amber, trailing: _getPlanBadge()),
                    ], isDark),

                    _buildMenuSection("PREFERENCES"),
                    _buildSettingsGroup([
                      _buildSettingsTile(Icons.settings_outlined, "Settings", "Privacy, security & more", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }, Colors.grey),
                      _buildDarkModeTile(isDark),
                      _buildSettingsTile(Icons.language_rounded, "App Language", "Change language", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen())); }, Colors.purpleAccent),
                    ], isDark),

                    _buildMenuSection("EXTRAS"),
                    _buildSettingsGroup([
                      _buildSettingsTile(Icons.card_giftcard_rounded, "Refer & Earn", "Invite friends & earn", () => _navigateProtected(targetScreen: const ReferEarnScreen(), featureName: "Referral"), Colors.green),
                      _buildSettingsTile(Icons.bug_report_outlined, "Report a Problem", "Help us improve", () => _navigateProtected(targetScreen: const ReportScreen(), featureName: "Support"), Colors.orangeAccent),
                    ], isDark),

                    if (isLoggedIn) ...[
                      const SizedBox(height: 15),
                      _buildSettingsGroup([_buildSettingsTile(Icons.logout_rounded, "Sign Out", "Log out from this device", _showLogoutDialog, Colors.redAccent)], isDark),
                    ],

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isLoggedIn) {
    return ValueListenableBuilder<BadgeProgress>(
      valueListenable: BadgeService.badgeNotifier,
      builder: (context, progress, _) {
        final badgeColor = AppBadgeTheme.colorForLevel(progress.level);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark ? [const Color(0xFF2C2C2C), const Color(0xFF1A1A1A)] : [Colors.white, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)), // হেডার একটু ছোট
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 28, // ✅ সাইজ কমানো হয়েছে (30 -> 28)
                        backgroundColor: AppColors.brandMain.withOpacity(0.1),
                        backgroundImage: _profileImage != null ? NetworkImage(_profileImage!) : null,
                        child: _profileImage == null ? const Icon(Icons.person, size: 28, color: Colors.grey) : null,
                      ),
                      if (isLoggedIn)
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(AppBadgeTheme.baseIcon, size: 10, color: badgeColor),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isLoggedIn ? _userName : "Welcome Guest",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // ✅ Verified Badge নামের পাশে
                            if (isLoggedIn && _isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.verified, size: 16, color: Colors.blue),
                              ),
                          ],
                        ),
                        if (isLoggedIn)
                        // ✅ শুধু Role দেখানো হচ্ছে (Worker/Supporter)
                          Text(
                            _userRole == 'finder' ? "Worker" : "Supporter",
                            style: const TextStyle(fontSize: 11, color: AppColors.brandMain, fontWeight: FontWeight.bold),
                          ),
                        if (isLoggedIn)
                          Text("$_followersCount Followers", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),

                  // Switch Role Button
                  if (isLoggedIn)
                    GestureDetector(
                      onTap: _switchRoleLogic,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandMain.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AppColors.brandMain.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.sync_alt_rounded, size: 12, color: AppColors.brandMain),
                            SizedBox(width: 4),
                            Text("Switch", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brandMain)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              if (isLoggedIn) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Level: ${BadgeService.getFormattedLevelName(progress.level)}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text("${progress.totalPoints} XP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress.progressPercentage, backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100, valueColor: AlwaysStoppedAnimation(badgeColor), minHeight: 4)),
              ],
              if (!isLoggedIn) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandMain, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text("LOGIN / SIGNUP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // --- Helpers (Small tweaks for padding) ---
  Widget _buildMenuSection(String title) {
    return Padding(padding: const EdgeInsets.only(left: 8, top: 10, bottom: 6), child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)));
  }

  Widget _buildSettingsGroup(List<Widget> tiles, bool isDark) {
    return Container(decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]), child: Column(children: tiles));
  }

  Widget _buildSettingsTile(IconData icon, String title, String sub, VoidCallback onTap, Color color, {Widget? trailing}) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: -2), // ✅ হাইট কমানো হয়েছে
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      leading: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
      dense: true,
    );
  }

  // ... (Other methods remain same, just ensure they are included in the class)

  Widget _buildDarkModeTile(bool isDark) {
    return ValueListenableBuilder<ThemeSettings>(valueListenable: ThemeService.themeSettings, builder: (context, settings, _) { final dark = settings.isDarkMode; return SwitchListTile(visualDensity: const VisualDensity(vertical: -2), contentPadding: const EdgeInsets.symmetric(horizontal: 16), secondary: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: (dark ? Colors.amber : Colors.blueGrey).withOpacity(0.1), shape: BoxShape.circle), child: Icon(dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: dark ? Colors.amber : Colors.blueGrey, size: 18)), title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), subtitle: const Text("Switch app theme", style: TextStyle(fontSize: 10, color: Colors.grey)), value: dark, activeThumbColor: AppColors.brandMain, onChanged: (val) { ThemeService.updateThemeSetting(isDarkMode: val); }, dense: true); });
  }

  Widget _getPlanBadge() { if (_subscriptionPlan == 'pro') return _chipBadge("PRO", Colors.amber); if (_subscriptionPlan == 'business') return _chipBadge("BIZ", Colors.blue); return const SizedBox(); }
  Widget _chipBadge(String text, Color color) { return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.5), width: 1)), child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold))); }
  void _showLogoutDialog() { showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: const Text("Sign Out?"), content: const Text("Are you sure you want to sign out?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))), TextButton(onPressed: () { Navigator.pop(ctx); _handleLogout(); }, child: const Text("LOGOUT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)))])); }
  Future<void> _handleLogout() async { await FirebaseAuth.instance.signOut(); final prefs = await SharedPreferences.getInstance(); await prefs.clear(); if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false); }

  // _switchRoleLogic & _buildRoleSwitchCard বাদ দেওয়া হয়েছে কারণ বাটন এখন হেডারে
  Future<void> _switchRoleLogic() async {
    HapticFeedback.mediumImpact();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // লগইন না থাকলে Login এ পাঠাই
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final uid = currentUser.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      final snap = await userRef.get();
      final data = snap.data() ?? <String, dynamic>{};

      // current core role বের করা (worker/supporter)
      String rawRole = (data['userRole'] ?? 'worker').toString().toLowerCase();
      if (rawRole == 'finder') rawRole = 'worker';
      if (rawRole == 'maker') rawRole = 'supporter';

      final String currentCoreRole =
      (rawRole == 'supporter') ? 'supporter' : 'worker';

      // টার্গেট role
      final String targetCoreRole =
      currentCoreRole == 'worker' ? 'supporter' : 'worker';

      // roles array থেকে টার্গেট role আছে কিনা দেখি
      final List<dynamic> rolesRaw = (data['roles'] as List?) ?? [];
      final List<String> roles =
      rolesRaw.map((e) => e.toString()).toList();

      final bool hasTargetRole = roles.contains(targetCoreRole);

      if (hasTargetRole) {
        // 🔹 শুধু active role (userRole) switch করব
        await userRef.set(
          {
            'userRole': targetCoreRole,
            'isWorker': targetCoreRole == 'worker',
            'isSupporter': targetCoreRole == 'supporter',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        if (!mounted) return;
        setState(() => _userRole = targetCoreRole);
        Navigator.pop(context); // Drawer বন্ধ
      } else {
        // 🔹 এখনও ওই role এর প্রোফাইল নেই → RoleSelectionScreen এ পাঠাই
        final targetLabel =
        targetCoreRole == 'worker' ? 'Worker' : 'Supporter';

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text("Create $targetLabel Profile?"),
            content: const Text(
              "You don't have this profile yet. Create one now to switch modes.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("LATER"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // dialog বন্ধ
                  Navigator.pop(context); // drawer বন্ধ
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoleSelectionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                ),
                child: const Text("CREATE"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in _switchRoleLogic: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to switch role. Please try again."),
          ),
        );
      }
    }
  }
}