import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

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

    setState(() {
      _allEnabled = prefs.getBool(_keyAll) ?? true;
      _jobsEnabled = prefs.getBool(_keyJobs) ?? true;
      _chatEnabled = prefs.getBool(_keyChat) ?? true;
      _promoEnabled = prefs.getBool(_keyPromo) ?? true;
      _emergencyEnabled = prefs.getBool(_keyEmergency) ?? true;
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
      final anyOn = _jobsEnabled || _chatEnabled || _promoEnabled || _emergencyEnabled;
      _allEnabled = anyOn;
    });
    _savePrefs();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingScaffold(
      title: "NOTIFICATIONS",
      backgroundColor: AppColors.bgBlue,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.brandMain),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Master Switch ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SwitchListTile(
              title: const Text(
                "All Notifications",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                  fontSize: 16,
                ),
              ),
              subtitle: const Text(
                "Turn all FINDUS notifications on or off.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              value: _allEnabled,
              onChanged: _updateAll,
              activeThumbColor: AppColors.brandMain,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandMain.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_rounded,
                    color: AppColors.brandMain),
              ),
            ),
          ),

          const SizedBox(height: 25),
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 10),
            child: Text(
              "NOTIFICATION TYPES",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // --- Category Switches ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.work_outline_rounded,
                  title: "Jobs & Support",
                  subtitle: "New jobs or relevant posts near you.",
                  value: _jobsEnabled && _allEnabled,
                  onChanged: _allEnabled ? (v) => _updateCategory(jobs: v) : null,
                  color: Colors.blue,
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: "Chat Messages",
                  subtitle: "Messages, replies and updates.",
                  value: _chatEnabled && _allEnabled,
                  onChanged: _allEnabled ? (v) => _updateCategory(chat: v) : null,
                  color: Colors.green,
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.campaign_rounded,
                  title: "Updates & Promo",
                  subtitle: "News, offers and feature tips.",
                  value: _promoEnabled && _allEnabled,
                  onChanged: _allEnabled ? (v) => _updateCategory(promo: v) : null,
                  color: Colors.orange,
                ),
                _buildDivider(),
                _buildSwitchTile(
                  icon: Icons.warning_amber_rounded,
                  title: "Emergency Alerts",
                  subtitle: "Safety or emergency notifications.",
                  value: _emergencyEnabled && _allEnabled,
                  onChanged: _allEnabled ? (v) => _updateCategory(emergency: v) : null,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "Note: You can also control app-level notification permissions directly from your device settings.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required Color color,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.brandMain,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onChanged == null ? Colors.grey.withOpacity(0.1) : color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: onChanged == null ? Colors.grey : color,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: onChanged == null ? Colors.grey : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Colors.grey.shade200,
      indent: 60,
      endIndent: 20,
    );
  }
}