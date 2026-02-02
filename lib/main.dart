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

  // গ্লোবাল এরর হ্যান্ডলিং
  FlutterError.onError = (details) {
    log("Flutter Error: ${details.exception}", stackTrace: details.stack);
  };

  // শুধুমাত্র পোর্ট্রেট মোড
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // সেইফ জোন এক্সিকিউশন
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

// প্যারালাল সার্ভিস ইনিশিয়ালাইজেশন (ফাস্ট স্টার্টআপের জন্য)
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

class FindUsApp extends StatefulWidget {
  const FindUsApp({super.key});

  @override
  State<FindUsApp> createState() => _FindUsAppState();
}

class _FindUsAppState extends State<FindUsApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // সিস্টেম থিম পরিবর্তনের লিসেনার
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

        // ✅ স্ট্যাটাস বার কালার কনফিগারেশন (মডার্ন লুক)
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDark ? const Color(0xFF1A1A1A) : Colors.white, // নিচে নেভিগেশন বার কালার ম্যাচিং
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ));

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FINDUS',

          // থিম মোড
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: _getTheme(false, themeSettings),
          darkTheme: _getTheme(true, themeSettings),

          // লোকালাইজেশন
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

          // ডাইনামিক ফন্ট স্কেলিং
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
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

  // ✅ থিম মেথড (কালার ম্যাচিং আপডেট করা হয়েছে)
  ThemeData _getTheme(bool isDark, ThemeSettings settings) {
    final primaryColor = settings.isHighContrast
        ? (isDark ? Colors.white : Colors.black)
        : const Color(0xFF38B6FF); // AppColors.brandMain

    // ✅ ডার্ক মোডের জন্য সেইম কালার ব্যবহার করা হয়েছে যা Settings/Subscription পেজে ছিল
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

      // বাটন থিম
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

// গ্লোবাল এরর স্ক্রিন
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