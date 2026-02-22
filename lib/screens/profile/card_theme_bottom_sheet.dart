// lib/widgets/card_theme_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:findus_app/screens/settings/subscription_screen.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/settings/theme_settings_screen.dart';
import 'package:findus_app/services/theme_service.dart';

class CardThemeBottomSheet extends StatefulWidget {
  final String userId;
  final int initialColorIndex;
  final bool isfree;
  final String subscriptionType;
  final Function(int) onThemeChanged;

  const CardThemeBottomSheet({
    super.key,
    required this.userId,
    required this.initialColorIndex,
    this.isfree = true,
    required this.subscriptionType,
    required this.onThemeChanged,
  });

  @override
  State<CardThemeBottomSheet> createState() => _CardThemeBottomSheetState();
}

class _CardThemeBottomSheetState extends State<CardThemeBottomSheet>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  bool _isSaving = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // ════════════════════════════════════════════════════════════════════════════
  // THEME DATA
  // ════════════════════════════════════════════════════════════════════════════

  final List<CardTheme> _themes = const [
    CardTheme(
      name: 'Teal',
      gradient: [Color(0xFFB2EBF2), Color(0xFFFFFFFF)],
      icon: Icons.water_drop,
      description: 'Cool & Fresh',
    ),
    CardTheme(
      name: 'Orange',
      gradient: [Color(0xFFFFCC80), Color(0xFFFFFFFF)],
      icon: Icons.wb_sunny,
      description: 'Warm & Energetic',
    ),
    CardTheme(
      name: 'Indigo',
      gradient: [Color(0xFFC5CAE9), Color(0xFFFFFFFF)],
      icon: Icons.nightlight,
      description: 'Professional',
    ),
    CardTheme(
      name: 'Pink',
      gradient: [Color(0xFFF8BBD0), Color(0xFFFFFFFF)],
      icon: Icons.favorite,
      description: 'Soft & Gentle',
    ),
    CardTheme(
      name: 'Purple',
      gradient: [Color(0xFFE1BEE7), Color(0xFFFFFFFF)],
      icon: Icons.auto_awesome,
      description: 'Creative',
    ),
    CardTheme(
      name: 'Green',
      gradient: [Color(0xFFC8E6C9), Color(0xFFFFFFFF)],
      icon: Icons.eco,
      description: 'Natural',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialColorIndex.clamp(0, _themes.length - 1);

    // Animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SAVE THEME
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _saveThemeIndexToUserDoc(int index) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) throw Exception('Not logged in');
    if (currentUid != widget.userId) throw Exception('Unauthorized');

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .set({
      'cardThemeIndex': index,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _onSelect(int index) async {
    if (_isSaving) return; // Prevent double tap

    // Free users - show upgrade dialog
    if (widget.isfree) {
      _showUpgradeDialog();
      return;
    }

    // Already selected
    if (_selectedIndex == index) {
      _showAlreadySelectedMessage();
      return;
    }

    // Animate selection
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    setState(() {
      _selectedIndex = index;
      _isSaving = true;
    });

    try {
      await _saveThemeIndexToUserDoc(index);
      widget.onThemeChanged(index);

      if (mounted) {
        _showSuccessMessage(index);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(e.toString());
        // Revert to previous selection
        setState(() {
          _selectedIndex = widget.initialColorIndex;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // MESSAGES
  // ════════════════════════════════════════════════════════════════════════════

  void _showSuccessMessage(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Card theme changed to ${_themes[index].name}'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text('Failed: $error')),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAlreadySelectedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text('This theme is already selected'),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // UPGRADE DIALOG
  // ════════════════════════════════════════════════════════════════════════════

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Upgrade to Pro',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unlock Premium Features:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem('6 Custom Card Themes', Icons.palette),
            _buildFeatureItem('Advanced Theme Settings', Icons.settings),
            _buildFeatureItem('Dark Mode Control', Icons.dark_mode),
            _buildFeatureItem('Font Customization', Icons.text_fields),
            _buildFeatureItem('AMOLED Black Mode', Icons.smartphone),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Limited time offer: 30% off!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(feature, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD COLOR CIRCLE
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildColorCircle({
    required int index,
    required bool isSelected,
    required bool canSelect,
    required _SheetColors colors,
  }) {
    final theme = _themes[index];
    final isLocked = !canSelect;

    return GestureDetector(
      onTap: () => _onSelect(index),
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Theme Circle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: theme.gradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? (colors.isDark ? Colors.white : AppColors.brandMain)
                          : Colors.grey.shade300,
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.brandMain.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: isLocked
                      ? Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 24,
                      color: Colors.white,
                    ),
                  )
                      : Center(
                    child: Icon(
                      theme.icon,
                      size: 20,
                      color: Colors.black54,
                    ),
                  ),
                ),

                // Selection Check
                if (isSelected && !isLocked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.brandMain,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // Saving Indicator
                if (_isSaving && isSelected && !isLocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Theme Name
            Text(
              theme.name,
              style: TextStyle(
                fontSize: 12,
                color: isLocked
                    ? Colors.grey
                    : (isSelected ? AppColors.brandMain : colors.textColor),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),

            // Description
            Text(
              theme.description,
              style: TextStyle(
                fontSize: 9,
                color: colors.subTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, settings, _) {
        final colors = _SheetColors(
          isDark: settings.isDarkMode,
          useAmoled: settings.useAmoledBlack,
        );

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.5,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colors.bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ═══════════════════════════════════════════════════════════
                  // HANDLE BAR
                  // ═══════════════════════════════════════════════════════════
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.subTextColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // ═══════════════════════════════════════════════════════════
                  // HEADER
                  // ═══════════════════════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.isfree
                                ? Colors.grey.withOpacity(0.2)
                                : AppColors.brandMain.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.palette,
                            color: widget.isfree
                                ? Colors.grey
                                : AppColors.brandMain,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Card Theme",
                                style: TextStyle(
                                  color: widget.isfree
                                      ? Colors.grey
                                      : colors.textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                "Customize your profile card",
                                style: TextStyle(
                                  color: colors.subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.isfree)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.shade400,
                                  Colors.amber.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lock, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  "PRO",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ═══════════════════════════════════════════════════════════
                  // CONTENT
                  // ═══════════════════════════════════════════════════════════
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Preview Section
                            _buildPreviewCard(colors),

                            const SizedBox(height: 25),

                            // Grid of Themes
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 20,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: _themes.length,
                              itemBuilder: (context, index) {
                                return _buildColorCircle(
                                  index: index,
                                  isSelected: index == _selectedIndex,
                                  canSelect: !widget.isfree,
                                  colors: colors,
                                );
                              },
                            ),

                            const SizedBox(height: 25),

                            // More Settings Button
                            _buildMoreSettingsButton(colors),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Preview Card
  Widget _buildPreviewCard(_SheetColors colors) {
    final selectedTheme = _themes[_selectedIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: selectedTheme.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              selectedTheme.icon,
              color: Colors.black87,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Theme',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedTheme.name,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  selectedTheme.description,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.visibility,
                  size: 14,
                  color: Colors.black87,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Preview',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// More Settings Button
  Widget _buildMoreSettingsButton(_SheetColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ThemeSettingsScreen(
                  workerKey: widget.userId,
                  isfree: widget.isfree,
                  subscriptionType: widget.subscriptionType,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.brandMain.withOpacity(0.2),
                        AppColors.brandMain.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: AppColors.brandMain,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Advanced Theme Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colors.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dark mode, fonts, AMOLED & more',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: colors.subTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MODELS
// ════════════════════════════════════════════════════════════════════════════

class CardTheme {
  final String name;
  final List<Color> gradient;
  final IconData icon;
  final String description;

  const CardTheme({
    required this.name,
    required this.gradient,
    required this.icon,
    required this.description,
  });
}

class _SheetColors {
  final bool isDark;
  final bool useAmoled;

  _SheetColors({required this.isDark, this.useAmoled = false});

  Color get bgColor {
    if (isDark && useAmoled) return Colors.black;
    if (isDark) return const Color(0xFF1E1E1E);
    return Colors.white;
  }

  Color get cardColor {
    if (isDark && useAmoled) return const Color(0xFF0A0A0A);
    if (isDark) return const Color(0xFF2C2C2C);
    return Colors.grey.shade50;
  }

  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  Color get borderColor => isDark ? Colors.grey.shade800 : Colors.grey.shade200;
}