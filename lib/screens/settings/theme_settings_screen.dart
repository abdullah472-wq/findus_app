// lib/screens/settings/theme_settings_screen.dart

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

  // ════════════════════════════════════════════════════════════════════════════
  // UPGRADE DIALOG
  // ════════════════════════════════════════════════════════════════════════════

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
            SizedBox(height: 12),
            _FeatureRow(icon: Icons.brightness_auto, text: 'Auto Theme Sync'),
            _FeatureRow(icon: Icons.format_size, text: 'Font Size Adjustment'),
            _FeatureRow(icon: Icons.contrast, text: 'High Contrast Mode'),
            _FeatureRow(icon: Icons.motion_photos_off, text: 'Reduced Motion'),
            _FeatureRow(icon: Icons.palette, text: 'Accent Colors'),
            _FeatureRow(icon: Icons.dark_mode, text: 'AMOLED Black'),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // RESET CONFIRMATION DIALOG
  // ════════════════════════════════════════════════════════════════════════════

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.orange, size: 24),
            SizedBox(width: 10),
            Text("Reset Settings?"),
          ],
        ),
        content: const Text(
          "This will restore all theme settings to their default values. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ThemeService.resetToDefault();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text("Theme reset to default"),
                    ],
                  ),
                  backgroundColor: Colors.green.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD METHOD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, settings, _) {
        // ✅ Theme Colors Setup
        final isDark = settings.isDarkMode;
        final colors = _ThemeColors(isDark: isDark, useAmoled: settings.useAmoledBlack);

        return FloatingScaffold(
          title: "THEME SETTINGS",
          backgroundColor: colors.bgColor,
          titleColor: colors.titleColor,
          iconColor: colors.iconColor,
          showBack: true,
          scrollable: true,
          bodyPadding: const EdgeInsets.all(16),
          actions: const [],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════════════════════════════════
              // PROMO BANNER (শুধু Free User দের জন্য)
              // ═══════════════════════════════════════════════════════════════
              if (isfree) _buildPromoBanner(context),

              // ═══════════════════════════════════════════════════════════════
              // SECTION: APPEARANCE
              // ═══════════════════════════════════════════════════════════════
              _buildSectionHeader("APPEARANCE", colors.subTextColor),

              _buildSettingsCard(
                colors: colors,
                children: [
                  // Dark Mode - FREE for everyone
                  _buildSwitchTile(
                    title: "Dark Mode",
                    subtitle: "Switch to dark theme",
                    icon: Icons.dark_mode_rounded,
                    value: settings.isDarkMode,
                    onChanged: (val) => ThemeService.toggleDarkMode(val),
                    color: Colors.indigo,
                    context: context,
                    isLocked: false, // ✅ সবার জন্য ফ্রি
                    colors: colors,
                  ),

                  _buildDivider(colors),

                  // Auto Theme - PREMIUM
                  _buildSwitchTile(
                    title: "Auto Theme",
                    subtitle: "Follow system settings",
                    icon: Icons.brightness_auto_rounded,
                    value: settings.isAutoTheme,
                    onChanged: (val) => ThemeService.toggleAutoTheme(val),
                    color: Colors.teal,
                    context: context,
                    isLocked: isfree,
                    colors: colors,
                  ),

                  _buildDivider(colors),

                  // AMOLED Black - PREMIUM
                  _buildSwitchTile(
                    title: "AMOLED Black",
                    subtitle: "Pure black for OLED screens",
                    icon: Icons.smartphone_rounded,
                    value: settings.useAmoledBlack,
                    onChanged: (val) => ThemeService.toggleAmoledBlack(val),
                    color: Colors.grey.shade800,
                    context: context,
                    isLocked: isfree,
                    colors: colors,
                    enabled: settings.isDarkMode, // শুধু Dark Mode এ কাজ করবে
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ═══════════════════════════════════════════════════════════════
              // SECTION: ACCENT COLOR
              // ═══════════════════════════════════════════════════════════════
              _buildSectionHeader("ACCENT COLOR", colors.subTextColor),

              _buildAccentColorCard(
                settings: settings,
                colors: colors,
                context: context,
              ),

              const SizedBox(height: 25),

              // ═══════════════════════════════════════════════════════════════
              // SECTION: ACCESSIBILITY
              // ═══════════════════════════════════════════════════════════════
              _buildSectionHeader("ACCESSIBILITY", colors.subTextColor),

              _buildSettingsCard(
                colors: colors,
                children: [
                  // Font Size - PREMIUM
                  _buildSliderTile(
                    title: "Font Size",
                    icon: Icons.format_size_rounded,
                    color: Colors.blue,
                    currentValue: settings.fontSize,
                    onChanged: (val) => ThemeService.setFontSize(val),
                    context: context,
                    isLocked: isfree,
                    colors: colors,
                  ),

                  _buildDivider(colors),

                  // High Contrast - PREMIUM
                  _buildSwitchTile(
                    title: "High Contrast",
                    subtitle: "Increase visibility",
                    icon: Icons.contrast_rounded,
                    value: settings.isHighContrast,
                    onChanged: (val) => ThemeService.toggleHighContrast(val),
                    color: Colors.deepOrange,
                    context: context,
                    isLocked: isfree,
                    colors: colors,
                  ),

                  _buildDivider(colors),

                  // Reduced Motion - PREMIUM
                  _buildSwitchTile(
                    title: "Reduced Motion",
                    subtitle: "Minimize animations",
                    icon: Icons.motion_photos_off_rounded,
                    value: settings.isReducedMotion,
                    onChanged: (val) => ThemeService.toggleReducedMotion(val),
                    color: Colors.purple,
                    context: context,
                    isLocked: isfree,
                    colors: colors,
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ═══════════════════════════════════════════════════════════════
              // SECTION: THEME PRESETS
              // ═══════════════════════════════════════════════════════════════
              _buildSectionHeader("QUICK PRESETS", colors.subTextColor),

              _buildPresetsCard(
                settings: settings,
                colors: colors,
                context: context,
              ),

              const SizedBox(height: 30),

              // ═══════════════════════════════════════════════════════════════
              // RESET BUTTON
              // ═══════════════════════════════════════════════════════════════
              Center(
                child: TextButton.icon(
                  onPressed: () => _showResetDialog(context),
                  icon: Icon(Icons.refresh, color: colors.subTextColor),
                  label: Text(
                    "Reset to Default",
                    style: TextStyle(color: colors.subTextColor),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ═══════════════════════════════════════════════════════════════
              // CURRENT SETTINGS INFO
              // ═══════════════════════════════════════════════════════════════
              _buildCurrentSettingsInfo(settings, colors),

              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ════════════════════════════════════════════════════════════════════════════

  /// Promo Banner Widget
  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade300, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showUpgradeDialog(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.palette, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Customize Your Look",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Upgrade to unlock Auto Theme, Accent Colors & more.",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  /// Section Header
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// Settings Card Container
  Widget _buildSettingsCard({
    required _ThemeColors colors,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  /// Switch Tile Widget
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
    required BuildContext context,
    required bool isLocked,
    required _ThemeColors colors,
    bool enabled = true,
  }) {
    final isDisabled = !enabled;
    final effectiveColor = isLocked || isDisabled ? Colors.grey : color;
    final effectiveTextColor = isLocked || isDisabled ? Colors.grey : colors.textColor;
    final effectiveSubColor = isLocked || isDisabled ? Colors.grey.shade400 : colors.subTextColor;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: SwitchListTile(
        value: isDisabled ? false : value,
        activeColor: AppColors.brandMain,
        activeTrackColor: AppColors.brandMain.withOpacity(0.3),
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.grey.shade300,
        onChanged: isDisabled
            ? null
            : (val) {
          if (isLocked) {
            _showUpgradeDialog(context);
          } else {
            onChanged(val);
          }
        },
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: effectiveColor, size: 22),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: effectiveTextColor,
                ),
              ),
            ),
            if (isLocked) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 12, color: Colors.amber),
                    SizedBox(width: 2),
                    Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isDisabled && !isLocked) ...[
              const SizedBox(width: 8),
              Text(
                '(Dark mode only)',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: effectiveSubColor),
        ),
      ),
    );
  }

  /// Slider Tile Widget
  Widget _buildSliderTile({
    required String title,
    required IconData icon,
    required Color color,
    required double currentValue,
    required Function(double) onChanged,
    required BuildContext context,
    required bool isLocked,
    required _ThemeColors colors,
  }) {
    final effectiveColor = isLocked ? Colors.grey : color;
    final effectiveTextColor = isLocked ? Colors.grey : colors.textColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: effectiveColor, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: effectiveTextColor,
                ),
              ),
              if (isLocked) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 12, color: Colors.amber),
                      SizedBox(width: 2),
                      Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isLocked ? Colors.grey : AppColors.brandMain).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${(currentValue * 100).toInt()}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isLocked ? Colors.grey : AppColors.brandMain,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: isLocked ? Colors.grey : AppColors.brandMain,
              inactiveTrackColor: isLocked ? Colors.grey.shade300 : AppColors.brandMain.withOpacity(0.2),
              thumbColor: isLocked ? Colors.grey : AppColors.brandMain,
            ),
            child: Slider(
              value: currentValue,
              min: 0.8,
              max: 1.4,
              divisions: 6,
              onChanged: (val) {
                if (isLocked) {
                  _showUpgradeDialog(context);
                } else {
                  onChanged(val);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "A",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "A",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Accent Color Card
  Widget _buildAccentColorCard({
    required ThemeSettings settings,
    required _ThemeColors colors,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardColor,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: settings.accentColor.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.palette_rounded,
                  color: isfree ? Colors.grey : settings.accentColor.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Choose Accent Color",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isfree ? Colors.grey : colors.textColor,
                ),
              ),
              if (isfree) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 12, color: Colors.amber),
                      SizedBox(width: 2),
                      Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AccentColor.values.map((accentColor) {
              final isSelected = settings.accentColor == accentColor;
              return GestureDetector(
                onTap: () {
                  if (isfree) {
                    _showUpgradeDialog(context);
                  } else {
                    ThemeService.setAccentColor(accentColor);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isfree ? Colors.grey.shade400 : accentColor.color,
                    shape: BoxShape.circle,
                    border: isSelected && !isfree
                        ? Border.all(
                      color: colors.isDark ? Colors.white : Colors.black,
                      width: 3,
                    )
                        : null,
                    boxShadow: isSelected && !isfree
                        ? [
                      BoxShadow(
                        color: accentColor.color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                        : null,
                  ),
                  child: isSelected && !isfree
                      ? Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 22,
                  )
                      : null,
                ),
              );
            }).toList(),
          ),
          if (!isfree) ...[
            const SizedBox(height: 12),
            Text(
              "Selected: ${settings.accentColor.displayName}",
              style: TextStyle(
                fontSize: 12,
                color: colors.subTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Theme Presets Card
  Widget _buildPresetsCard({
    required ThemeSettings settings,
    required _ThemeColors colors,
    required BuildContext context,
  }) {
    final presets = [
      _PresetItem(
        preset: ThemePreset.standard,
        icon: Icons.smartphone,
        color: Colors.blue,
      ),
      _PresetItem(
        preset: ThemePreset.highContrast,
        icon: Icons.contrast,
        color: Colors.deepOrange,
      ),
      _PresetItem(
        preset: ThemePreset.large,
        icon: Icons.text_fields,
        color: Colors.green,
      ),
      _PresetItem(
        preset: ThemePreset.amoled,
        icon: Icons.dark_mode,
        color: Colors.grey.shade800,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardColor,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: isfree ? Colors.grey : AppColors.brandMain,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Quick Apply",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isfree ? Colors.grey : colors.textColor,
                ),
              ),
              if (isfree) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 12, color: Colors.amber),
                      SizedBox(width: 2),
                      Text(
                        'PRO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: presets.map((item) {
              final isSelected = settings.themePreset == item.preset;
              return GestureDetector(
                onTap: () {
                  if (isfree) {
                    _showUpgradeDialog(context);
                  } else {
                    ThemeService.applyPreset(item.preset);
                  }
                },
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isfree
                            ? Colors.grey.shade300
                            : (isSelected
                            ? item.color.withOpacity(0.2)
                            : colors.isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100),
                        shape: BoxShape.circle,
                        border: isSelected && !isfree
                            ? Border.all(color: item.color, width: 2)
                            : null,
                      ),
                      child: Icon(
                        item.icon,
                        color: isfree
                            ? Colors.grey
                            : (isSelected ? item.color : colors.subTextColor),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.preset.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected && !isfree ? FontWeight.bold : FontWeight.normal,
                        color: isfree
                            ? Colors.grey
                            : (isSelected ? item.color : colors.subTextColor),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Current Settings Info
  Widget _buildCurrentSettingsInfo(ThemeSettings settings, _ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: colors.subTextColor),
              const SizedBox(width: 8),
              Text(
                "Current Settings",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.subTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                settings.isDarkMode ? "Dark" : "Light",
                Icons.brightness_6,
                colors,
              ),
              if (settings.isAutoTheme)
                _buildInfoChip("Auto", Icons.brightness_auto, colors),
              _buildInfoChip(
                "${(settings.fontSize * 100).toInt()}%",
                Icons.format_size,
                colors,
              ),
              _buildInfoChip(
                settings.accentColor.displayName,
                Icons.palette,
                colors,
                accentColor: settings.accentColor.color,
              ),
              if (settings.useAmoledBlack)
                _buildInfoChip("AMOLED", Icons.smartphone, colors),
              if (settings.isHighContrast)
                _buildInfoChip("High Contrast", Icons.contrast, colors),
              if (settings.isReducedMotion)
                _buildInfoChip("Reduced Motion", Icons.motion_photos_off, colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, _ThemeColors colors, {Color? accentColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (accentColor ?? colors.subTextColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accentColor ?? colors.subTextColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: accentColor ?? colors.subTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Divider Widget
  Widget _buildDivider(_ThemeColors colors) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: colors.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      indent: 60,
      endIndent: 20,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ════════════════════════════════════════════════════════════════════════════

/// Theme Colors Helper
class _ThemeColors {
  final bool isDark;
  final bool useAmoled;

  _ThemeColors({required this.isDark, this.useAmoled = false});

  Color get bgColor {
    if (isDark && useAmoled) return Colors.black;
    if (isDark) return const Color(0xFF1A1A1A);
    return AppColors.bgBlue;
  }

  Color get cardColor {
    if (isDark && useAmoled) return const Color(0xFF121212);
    if (isDark) return const Color(0xFF2C2C2C);
    return Colors.white;
  }

  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.white54 : Colors.grey;
  Color get titleColor => isDark ? Colors.white : AppColors.brandDark;
  Color get iconColor => isDark ? Colors.white : AppColors.brandDark;
}

/// Feature Row Widget (for Upgrade Dialog)
class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: Colors.green, size: 14),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

/// Preset Item Helper
class _PresetItem {
  final ThemePreset preset;
  final IconData icon;
  final Color color;

  const _PresetItem({
    required this.preset,
    required this.icon,
    required this.color,
  });
}