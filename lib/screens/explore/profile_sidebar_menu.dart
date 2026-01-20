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
import 'package:findus_app/screens/auth/login_screen.dart';
import 'package:findus_app/screens/auth/role_selection_screen.dart';
import 'package:findus_app/screens/settings/settings_screen.dart';
import 'package:findus_app/screens/explore/refer_earn_screen.dart';
import 'package:findus_app/screens/settings/subscription_screen.dart';
import 'package:findus_app/screens/report/report_screen.dart';
import 'package:findus_app/screens/settings/language_settings_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart'; // ✅ প্রোফাইল স্ক্রিন ইম্পোর্ট

class ProfileSideBar extends StatefulWidget {
  const ProfileSideBar({super.key});

  @override
  State<ProfileSideBar> createState() => _ProfileSideBarState();
}

class _ProfileSideBarState extends State<ProfileSideBar> {
  String _userName = 'FINDUS User';
  String? _userRole; // 'finder' = Worker, 'maker' = Supporter
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
    if (uid != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists && mounted) {
          final data = userDoc.data()!;
          setState(() {
            _userName = data['name'] ?? 'User';
            _userRole = data['userRole'] ?? 'finder';
            _profileImage = data['image'] ?? data['imageUrl'];
            _followersCount = data['followersCount'] ?? 0;
            _subscriptionPlan = (data['subscription'] ?? 'free').toLowerCase();
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FD),
      child: Column(
        children: [
          // ১. প্রিমিয়াম হেডার (ব্যাজ ও প্রোফাইল সামারি)
          _buildHeader(isDark),

          // ২. মেনু আইটেমস
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: [
                _buildMenuSection("ACCOUNT"),
                _buildModernMenuItem(Icons.person_outline_rounded, "My Profile", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => UnifiedProfileScreen(uid: uid, isOwner: true)));
                }, isDark),
                _buildModernMenuItem(Icons.workspace_premium_rounded, "Subscription", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                }, isDark, trailing: _getPlanBadge()),

                const SizedBox(height: 10),
                _buildMenuSection("PREFERENCES"),
                _buildModernMenuItem(Icons.settings_outlined, "Settings", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                }, isDark),

                // ডার্ক মোড সুইচ
                _buildDarkModeToggle(isDark),

                _buildModernMenuItem(Icons.language_rounded, "App Language", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()));
                }, isDark),

                const SizedBox(height: 10),
                _buildMenuSection("OTHERS"),
                _buildModernMenuItem(Icons.card_giftcard_rounded, "Refer & Earn", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferEarnScreen()));
                }, isDark),
                _buildModernMenuItem(Icons.bug_report_outlined, "Report a Problem", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()));
                }, isDark),

                const SizedBox(height: 20),
                _buildModernMenuItem(Icons.logout_rounded, "Sign Out", _showLogoutDialog, isDark, color: Colors.redAccent),
              ],
            ),
          ),

          // ৩. রোল সুইচ এরিয়া
          _buildRoleSwitchCard(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
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
                  : [AppColors.brandLight, Colors.white],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: AppColors.brandMain.withOpacity(0.2),
                        backgroundImage: _profileImage != null ? NetworkImage(_profileImage!) : null,
                        child: _profileImage == null ? const Icon(Icons.person, size: 35) : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(AppBadgeTheme.baseIcon, size: 16, color: badgeColor),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                            _userRole == 'finder' ? "Verified Worker" : "Top Supporter",
                            style: TextStyle(fontSize: 12, color: AppColors.brandMain, fontWeight: FontWeight.bold)
                        ),
                        Text("$_followersCount Followers", style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // XP Progress Bar
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
                  backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(badgeColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernMenuItem(IconData icon, String title, VoidCallback onTap, bool isDark, {Color? color, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.transparent,
      ),
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        leading: Icon(icon, color: color ?? (isDark ? Colors.white70 : AppColors.brandDark), size: 22),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? (isDark ? Colors.white : Colors.black87))),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        dense: true,
      ),
    );
  }

  Widget _buildRoleSwitchCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : AppColors.brandMain.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.brandMain.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              "You are currently in ${_userRole == 'finder' ? 'EARNING' : 'SUPPORT'} mode",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _switchRoleLogic,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sync_rounded, size: 20),
                  SizedBox(width: 10),
                  Text("SWITCH MODE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 15, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildDarkModeToggle(bool isDark) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkMode,
      builder: (context, dark, _) {
        return SwitchListTile(
          secondary: Icon(dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: dark ? Colors.amber : Colors.blueGrey),
          title: const Text("Dark Mode", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          value: dark,
          activeColor: AppColors.brandMain,
          onChanged: (val) => ThemeService.updateTheme(val),
        );
      },
    );
  }

  Widget _getPlanBadge() {
    if (_subscriptionPlan == 'pro') return _chipBadge("PRO", Colors.amber);
    if (_subscriptionPlan == 'business') return _chipBadge("BIZ", Colors.blue);
    return const SizedBox();
  }

  Widget _chipBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: color, width: 1)),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  // --- লজিক অংশ ---
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Sign Out?"),
        content: const Text("Do you really want to leave FINDUS?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("LOGOUT", style: TextStyle(color: Colors.white)),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Switched to ${targetRole == 'finder' ? 'Worker' : 'Supporter'} Mode")));
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Create ${targetRole == 'finder' ? 'Worker' : 'Supporter'} Profile?"),
          content: const Text("You don't have this profile yet. Let's set it up!"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("NOT NOW")),
            ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen())), child: const Text("CREATE NOW")),
          ],
        ),
      );
    }
  }
}