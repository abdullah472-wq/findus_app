import 'package:flutter/material.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/locale_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedCode = 'en';

  @override
  void initState() {
    super.initState();
    _selectedCode = LocaleService.localeNotifier.value.languageCode; // en / bn
  }

  Future<void> _onChange(String code) async {
    setState(() => _selectedCode = code);
    await LocaleService.updateLocale(code);

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _showComingSoon(String language) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$language is coming soon!"),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ডার্ক মোড চেক
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final titleColor = isDark ? Colors.white : AppColors.brandDark;

    return FloatingScaffold(
      title: 'LANGUAGE',
      backgroundColor: bgColor,
      titleColor: titleColor,
      iconColor: titleColor,
      showBack: true,
      scrollable: true,
      bodyPadding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      body: Column(
        children: [
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: cardColor,
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
                // ✅ সক্রিয় ভাষা
                _buildLanguageTile(
                  title: "English",
                  code: "en",
                  textColor: textColor,
                  isDark: isDark,
                  isActive: true,
                ),
                _buildDivider(isDark),
                _buildLanguageTile(
                  title: "বাংলা",
                  code: "bn",
                  textColor: textColor,
                  isDark: isDark,
                  isActive: true,
                ),

                _buildDivider(isDark),

                // 🚧 আসন্ন ভাষা (Coming Soon)
                _buildLanguageTile(
                  title: "हिन्दी (Hindi)",
                  code: "hi",
                  textColor: textColor,
                  isDark: isDark,
                  isActive: false,
                ),
                _buildDivider(isDark),
                _buildLanguageTile(
                  title: "Español (Spanish)",
                  code: "es",
                  textColor: textColor,
                  isDark: isDark,
                  isActive: false,
                ),
                _buildDivider(isDark),
                _buildLanguageTile(
                  title: "Français (French)",
                  code: "fr",
                  textColor: textColor,
                  isDark: isDark,
                  isActive: false,
                ),
                _buildDivider(isDark),
                _buildLanguageTile(
                  title: "العربية (Arabic)",
                  code: "ar",
                  textColor: textColor,
                  isDark: isDark,
                  isActive: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "Changing the language will reload the app to apply changes.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Reusable Tile Widget
  Widget _buildLanguageTile({
    required String title,
    required String code,
    required Color textColor,
    required bool isDark,
    required bool isActive,
  }) {
    return ListTile(
      title: Row(
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isActive ? textColor : textColor.withOpacity(0.5)
            ),
          ),
          if (!isActive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.withOpacity(0.5)),
              ),
              child: const Text(
                "SOON",
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ),
          ]
        ],
      ),
      leading: Radio<String>(
        value: code,
        groupValue: _selectedCode,
        activeColor: AppColors.brandMain,
        fillColor: WidgetStateProperty.resolveWith(
              (states) {
            if (!isActive) return Colors.grey.withOpacity(0.3); // ডিজেবল লুক
            return states.contains(WidgetState.selected)
                ? AppColors.brandMain
                : (isDark ? Colors.grey : Colors.black54);
          },
        ),
        onChanged: isActive
            ? (v) { if (v != null) _onChange(v); }
            : null, // ডিজেবল হলে ক্লিক কাজ করবে না
      ),
      onTap: () {
        if (isActive) {
          _onChange(code);
        } else {
          _showComingSoon(title.split(' ')[0]); // শুধু নামটা দেখাবে (ব্র্যাকেট ছাড়া)
        }
      },
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
        height: 0,
        indent: 16,
        endIndent: 16,
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200
    );
  }
}