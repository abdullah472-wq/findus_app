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
    if (currentUid == null) {
      throw Exception('Not logged in');
    }
    if (currentUid != widget.userId) {
      throw Exception('Unauthorized');
    }

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

    setState(() {
      _selectedIndex = index;
    });

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
          SnackBar(
            content: Text('Theme change failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
            const Text('Premium Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildFeatureItem('Custom Card Themes (কার্ড থিম)'),
            _buildFeatureItem('Advanced Theme Settings'),
            _buildFeatureItem('Dark Mode Control'),
            _buildFeatureItem('Font Size Adjustment'),
            const SizedBox(height: 15),
            const Text('Unlock all premium features!', style: TextStyle(fontWeight: FontWeight.bold)),
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
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
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

  Widget _buildColorCircle(int index, bool isSelected, bool canSelect) {
    final colors = _gradients[index];
    final isLocked = !canSelect;

    return GestureDetector(
      onTap: () => _onSelect(index),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: isLocked
                    ? Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, size: 24, color: Colors.white),
                )
                    : null,
              ),
              if (isSelected && !isLocked)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _gradientNames[index],
            style: TextStyle(
              fontSize: 12,
              color: isLocked ? Colors.grey : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected && !isLocked)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandMain.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'বর্তমান',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.brandMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canSelectColors = !widget.isfree;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
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
                        "কার্ড থিম",
                        style: TextStyle(
                          color: widget.isfree ? Colors.grey : Colors.black87,
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

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'প্রোফাইল কার্ডের থিম সিলেক্ট করুন',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

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
                              const Icon(Icons.preview, color: Colors.white, size: 30),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'বর্তমান থিম',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      _gradientNames[_selectedIndex],
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'প্রিভিউ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: _gradients.length,
                          itemBuilder: (context, index) {
                            final isLocked = widget.isfree;
                            return _buildColorCircle(
                              index,
                              index == _selectedIndex,
                              !isLocked,
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      ThemeSettingsScreen(
                                        workerKey: widget.userId,
                                        isfree: widget.isfree,
                                        subscriptionType: widget.subscriptionType,
                                      ),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.ease;
                                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                    var offsetAnimation = animation.drive(tween);
                                    return SlideTransition(position: offsetAnimation, child: child);
                                  },
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
                            title: const Text(
                              'ফুল থিম সেটিংস',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            subtitle: const Text(
                              'ডার্ক মোড, ফন্ট সাইজ এবং আরও সেটিংস',
                              style: TextStyle(fontSize: 11),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
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