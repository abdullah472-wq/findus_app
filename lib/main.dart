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
import 'package:provider/provider.dart';

import 'constants/card_themes.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'badge/badge_service.dart';
import 'services/theme_service.dart';
import 'services/profile_status_service.dart';
import 'services/app_config_service.dart';
import 'services/saved_service.dart';
import 'services/blocked_user_service.dart';
import 'services/push_notification_service.dart';
import 'achievement/achievement_service.dart';

import 'localization/localization_wrapper.dart';
import 'localization/app_localizations_delegate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    log("Flutter Error: ${details.exception}", stackTrace: details.stack);
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runZonedGuarded(() async {
    try {
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        log("Warning: .env file missing");
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (kIsWeb) {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: false,
        );
      }

      await _initializeAllServices();

      runApp(
        ChangeNotifierProvider(
          create: (_) => LocalizationWrapper(),
          child: const FindUsApp(),
        ),
      );
    } catch (error, stackTrace) {
      log("Fatal Initialization Error", error: error, stackTrace: stackTrace);
      runApp(const _ErrorApp());
    }
  }, (error, stack) {
    log("Async Error: $error", stackTrace: stack);
  });
}

Future<void> _initializeAllServices() async {
  try {
    await Future.wait([
      ThemeService.loadTheme(),
      AppConfigService.init(),
      BadgeService.init(),
      PushNotificationService.init(),
    ]).timeout(const Duration(seconds: 5));

    await Future.wait([
      ProfileStatusService.init(),
      SavedService.init(),
      AchievementService.init(),
      BlockedUserService().syncWithFirestore(),
    ]).timeout(const Duration(seconds: 5));

    log("All services initialized successfully");
  } catch (e) {
    log("Service Init Warning: $e");
  }
}

class FindUsApp extends StatelessWidget {
  const FindUsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationWrapper = Provider.of<LocalizationWrapper>(context);

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

          locale: localizationWrapper.locale,
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('bn', 'BD'),
          ],
          localizationsDelegates: const [
            AppLocalizationDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          home: const MySplashScreen(),

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

  // ✅ ফিক্সড থিম মেথড (as dynamic ব্যবহার করে বাইপাস করা হয়েছে)
  ThemeData _getTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamily: 'Poppins',
      colorSchemeSeed: const Color(0xFF38B6FF),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
      ),

      // ✅ সরাসরি cardTheme সেট করো, কোনো cast ছাড়াই
      cardTheme: isDark
          ? AppCardThemes.darkCardTheme
          : AppCardThemes.lightCardTheme,
    );
  }
}

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