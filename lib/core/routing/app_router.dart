import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/calendar/calendar_screen.dart';
import '../../presentation/screens/insights/insights_screen.dart';
import '../../presentation/screens/wellness/wellness_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/cycle/log_period_screen.dart';
import '../../presentation/screens/pads/pad_management_screen.dart';
import '../../presentation/screens/wellness/wellness_journal_screen.dart';
import '../../presentation/screens/profile/settings/pin_setup_screen.dart';
import '../../presentation/screens/profile/settings/biometric_setup_screen.dart';
import '../../presentation/screens/subscription/subscription_screen.dart';
import '../../presentation/screens/wellness/wellness_content_detail_screen.dart';
import '../../presentation/screens/profile/emergency_contacts_screen.dart';
import '../../presentation/screens/profile/emergency_contact_form_screen.dart';
import '../../data/models/emergency_contact_model.dart';
import '../../presentation/screens/settings/notification_settings_screen.dart';
import '../../presentation/screens/pregnancy/pregnancy_tracking_screen.dart';
import '../../presentation/screens/pregnancy/pregnancy_form_screen.dart';
import '../../data/models/pregnancy_model.dart';
import '../../presentation/screens/fertility/fertility_tracking_screen.dart';
import '../../presentation/screens/fertility/fertility_entry_form_screen.dart';
import '../../data/models/fertility_model.dart';
import '../../presentation/screens/skincare/skincare_tracking_screen.dart';
import '../../presentation/screens/skincare/skincare_product_form_screen.dart';
import '../../presentation/screens/skincare/skincare_routine_form_screen.dart';
import '../../data/models/skincare_model.dart';
import '../../presentation/screens/alerts/red_flag_alerts_screen.dart';
import '../../presentation/screens/reports/health_report_screen.dart';
import '../../core/providers/auth_provider.dart';
import 'dart:async';
import 'package:flutter/material.dart';

/// App routing configuration with auth guards
class AppRouter {
  /// Check if onboarding is complete
  static Future<bool> _isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefsKeyOnboardingComplete) ?? false;
  }

  static final routerProvider = Provider<GoRouter>((ref) {
    final router = GoRouter(
      redirect: (context, state) async {
        final isOnboardingComplete = await _isOnboardingComplete();

        final userAsync = ref.read(currentUserStreamProvider);
        final user = userAsync.value;
        final isAuthenticated = user != null;

        final isOnboardingRoute = state.matchedLocation == '/onboarding';
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup';
        final isProtectedRoute = !isOnboardingRoute && !isAuthRoute;

        // If onboarding not complete and not on onboarding route
        if (!isOnboardingComplete && !isOnboardingRoute) {
          return '/onboarding';
        }

        // If onboarding complete but not authenticated and trying to access protected route
        if (isOnboardingComplete && !isAuthenticated && isProtectedRoute) {
          return '/login';
        }

        // If authenticated and on auth routes, redirect to home
        if (isAuthenticated && isAuthRoute) {
          return '/home';
        }

        return null; // No redirect needed
      },
      refreshListenable: RouterRefreshNotifier(ref),
      initialLocation: '/onboarding', // Will be redirected by redirect logic
      routes: [
        // Onboarding
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),

        // Authentication
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignUpScreen(),
        ),

        // Main App (with bottom navigation) - Protected routes
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/calendar',
          name: 'calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/insights',
          name: 'insights',
          builder: (context, state) => const InsightsScreen(),
        ),
        GoRoute(
          path: '/wellness',
          name: 'wellness',
          builder: (context, state) => const WellnessScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),

        // Feature Screens - Protected routes
        GoRoute(
          path: '/log-period',
          name: 'log-period',
          builder: (context, state) => const LogPeriodScreen(),
        ),
        GoRoute(
          path: '/pad-management',
          name: 'pad-management',
          builder: (context, state) => const PadManagementScreen(),
        ),
        GoRoute(
          path: '/wellness-journal',
          name: 'wellness-journal',
          builder: (context, state) => const WellnessJournalScreen(),
        ),

        // Settings - Protected routes
        GoRoute(
          path: '/pin-setup',
          name: 'pin-setup',
          builder: (context, state) => const PinSetupScreen(),
        ),
        GoRoute(
          path: '/biometric-setup',
          name: 'biometric-setup',
          builder: (context, state) => const BiometricSetupScreen(),
        ),

        // Subscription - Protected route
        GoRoute(
          path: '/subscription',
          name: 'subscription',
          builder: (context, state) => const SubscriptionScreen(),
        ),

        // Wellness Content - Protected route
        GoRoute(
          path: '/wellness-content/:id',
          name: 'wellness-content',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return WellnessContentDetailScreen(contentId: id);
          },
        ),

        // Emergency Contacts - Protected routes
        GoRoute(
          path: '/emergency-contacts',
          name: 'emergency-contacts',
          builder: (context, state) => const EmergencyContactsScreen(),
        ),
        GoRoute(
          path: '/emergency-contact-form',
          name: 'emergency-contact-form',
          builder: (context, state) {
            final contact = state.extra as EmergencyContact?;
            return EmergencyContactFormScreen(contact: contact);
          },
        ),

        // Settings - Protected routes
        GoRoute(
          path: '/notification-settings',
          name: 'notification-settings',
          builder: (context, state) => const NotificationSettingsScreen(),
        ),

        // Health Alerts - Protected route
        GoRoute(
          path: '/red-flag-alerts',
          name: 'red-flag-alerts',
          builder: (context, state) => const RedFlagAlertsScreen(),
        ),

        // Health Reports - Protected route
        GoRoute(
          path: '/health-report',
          name: 'health-report',
          builder: (context, state) => const HealthReportScreen(),
        ),

        // Pregnancy Tracking - Protected routes
        GoRoute(
          path: '/pregnancy-tracking',
          name: 'pregnancy-tracking',
          builder: (context, state) => const PregnancyTrackingScreen(),
        ),
        GoRoute(
          path: '/pregnancy-form',
          name: 'pregnancy-form',
          builder: (context, state) {
            final pregnancy = state.extra as Pregnancy?;
            return PregnancyFormScreen(pregnancy: pregnancy);
          },
        ),

        // Fertility Tracking - Protected routes
        GoRoute(
          path: '/fertility-tracking',
          name: 'fertility-tracking',
          builder: (context, state) => const FertilityTrackingScreen(),
        ),
        GoRoute(
          path: '/fertility-entry-form',
          name: 'fertility-entry-form',
          builder: (context, state) {
            final entry = state.extra as FertilityEntry?;
            return FertilityEntryFormScreen(entry: entry);
          },
        ),

        // Skincare Tracking - Protected routes
        GoRoute(
          path: '/skincare-tracking',
          name: 'skincare-tracking',
          builder: (context, state) => const SkincareTrackingScreen(),
        ),
        GoRoute(
          path: '/skincare-product-form',
          name: 'skincare-product-form',
          builder: (context, state) {
            final product = state.extra as SkincareProduct?;
            return SkincareProductFormScreen(product: product);
          },
        ),
        GoRoute(
          path: '/skincare-routine-form',
          name: 'skincare-routine-form',
          builder: (context, state) {
            final entry = state.extra as SkincareEntry?;
            return SkincareRoutineFormScreen(entry: entry);
          },
        ),
      ],
    );

    return router;
  });

  // Legacy static router for backward compatibility
  static GoRouter get router {
    // This will be replaced by routerProvider in main.dart
    throw UnimplementedError('Use routerProvider instead');
  }
}

/// Router refresh notifier helper
class RouterRefreshNotifier extends ChangeNotifier {
  final Ref _ref;
  StreamSubscription? _subscription;

  RouterRefreshNotifier(this._ref) {
    // Listen to auth state changes
    final authService = _ref.read(authServiceProvider);
    _subscription = authService.authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
