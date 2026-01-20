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
      body: Stack(
        children: [
          // Main Content
          ListView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
              left: 0,
              right: 0,
              bottom: 20,
            ),
            children: [
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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

          // Floating AppBar (KYC-style)
          Positioned(
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
                              size: 20,
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
                                  "Language",
                                  style: TextStyle(
                                    color: AppColors.brandDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}