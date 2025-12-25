import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:findus_app/constants/app_colors.dart';

class NotificationControlPage extends StatefulWidget {
  const NotificationControlPage({super.key});

  @override
  State<NotificationControlPage> createState() => _NotificationControlPageState();
}

class _NotificationControlPageState extends State<NotificationControlPage> {
  // master + per-category flags
  bool _allEnabled = true;
  bool _jobsEnabled = true;
  bool _chatEnabled = true;
  bool _promoEnabled = true;
  bool _emergencyEnabled = true;

  bool _loading = true;

  static const _keyAll = 'notif_all';
  static const _keyJobs = 'notif_jobs';
  static const _keyChat = 'notif_chat';
  static const _keyPromo = 'notif_promo';
  static const _keyEmergency = 'notif_emergency';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // ডিফল্টে সব true
    setState(() {
      _allEnabled = prefs.getBool(_keyAll) ?? true;
      _jobsEnabled = prefs.getBool(_keyJobs) ?? true;
      _chatEnabled = prefs.getBool(_keyChat) ?? true;
      _promoEnabled = prefs.getBool(_keyPromo) ?? true;
      _emergencyEnabled =
          prefs.getBool(_keyEmergency) ?? true;
      _loading = false;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAll, _allEnabled);
    await prefs.setBool(_keyJobs, _jobsEnabled);
    await prefs.setBool(_keyChat, _chatEnabled);
    await prefs.setBool(_keyPromo, _promoEnabled);
    await prefs.setBool(_keyEmergency, _emergencyEnabled);
  }

  void _updateAll(bool value) {
    setState(() {
      _allEnabled = value;
      // master off করলে বাকি সবও off
      if (!value) {
        _jobsEnabled = false;
        _chatEnabled = false;
        _promoEnabled = false;
        _emergencyEnabled = false;
      }
    });
    _savePrefs();
    // ভবিষ্যতে এখানে NotificationService / FCM topics handle করতে পারো
  }

  void _updateCategory({
    bool? jobs,
    bool? chat,
    bool? promo,
    bool? emergency,
  }) {
    setState(() {
      if (jobs != null) _jobsEnabled = jobs;
      if (chat != null) _chatEnabled = chat;
      if (promo != null) _promoEnabled = promo;
      if (emergency != null) _emergencyEnabled = emergency;

      // যদি কোনো একটাও true থাকে → master চালু
      final anyOn = _jobsEnabled ||
          _chatEnabled ||
          _promoEnabled ||
          _emergencyEnabled;
      _allEnabled = anyOn;
    });
    _savePrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.brandLight,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.brandMain,
        ),
      )
          : ListView(
        padding:
        const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // master switch
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SwitchListTile(
              title: const Text(
                "All notifications",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
              subtitle: const Text(
                "Turn all FINDUS notifications on or off.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              value: _allEnabled,
              onChanged: _updateAll,
              activeColor: AppColors.brandMain,
              contentPadding:
              const EdgeInsets.symmetric(
                  horizontal: 0),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Notification types",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 8),

          _buildSwitchCard(
            icon: Icons.work_outline,
            title: "Jobs & Support posts",
            subtitle:
            "Alerts when new jobs or relevant posts appear near you.",
            value: _jobsEnabled && _allEnabled,
            // master off হলে child switch visually off ও disabled
            onChanged: _allEnabled
                ? (v) => _updateCategory(jobs: v)
                : null,
          ),

          _buildSwitchCard(
            icon: Icons.chat_bubble_outline,
            title: "Chat messages",
            subtitle:
            "New messages, replies and important chat updates.",
            value: _chatEnabled && _allEnabled,
            onChanged: _allEnabled
                ? (v) => _updateCategory(chat: v)
                : null,
          ),

          _buildSwitchCard(
            icon: Icons.campaign_outlined,
            title: "Updates & promotions",
            subtitle:
            "News, offers, feature updates and tips.",
            value: _promoEnabled && _allEnabled,
            onChanged: _allEnabled
                ? (v) => _updateCategory(promo: v)
                : null,
          ),

          _buildSwitchCard(
            icon: Icons.warning_amber_rounded,
            title: "Emergency alerts",
            subtitle:
            "Important safety or emergency notifications.",
            value: _emergencyEnabled && _allEnabled,
            onChanged: _allEnabled
                ? (v) =>
                _updateCategory(emergency: v)
                : null,
          ),

          const SizedBox(height: 12),
          const Text(
            "You can also control app‑level notification permissions "
                "from your device settings.",
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    ValueChanged<bool>? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.brandMain),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.brandDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.brandMain,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 2),
      ),
    );
  }
}