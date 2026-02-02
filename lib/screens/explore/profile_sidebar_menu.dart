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
import 'package:findus_app/screens/settings/settings_screen.dart';
import 'package:findus_app/screens/explore/refer_earn_screen.dart';
import 'package:findus_app/screens/settings/subscription_screen.dart';
import 'package:findus_app/screens/report/report_screen.dart';
import 'package:findus_app/screens/settings/language_settings_screen.dart';
import 'package:findus_app/screens/profile/unified_profile_screen.dart';
import 'package:findus_app/screens/auth/log_in_chacker_screen.dart';
import 'package:findus_app/screens/home_feed_screen.dart';
import 'package:findus_app/screens/tabs/save_screen.dart';

class ProfileSideBar extends StatefulWidget {
  const ProfileSideBar({super.key});

  @override
  State<ProfileSideBar> createState() => _ProfileSideBarState();
}

class _ProfileSideBarState extends State<ProfileSideBar> {
  String _userName = 'FINDUS User';
  String? _userRole;
  String? _profileImage;
  String _userEmail = '';
  String _subscriptionPlan = 'free';

  bool _isVerified = false;
  bool _isTopRated = false;
  bool _isTrusted = false;

  bool _isLocked = false;
  bool _isPaused = false;
  bool _isHidden = false;

  bool _isLoading = true;
  int _cardThemeIndex = 0;

  final List<List<Color>> _themeGradients = const [
    [Color(0xFFE0F7FA), Color(0xFFFFFFFF)],
    [Color(0xFFFFF3E0), Color(0xFFFFFFFF)],
    [Color(0xFFE8EAF6), Color(0xFFFFFFFF)],
    [Color(0xFFFCE4EC), Color(0xFFFFFFFF)],
  ];

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
        final double rating = (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0;
        final int completed = (data['completedCount'] ?? 0) as int;

        setState(() {
          _userName = data['name'] ?? 'User';
          _userEmail = FirebaseAuth.instance.currentUser?.email ?? 'No Email';

          final rawRole = (data['userRole'] ?? 'worker').toString().toLowerCase();
          _userRole = (rawRole == 'finder') ? 'Worker' : (rawRole == 'maker') ? 'Supporter' : rawRole;

          _profileImage = data['image'] ?? data['imageUrl'];
          _subscriptionPlan = (data['subscription'] ?? 'free').toLowerCase();

          _isVerified = data['kyc_completed'] == true;
          _isTopRated = rating >= 4.8;
          _isTrusted = completed >= 50 && rating >= 4.5;

          _isLocked = data['accountLocked'] == true;
          _isPaused = data['workPaused'] == true;
          _isHidden = data['profileHidden'] == true;

          _cardThemeIndex = (data['cardThemeIndex'] ?? 0) as int;

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
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileNotLoggedIn(title: featureName, showBackButton: true)));
    }
  }

  void _goToDashboard() {
    Navigator.pop(context);
    HomeFeedScreen.goToTab(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: Colors.transparent,
      child: Column( // ✅ Full Height Drawer Fix
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 75), // ✅ Bottom Nav Bar এর জন্য জায়গা রাখা হয়েছে
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  _buildHeader(isDark, isLoggedIn),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                      children: [
                        _buildMenuSection("ACCOUNT"),
                        _buildSettingsGroup([
                          _buildCompactTile(Icons.person_outline_rounded, "My Profile", () => _navigateProtected(targetScreen: UnifiedProfileScreen(uid: uid, isOwner: true, showBack: true), featureName: "Profile"), Colors.blueAccent),
                          if (isLoggedIn) _buildCompactTile(Icons.dashboard_rounded, "My Dashboard", _goToDashboard, Colors.teal),
                          _buildCompactTile(Icons.bookmark_outline_rounded, "Saved Profiles", () => _navigateProtected(targetScreen: const SaveScreen(), featureName: "Saved Profiles"), Colors.pinkAccent),
                          _buildCompactTile(Icons.workspace_premium_rounded, "Subscription", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())); }, Colors.amber, trailing: _getPlanBadge()),
                        ], isDark),

                        _buildMenuSection("PREFERENCES"),
                        _buildSettingsGroup([
                          _buildCompactTile(Icons.settings_outlined, "Settings", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }, Colors.grey),
                          _buildDarkModeTile(isDark),
                          _buildCompactTile(Icons.language_rounded, "App Language", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen())); }, Colors.purpleAccent),
                        ], isDark),

                        _buildMenuSection("EXTRAS"),
                        _buildSettingsGroup([
                          _buildCompactTile(Icons.card_giftcard_rounded, "Refer & Earn", () => _navigateProtected(targetScreen: const ReferEarnScreen(), featureName: "Referral"), Colors.green),
                          _buildCompactTile(Icons.bug_report_outlined, "Report a Problem", () => _navigateProtected(targetScreen: const ReportScreen(), featureName: "Support"), Colors.orangeAccent),
                        ], isDark),

                        if (isLoggedIn) ...[
                          const SizedBox(height: 15),
                          _buildSettingsGroup([_buildCompactTile(Icons.logout_rounded, "Sign Out", _showLogoutDialog, Colors.redAccent)], isDark),
                        ],
                        const SizedBox(height: 20),
                      ],
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

  // 🔥 Compact Tile (Smaller Height)
  Widget _buildCompactTile(IconData icon, String title, VoidCallback onTap, Color color, {Widget? trailing}) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: 0), // ✅ একদম কমপ্যাক্ট
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 15), // Smaller Icon
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
      dense: true,
    );
  }

  Widget _buildDarkModeTile(bool isDark) {
    return ValueListenableBuilder<ThemeSettings>(
        valueListenable: ThemeService.themeSettings,
        builder: (context, settings, _) {
          final dark = settings.isDarkMode;
          return SwitchListTile(
              visualDensity: const VisualDensity(vertical: -3),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              secondary: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: (dark ? Colors.amber : Colors.blueGrey).withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: dark ? Colors.amber : Colors.blueGrey, size: 18)
              ),
              title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              value: dark,
              activeThumbColor: AppColors.brandMain,
              onChanged: (val) { ThemeService.updateThemeSetting(isDarkMode: val); },
              dense: true
          );
        }
    );
  }

  // 🔥 Header Design (Same as before)
  Widget _buildHeader(bool isDark, bool isLoggedIn) {
    return ValueListenableBuilder<BadgeProgress>(
      valueListenable: BadgeService.badgeNotifier,
      builder: (context, progress, _) {
        final badgeColor = AppBadgeTheme.colorForLevel(progress.level);
        final badgeName = BadgeService.getFormattedLevelName(progress.level);

        final themeIdx = _cardThemeIndex.clamp(0, _themeGradients.length - 1);
        final selectedTheme = _themeGradients[themeIdx];
        final gradientColors = isDark ? [selectedTheme[0].withOpacity(0.8), const Color(0xFF1E1E1E)] : selectedTheme;
        final textColor = isDark ? Colors.white : Colors.black87;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20), // Reduced Padding
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isLoggedIn ? gradientColors : (isDark ? [const Color(0xFF2C2C2C), const Color(0xFF1A1A1A)] : [Colors.white, Colors.grey.shade50]),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Stack(
            children: [
              if (isLoggedIn)
                Positioned(
                  right: -30, top: -30,
                  child: Opacity(
                    opacity: 0.05,
                    child: Icon(Icons.workspace_premium, size: 150, color: isDark ? Colors.white : Colors.black),
                  ),
                ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 30, // Slightly smaller
                              backgroundColor: AppColors.brandMain.withOpacity(0.1),
                              backgroundImage: _profileImage != null ? NetworkImage(_profileImage!) : null,
                              child: _profileImage == null ? const Icon(Icons.person, size: 30, color: Colors.grey) : null,
                            ),
                            if (isLoggedIn && _isVerified)
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: const Icon(Icons.verified, size: 16, color: Colors.blue),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Text(
                          isLoggedIn ? _userName : "Welcome Guest",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        if (isLoggedIn) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text((_userRole ?? "USER").toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brandMain)),
                              const SizedBox(width: 6),
                              if (_isLocked) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.lock_outline, size: 14, color: Colors.redAccent)),
                              if (_isPaused) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.pause_circle_outline, size: 14, color: Colors.amber)),
                              if (_isHidden) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.visibility_off_outlined, size: 14, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_userEmail, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],

                        if (!isLoggedIn) ...[
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())); },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandMain, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), minimumSize: const Size(80, 32)),
                            child: const Text("LOGIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (isLoggedIn)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: badgeColor.withOpacity(0.3), width: 2)),
                          child: Icon(AppBadgeTheme.baseIcon, size: 30, color: badgeColor),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(10)),
                          child: Text(badgeName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                        const SizedBox(height: 4),
                        Text("${progress.totalPoints} XP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey.shade700)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildCleanStatusIcon(Icons.verified, _isVerified, Colors.blue),
                            const SizedBox(width: 4),
                            _buildCleanStatusIcon(Icons.star, _isTopRated, Colors.orange),
                            const SizedBox(width: 4),
                            _buildCleanStatusIcon(Icons.shield, _isTrusted, Colors.green),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCleanStatusIcon(IconData icon, bool isActive, Color color) {
    if (!isActive) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, spreadRadius: 1)]),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _buildMenuSection(String title) { return Padding(padding: const EdgeInsets.only(left: 12, top: 10, bottom: 4), child: Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2))); }
  Widget _buildSettingsGroup(List<Widget> tiles, bool isDark) { return Container(decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))]), child: Column(children: tiles)); }
  Widget _getPlanBadge() { if (_subscriptionPlan == 'pro') return _chipBadge("PRO", Colors.amber); if (_subscriptionPlan == 'business') return _chipBadge("BIZ", Colors.blue); return const SizedBox(); }
  Widget _chipBadge(String text, Color color) { return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.5), width: 1)), child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold))); }
  void _showLogoutDialog() { showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: const Text("Sign Out?"), content: const Text("Are you sure you want to sign out?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))), TextButton(onPressed: () { Navigator.pop(ctx); _handleLogout(); }, child: const Text("LOGOUT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)))])); }
  Future<void> _handleLogout() async { await FirebaseAuth.instance.signOut(); final prefs = await SharedPreferences.getInstance(); await prefs.clear(); if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false); }
}