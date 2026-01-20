import 'dart:async';
import 'dart:developer';
import 'dart:ui' as html;
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
import 'achievement/achievement_service.dart';
import 'localization/app_localizations_delegate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarColor: Colors.transparent,
  ));

  try {
    await dotenv.load(fileName: ".env");
    log("Environment variables loaded");

    log("Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log("Firebase initialized successfully");

// ✅ add this
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }

    await _initializeServices();

    runApp(const FindUsApp());

  } catch (error, stackTrace) {
    log("Fatal error during initialization: $error",
        error: error, stackTrace: stackTrace);

    runApp(const _ErrorApp());
  }
}

Future<void> _initializeServices() async {
  const timeoutDuration = Duration(seconds: 10);

  final services = [
    ThemeService.loadTheme(),
    BadgeService.init(),
    ProfileStatusService.init(),
    AppConfigService.init(),
    SavedService.init(),
    AchievementService.init(),
  ];

  for (var service in services) {
    try {
      await service.timeout(timeoutDuration);
    } catch (e) {
      log("Service initialization failed: $e");
    }
  }
}

class _ErrorApp extends StatelessWidget {
  const _ErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.brandMain,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Please restart the app. If the problem persists, contact support.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    if (kIsWeb) {
                      html.window.location.reload(); // full reload (best)
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.brandMain,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FindUsApp extends StatelessWidget {
  const FindUsApp({super.key});

  ThemeData get _lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF38B6FF),
      onPrimary: Colors.white,
      secondary: Color(0xFF003F67),
      surface: Colors.white,
      error: Colors.red,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF003F67)),
      titleTextStyle: TextStyle(
        color: Color(0xFF003F67),
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
      centerTitle: false,
      scrolledUnderElevation: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF38B6FF),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Color(0xFF003F67),
        fontFamily: 'Poppins',
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFF003F67),
        fontFamily: 'Poppins',
        height: 1.3,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        fontFamily: 'Poppins',
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF38B6FF), width: 2),
      ),
    ),
  );

  ThemeData get _darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF38B6FF),
      onPrimary: Colors.white,
      secondary: Color(0xFF2C2C2C),
      surface: Color(0xFF2C2C2C),
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandMain,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        fontFamily: 'Poppins',
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: 'Poppins',
        height: 1.3,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.white70,
        fontFamily: 'Poppins',
        height: 1.5,
      ),
    ),
    cardTheme: CardThemes.darkCardTheme,
    dividerTheme: DividerThemeData(
      color: Colors.grey[700],
      thickness: 1,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, themeSettings, _) {
        final isDark = themeSettings.isDarkMode;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FINDUS',
          theme: _lightTheme,
          darkTheme: _darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          // Localization
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

          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(1.0),
              ),
              child: child ?? const SizedBox(),
            );
          },
        );
      },
    );
  }
}