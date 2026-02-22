// lib/screens/settings/language_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:findus_app/constants/app_colors.dart';
import 'package:findus_app/services/locale_service.dart';
import 'package:findus_app/services/theme_service.dart';
import 'package:findus_app/widgets/floating_scaffold.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedCode = 'en';
  bool _isChanging = false;

  // ════════════════════════════════════════════════════════════════════════════
  // LANGUAGE DATA
  // ════════════════════════════════════════════════════════════════════════════

  final List<_LanguageItem> _languages = [
    // Active Languages
    _LanguageItem(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
      isActive: true,
      completionPercent: 100,
    ),
    _LanguageItem(
      code: 'bn',
      name: 'Bengali',
      nativeName: 'বাংলা',
      flag: '🇧🇩',
      isActive: true,
      completionPercent: 95,
    ),

    // Coming Soon Languages
    _LanguageItem(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
      isActive: false,
      completionPercent: 40,
    ),
    _LanguageItem(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
      isActive: false,
      completionPercent: 25,
    ),
    _LanguageItem(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
      isActive: false,
      completionPercent: 15,
    ),
    _LanguageItem(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
      isActive: false,
      completionPercent: 10,
      isRTL: true,
    ),
    _LanguageItem(
      code: 'ur',
      name: 'Urdu',
      nativeName: 'اردو',
      flag: '🇵🇰',
      isActive: false,
      completionPercent: 5,
      isRTL: true,
    ),
    _LanguageItem(
      code: 'ne',
      name: 'Nepali',
      nativeName: 'नेपाली',
      flag: '🇳🇵',
      isActive: false,
      completionPercent: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCode = LocaleService.localeNotifier.value.languageCode;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LANGUAGE CHANGE
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _confirmAndChange(String code) async {
    if (code == _selectedCode) return;

    final language = _languages.firstWhere((l) => l.code == code);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildConfirmDialog(ctx, language),
    );

    if (confirm != true || !mounted) return;

    await _changeLanguage(code);
  }

  Future<void> _changeLanguage(String code) async {
    setState(() => _isChanging = true);

    HapticFeedback.mediumImpact();

    try {
      await LocaleService.updateLocale(code);

      if (!mounted) return;

      setState(() {
        _selectedCode = code;
        _isChanging = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text("Language changed to ${_languages.firstWhere((l) => l.code == code).name}"),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Pop after short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isChanging = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to change language: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showComingSoon(_LanguageItem language) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildComingSoonSheet(ctx, language),
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
        final colors = _LanguageColors(
          isDark: settings.isDarkMode,
          useAmoled: settings.useAmoledBlack,
        );

        final activeLanguages = _languages.where((l) => l.isActive).toList();
        final comingSoonLanguages = _languages.where((l) => !l.isActive).toList();

        return FloatingScaffold(
          title: 'LANGUAGE',
          backgroundColor: colors.bgColor,
          titleColor: colors.textColor,
          iconColor: colors.textColor,
          showBack: true,
          scrollable: true,
          bodyPadding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          body: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══════════════════════════════════════════════════════════
                  // CURRENT LANGUAGE CARD
                  // ═══════════════════════════════════════════════════════════
                  _buildCurrentLanguageCard(colors),

                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════════
                  // AVAILABLE LANGUAGES
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionHeader("Available Languages", colors),
                  const SizedBox(height: 12),

                  _buildLanguageList(activeLanguages, colors),

                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════════
                  // COMING SOON
                  // ═══════════════════════════════════════════════════════════
                  _buildSectionHeader("Coming Soon", colors),
                  const SizedBox(height: 12),

                  _buildLanguageList(comingSoonLanguages, colors),

                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════════
                  // HELP TRANSLATE
                  // ═══════════════════════════════════════════════════════════
                  _buildHelpTranslateCard(colors),

                  const SizedBox(height: 20),

                  // Info Text
                  _buildInfoText(colors),

                  const SizedBox(height: 30),
                ],
              ),

              // Loading Overlay
              if (_isChanging) _buildLoadingOverlay(colors),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // WIDGET BUILDERS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildCurrentLanguageCard(_LanguageColors colors) {
    final currentLang = _languages.firstWhere(
          (l) => l.code == _selectedCode,
      orElse: () => _languages.first,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandMain,
            AppColors.brandMain.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandMain.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                currentLang.flag,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Current Language",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentLang.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentLang.nativeName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, _LanguageColors colors) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: colors.subTextColor,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildLanguageList(List<_LanguageItem> languages, _LanguageColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: languages.asMap().entries.map((entry) {
          final index = entry.key;
          final language = entry.value;
          final isLast = index == languages.length - 1;

          return Column(
            children: [
              _buildLanguageTile(language, colors),
              if (!isLast) _buildDivider(colors),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageTile(_LanguageItem language, _LanguageColors colors) {
    final isSelected = _selectedCode == language.code;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (language.isActive) {
            _confirmAndChange(language.code);
          } else {
            _showComingSoon(language);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Flag
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: language.isActive
                      ? (isSelected
                      ? AppColors.brandMain.withOpacity(0.1)
                      : colors.isDark
                      ? Colors.white10
                      : Colors.grey.shade100)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    language.flag,
                    style: TextStyle(
                      fontSize: 24,
                      color: language.isActive ? null : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Language Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          language.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: language.isActive
                                ? colors.textColor
                                : colors.textColor.withOpacity(0.5),
                          ),
                        ),
                        if (!language.isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${language.completionPercent}%",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                        if (language.isRTL) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "RTL",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      language.nativeName,
                      style: TextStyle(
                        fontSize: 13,
                        color: language.isActive
                            ? colors.subTextColor
                            : colors.subTextColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Selection Indicator
              if (language.isActive)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brandMain
                        : colors.isDark
                        ? Colors.white10
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? null
                        : Border.all(
                      color: colors.isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                      : null,
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: colors.subTextColor.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(_LanguageColors colors) {
    return Divider(
      height: 1,
      indent: 74,
      endIndent: 16,
      color: colors.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
    );
  }

  Widget _buildHelpTranslateCard(_LanguageColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.isDark
              ? Colors.blue.withOpacity(0.2)
              : Colors.blue.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.translate,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Help Us Translate",
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Contribute to FINDUS translations and help users worldwide!",
                  style: TextStyle(
                    color: colors.subTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              // TODO: Open translation portal
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Translation portal coming soon!")),
              );
            },
            icon: Icon(
              Icons.arrow_forward,
              color: colors.subTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(_LanguageColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline,
          size: 14,
          color: colors.subTextColor,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            "Changing language will apply immediately",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colors.subTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay(_LanguageColors colors) {
    return Positioned.fill(
      child: Container(
        color: colors.bgColor.withOpacity(0.8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.brandMain),
              const SizedBox(height: 16),
              Text(
                "Changing language...",
                style: TextStyle(
                  color: colors.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DIALOGS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildConfirmDialog(BuildContext ctx, _LanguageItem language) {
    final colors = _LanguageColors(
      isDark: Theme.of(ctx).brightness == Brightness.dark,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colors.cardColor,
      title: Row(
        children: [
          Text(language.flag, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Change Language?",
              style: TextStyle(
                color: colors.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Change app language to ${language.name} (${language.nativeName})?",
            style: TextStyle(color: colors.textColor),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: colors.subTextColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "The app will update to use the new language immediately.",
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.subTextColor,
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
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            "Cancel",
            style: TextStyle(color: colors.subTextColor),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.check, size: 18),
          label: Text("Change to ${language.name}"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandMain,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComingSoonSheet(BuildContext ctx, _LanguageItem language) {
    final colors = _LanguageColors(
      isDark: Theme.of(ctx).brightness == Brightness.dark,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.subTextColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Flag
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.isDark ? Colors.white10 : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                language.flag,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            "${language.name} Coming Soon!",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textColor,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            language.nativeName,
            style: TextStyle(
              fontSize: 16,
              color: colors.subTextColor,
            ),
          ),
          const SizedBox(height: 20),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Translation Progress",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.textColor,
                    ),
                  ),
                  Text(
                    "${language.completionPercent}%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandMain,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: language.completionPercent / 100,
                  backgroundColor:
                  colors.isDark ? Colors.white10 : Colors.grey.shade200,
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.brandMain),
                  minHeight: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Notify Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Colors.white),
                      const SizedBox(width: 10),
                      Text("We'll notify you when ${language.name} is ready!"),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
            label: const Text("Notify Me When Ready"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Help Translate Button
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Translation portal coming soon!")),
              );
            },
            icon: const Icon(Icons.translate),
            label: const Text("Help Translate"),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textColor,
              side: BorderSide(
                color: colors.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(ctx).padding.bottom + 10),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ════════════════════════════════════════════════════════════════════════════

class _LanguageColors {
  final bool isDark;
  final bool useAmoled;

  _LanguageColors({required this.isDark, this.useAmoled = false});

  Color get bgColor {
    if (isDark && useAmoled) return Colors.black;
    if (isDark) return const Color(0xFF1A1A1A);
    return AppColors.bgBlue;
  }

  Color get cardColor {
    if (isDark && useAmoled) return const Color(0xFF0A0A0A);
    if (isDark) return const Color(0xFF2C2C2C);
    return Colors.white;
  }

  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.grey.shade400 : Colors.grey.shade600;
}

class _LanguageItem {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isActive;
  final int completionPercent;
  final bool isRTL;

  const _LanguageItem({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.isActive,
    required this.completionPercent,
    this.isRTL = false,
  });
}