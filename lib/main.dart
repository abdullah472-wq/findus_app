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
import 'constants/app_colors.dart'; // ✅ AppColors ইমপোর্ট নিশ্চিত করুন
import 'firebase_options.dart';
import 'splash_screen.dart';

// Services
import 'badge/badge_service.dart';
import 'services/theme_service.dart'; // ✅ ThemeService
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
    await Future.wait([
      ThemeService.loadTheme(), // ✅ থিম লোড হচ্ছে
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

// ✅ StatefulWidget এ কনভার্ট করা হয়েছে (System Theme Listener এর জন্য)
class FindUsApp extends StatefulWidget {
  const FindUsApp({super.key});

  @override
  State<FindUsApp> createState() => _FindUsAppState();
}

class _FindUsAppState extends State<FindUsApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    // সিস্টেম থিম পরিবর্তনের জন্য লিসেনার যোগ করা
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ফোন সেটিংসে ডার্ক মোড অন/অফ করলে এটা কল হবে
  @override
  void didChangePlatformBrightness() {
    ThemeService.onSystemThemeChanged();
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    final localizationWrapper = Provider.of<LocalizationWrapper>(context);

    // ✅ ValueListenableBuilder দিয়ে রিবিল্ড করা হচ্ছে
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, themeSettings, _) {
        final isDark = themeSettings.isDarkMode;

        // স্ট্যাটাস বারের স্টাইল আপডেট
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ));

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FINDUS',

          // ১. থিম কনফিগারেশন
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

          // ২. ফন্ট স্কেলিং (Settings Page এর স্লাইডার অনুযায়ী কাজ করবে)
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                // ✅ noScaling এর বদলে ডাইনামিক স্কেলিং
                textScaler: TextScaler.linear(themeSettings.fontSize),
              ),
              child: child ?? const SizedBox(),
            );
          },
        );
      },
    );
  }

  // ✅ আপডেটেড থিম মেথড
  ThemeData _getTheme(bool isDark, ThemeSettings settings) {
    // High Contrast Logic
    final primaryColor = settings.isHighContrast
        ? (isDark ? Colors.white : Colors.black)
        : const Color(0xFF38B6FF);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamily: 'Poppins',
      colorSchemeSeed: primaryColor,

      // ✅ লাইট মোডে Settings Page এর মতো ব্যাকগ্রাউন্ড কালার
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : AppColors.bgBlue,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppColors.bgBlue,
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
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold
                  )
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF38B6FF),
                ),
                child: const Text('Close App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}