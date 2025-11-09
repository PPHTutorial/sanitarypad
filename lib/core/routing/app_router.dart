import 'package:go_router/go_router.dart';
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

/// App routing configuration
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
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

      // Main App (with bottom navigation)
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

      // Feature Screens
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

      // Settings
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

      // Subscription
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),

      // Wellness Content
      GoRoute(
        path: '/wellness-content/:id',
        name: 'wellness-content',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return WellnessContentDetailScreen(contentId: id);
        },
      ),

      // Emergency Contacts
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

      // Settings
      GoRoute(
        path: '/notification-settings',
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),

      // Pregnancy Tracking
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

      // Fertility Tracking
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

      // Skincare Tracking
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
}
