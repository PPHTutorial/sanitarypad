import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/config/responsive_config.dart';
import 'core/storage/hive_storage.dart';
import 'core/firebase/firebase_service.dart';
import 'core/routing/app_router.dart';
import 'core/utils/error_handler.dart';
import 'core/widgets/splash_background_wrapper.dart';
import 'core/widgets/double_back_to_exit.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  } catch (e, stackTrace) {
    // Handle initialization errors gracefully
    await ErrorHandler.handleError(
      e,
      stackTrace,
      context: 'App Initialization',
      fatal: false,
    );
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
