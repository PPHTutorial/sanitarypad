import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sanitarypad/presentation/screens/movie/data/models/movie_model.dart';
import 'core/theme/app_theme.dart';
import 'core/config/responsive_config.dart';
import 'core/storage/hive_storage.dart';
import 'core/firebase/firebase_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/routing/app_router.dart';
import 'core/utils/error_handler.dart';
import 'core/widgets/splash_background_wrapper.dart';
import 'core/widgets/double_back_to_exit.dart';
import 'core/providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'core/providers/notification_provider.dart';
import 'services/ads_service.dart';
import 'core/constants/app_constants.dart';

import 'core/providers/onboarding_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Hive for local storage
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(MovieModelAdapter());
  }

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set initial system UI overlay style
  // Will be overridden by SplashBackgroundWrapper based on theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor:
          AppTheme.splashLight, // Default to light splash color
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorHandler.handleFlutterError(details);
  };

  // Initialize services
  try {
    // Initialize Hive (local storage)
    await HiveStorage.initialize();

    // Initialize Firebase
    await FirebaseService.initialize();

    // Initialize notifications
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete =
        prefs.getBool(AppConstants.prefsKeyOnboardingComplete) ?? false;

    // Initialize Ads (fire and forget to not block app start)
    AdsService().initialize();

    runApp(
      ProviderScope(
        overrides: [
          onboardingCompleteProvider.overrideWith((ref) => onboardingComplete),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    // Handle initialization errors gracefully
    await ErrorHandler.handleError(
      e,
      stackTrace,
      context: 'App Initialization',
      fatal: false,
    );

    // Still run the app even if some services fail
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Check for due notifications when app comes to foreground
      ref.read(notificationServiceProvider).checkAndFireDueNotifications();

      // Show App Open Ad if available
      AdsService().showAppOpenAdIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(AppRouter.routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return ResponsiveConfig.init(
      context: context,
      minTextAdapt: true,
      splitScreenMode: false,
      child: MaterialApp.router(
        title: 'FemCare+',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: router,
        builder: (context, child) {
          // Wrap with splash background that extends behind status bar
          // and double-back-to-exit functionality
          return SplashBackgroundWrapper(
            child: DoubleBackToExit(
              message: 'Press back again to exit FemCare+',
              child: child ?? const SizedBox(),
            ),
          );
        },
      ),
    );
  }
}
