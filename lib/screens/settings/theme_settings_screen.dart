import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';
import 'package:findus_app/screens/settings/subscription_screen.dart';
import 'package:findus_app/services/theme_service.dart'; // ✅ সার্ভিস ইম্পোর্ট

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
            _FeatureRow('Dark Mode Control'),
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
    // ✅ ValueListenableBuilder: সার্ভিস আপডেট হলে UI সাথে সাথে বদলাবে
    return ValueListenableBuilder<ThemeSettings>(
        valueListenable: ThemeService.themeSettings,
        builder: (context, settings, _) {

          return FloatingScaffold(
            title: "THEME SETTINGS",
            backgroundColor: AppColors.bgBlue,
            showBack: true,
            scrollable: true,
            bodyPadding: const EdgeInsets.all(16),

            // প্রো ব্যাজ (ফ্রি ইউজারদের জন্য)
            actions: [
              if (isfree)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text("PRO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],

            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // প্রোমো ব্যানার
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
                              Text("Upgrade to unlock Dark Mode, Fonts & more.", style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 10),
                  child: Text("APPEARANCE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
                ),

                // সেটিংস গ্রুপ ১: থিম মোড
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      _buildSwitchTile(
                          "Dark Mode",
                          "Switch to dark theme",
                          Icons.dark_mode_rounded,
                          settings.isDarkMode,
                              (val) {
                            // ✅ সরাসরি সার্ভিস কল
                            ThemeService.updateThemeSetting(isDarkMode: val);
                          },
                          Colors.indigo,
                          context
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                          "Auto Theme",
                          "Follow system settings",
                          Icons.brightness_auto_rounded,
                          settings.isAutoTheme,
                              (val) {
                            ThemeService.updateThemeSetting(isAutoTheme: val);
                          },
                          Colors.teal,
                          context
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 10),
                  child: Text("ACCESSIBILITY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
                ),

                // সেটিংস গ্রুপ ২: অ্যাক্সেসিবিলিটি
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                          context
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                          "High Contrast",
                          "Increase visibility",
                          Icons.contrast_rounded,
                          settings.isHighContrast,
                              (val) {
                            ThemeService.updateThemeSetting(isHighContrast: val);
                          },
                          Colors.deepOrange,
                          context
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                          "Reduced Motion",
                          "Minimize animations",
                          Icons.motion_photos_off_rounded,
                          settings.isReducedMotion,
                              (val) {
                            ThemeService.updateThemeSetting(isReducedMotion: val);
                          },
                          Colors.purple,
                          context
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // রিসেট বাটন (শুধুমাত্র প্রিমিয়াম ইউজারদের জন্য)
                if (!isfree)
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        // সব ডিফল্ট ভ্যালুতে রিসেট
                        ThemeService.updateThemeSetting(
                          isDarkMode: false,
                          isAutoTheme: true,
                          isHighContrast: false,
                          isReducedMotion: false,
                          fontSize: 1.0,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Theme reset to default")));
                      },
                      icon: const Icon(Icons.refresh, color: Colors.grey),
                      label: const Text("Reset to Default", style: TextStyle(color: Colors.grey)),
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

  Widget _buildSwitchTile(String title, String sub, IconData icon, bool value, Function(bool) onChanged, Color color, BuildContext context) {
    return SwitchListTile(
      value: value,
      activeThumbColor: AppColors.brandMain,
      onChanged: (val) {
        if (isfree) {
          _showUpgradeDialog(context);
        } else {
          onChanged(val);
        }
      },
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: isfree ? Colors.grey : color, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isfree ? Colors.grey : Colors.black87)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    );
  }

  Widget _buildSliderTile(String title, IconData icon, Color color, double currentValue, Function(double) onChanged, BuildContext context) {
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
                child: Icon(icon, color: isfree ? Colors.grey : color, size: 22),
              ),
              const SizedBox(width: 16),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isfree ? Colors.grey : Colors.black87)),
              const Spacer(),
              Text("${(currentValue * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: isfree ? Colors.grey : AppColors.brandMain)),
            ],
          ),
          Slider(
            value: currentValue,
            min: 0.8, max: 1.2, divisions: 4,
            activeColor: isfree ? Colors.grey : AppColors.brandMain,
            onChanged: (val) {
              if (isfree) {
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

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200, indent: 60, endIndent: 20);
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