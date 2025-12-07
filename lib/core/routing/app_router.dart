import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanitarypad/data/models/cycle_model.dart';
import 'package:sanitarypad/presentation/screens/movie/movies.dart';
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
import '../../presentation/screens/cycle/cycles_list_screen.dart';
import '../../presentation/screens/pads/pad_management_screen.dart';
import '../../presentation/screens/wellness/wellness_journal_screen.dart';
import '../../presentation/screens/wellness/wellness_journal_list_screen.dart';
import '../../data/models/wellness_model.dart';
import '../../presentation/screens/profile/settings/pin_setup_screen.dart';
import '../../presentation/screens/profile/settings/biometric_setup_screen.dart';
import '../../presentation/screens/subscription/subscription_screen.dart';
import '../../presentation/screens/wellness/wellness_content_detail_screen.dart';
import '../../presentation/screens/wellness/wellness_content_management_screen.dart';
import '../../presentation/screens/wellness/wellness_content_form_screen.dart';
import '../../services/wellness_content_service.dart';
import '../../presentation/screens/profile/emergency_contacts_screen.dart';
import '../../presentation/screens/profile/emergency_contact_form_screen.dart';
import '../../data/models/emergency_contact_model.dart';
import '../../presentation/screens/settings/notification_settings_screen.dart';
import '../../presentation/screens/reminders/reminders_list_screen.dart';
import '../../presentation/screens/pregnancy/pregnancy_tracking_screen.dart';
import '../../presentation/screens/pregnancy/pregnancy_form_screen.dart';
import '../../data/models/pregnancy_model.dart';
import '../../presentation/screens/fertility/fertility_tracking_screen.dart';
import '../../presentation/screens/fertility/fertility_entry_form_screen.dart';
import '../../data/models/fertility_model.dart';
import '../../presentation/screens/skincare/skincare_tracking_screen.dart';
import '../../presentation/screens/skincare/skincare_product_management_screen.dart';
import '../../presentation/screens/skincare/skincare_product_form_screen.dart';
import '../../presentation/screens/skincare/skincare_routine_form_screen.dart';
import '../../data/models/skincare_model.dart';
import '../../presentation/screens/alerts/red_flag_alerts_screen.dart';
import '../../presentation/screens/reports/health_report_screen.dart';
import '../../presentation/screens/community/groups_list_screen.dart';
import '../../presentation/screens/community/group_detail_screen.dart';
import '../../presentation/screens/community/group_chat_screen.dart';
import '../../presentation/screens/community/group_form_screen.dart';
import '../../presentation/screens/community/events_list_screen.dart';
import '../../presentation/screens/community/event_detail_screen.dart';
import '../../presentation/screens/community/event_form_screen.dart';
import '../../presentation/screens/ai/ai_chat_screen.dart';
import '../../core/providers/auth_provider.dart';
import 'dart:async';
import 'package:flutter/material.dart';

/// App routing configuration with auth guards
class AppRouter {
  // Cache onboarding state to avoid repeated SharedPreferences reads
  static bool? _cachedOnboardingState;
  static DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(seconds: 5);

  /// Check if onboarding is complete (with caching)
  static Future<bool> _isOnboardingComplete() async {
    // Use cache if available and not expired
    if (_cachedOnboardingState != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedOnboardingState!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final isComplete =
          prefs.getBool(AppConstants.prefsKeyOnboardingComplete) ?? false;

      // Update cache
      _cachedOnboardingState = isComplete;
      _cacheTimestamp = DateTime.now();

      return isComplete;
    } catch (e) {
      // If there's an error reading preferences, default to false (show onboarding)
      _cachedOnboardingState = false;
      _cacheTimestamp = DateTime.now();
      return false;
    }
  }

  /// Clear onboarding cache (call after completing onboarding)
  static void clearOnboardingCache() {
    _cachedOnboardingState = null;
    _cacheTimestamp = null;
  }

  // Expose for RouterRefreshNotifier
  static Future<bool> isOnboardingComplete() => _isOnboardingComplete();

  static final routerProvider = Provider<GoRouter>((ref) {
    final router = GoRouter(
      // Handle back button navigation
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Page not found: ${state.uri}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
      redirect: (context, state) async {
        final isOnboardingComplete = await _isOnboardingComplete();

        // Check Firebase Auth directly for immediate auth state (persisted)
        final asyncUser = ref.watch(currentUserStreamProvider);
        final isAuthenticated = ref.watch(isAuthenticatedProvider);

        print('Group auth is, $isAuthenticated');

        final currentLocation = state.matchedLocation;

        final isSplasingRoute = currentLocation == '/splash';
        final isOnboardingRoute = currentLocation == '/onboarding';
        final isAuthRoute =
            currentLocation == '/login' || currentLocation == '/signup';
        final isProtectedRoute =
            !isOnboardingRoute && !isAuthRoute && !isSplasingRoute;

        // While loading → don't redirect yet
        if (asyncUser.isLoading) {
          return '/splash';
        }
        // If onboarding is complete and user is on onboarding route, redirect to login
        if (isOnboardingComplete && isOnboardingRoute) {
          return '/login';
        }

        // If onboarding not complete and not on onboarding route, redirect to onboarding
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

        // If authenticated and on onboarding route, redirect to home
        if (isAuthenticated && isOnboardingRoute) {
          return '/home';
        }

        return null; // No redirect needed
      },

      refreshListenable: RouterRefreshNotifier(ref),
      initialLocation: '/onboarding', // Will be redirected by redirect logic
      routes: [
        // Onboarding
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreenPage(),
        ),
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
          builder: (context, state) {
            final cycle = state.extra as CycleModel?;
            return LogPeriodScreen(cycle: cycle);
          },
        ),
        GoRoute(
          path: '/cycles-list',
          name: 'cycles-list',
          builder: (context, state) => const CyclesListScreen(),
        ),
        GoRoute(
          path: '/pad-management',
          name: 'pad-management',
          builder: (context, state) => const PadManagementScreen(),
        ),
        GoRoute(
          path: '/wellness-journal',
          name: 'wellness-journal',
          builder: (context, state) {
            final entry = state.extra as WellnessModel?;
            return WellnessJournalScreen(entry: entry);
          },
        ),
        GoRoute(
          path: '/wellness-journal-list',
          name: 'wellness-journal-list',
          builder: (context, state) => const WellnessJournalListScreen(),
        ),
        GoRoute(
          path: '/movies',
          name: 'movies',
          builder: (context, state) => const MovieScreen(),
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

        // Wellness Content - Protected routes
        GoRoute(
          path: '/wellness-content/:id',
          name: 'wellness-content',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return WellnessContentDetailScreen(contentId: id);
          },
        ),
        GoRoute(
          path: '/wellness-content-management',
          name: 'wellness-content-management',
          builder: (context, state) => const WellnessContentManagementScreen(),
        ),
        GoRoute(
          path: '/wellness-content-form',
          name: 'wellness-content-form',
          builder: (context, state) {
            final content = state.extra as WellnessContent?;
            return WellnessContentFormScreen(content: content);
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
        GoRoute(
          path: '/reminders',
          name: 'reminders',
          builder: (context, state) => const RemindersListScreen(),
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
          path: '/skincare/products',
          name: 'skincare-products',
          builder: (context, state) {
            final view = state.extra as ProductInventoryView? ??
                ProductInventoryView.all;
            return SkincareProductManagementScreen(view: view);
          },
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

        // Community - Groups - Protected routes
        GoRoute(
          path: '/groups',
          name: 'groups',
          builder: (context, state) {
            final category = state.extra as String? ?? 'all';
            print('(Router) Group List: $category');
            return GroupsListScreen(category: category);
          },
        ),
        GoRoute(
          path: '/groups/create',
          name: 'group-create',
          builder: (context, state) {
            final category = state.extra as String?;
            print('(Route) Group creation $category');
            return GroupFormScreen(category: category);
          },
        ),
        GoRoute(
          path: '/groups/:id',
          name: 'group-detail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return GroupDetailScreen(groupId: id);
          },
        ),
        GoRoute(
          path: '/groups/:id/chat',
          name: 'group-chat',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final groupName = state.extra as String?;
            return GroupChatScreen(groupId: id, groupName: groupName);
          },
        ),

        // Community - Events - Protected routes
        GoRoute(
          path: '/events',
          name: 'events',
          builder: (context, state) {
            final category = state.extra as String? ?? 'all';
            return EventsListScreen(category: category);
          },
        ),
        GoRoute(
          path: '/events/create',
          name: 'event-create',
          builder: (context, state) {
            String? category;
            String? groupId;
            String? groupName;

            final extra = state.extra;
            if (extra is String) {
              category = extra;
            } else if (extra is Map) {
              category = extra['category'] as String?;
              groupId = extra['groupId'] as String?;
              groupName = extra['groupName'] as String?;
            }

            return EventFormScreen(
              category: category,
              groupId: groupId,
              groupName: groupName,
            );
          },
        ),
        GoRoute(
          path: '/events/:id',
          name: 'event-detail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return EventDetailScreen(eventId: id);
          },
        ),

        // AI Assistant - Protected routes
        GoRoute(
          path: '/ai-chat/:category',
          name: 'ai-chat',
          builder: (context, state) {
            final category = state.pathParameters['category']!;
            final context = state.extra as Map<String, dynamic>?;
            return AIChatScreen(
              category: category,
              context: context,
            );
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

class SplashScreenPage extends StatelessWidget {
  const SplashScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
