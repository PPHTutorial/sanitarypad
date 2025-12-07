import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/config/responsive_config.dart';
import 'core/storage/hive_storage.dart';
import 'core/firebase/firebase_service.dart';
import 'core/routing/app_router.dart';
import 'core/utils/error_handler.dart';
import 'core/widgets/splash_background_wrapper.dart';
import 'core/widgets/double_back_to_exit.dart';
import 'core/providers/theme_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  // Note: .env file must be in the project root and listed in pubspec.yaml assets
  try {
    await dotenv.load();
    debugPrint('✓ Environment variables loaded successfully');
    if (dotenv.env['OPENAI_API_KEY'] == null ||
        dotenv.env['OPENAI_API_KEY']!.isEmpty ||
        dotenv.env['OPENAI_API_KEY'] == 'sk-your-api-key-here') {
      debugPrint(
          '⚠ Warning: OPENAI_API_KEY is not set or is using placeholder value');
    }
  } catch (e) {
    // .env file not found or error loading - app will still run but AI features won't work
    debugPrint('⚠ Warning: Could not load .env file: $e');
    debugPrint(
        '⚠ AI Assistant features will not be available without .env configuration.');
    debugPrint('⚠ Steps to fix:');
    debugPrint(
        '   1. Create .env file in project root (same directory as pubspec.yaml)');
    debugPrint('   2. Add: OPENAI_API_KEY=sk-your-actual-api-key-here');
    debugPrint('   3. Ensure .env is listed in pubspec.yaml assets section');
    debugPrint('   4. Run: flutter pub get');
    debugPrint('   5. Restart the app');
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

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final _notificationService = NotificationService();

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
      _notificationService.checkAndFireDueNotifications();
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
