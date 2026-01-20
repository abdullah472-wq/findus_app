import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:findus_app/services/theme_service.dart';
import 'package:findus_app/services/badge_service.dart';
import 'package:findus_app/models/badge_model.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/constants/badge_theme.dart';
import 'package:findus_app/screens/auth/login_screen.dart'; // সঠিক ইমপোর্ট চেক করুন
import 'package:findus_app/screens/auth/role_selection_screen.dart';
import 'package:findus_app/screens/settings/settings_screen.dart';
import 'package:findus_app/screens/explore/refer_earn_screen.dart';
import 'package:findus_app/screens/settings/subscription_screen.dart';
import 'package:findus_app/screens/report/report_screen.dart';
import 'package:findus_app/screens/settings/language_settings_screen.dart';
import 'package:findus_app/screens/supporter/supporter_profile_screen.txt';
import 'package:findus_app/screens/earner/worker_profile_screen.txt';
import 'package:findus_app/models/worker_model.dart';

import '../../badge/badge_model.dart';
import '../../badge/badge_service.dart' hide BadgeProgress;
import '../../badge/badge_theme.dart';

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
  bool _isProfileCompleted = false;
  double _completionPercent = 0.0;
  String _subscriptionPlan = 'free';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && mounted) {
        final data = userDoc.data()!;
        setState(() {
          _followersCount = data['followersCount'] ?? 0;
          _profileImage = data['image'];
        });
      }
    }

    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'FINDUS User';
        _userRole = prefs.getString('user_role');
        _subscriptionPlan = (prefs.getString('subscription_plan') ?? 'free').toLowerCase();
      });
    }
  }

  // --- ১. সাইন আউট কনফার্মেশন পপ-আপ ---
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleLogout(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Sign Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- ২. রোল সুইচ লজিক (অ্যাকাউন্ট চেকসহ) ---
  Future<void> _switchRoleLogic() async {
    final prefs = await SharedPreferences.getInstance();
    String currentRole = _userRole ?? 'finder';
    String targetRole = (currentRole == 'finder') ? 'maker' : 'finder';

    // চেক করা যে অন্য অ্যাকাউন্টটি অলরেডি আছে কি না
    bool hasTargetAccount = false;
    if (targetRole == 'finder') {
      hasTargetAccount = prefs.getBool('has_worker_account') ?? false;
    } else {
      hasTargetAccount = prefs.getBool('has_supporter_account') ?? false;
    }

    if (hasTargetAccount) {
      // সুইচ করা (অ্যাপ থেকে বের না হয়ে)
      await prefs.setString('user_role', targetRole);
      setState(() {
        _userRole = targetRole;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Switched to ${targetRole == 'finder' ? 'Worker' : 'Supporter'} Mode")));
    } else {
      // অ্যাকাউন্ট না থাকলে ক্রিয়েট অ্যাকাউন্ট পপ-আপ
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Create ${targetRole == 'finder' ? 'Worker' : 'Supporter'} Account?"),
          content: Text("You don't have a ${targetRole == 'finder' ? 'Worker' : 'Supporter'} profile yet. Create one to continue."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
              },
              child: const Text("Create Now"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppColors.bgBlue,
      child: Column(
        children: [
          // --- ৩. হেডার (ব্যাজ নামের উপরে) ---
          _buildHeader(isDark),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(Icons.person_outline, "My Profile", () { Navigator.pop(context); _openOwnerProfile(); }),
                _buildMenuItem(Icons.settings_outlined, "Settings", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
                const Divider(),

                // --- ৪. ডার্ক মোড সুইচ (ফিরে আনা হয়েছে) ---
                ValueListenableBuilder<bool>(
                  valueListenable: ThemeService.isDarkMode,
                  builder: (context, dark, _) {
                    return SwitchListTile(
                      secondary: Icon(dark ? Icons.dark_mode : Icons.light_mode, color: dark ? Colors.amber : AppColors.brandDark),
                      title: const Text("Dark Mode", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      value: dark,
                      activeColor: AppColors.brandMain,
                      onChanged: (val) => ThemeService.updateTheme(val),
                    );
                  },
                ),

                _buildMenuItem(Icons.workspace_premium_outlined, "Subscription", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())); }),
                _buildMenuItem(Icons.card_giftcard, "Refer & Earn", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => ReferEarnScreen())); }),
                const Divider(),
                _buildMenuItem(Icons.flag_outlined, "Report Problem", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())); }),
                _buildMenuItem(Icons.language, "App Language", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen())); }),
                _buildMenuItem(Icons.logout, "Sign Out", _showLogoutDialog, color: Colors.redAccent),
              ],
            ),
          ),

          // --- ৫. রোল সুইচ বাটন (অ্যাপ না বেরিয়ে সুইচ হবে) ---
          _buildRoleSwitchButton(),
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
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : AppColors.brandLight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // নামের উপরে ব্যাজ আইকন
              Icon(AppBadgeTheme.baseIcon, size: 28, color: badgeColor),
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(radius: 30, backgroundColor: Colors.white, backgroundImage: _profileImage != null ? NetworkImage(_profileImage!) : null, child: _profileImage == null ? const Icon(Icons.person, size: 30) : null),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        // 'Job Maker' এর বদলে রিয়েল রোল
                        Text(_userRole == 'finder' ? "Worker" : "Supporter", style: const TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("$_followersCount Followers", style: TextStyle(fontSize: 11, color: badgeColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _getPlanIndicator(),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
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

  Widget _getPlanIndicator() {
    if (_subscriptionPlan == 'pro') return const Icon(Icons.workspace_premium, color: Colors.amber, size: 20);
    if (_subscriptionPlan == 'business') return const Icon(Icons.group, color: Colors.blue, size: 20);
    return const Text("Free", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey));
  }

  Widget _buildRoleSwitchButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _switchRoleLogic,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandMain, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        icon: const Icon(Icons.swap_horiz, color: Colors.white),
        label: Text(_userRole == 'finder' ? "SWITCH TO SUPPORT" : "SWITCH TO EARN", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String text, VoidCallback onTap, {Color color = Colors.black87}) {
    return ListTile(leading: Icon(icon, color: color == Colors.redAccent ? color : AppColors.brandDark.withOpacity(0.7), size: 22), title: Text(text, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)), onTap: onTap, dense: true);
  }

  Future<void> _openOwnerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_userRole == 'maker' || _userRole == 'supporter') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SupporterProfileScreen(isOwner: true, name: _userName, role: 'supporter', location: prefs.getString('user_location') ?? '', phone: prefs.getString('user_phone') ?? '')));
    } else {
      final worker = Worker(id: uid, name: _userName, role: 'earner', image: _profileImage ?? '', location: '', price: '', rating: 4.8, isVerified: false);
      Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerProfileScreen(worker: worker, isOwner: true, phoneNumber: prefs.getString('user_phone'))));
    }
  }

  void _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }
}