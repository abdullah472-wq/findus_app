import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/locale_service.dart';

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
    _selectedCode =
        LocaleService.localeNotifier.value.languageCode; // en / bn
  }

  Future<void> _onChange(String code) async {
    setState(() {
      _selectedCode = code;
    });
    await LocaleService.updateLocale(code);

    // চাইলে সাথে সাথে পপ করে দিতে পারো
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlue,
      appBar: AppBar(
        backgroundColor: AppColors.brandLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brandDark),
        title: const Text(
          "Language",
          style: TextStyle(
            color: AppColors.brandDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
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
          const Divider(height: 0),
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
    );
  }
}