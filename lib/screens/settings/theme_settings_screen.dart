import 'package:flutter/material.dart';
import 'package:findus_app/services/profile_color_service.dart';

class ThemeSettingsScreen extends StatefulWidget {
  final String workerKey;         // কোন worker এর রঙ বদলাবে
  final int initialColorIndex;    // এখনকার index
  final bool isPro;               // প্রো ইউজার কিনা

  const ThemeSettingsScreen({
    super.key,
    required this.workerKey,
    required this.initialColorIndex,
    this.isPro = true,            // এখন ডিফল্টভাবে সবাই প্রো; পরে সাবস্ক্রিপশন লাগালে ভাগ করে নেবে
  });

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  late int _selectedIndex;

  final List<List<Color>> _gradients = const [
    [Color(0xFFB2EBF2), Color(0xFFE0F7FA)], // teal/light blue
    [Color(0xFFFFCC80), Color(0xFFFFE0B2)], // orange
    [Color(0xFFC5CAE9), Color(0xFFE8EAF6)], // indigo
    [Color(0xFFF8BBD0), Color(0xFFFCE4EC)], // pink
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialColorIndex.clamp(0, _gradients.length - 1);
  }

  Future<void> _onSelect(int index) async {
    if (!widget.isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is a Pro feature. Upgrade to change card color.'),
        ),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    await ProfileColorService.setColorIndex(widget.workerKey, index);

    // caller কে নতুন index রিটার্ন করব
    if (mounted) {
      Navigator.pop(context, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Theme'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile card color',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(_gradients.length, (i) {
                final colors = _gradients[i];
                final bool isSelected = i == _selectedIndex;
                return GestureDetector(
                  onTap: () => _onSelect(i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.white,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            if (!widget.isPro)
              const Text(
                'Only Pro users can customize their profile card color.',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}