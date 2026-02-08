import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanitarypad/data/models/cycle_model.dart';
import 'package:sanitarypad/presentation/screens/movie/domain/entities/movie.dart'
    as movie_model;
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
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/profile/full_profile_screen.dart';
import '../../presentation/screens/profile/credit_history_screen.dart';
import '../../presentation/screens/profile/settings/cycle_settings_screen.dart';
import '../../presentation/screens/profile/settings/privacy_settings_screen.dart';
import '../../presentation/screens/cycle/log_period_screen.dart';
import '../../presentation/screens/cycle/cycles_list_screen.dart';
import '../../presentation/screens/pads/pad_management_screen.dart';
import '../../presentation/screens/wellness/wellness_journal_screen.dart';
import '../../presentation/screens/wellness/wellness_journal_list_screen.dart';
import '../../data/models/wellness_model.dart';
import '../../presentation/screens/profile/settings/pin_setup_screen.dart';
import '../../presentation/screens/profile/settings/biometric_setup_screen.dart';
import '../../presentation/screens/profile/settings/security_settings_screen.dart';
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
import '../../presentation/screens/pregnancy/partner_dashboard_screen.dart';
import '../../data/models/pregnancy_model.dart';
import '../../presentation/screens/fertility/fertility_tracking_screen.dart';
import '../../presentation/screens/fertility/fertility_entry_form_screen.dart';
import '../../data/models/fertility_model.dart';
import '../../presentation/screens/skincare/skincare_tracking_screen.dart';
import '../../presentation/screens/skincare/skincare_product_management_screen.dart';
import '../../presentation/screens/skincare/skincare_product_form_screen.dart';
import '../../presentation/screens/skincare/skincare_routine_form_screen.dart';
import '../../presentation/screens/skincare/dermatologist_search_screen.dart';
import '../../data/models/skincare_model.dart';
import '../../presentation/screens/alerts/red_flag_alerts_screen.dart';
import '../../presentation/screens/nutrition/nutrition_tracking_screen.dart';
import '../../presentation/screens/workout/workout_tracking_screen.dart';
import '../../presentation/screens/workout/workout_challenges_screen.dart';
import '../../presentation/screens/workout/workout_achievements_screen.dart';
import '../../presentation/screens/reports/health_report_screen.dart';
import '../../data/models/group_model.dart';
import '../../presentation/screens/community/groups_list_screen.dart';
import '../../presentation/screens/community/group_detail_screen.dart';
import '../../presentation/screens/community/group_chat_screen.dart';
import '../../presentation/screens/community/group_form_screen.dart';
import '../../presentation/screens/community/events_list_screen.dart';
import '../../presentation/screens/community/event_detail_screen.dart';
import '../../presentation/screens/community/event_form_screen.dart';
import '../../presentation/screens/ai/ai_chat_screen.dart';
import '../../presentation/screens/movie/presentation/screens/home/home_screen.dart'
    as movie_home;
import '../../presentation/screens/movie/presentation/screens/search/search_screen.dart'
    as movie_search;
import '../../presentation/screens/movie/presentation/screens/favorites/favorites_screen.dart'
    as movie_favorites;
import '../../presentation/screens/movie/presentation/screens/detail/movie_detail_screen.dart'
    as movie_detail;
import '../../presentation/screens/movie/movies.dart' as movie_player;
import '../../presentation/screens/movie/customplayer.dart' as video_player;
import '../../presentation/screens/profile/help_support_screen.dart';
import '../../presentation/screens/profile/create_ticket_screen.dart';
import 'package:sanitarypad/data/models/user_model.dart';
import '../../presentation/screens/splash/custom_splash_screen.dart';
import '../../presentation/screens/security/lock_screen.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/onboarding_provider.dart';
import '../../core/providers/firebase_provider.dart';
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
      redirect: (context, state) {
        final isOnboardingComplete = ref.read(onboardingCompleteProvider);
        final isFirebaseReady = ref.read(firebaseReadyProvider);
        final authState = ref.read(currentUserStreamProvider);

        // If Firebase isn't ready or auth status is still loading, stay on splash
        if (!isFirebaseReady || authState.isLoading) return null;

        final isAuthenticated = authState.value != null;

        final currentLocation = state.matchedLocation;

        final isSplashRoute = currentLocation == '/splash';
        final isOnboardingRoute = currentLocation == '/onboarding';
        final isAuthRoute =
            currentLocation == '/login' || currentLocation == '/signup';
        final isProtectedRoute =
            !isOnboardingRoute && !isAuthRoute && !isSplashRoute;

        // If on splash, determine where to go next
        if (isSplashRoute) {
          if (!isOnboardingComplete) return '/onboarding';
          if (!isAuthenticated) return '/login';
          return '/home';
        }

        // If onboarding is complete and user is on onboarding route, redirect to login
        if (isOnboardingComplete && isOnboardingRoute) {
          return isAuthenticated ? '/home' : '/login';
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
        if (isAuthenticated && (isAuthRoute || isOnboardingRoute)) {
          return '/home';
        }

        return null; // No redirect needed
      },

      refreshListenable: RouterRefreshNotifier(ref),
      initialLocation: '/splash', // Start at splash to determine destination
      routes: [
        // Onboarding
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const CustomSplashScreen(),
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
        GoRoute(
          path: '/lock',
          name: 'lock',
          builder: (context, state) => const LockScreen(),
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
        GoRoute(
          path: '/edit-profile',
          name: 'edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/cycle-settings',
          name: 'cycle-settings',
          builder: (context, state) => const CycleSettingsScreen(),
        ),
        GoRoute(
          path: '/privacy-settings',
          name: 'privacy-settings',
          builder: (context, state) => const PrivacySettingsScreen(),
        ),
        GoRoute(
          path: '/profile-details',
          name: 'profile-details',
          builder: (context, state) => const FullProfileScreen(),
        ),
        GoRoute(
          path: '/security-settings',
          name: 'security-settings',
          builder: (context, state) => const SecuritySettingsScreen(),
        ),
        GoRoute(
          path: '/credit-history',
          name: 'credit-history',
          builder: (context, state) => const CreditHistoryScreen(),
        ),
        GoRoute(
          path: '/help-support',
          name: 'help-support',
          builder: (context, state) => const HelpSupportScreen(),
        ),
        GoRoute(
          path: '/create-ticket',
          name: 'create-ticket',
          builder: (context, state) => const CreateTicketScreen(),
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
        GoRoute(
          path: '/pregnancy/partner/:id',
          name: 'pregnancy-partner',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return PartnerDashboardScreen(pregnancyId: id);
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
        GoRoute(
          path: '/dermatologist-search',
          name: 'dermatologist-search',
          builder: (context, state) => const DermatologistSearchScreen(),
        ),

        // Nutrition & Workout Tracking - Protected routes
        GoRoute(
          path: '/nutrition-tracking',
          name: 'nutrition-tracking',
          builder: (context, state) => const NutritionTrackingScreen(),
        ),
        GoRoute(
          path: '/workout-tracking',
          name: 'workout-tracking',
          builder: (context, state) => const WorkoutTrackingScreen(),
        ),
        GoRoute(
          path: '/workout-challenges',
          name: 'workout-challenges',
          builder: (context, state) {
            final userId = state.extra as String?;
            if (userId == null) {
              return const Scaffold(
                  body: Center(child: Text('User ID required')));
            }
            return WorkoutChallengesScreen(userId: userId);
          },
        ),
        GoRoute(
          path: '/workout-achievements',
          name: 'workout-achievements',
          builder: (context, state) {
            final userId = state.extra as String?;
            if (userId == null) {
              return const Scaffold(
                  body: Center(child: Text('User ID required')));
            }
            return WorkoutAchievementsScreen(userId: userId);
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
          path: '/groups/edit',
          name: 'group-edit',
          builder: (context, state) {
            final group = state.extra as GroupModel?;
            print('(Route) Group edit: id=${group?.id}, name=${group?.name}');
            if (group == null) {
              return const Scaffold(
                body: Center(child: Text('No group data provided')),
              );
            }
            return GroupFormScreen(editGroup: group);
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

        // Movie Module - Protected routes
        GoRoute(
          path: '/movies',
          name: 'movies',
          builder: (context, state) => const movie_home.MovieMovieHomeScreen(),
        ),
        GoRoute(
          path: '/movies/search',
          name: 'movie-search',
          builder: (context, state) => const movie_search.SearchScreen(),
        ),
        GoRoute(
          path: '/movies/favorites',
          name: 'movie-favorites',
          builder: (context, state) => const movie_favorites.FavoritesScreen(),
        ),
        GoRoute(
          path: '/movies/play',
          name: 'movie-play',
          builder: (context, state) {
            final movie = state.extra as movie_model.Movie?;
            final season = state.uri.queryParameters['season'];
            final episode = state.uri.queryParameters['episode'];

            if (movie == null) {
              return const Scaffold(
                body: Center(child: Text('Movie not found')),
              );
            }
            return movie_player.MovieScreen(
                movie: movie, season: season, episode: episode);
          },
        ),
        GoRoute(
          path: '/movies/player',
          name: 'movie-player',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final url = extra?['url'] as String?;
            final movie = extra?['movie'] as movie_model.Movie?;
            final episodes =
                (extra?['episodes'] as List?)?.cast<Map<String, dynamic>>();
            final currentEpisode =
                extra?['currentEpisode'] as Map<String, dynamic>?;
            final movieId = extra?['movieId'] as String?;

            if (url == null || movieId == null) {
              return const Scaffold(
                body: Center(child: Text('Playback error: Missing data')),
              );
            }
            return video_player.CustomVideoPlayer(
              url: url,
              movieId: movieId,
              sourceMovie: movie,
              episodes: episodes,
              currentEpisode: currentEpisode,
            );
          },
        ),
        GoRoute(
          path: '/movies/detail',
          name: 'movie-detail',
          builder: (context, state) {
            final movie = state.extra as movie_model.Movie?;
            if (movie == null) {
              return const Scaffold(
                body: Center(child: Text('Movie not found')),
              );
            }
            return movie_detail.MovieDetailScreen(movie: movie);
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
    // Listen to both auth state changes and profile loading state
    // This ensures redirect logic re-runs when profile finishes loading
    // Listen to authentication status specifically
    _ref.listen<bool>(
      isAuthenticatedProvider,
      (previous, next) {
        if (previous != next) {
          notifyListeners();
        }
      },
    );

    // Profile loading state listener
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (previous, next) {
        if (previous?.isLoading != next.isLoading) {
          notifyListeners();
        }
      },
    );

    // Onboarding state listener
    _ref.listen<bool>(
      onboardingCompleteProvider,
      (previous, next) {
        if (previous != next) {
          notifyListeners();
        }
      },
    );

    // Firebase ready listener
    _ref.listen<bool>(
      firebaseReadyProvider,
      (previous, next) {
        if (previous != next) {
          notifyListeners();
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
