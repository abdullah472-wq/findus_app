import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/locale_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedCode = 'en';

  @override
  void initState() {
    super.initState();
    _selectedCode = LocaleService.localeNotifier.value.languageCode; // en / bn
  }

  Future<void> _onChange(String code) async {
    setState(() {
      _selectedCode = code;
    });
    await LocaleService.updateLocale(code);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingScaffold(
      title: 'Language',
      backgroundColor: AppColors.bgBlue,
      titleColor: AppColors.brandDark,
      iconColor: AppColors.brandDark,
      showBack: true,
      scrollable: false,
      bodyPadding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text(
                    'English',
                    style: TextStyle(fontSize: 16),
                  ),
                  leading: Radio<String>(
                    value: 'en',
                    groupValue: _selectedCode,
                    activeColor: AppColors.brandMain,
                    onChanged: (v) {
                      if (v == null) return;
                      _onChange(v);
                    },
                  ),
                  onTap: () => _onChange('en'),
                ),
                const Divider(height: 0, indent: 16, endIndent: 16),
                ListTile(
                  title: const Text(
                    'বাংলা',
                    style: TextStyle(fontSize: 16),
                  ),
                  leading: Radio<String>(
                    value: 'bn',
                    groupValue: _selectedCode,
                    activeColor: AppColors.brandMain,
                    onChanged: (v) {
                      if (v == null) return;
                      _onChange(v);
                    },
                  ),
                  onTap: () => _onChange('bn'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}