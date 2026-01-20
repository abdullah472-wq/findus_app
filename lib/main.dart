// main.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'firebase_options.dart';
import 'splash_screen.dart';
import 'constants/app_colors.dart';
import 'constants/card_themes.dart';
import 'badge/badge_service.dart';
import 'services/theme_service.dart';
import 'services/profile_status_service.dart';
import 'services/app_config_service.dart';
import 'services/saved_service.dart';
import 'services/blocked_user_service.dart'; // ✅ নতুন সার্ভিস
import 'achievement/achievement_service.dart';
import 'localization/app_localizations_delegate.dart';

Future<void> main() async {
  // ১. ফ্লাটার ইঞ্জিন ইনিশিয়ালাইজেশন
  WidgetsFlutterBinding.ensureInitialized();

  // ২. গ্লোবাল এরর হ্যান্ডলিং (Production Grade)
  FlutterError.onError = (details) {
    log("Flutter Error: ${details.exception}", stackTrace: details.stack);
    // এখানে চাইলে Sentry বা Firebase Crashlytics যোগ করতে পারেন
  };

  // ৩. স্ক্রিন এবং সিস্টেম ইউআই সেটিংস
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // ৪. অ্যাপ ইনিশিয়ালাইজেশন ব্লক
  runZonedGuarded(() async {
    try {
      // .env লোড
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        log("Warning: .env file missing");
      }

      // ফায়ারবেস ইনিশিয়ালাইজেশন
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // ফায়ারস্টোর ওয়েব সেটিংস
      if (kIsWeb) {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: false,
        );
      }

      // সার্ভিসগুলো ইনিশিয়ালাইজ করা
      await _initializeAllServices();

      runApp(const FindUsApp());
    } catch (error, stackTrace) {
      log("Fatal Initialization Error", error: error, stackTrace: stackTrace);
      runApp(const _ErrorApp());
    }
  }, (error, stack) {
    log("Async Error: $error", stackTrace: stack);
  });
}

/// সব সার্ভিসগুলো একসাথে লোড করার জন্য প্রোফেশনাল মেথড
Future<void> _initializeAllServices() async {
  // কিছু সার্ভিস ডিপেন্ডেন্সি থাকতে পারে, তাই গ্রুপিং করে লোড করা ভালো
  try {
    await Future.wait([
      ThemeService.loadTheme(),
      AppConfigService.init(),
      BadgeService.init(),
    ]).timeout(const Duration(seconds: 5));

    // সেকেন্ডারি সার্ভিস (এগুলো আগের গুলোর ওপর ডিপেন্ড করতে পারে)
    await Future.wait([
      ProfileStatusService.init(),
      SavedService.init(),
      AchievementService.init(),
      BlockedUserService().syncWithFirestore(), // ✅ ব্লক লিস্ট ক্লাউড থেকে সিঙ্ক
    ]).timeout(const Duration(seconds: 5));

    log("All services initialized successfully");
  } catch (e) {
    log("Service Init Warning: $e");
    // সার্ভিস ফেইল করলেও অ্যাপ যেন ওপেন হয়
  }
}

class FindUsApp extends StatelessWidget {
  const FindUsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, themeSettings, _) {
        final isDark = themeSettings.isDarkMode;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FINDUS',
          theme: _getTheme(false),
          darkTheme: _getTheme(true),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('bn', 'BD'),
          ],
          locale: const Locale('en', 'US'),

          home: const MySplashScreen(),

          // গ্লোবাল টেক্সট স্কেলিং ফিক্স
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.noScaling,
              ),
              child: child ?? const SizedBox(),
            );
          },
        );
      },
    );
  }

  // থিম জেনারেটর মেথড (কোড ক্লিন রাখার জন্য)
  ThemeData _getTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamily: 'Poppins',
      colorSchemeSeed: const Color(0xFF38B6FF), // আপনার ব্র্যান্ড কালার
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: isDark ? CardThemes.darkCardTheme : const CardTheme(
        color: Colors.white,
        elevation: 1,
      ),
    );
  }
}

/// fatal এরর স্ক্রিন
class _ErrorApp extends StatelessWidget {
  const _ErrorApp();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF38B6FF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 80),
              const SizedBox(height: 20),
              const Text('System Error', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Failed to connect to FINDUS servers. Please check your internet.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
                child: const Text('Close App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}