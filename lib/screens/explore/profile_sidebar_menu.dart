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
import '../auth/log_in_chacker_screen.dart';

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
          _userRole = data['userRole'] ?? 'finder';
          _profileImage = data['image'] ?? data['imageUrl'];
          _followersCount = data['followersCount'] ?? 0;
          _subscriptionPlan = (data['subscription'] ?? 'free').toLowerCase();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ লজিক চেকার ফাংশন (যেকোনো বাটন ট্যাপ করলে এটি কল হবে)
  void _navigateProtected({required Widget targetScreen, required String featureName}) {
    Navigator.pop(context); // ড্রয়ার বন্ধ করা

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // ইউজার লগইন আছে -> টার্গেট পেজে যাও
      Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
    } else {
      // ইউজার লগইন নেই -> ProfileNotLoggedIn পেজে যাও
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
      backgroundColor: bgColor,
      child: Column(
        children: [
          _buildHeader(isDark, isLoggedIn),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                _buildMenuSection("ACCOUNT"),
                _buildSettingsGroup([
                  // ✅ ১. My Profile (লগইন চেক বসানো হয়েছে)
                  _buildSettingsTile(
                    Icons.person_outline_rounded,
                    "My Profile",
                    "View and edit profile",
                        () => _navigateProtected(
                      targetScreen: UnifiedProfileScreen(uid: uid, isOwner: true, showBack: true),
                      featureName: "Profile",
                    ),
                    Colors.blueAccent,
                  ),

                  // Subscription (সাধারণত লগইন ছাড়া সাবস্ক্রিপশন হয় না, তাই এখানেও চেক দিতে পারেন)
                  _buildSettingsTile(
                    Icons.workspace_premium_rounded,
                    "Subscription",
                    "Manage your plan",
                        () => _navigateProtected(
                      targetScreen: const SubscriptionScreen(),
                      featureName: "Subscription",
                    ),
                    Colors.amber,
                    trailing: _getPlanBadge(),
                  ),
                ], isDark),

                _buildMenuSection("PREFERENCES"),
                _buildSettingsGroup([
                  _buildSettingsTile(
                    Icons.settings_outlined,
                    "Settings",
                    "Privacy, security & more",
                        () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                    Colors.grey,
                  ),
                  _buildDarkModeTile(isDark),
                  _buildSettingsTile(
                    Icons.language_rounded,
                    "App Language",
                    "Change language",
                        () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()));
                    },
                    Colors.purpleAccent,
                  ),
                ], isDark),

                _buildMenuSection("EXTRAS"),
                _buildSettingsGroup([
                  // ✅ ২. Refer & Earn (লগইন চেক বসানো হয়েছে)
                  _buildSettingsTile(
                    Icons.card_giftcard_rounded,
                    "Refer & Earn",
                    "Invite friends & earn",
                        () => _navigateProtected(
                      targetScreen: const ReferEarnScreen(),
                      featureName: "Referral",
                    ),
                    Colors.green,
                  ),
                  // ✅ ৩. Report a Problem (লগইন চেক বসানো হয়েছে)
                  _buildSettingsTile(
                    Icons.bug_report_outlined,
                    "Report a Problem",
                    "Help us improve",
                        () => _navigateProtected(
                      targetScreen: const ReportScreen(),
                      featureName: "Support",
                    ),
                    Colors.orangeAccent,
                  ),
                ], isDark),

                if (isLoggedIn) ...[
                  const SizedBox(height: 20),
                  _buildSettingsGroup([
                    _buildSettingsTile(
                      Icons.logout_rounded,
                      "Sign Out",
                      "Log out from this device",
                      _showLogoutDialog,
                      Colors.redAccent,
                    ),
                  ], isDark),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),

          if (isLoggedIn) _buildRoleSwitchCard(isDark),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildHeader(bool isDark, bool isLoggedIn) {
    return ValueListenableBuilder<BadgeProgress>(
      valueListenable: BadgeService.badgeNotifier,
      builder: (context, progress, _) {
        final badgeColor = AppBadgeTheme.colorForLevel(progress.level);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF2C2C2C), const Color(0xFF1A1A1A)]
                  : [Colors.white, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: AppColors.brandMain.withOpacity(0.1),
                        backgroundImage: _profileImage != null ? NetworkImage(_profileImage!) : null,
                        child: _profileImage == null ? const Icon(Icons.person, size: 35, color: Colors.grey) : null,
                      ),
                      if (isLoggedIn)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(AppBadgeTheme.baseIcon, size: 14, color: badgeColor),
                        ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoggedIn ? _userName : "Welcome Guest",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isLoggedIn)
                          Text(
                            _userRole == 'finder' ? "Verified Worker" : "Top Supporter",
                            style: const TextStyle(fontSize: 12, color: AppColors.brandMain, fontWeight: FontWeight.bold),
                          ),
                        if (isLoggedIn)
                          Text(
                            "$_followersCount Followers",
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isLoggedIn) ...[
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Level: ${BadgeService.getFormattedLevelName(progress.level)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text("${progress.totalPoints} XP", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress.progressPercentage,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(badgeColor),
                    minHeight: 6,
                  ),
                ),
              ],
              if (!isLoggedIn) ...[
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandMain,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("LOGIN / SIGNUP", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 15, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> tiles, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: tiles),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String sub, VoidCallback onTap, Color color, {Widget? trailing}) {
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      dense: true,
    );
  }

  Widget _buildDarkModeTile(bool isDark) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, settings, _) {
        final dark = settings.isDarkMode;
        return SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (dark ? Colors.amber : Colors.blueGrey).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: dark ? Colors.amber : Colors.blueGrey,
              size: 20,
            ),
          ),
          title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: const Text("Switch app theme", style: TextStyle(fontSize: 10, color: Colors.grey)),
          value: dark,
          activeColor: AppColors.brandMain,
          onChanged: (val) {
            ThemeService.updateThemeSetting(isDarkMode: val);
          },
          dense: true,
        );
      },
    );
  }

  Widget _buildRoleSwitchCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: AppColors.brandMain.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.brandMain.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.sync_alt_rounded, color: AppColors.brandMain, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userRole == 'finder' ? "Worker Mode" : "Supporter Mode",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Text(
                      "Switch to other profile",
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _switchRoleLogic,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandMain,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("SWITCH", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getPlanBadge() {
    if (_subscriptionPlan == 'pro') return _chipBadge("PRO", Colors.amber);
    if (_subscriptionPlan == 'business') return _chipBadge("BIZ", Colors.blue);
    return const SizedBox();
  }

  Widget _chipBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  // --- লজিক ---
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Sign Out?"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleLogout();
            },
            child: const Text("LOGOUT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }

  Future<void> _switchRoleLogic() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    String currentRole = _userRole ?? 'finder';
    String targetRole = (currentRole == 'finder') ? 'maker' : 'finder';

    bool hasTargetAccount = (targetRole == 'finder')
        ? (prefs.getBool('has_worker_account') ?? false)
        : (prefs.getBool('has_supporter_account') ?? false);

    if (hasTargetAccount) {
      await prefs.setString('user_role', targetRole);
      setState(() => _userRole = targetRole);
      Navigator.pop(context);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Create ${targetRole == 'finder' ? 'Worker' : 'Supporter'} Profile?"),
          content: const Text("You don't have this profile yet. Create one now to switch modes."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("LATER")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandMain, foregroundColor: Colors.white),
              child: const Text("CREATE"),
            ),
          ],
        ),
      );
    }
  }
}