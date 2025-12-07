import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'themes/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/providers/theme_provider.dart';

/// Root application widget
class MovieWallsApp extends ConsumerWidget {
  const MovieWallsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 11 Pro size as base
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

