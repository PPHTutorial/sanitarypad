import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../core/providers/firebase_provider.dart';
import 'package:sanitarypad/core/storage/hive_storage.dart';
import 'package:sanitarypad/core/providers/notification_provider.dart';
import 'package:sanitarypad/services/ads_service.dart';
import 'package:sanitarypad/core/constants/app_constants.dart';
import 'package:sanitarypad/core/utils/error_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sanitarypad/presentation/screens/movie/data/models/movie_model.dart';
import 'package:sanitarypad/core/firebase/firebase_service.dart';
import 'package:sanitarypad/services/config_service.dart';

class CustomSplashScreen extends ConsumerStatefulWidget {
  const CustomSplashScreen({super.key});

  @override
  ConsumerState<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends ConsumerState<CustomSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _navigateToNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    // 🚀 Start Initialization in parallel with animation
    await _initializeApp();

    // Minimum delay for branding
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // We no longer call context.go() here.
    // Setting firebaseReadyProvider in _initializeApp will trigger the router's redirect.
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Initialize Hive
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MovieModelAdapter());
      }
      await HiveStorage.initialize();

      // 2. Initialize Firebase & Config (Moved back from main.dart for faster startup)
      await FirebaseService.initialize();
      await ConfigService().initialize();

      // 3. Initialize Notifications
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();

      // 4. Load Onboarding status & update Provider
      final prefs = await SharedPreferences.getInstance();
      final onboardingStatus =
          prefs.getBool(AppConstants.prefsKeyOnboardingComplete) ?? false;

      // Update the state provider
      ref.read(onboardingCompleteProvider.notifier).state = onboardingStatus;

      // Update the ready provider AFTER onboarding is confirmed to notify the router
      // This sequence ensures the router has correct data for redirect logic
      ref.read(firebaseReadyProvider.notifier).state = true;

      // 5. Initialize Ads
      AdsService().initialize();

    } catch (e, stackTrace) {
      debugPrint("Initialization error: $e");
      ErrorHandler.handleError(e, stackTrace, context: 'Splash Initialization');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force dark background as per user preference for splash
    const backgroundColor = AppTheme.splashDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/logo.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.spa,
                  color: AppTheme.primaryPink,
                  size: 80,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Thin progress bar
            const SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
