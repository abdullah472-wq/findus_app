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

// Constants
import 'constants/card_themes.dart';
import 'constants/app_colors.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';

// Services
import 'badge/badge_service.dart';
import 'services/theme_service.dart';
import 'services/profile_status_service.dart';
import 'services/app_config_service.dart';
import 'services/saved_service.dart';
import 'services/blocked_user_service.dart';
import 'services/push_notification_service.dart';
import 'achievement/achievement_service.dart';

// Localization
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
    log("Starting service initialization...");

    await Future.wait([
      ThemeService.loadTheme(),
      AppConfigService.init(),
      PushNotificationService.init(),
    ]).timeout(const Duration(seconds: 5));

    await BadgeService.init();
    log("BadgeService initialized");

    await AchievementService.init();
    log("AchievementService initialized");

    await Future.wait([
      ProfileStatusService.init(),
      SavedService.init(),
      BlockedUserService().syncWithFirestore(),
    ]).timeout(const Duration(seconds: 5));

    log("All services initialized successfully");
  } catch (e) {
    log("Service Init Warning: $e");
    await _sequentialInitializeServices();
  }
}

Future<void> _sequentialInitializeServices() async {
  try {
    log("Trying sequential initialization...");

    await ThemeService.loadTheme();
    log("ThemeService initialized");

    await AppConfigService.init();
    log("AppConfigService initialized");

    await BadgeService.init();
    log("BadgeService initialized");

    await AchievementService.init();
    log("AchievementService initialized");

    await PushNotificationService.init();
    log("PushNotificationService initialized");

    await ProfileStatusService.init();
    log("ProfileStatusService initialized");

    await SavedService.init();
    log("SavedService initialized");

    await BlockedUserService().syncWithFirestore();
    log("BlockedUserService initialized");

    log("Sequential initialization completed successfully");
  } catch (e) {
    log("Sequential initialization failed: $e");
    throw e;
  }
}

class FindUsApp extends StatefulWidget {
  const FindUsApp({super.key});

  @override
  State<FindUsApp> createState() => _FindUsAppState();
}

class _FindUsAppState extends State<FindUsApp> with WidgetsBindingObserver {
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkServices();
  }

  void _checkServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final achievements = AchievementService.achievementsNotifier.value;
        log("Achievements loaded: ${achievements.length}");

        final badgeProgress = BadgeService.badgeNotifier.value;
        // ✅ FIX: totalPoints -> totalXP
        log("Badge points: ${badgeProgress.totalXP}");

        setState(() {
          _servicesInitialized = true;
        });
      } catch (e) {
        log("Error checking services: $e");
        await _retryServices();
      }
    });
  }

  Future<void> _retryServices() async {
    try {
      log("Retrying service initialization...");
      await AchievementService.init();
      await BadgeService.init();
      setState(() {
        _servicesInitialized = true;
      });
      log("Services re-initialized successfully");
    } catch (e) {
      log("Failed to re-initialize services: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // ✅ FIX: BadgeService.dispose() called only if method exists
    BadgeService.dispose();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    ThemeService.onSystemThemeChanged();
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    final localizationWrapper = Provider.of<LocalizationWrapper>(context);

    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, themeSettings, _) {
        final isDark = themeSettings.isDarkMode;

        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ));

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FINDUS',
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: _getTheme(false, themeSettings),
          darkTheme: _getTheme(true, themeSettings),
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
            final mediaQuery = MediaQuery.of(context);

            if (!_servicesInitialized && child is! MySplashScreen) {
              return const Material(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(themeSettings.fontSize),
              ),
              child: child ?? const SizedBox(),
            );
          },
        );
      },
    );
  }

  ThemeData _getTheme(bool isDark, ThemeSettings settings) {
    final primaryColor = settings.isHighContrast
        ? (isDark ? Colors.white : Colors.black)
        : const Color(0xFF38B6FF);

    final scaffoldBg = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;
    final appBarBg = isDark ? const Color(0xFF1A1A1A) : AppColors.bgBlue;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamily: 'Poppins',
      colorSchemeSeed: primaryColor,
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: appBarBg,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: isDark
          ? AppCardThemes.darkCardTheme
          : AppCardThemes.lightCardTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandMain,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _ErrorApp extends StatelessWidget {
  const _ErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF38B6FF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 80),
              const SizedBox(height: 20),
              const Text(
                  'System Error',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF38B6FF)),
                child: const Text('Close App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}