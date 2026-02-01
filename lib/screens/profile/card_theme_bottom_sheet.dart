import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:findus_app/screens/settings/subscription_screen.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/screens/settings/theme_settings_screen.dart';

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

class _CardThemeBottomSheetState extends State<CardThemeBottomSheet> {
  late int _selectedIndex;

  final List<List<Color>> _gradients = const [
    [Color(0xFFB2EBF2), Color(0xFFFFFFFF)], // teal/light blue
    [Color(0xFFFFCC80), Color(0xFFFFFFFF)], // orange
    [Color(0xFFC5CAE9), Color(0xFFFFFFFF)], // indigo
    [Color(0xFFF8BBD0), Color(0xFFFFFFFF)], // pink
  ];

  final List<String> _gradientNames = const [
    'Teal',
    'Orange',
    'Indigo',
    'Pink',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialColorIndex.clamp(0, _gradients.length - 1);
  }

  Future<void> _saveThemeIndexToUserDoc(int index) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) throw Exception('Not logged in');
    if (currentUid != widget.userId) throw Exception('Unauthorized');

    await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
      'cardThemeIndex': index,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _onSelect(int index) async {
    if (widget.isfree) {
      _showUpgradeDialog();
      return;
    }

    setState(() => _selectedIndex = index);

    try {
      await _saveThemeIndexToUserDoc(index);
      widget.onThemeChanged(index);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Card theme changed to ${_gradientNames[index]}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
            SizedBox(width: 10),
            Text('Upgrade to Pro', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Premium Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildFeatureItem('Custom Card Themes'),
            _buildFeatureItem('Advanced Theme Settings'),
            _buildFeatureItem('Dark Mode Control'),
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
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white),
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

  Widget _buildColorCircle(int index, bool isSelected, bool canSelect, bool isDark) {
    final colors = _gradients[index];
    final isLocked = !canSelect;

    // ✅ টেক্সট কালার লজিক
    final textColor = isLocked
        ? Colors.grey
        : (isDark ? Colors.white70 : Colors.black87);

    return GestureDetector(
      onTap: () => _onSelect(index),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60, // সাইজ একটু ছোট করা হয়েছে যাতে গ্রিডে সুন্দর দেখায়
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    // সিলেকশন বর্ডার কালার
                    color: isSelected ? (isDark ? Colors.white : AppColors.brandMain) : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: isLocked
                    ? Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, size: 20, color: Colors.white),
                )
                    : null,
              ),
              if (isSelected && !isLocked)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.brandMain,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _gradientNames[index],
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ডার্ক মোড ভেরিয়েবলস
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white; // শিটের ব্যাকগ্রাউন্ড
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              // হ্যান্ডেল বার
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.color_lens,
                      color: widget.isfree ? Colors.grey : AppColors.brandMain,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Card Theme",
                        style: TextStyle(
                          color: widget.isfree ? Colors.grey : textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
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
                            Text("PRO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Select your profile card theme',
                          style: TextStyle(color: subTextColor, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Preview Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _gradients[_selectedIndex],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.preview, color: Colors.black54, size: 30),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Current Theme',
                                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      _gradientNames[_selectedIndex],
                                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Preview',
                                  style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Grid of Themes
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.8, // Adjusted specifically for layout
                          ),
                          itemCount: _gradients.length,
                          itemBuilder: (context, index) {
                            return _buildColorCircle(
                              index,
                              index == _selectedIndex,
                              !widget.isfree,
                              isDark,
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // More Settings Button
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: ListTile(
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
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.brandMain.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.settings, color: AppColors.brandMain, size: 20),
                            ),
                            title: Text(
                              'Full Theme Settings',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
                            ),
                            subtitle: Text(
                              'Dark mode, fonts & more',
                              style: TextStyle(fontSize: 11, color: subTextColor),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor),
                          ),
                        ),

                        const SizedBox(height: 20),
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
  }
}