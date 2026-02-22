// lib/main.dart

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, kReleaseMode;
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Constants
import 'constants/card_themes.dart';
import 'constants/app_colors.dart'; // ✅ Only import from here
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

/// ═══════════════════════════════════════════════════════════════════════════
/// MAIN ENTRY POINT
/// ═══════════════════════════════════════════════════════════════════════════
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Global error handler
  FlutterError.onError = (details) {
    log(
      "Flutter Error: ${details.exception}",
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // ✅ Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runZonedGuarded(() async {
    try {
      // ✅ Load .env (optional)
      await _loadEnvironment();

      // ✅ Initialize Firebase
      await _initializeFirebase();

      // ✅ Initialize Push Notifications (Firebase এর পরে!)
      await PushNotificationService.init(navKey: navigatorKey);

      // ✅ Initialize all other services
      await _initializeAllServices();

      // ✅ Run app
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocalizationWrapper()),
          ],
          child: const FindUsApp(),  // 👈 navigatorKey পাস করতে হবে
        ),
      );
    } catch (error, stackTrace) {
      _handleFatalError(error, stackTrace);
    }
  }, (error, stack) {
    log("❌ Async Error: $error", error: error, stackTrace: stack);
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// INITIALIZATION HELPERS
/// ═══════════════════════════════════════════════════════════════════════════

Future<void> _loadEnvironment() async {
  try {
    await dotenv.load(fileName: ".env");
    if (kDebugMode) log("✅ .env loaded");
  } catch (e) {
    if (kDebugMode) log("⚠️ .env file missing (optional) - $e");
  }
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) log("✅ Firebase initialized");

    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
      if (kDebugMode) log("✅ Firestore persistence disabled (Web)");
    }
  } catch (e, stack) {
    log("❌ Firebase initialization failed", error: e, stackTrace: stack);
    rethrow;
  }
}

Future<void> _initializeAllServices() async {
  try {
    if (kDebugMode) log("🚀 Starting service initialization...");

    try {
      await _parallelInitializeServices();
    } on TimeoutException {
      if (kDebugMode) {
        log("⏱️ Parallel initialization timeout - falling back to sequential");
      }
      await _sequentialInitializeServices();
    } catch (e) {
      if (kDebugMode) {
        log("⚠️ Parallel initialization failed - falling back to sequential: $e");
      }
      await _sequentialInitializeServices();
    }

    if (kDebugMode) log("✅ Service initialization completed");
  } catch (e, stack) {
    log("❌ Service initialization error", error: e, stackTrace: stack);
  }
}

Future<void> _parallelInitializeServices() async {
  await Future.wait(
    [
      ThemeService.init().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          if (kDebugMode) log("⏱️ ThemeService timeout");
          throw TimeoutException("ThemeService timeout");
        },
      ),
      AppConfigService.init().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          if (kDebugMode) log("⏱️ AppConfigService timeout");
          throw TimeoutException("AppConfigService timeout");
        },
      ),
      BadgeService.init().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          if (kDebugMode) log("⏱️ BadgeService timeout");
          throw TimeoutException("BadgeService timeout");
        },
      ),
      AchievementService.init().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          if (kDebugMode) log("⏱️ AchievementService timeout");
          throw TimeoutException("AchievementService timeout");
        },
      ),
    ],
    eagerError: true,
  ).timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      if (kDebugMode) log("⏱️ Overall parallel initialization timeout");
      throw TimeoutException("Overall parallel initialization timeout");
    },
  );

  if (kDebugMode) log("✅ Essential services initialized (parallel)");

  _initializeOptionalServices();
}

Future<void> _sequentialInitializeServices() async {
  try {
    if (kDebugMode) log("🔄 Starting sequential initialization...");

    try {
      await ThemeService.init();
      if (kDebugMode) log("✅ ThemeService initialized");
    } catch (e) {
      if (kDebugMode) log("⚠️ ThemeService failed: $e");
    }

    try {
      await AppConfigService.init();
      if (kDebugMode) log("✅ AppConfigService initialized");
    } catch (e) {
      if (kDebugMode) log("⚠️ AppConfigService failed: $e");
    }

    try {
      await BadgeService.init();
      if (kDebugMode) log("✅ BadgeService initialized");
    } catch (e) {
      if (kDebugMode) log("⚠️ BadgeService failed: $e");
    }

    try {
      await AchievementService.init();
      if (kDebugMode) log("✅ AchievementService initialized");
    } catch (e) {
      if (kDebugMode) log("⚠️ AchievementService failed: $e");
    }

    _initializeOptionalServices();

    if (kDebugMode) log("✅ Sequential initialization completed");
  } catch (e, stack) {
    log("❌ Sequential initialization failed", error: e, stackTrace: stack);
  }
}

void _initializeOptionalServices() {
  ProfileStatusService.init().catchError((e) {
    if (kDebugMode) log("⚠️ ProfileStatusService failed: $e");
  });

  SavedService.init().catchError((e) {
    if (kDebugMode) log("⚠️ SavedService failed: $e");
  });

  BlockedUserService().syncWithFirestore().catchError((e) {
    if (kDebugMode) log("⚠️ BlockedUserService failed: $e");
  });

  if (kDebugMode) log("🔄 Optional services initializing in background...");
}

void _handleFatalError(Object error, StackTrace stackTrace) {
  log(
    "❌ Fatal Initialization Error",
    error: error,
    stackTrace: stackTrace,
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _ErrorScreen(
        error: error.toString(),
        stackTrace: stackTrace.toString(),
      ),
    ),
  );
}

/// ═══════════════════════════════════════════════════════════════════════════
/// MAIN APP
/// ═══════════════════════════════════════════════════════════════════════════

class FindUsApp extends StatefulWidget {
  const FindUsApp({super.key});

  @override
  State<FindUsApp> createState() => _FindUsAppState();
}

class _FindUsAppState extends State<FindUsApp> with WidgetsBindingObserver {
  bool _servicesInitialized = false;
  bool _isFirstLaunch = true;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 2;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // ✅ FIX: Use correct type for connectivity_plus
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePushNotifications();
    _listenToConnectivity();
    _checkServices();
    _checkAppVersion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializePushNotifications() async {
    try {
      await PushNotificationService.init(navKey: navigatorKey);
      if (kDebugMode) log("✅ Push notifications initialized");
    } catch (e) {
      if (kDebugMode) log("⚠️ Push notification init failed: $e");
    }
  }

  // ✅ FIX: Connectivity Plus returns single ConnectivityResult
  void _listenToConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (ConnectivityResult result) {
        // ✅ Single result, not List
        final isConnected = result != ConnectivityResult.none;

        if (_isOnline != isConnected) {
          setState(() {
            _isOnline = isConnected;
          });

          if (kDebugMode) {
            log(isConnected ? "🌐 Internet connected" : "📡 No internet");
          }

          if (isConnected) {
            _refreshOnResume();
          }
        }
      },
      onError: (error) {
        if (kDebugMode) log("⚠️ Connectivity listener error: $error");
      },
    );
  }

  Future<void> _checkAppVersion() async {
    try {
      await Future.delayed(const Duration(seconds: 3));

      final updateRequired = await AppConfigService.isUpdateRequired();
      final updateRecommended = await AppConfigService.isUpdateRecommended();

      if (!mounted) return;

      if (updateRequired) {
        _showForceUpdateDialog();
      } else if (updateRecommended) {
        _showOptionalUpdateDialog();
      }
    } catch (e) {
      if (kDebugMode) log("⚠️ Version check failed: $e");
    }
  }

  void _showForceUpdateDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false, // ✅ Use PopScope instead of WillPopScope
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.system_update, color: AppColors.brandMain, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Update Required',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConfigService.updateMessage.isNotEmpty
                    ? AppConfigService.updateMessage
                    : 'A critical update is required to continue using the app.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This update includes important security improvements.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Open app store
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandMain,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.download),
              label: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionalUpdateDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.new_releases, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text('Update Available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A new version is available with exciting features and improvements!',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade700, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'What\'s New',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Improved performance\n• Bug fixes\n• New features',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Open app store
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandMain,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _checkServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final achievements = AchievementService.achievementsNotifier.value;
        final badgeProgress = BadgeService.badgeNotifier.value;

        final isReady = achievements.isNotEmpty && badgeProgress.totalXP >= 0;

        if (kDebugMode) {
          log(
            "📊 Service Status - Achievements: ${achievements.length}, "
                "Badge XP: ${badgeProgress.totalXP}, Ready: $isReady",
          );
        }

        if (mounted) {
          setState(() {
            _servicesInitialized = isReady;
          });
        }

        if (!isReady && _retryCount < _maxRetries) {
          _scheduleRetry();
        }
      } catch (e) {
        if (kDebugMode) log("⚠️ Error checking services: $e");
        if (_retryCount < _maxRetries) {
          _scheduleRetry();
        } else {
          if (kDebugMode) log("⚠️ Max retries reached. Proceeding with app launch.");
          if (mounted) {
            setState(() {
              _servicesInitialized = true;
            });
          }
        }
      }
    });
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _retryCount++;
        if (kDebugMode) {
          log("🔄 Scheduling retry ${_retryCount}/$_maxRetries...");
        }
        _retryServices();
      }
    });
  }

  Future<void> _retryServices() async {
    try {
      if (kDebugMode) {
        log("🔄 Retrying service initialization (attempt $_retryCount/$_maxRetries)...");
      }

      await Future.wait([
        AchievementService.init(),
        BadgeService.init(),
      ]).timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _servicesInitialized = true;
        });
      }

      if (kDebugMode) log("✅ Services re-initialized successfully");
    } catch (e) {
      if (kDebugMode) log("❌ Failed to re-initialize services: $e");

      if (_retryCount >= _maxRetries) {
        if (kDebugMode) log("⚠️ Max retries reached. Proceeding anyway.");
        if (mounted) {
          setState(() {
            _servicesInitialized = true;
          });
        }
      }
    }
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    ThemeService.onSystemThemeChanged();
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        if (kDebugMode) log("📱 App resumed");
        _refreshOnResume();
        break;

      case AppLifecycleState.paused:
        if (kDebugMode) log("⏸️ App paused");
        break;

      case AppLifecycleState.inactive:
        if (kDebugMode) log("😴 App inactive");
        break;

      case AppLifecycleState.detached:
        if (kDebugMode) log("🔌 App detached");
        break;

      case AppLifecycleState.hidden:
        if (kDebugMode) log("🙈 App hidden");
        break;
    }
  }

  Future<void> _refreshOnResume() async {
    if (!_isOnline) {
      if (kDebugMode) log("⚠️ Cannot refresh - offline");
      return;
    }

    try {
      await Future.wait([
        AppConfigService.refresh(),
        AchievementService.syncWeeklyChestFromServer(),
      ]).timeout(const Duration(seconds: 5));

      if (kDebugMode) log("✅ Data refreshed on resume");
    } catch (e) {
      if (kDebugMode) log("⚠️ Refresh on resume failed: $e");
    }
  }

  void _updateSystemUI(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeSettings>(
      valueListenable: ThemeService.themeSettings,
      builder: (context, themeSettings, _) {
        final isDark = themeSettings.isDarkMode;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateSystemUI(isDark);
        });

        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'FINDUS',
          themeMode: themeSettings.isAutoTheme
              ? ThemeMode.system
              : (isDark ? ThemeMode.dark : ThemeMode.light),
          theme: _buildTheme(isDark: false, settings: themeSettings),
          darkTheme: _buildTheme(isDark: true, settings: themeSettings),

          // ════════════════════════════════════════════════════════════════
          // LOCALIZATION
          // ════════════════════════════════════════════════════════════════
          locale: context.read<LocalizationWrapper>().locale,
          supportedLocales: AppLocalizationsDelegate.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: AppLocalizationsDelegate.localeResolutionCallback,

          home: const MySplashScreen(),
          builder: (context, child) => _buildAppWrapper(
            context: context,
            child: child,
            isDark: isDark,
            settings: themeSettings,
          ),
        );
      },
    );
  }

  Widget _buildAppWrapper({
    required BuildContext context,
    required Widget? child,
    required bool isDark,
    required ThemeSettings settings,
  }) {
    final mediaQuery = MediaQuery.of(context);

    // Show loading on first launch
    if (!_servicesInitialized && _isFirstLaunch) {
      return Material(
        color: isDark
            ? (settings.useAmoledBlack ? Colors.black : const Color(0xFF1A1A1A))
            : Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ FIX: Remove const - AppColors.brandMain is not const
              CircularProgressIndicator(color: AppColors.brandMain),
              const SizedBox(height: 20),
              Text(
                'Loading services...',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isFirstLaunch && _servicesInitialized) {
      _isFirstLaunch = false;
    }

    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: TextScaler.linear(settings.fontSize),
        disableAnimations: settings.isReducedMotion,
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  ThemeData _buildTheme({
    required bool isDark,
    required ThemeSettings settings,
  }) {
    // ✅ FIX: Get accent color properly
    final primaryColor = settings.isHighContrast
        ? (isDark ? Colors.white : Colors.black)
        : settings.accentColor.color;

    final scaffoldBg = isDark
        ? (settings.useAmoledBlack ? Colors.black : const Color(0xFF1A1A1A))
        : AppColors.bgBlue;

    final cardBg = isDark
        ? (settings.useAmoledBlack ? const Color(0xFF0A0A0A) : const Color(0xFF2C2C2C))
        : Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      fontFamily: 'Poppins',
      colorSchemeSeed: primaryColor,
      scaffoldBackgroundColor: scaffoldBg,

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ✅ FIX: Use CardTheme.of() pattern or just set properties
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: isDark ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: settings.isReducedMotion ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        thickness: 0.5,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scaffoldBg,
        selectedItemColor: primaryColor,
        unselectedItemColor: isDark ? Colors.grey : Colors.grey.shade600,
        elevation: 8,
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// ERROR SCREEN
/// ═══════════════════════════════════════════════════════════════════════════

class _ErrorScreen extends StatelessWidget {
  final String error;
  final String stackTrace;

  const _ErrorScreen({
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandMain,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 80,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'System Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Failed to initialize the app.\nPlease restart or contact support.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                if (kDebugMode) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Error Details:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (kDebugMode)
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: '$error\n\n$stackTrace'),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy Error'),
                      ),

                    if (kDebugMode) const SizedBox(width: 12),

                    ElevatedButton.icon(
                      onPressed: () {
                        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.brandMain,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Close App'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}