import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'splash_screen.dart';

import 'constants/app_colors.dart';
import 'services/badge_service.dart';
import 'services/theme_service.dart';
import 'services/profile_status_service.dart';
import 'services/app_config_service.dart';
import 'services/locale_service.dart';
import 'package:findus_app/services/saved_service.dart';
import 'package:findus_app/achievement/achievement_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase + ThemeService লোড
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await ThemeService.loadTheme();

  await BadgeService.init();
  await ProfileStatusService.init();
  await AppConfigService.init();
  await LocaleService.init();
  await SavedService.init();
  await AchievementService.init();

  runApp(const FindUsApp());
}

class FindUsApp extends StatelessWidget {
  const FindUsApp({super.key});

  // --- লাইট থিম কনফিগারেশন ---
  ThemeData get _lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'GoogleFonts.poppins',
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF38B6FF),
      onPrimary: Colors.white,
      secondary: Color(0xFF003F67),
      surface: Colors.white,
      background: Color(0xFFE0F7FA),
    ),
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF003F67)),
      titleTextStyle: TextStyle(
        color: Color(0xFF003F67),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF38B6FF),
        foregroundColor: Colors.white,
      ),
    ),
  );

  // --- ডার্ক থিম কনফিগারেশন (ডার্ক গ্রে ফিক্সড) ---
  ThemeData get _darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1E1E1E), // ডার্ক গ্রে ব্যাকগ্রাউন্ড
    cardColor: const Color(0xFF2C2C2C),              // কার্ডের জন্য হালকা ডার্ক গ্রে
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF38B6FF),                    // প্রাইমারি কালার হিসেবে ব্লু রাখা হয়েছে
      onPrimary: Colors.white,
      secondary: Color(0xFF2C2C2C),
      surface: Color(0xFF2C2C2C),
      background: Color(0xFF1E1E1E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandMain,
        foregroundColor: Colors.white,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkMode,
      builder: (context, isDark, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleService.localeNotifier,
          builder: (context, currentLocale, __) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'FINDUS',
              theme: _lightTheme,
              darkTheme: _darkTheme,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light, // ডার্ক মোড লজিক
              locale: currentLocale,
              supportedLocales: const [
                Locale('en'),
                Locale('bn'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // MySplashScreen এর জায়গায় আপনার আসল স্প্ল্যাশ স্ক্রিন দিন
              home: const MySplashScreen(),
            );
          },
        );
      },
    );
  }
}