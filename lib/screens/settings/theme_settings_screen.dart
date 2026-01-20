// lib/screens/settings/theme_settings_screen.dart
// পুরোনো ThemeSettingsScreen কোডটি একই রাখুন
// কিন্তু এটাতে শুধু কার্ড থিম অপশনগুলো সরিয়ে ফেলুন

// বা নতুনভাবে তৈরি করুন যেটা শুধু অ্যাডভান্সড থিম সেটিংস দেখাবে:

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/settings/subscription_screen.dart';

class ThemeSettingsScreen extends StatefulWidget {
  final String workerKey;
  final bool isfree;
  final String subscriptionType;

  const ThemeSettingsScreen({
    super.key,
    required this.workerKey,
    this.isfree = true,
    required this.subscriptionType,
  });

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  bool _isDarkMode = false;
  bool _isAutoTheme = true;
  bool _isHighContrast = false;
  bool _isReducedMotion = false;
  double _fontSize = 1.0;

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Ensure we're in a mounted state before calling setState
      if (!mounted) return;

      setState(() {
        _isDarkMode = prefs.getBool('theme_dark_mode') ?? false;
        _isAutoTheme = prefs.getBool('theme_auto_mode') ?? true;
        _isHighContrast = prefs.getBool('theme_high_contrast') ?? false;
        _isReducedMotion = prefs.getBool('theme_reduced_motion') ?? false;
        _fontSize = prefs.getDouble('theme_font_size') ?? 1.0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load theme settings: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _saveThemeSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    } catch (_) {
      // ignore
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
            SizedBox(width: 10),
            Text(
              'Upgrade to Premium',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Premium Theme Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildFeatureItem('Dark Mode Control'),
            _buildFeatureItem('Auto Theme Following'),
            _buildFeatureItem('Font Size Adjustment'),
            _buildFeatureItem('High Contrast Mode'),
            _buildFeatureItem('Reduced Motion'),
            const SizedBox(height: 15),
            const Text(
              'Unlock all advanced theme settings!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(feature, style: const TextStyle(fontSize: 14)),
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
                            "THEME SETTINGS",
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

                    // Premium Badge for free users
                    if (widget.isfree)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              "PRO",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    bool disabled = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        activeColor: widget.isfree ? Colors.grey : Colors.blue,
        onChanged: disabled ? null : onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        secondary: Icon(icon, color: widget.isfree ? Colors.grey : Colors.blue),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: widget.isfree ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: widget.isfree ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    required IconData icon,
    bool disabled = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: widget.isfree ? Colors.grey : Colors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: widget.isfree ? Colors.grey : Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: widget.isfree ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.isfree ? Colors.grey : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 4,
            onChanged: disabled ? null : onChanged,
            activeColor: widget.isfree ? Colors.grey : Colors.blue,
            inactiveColor: Colors.grey.shade300,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Small',
                style: TextStyle(
                  color: widget.isfree ? Colors.grey : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              Text(
                'Large',
                style: TextStyle(
                  color: widget.isfree ? Colors.grey : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // Main Content
          ListView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            children: [
              // Advanced Theme Settings
              _buildSectionTitle("ADVANCED THEME SETTINGS"),

              const SizedBox(height: 10),

              // Free users info
              if (widget.isfree)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Advanced theme settings are available only for premium users.',
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              _buildSwitchTile(
                title: "Dark Mode",
                subtitle: "Switch to dark theme",
                value: _isDarkMode,
                onChanged: (value) {
                  if (widget.isfree) {
                    _showUpgradeDialog();
                    return;
                  }
                  setState(() {
                    _isDarkMode = value;
                  });
                  _saveThemeSetting('theme_dark_mode', value);
                },
                icon: Icons.dark_mode,
                disabled: widget.isfree,
              ),

              _buildSwitchTile(
                title: "Auto Theme",
                subtitle: "Follow system theme",
                value: _isAutoTheme,
                onChanged: (value) {
                  if (widget.isfree) {
                    _showUpgradeDialog();
                    return;
                  }
                  setState(() {
                    _isAutoTheme = value;
                  });
                  _saveThemeSetting('theme_auto_mode', value);
                },
                icon: Icons.brightness_auto,
                disabled: widget.isfree,
              ),

              _buildSliderTile(
                title: "Font Size",
                subtitle: "Adjust text size",
                value: _fontSize,
                min: 0.8,
                max: 1.2,
                onChanged: (value) {
                  if (widget.isfree) {
                    _showUpgradeDialog();
                    return;
                  }
                  setState(() {
                    _fontSize = value;
                  });
                  _saveThemeSetting('theme_font_size', value);
                },
                icon: Icons.format_size,
                disabled: widget.isfree,
              ),

              _buildSwitchTile(
                title: "High Contrast",
                subtitle: "Increase contrast for readability",
                value: _isHighContrast,
                onChanged: (value) {
                  if (widget.isfree) {
                    _showUpgradeDialog();
                    return;
                  }
                  setState(() {
                    _isHighContrast = value;
                  });
                  _saveThemeSetting('theme_high_contrast', value);
                },
                icon: Icons.contrast,
                disabled: widget.isfree,
              ),

              _buildSwitchTile(
                title: "Reduced Motion",
                subtitle: "Minimize animations",
                value: _isReducedMotion,
                onChanged: (value) {
                  if (widget.isfree) {
                    _showUpgradeDialog();
                    return;
                  }
                  setState(() {
                    _isReducedMotion = value;
                  });
                  _saveThemeSetting('theme_reduced_motion', value);
                },
                icon: Icons.motion_photos_off,
                disabled: widget.isfree,
              ),

              const SizedBox(height: 25),

              // Reset to Default Button
              if (!widget.isfree)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        _isDarkMode = false;
                        _isAutoTheme = true;
                        _isHighContrast = false;
                        _isReducedMotion = false;
                        _fontSize = 1.0;
                      });
                      // Reset all settings
                      _saveThemeSetting('theme_dark_mode', false);
                      _saveThemeSetting('theme_auto_mode', true);
                      _saveThemeSetting('theme_high_contrast', false);
                      _saveThemeSetting('theme_reduced_motion', false);
                      _saveThemeSetting('theme_font_size', 1.0);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Theme settings reset to default'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restart_alt, color: Colors.black54),
                    ),
                    title: const Text(
                      "Reset to Default",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: const Text(
                      "Reset all theme settings",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),

              // Upgrade Banner for free users
              if (widget.isfree)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Unlock Advanced Themes",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Get all advanced theme settings",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SubscriptionScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.amber,
                                minimumSize: const Size(double.infinity, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'UPGRADE NOW',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),

          // Floating AppBar
          _buildFloatingAppBar(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 5),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          if (widget.isfree)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "PRO",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}