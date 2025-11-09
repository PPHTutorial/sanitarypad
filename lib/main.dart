import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/config/responsive_config.dart';
import 'core/storage/hive_storage.dart';
import 'core/firebase/firebase_service.dart';
import 'core/routing/app_router.dart';
import 'core/utils/error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
    return ResponsiveConfig.init(
      context: context,
      minTextAdapt: true,
      splitScreenMode: false,
      child: MaterialApp.router(
        title: 'FemCare+',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
