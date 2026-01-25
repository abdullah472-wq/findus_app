import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/screens/settings/subscription_screen.dart';
import 'package:findus_app/services/theme_service.dart';

class ThemeSettingsScreen extends StatelessWidget {
  final String workerKey;
  final bool isfree;
  final String subscriptionType;

  const ThemeSettingsScreen({
    super.key,
    required this.workerKey,
    this.isfree = true,
    required this.subscriptionType,
  });

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
            SizedBox(width: 10),
            Text('Upgrade to Pro', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unlock advanced theme features:'),
            SizedBox(height: 10),
            _FeatureRow('Auto Theme Sync'),
            _FeatureRow('Font Size Adjustment'),
            _FeatureRow('High Contrast & Motion'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandMain, foregroundColor: Colors.white),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
        valueListenable: ThemeService.themeSettings,
        builder: (context, settings, _) {

          // ✅ ডার্ক মোড কালার লজিক
          final isDark = settings.isDarkMode;
          final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
          final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
          final textColor = isDark ? Colors.white : Colors.black87;
          final subTextColor = isDark ? Colors.white54 : Colors.grey;

          return FloatingScaffold(
            title: "THEME SETTINGS",
            backgroundColor: bgColor,
            titleColor: isDark ? Colors.white : AppColors.brandDark,
            iconColor: isDark ? Colors.white : AppColors.brandDark,
            showBack: true,
            scrollable: true,
            bodyPadding: const EdgeInsets.all(16),

            // ✅ App Bar থেকে PRO ব্যাজ সরিয়ে ফেলা হয়েছে
            actions: const [],

            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // প্রোমো ব্যানার (শুধুমাত্র যদি ইউজার ফ্রি হয়)
                if (isfree)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.amber.shade300, Colors.orange.shade400]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.palette, color: Colors.white, size: 30),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Customize Your Look", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 4),
                              Text("Upgrade to unlock Auto Theme, Fonts & more.", style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 10),
                  child: Text("APPEARANCE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: subTextColor, letterSpacing: 1.2)),
                ),

                // সেটিংস গ্রুপ ১: থিম মোড
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      // ✅ Dark Mode এখন সবার জন্য ফ্রি
                      _buildSwitchTile(
                          "Dark Mode",
                          "Switch to dark theme",
                          Icons.dark_mode_rounded,
                          settings.isDarkMode,
                              (val) {
                            ThemeService.updateThemeSetting(isDarkMode: val);
                          },
                          Colors.indigo,
                          context,
                          isLocked: false, // লক নেই
                          textColor: textColor,
                          subTextColor: subTextColor
                      ),
                      _buildDivider(isDark),
                      // Auto Theme প্রিমিয়াম
                      _buildSwitchTile(
                          "Auto Theme",
                          "Follow system settings",
                          Icons.brightness_auto_rounded,
                          settings.isAutoTheme,
                              (val) {
                            ThemeService.updateThemeSetting(isAutoTheme: val);
                          },
                          Colors.teal,
                          context,
                          isLocked: isfree, // লক আছে
                          textColor: textColor,
                          subTextColor: subTextColor
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 10),
                  child: Text("ACCESSIBILITY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: subTextColor, letterSpacing: 1.2)),
                ),

                // সেটিংস গ্রুপ ২: অ্যাক্সেসিবিলিটি (এগুলো প্রিমিয়াম)
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      _buildSliderTile(
                          "Font Size",
                          Icons.format_size_rounded,
                          Colors.blue,
                          settings.fontSize,
                              (val) {
                            ThemeService.updateThemeSetting(fontSize: val);
                          },
                          context,
                          isLocked: isfree,
                          textColor: textColor
                      ),
                      _buildDivider(isDark),
                      _buildSwitchTile(
                          "High Contrast",
                          "Increase visibility",
                          Icons.contrast_rounded,
                          settings.isHighContrast,
                              (val) {
                            ThemeService.updateThemeSetting(isHighContrast: val);
                          },
                          Colors.deepOrange,
                          context,
                          isLocked: isfree,
                          textColor: textColor,
                          subTextColor: subTextColor
                      ),
                      _buildDivider(isDark),
                      _buildSwitchTile(
                          "Reduced Motion",
                          "Minimize animations",
                          Icons.motion_photos_off_rounded,
                          settings.isReducedMotion,
                              (val) {
                            ThemeService.updateThemeSetting(isReducedMotion: val);
                          },
                          Colors.purple,
                          context,
                          isLocked: isfree,
                          textColor: textColor,
                          subTextColor: subTextColor
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // রিসেট বাটন (সবার জন্য কাজ করবে এখন, যেহেতু ডার্ক মোড ফ্রি)
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      ThemeService.updateThemeSetting(
                        isDarkMode: false,
                        isAutoTheme: true,
                        isHighContrast: false,
                        isReducedMotion: false,
                        fontSize: 1.0,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Theme reset to default")));
                    },
                    icon: Icon(Icons.refresh, color: subTextColor),
                    label: Text("Reset to Default", style: TextStyle(color: subTextColor)),
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          );
        }
    );
  }

  // --- হেল্পার উইজেট ---

  Widget _buildSwitchTile(
      String title,
      String sub,
      IconData icon,
      bool value,
      Function(bool) onChanged,
      Color color,
      BuildContext context, {
        required bool isLocked,
        required Color textColor,
        required Color subTextColor
      }) {
    return SwitchListTile(
      value: value,
      activeThumbColor: AppColors.brandMain,
      activeTrackColor: AppColors.brandMain.withOpacity(0.3),
      onChanged: (val) {
        if (isLocked) {
          _showUpgradeDialog(context);
        } else {
          onChanged(val);
        }
      },
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: isLocked ? Colors.grey : color, size: 22),
      ),
      title: Row(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isLocked ? Colors.grey : textColor)),
          if (isLocked) ...[
            const SizedBox(width: 8),
            const Icon(Icons.lock, size: 14, color: Colors.amber),
          ]
        ],
      ),
      subtitle: Text(sub, style: TextStyle(fontSize: 11, color: isLocked ? Colors.grey.shade400 : subTextColor)),
    );
  }

  Widget _buildSliderTile(
      String title,
      IconData icon,
      Color color,
      double currentValue,
      Function(double) onChanged,
      BuildContext context, {
        required bool isLocked,
        required Color textColor
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: isLocked ? Colors.grey : color, size: 22),
              ),
              const SizedBox(width: 16),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isLocked ? Colors.grey : textColor)),
              if (isLocked) ...[
                const SizedBox(width: 8),
                const Icon(Icons.lock, size: 14, color: Colors.amber),
              ],
              const Spacer(),
              Text("${(currentValue * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: isLocked ? Colors.grey : AppColors.brandMain)),
            ],
          ),
          Slider(
            value: currentValue,
            min: 0.8, max: 1.2, divisions: 4,
            activeColor: isLocked ? Colors.grey : AppColors.brandMain,
            onChanged: (val) {
              if (isLocked) {
                _showUpgradeDialog(context);
              } else {
                onChanged(val);
              }
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("A", style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              Text("A", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, thickness: 0.5, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, indent: 60, endIndent: 20);
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}