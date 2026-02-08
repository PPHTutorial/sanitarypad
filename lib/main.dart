import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/config/responsive_config.dart';
import 'core/routing/app_router.dart';
import 'core/widgets/splash_background_wrapper.dart';
import 'core/widgets/double_back_to_exit.dart';
import 'core/providers/theme_provider.dart';
import 'services/ads_service.dart';
import 'services/security_service.dart';
import 'core/providers/notification_provider.dart';
import 'services/periodic_ad_manager.dart';

import 'package:sanitarypad/services/config_service.dart';
import 'package:sanitarypad/core/firebase/firebase_service.dart';
import 'presentation/widgets/global_video_overlay.dart';

void main() async {
  // 1. Ensure bindings are initialized immediately
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase (Critical for providers)
  await FirebaseService.initialize();

  // Initialize ConfigService
  await ConfigService().initialize();

  // Initialize AdsService
  await AdsService().initialize();

  // 3. Run app immediately to show Splash Screen
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );

  // 3. Set orientations for the whole app
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 4. Default System UI Style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.splashDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
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
    // Pre-load ads
    AdsService().loadRewardedAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  bool _isLocked = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Check for due notifications when app comes to foreground
      ref.read(notificationServiceProvider).checkAndFireDueNotifications();

      // Show App Open Ad if available
      AdsService().showAppOpenAdIfAvailable();

      // Security Lock Logic
      _checkAndShowLockScreen();
    }
  }

  Future<void> _checkAndShowLockScreen() async {
    if (_isLocked) return;

    final securityService = ref.read(securityServiceProvider);
    final hasPin = await securityService.hasPin();
    final isBiometricEnabled = await securityService.isBiometricEnabled();

    if (hasPin || isBiometricEnabled) {
      _isLocked = true;
      final router = ref.read(AppRouter.routerProvider);

      // Use push to overlay the lock screen
      final result = await router.push('/lock');

      if (result == true) {
        _isLocked = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(AppRouter.routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Initialize Periodic Ad Manager for Eco users
    ref.watch(periodicAdManagerProvider);

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
          return SplashBackgroundWrapper(
            child: DoubleBackToExit(
              message: 'Press back again to exit FemCare+',
              child: Stack(
                children: [
                  child ?? const SizedBox(),
                  const GlobalVideoOverlay(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
