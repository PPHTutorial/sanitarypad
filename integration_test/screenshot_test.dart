import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanitarypad/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanitarypad/core/providers/auth_provider.dart';
import 'package:sanitarypad/core/providers/notification_provider.dart';
import 'package:sanitarypad/data/models/user_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sanitarypad/presentation/screens/movie/data/models/movie_model.dart';
import 'package:sanitarypad/services/auth_service.dart';
import 'package:sanitarypad/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sanitarypad/core/constants/app_constants.dart';
import 'package:sanitarypad/data/models/cycle_model.dart';
import 'package:sanitarypad/core/providers/cycle_provider.dart';

// Mock AuthService using implements to avoid inheriting default initializers
class MockAuthService implements AuthService {
  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  Future<UserModel> signInWithEmail(
      {required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError();
  }

  // Handle all other methods by throwing or returning dummy values
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mock NotificationService
class MockNotificationService implements NotificationService {
  @override
  Future<void> checkAndFireDueNotifications() async {
    // Do nothing
  }

  @override
  Future<void> initialize() async {
    // Do nothing
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Define a mock user
  final mockUser = UserModel(
    userId: 'test-user-id',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime.now(),
    settings: const UserSettings(units: UserUnits()),
    subscription: const UserSubscription(),
    privacy: const UserPrivacy(),
  );

  // Define a mock cycle
  final mockCycle = CycleModel(
    cycleId: 'cycle-1',
    userId: 'test-user-id',
    startDate: DateTime.now().subtract(const Duration(days: 3)),
    cycleLength: 28,
    periodLength: 5,
    flowIntensity: 'medium',
    symptoms: const ['cramps', 'headache'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() async {
    // Initialize Hive
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MovieModelAdapter());
    }

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({
      AppConstants.prefsKeyOnboardingComplete: true,
    });
  });

  testWidgets('take screenshots of all main screens',
      (WidgetTester tester) async {
    // Set a realistic screen size for testing
    await tester.binding
        .setSurfaceSize(const Size(390, 844)); // iPhone 12/13/14

    // Initialize the app with mocked providers
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override auth service to prevent Firebase interactions
          authServiceProvider.overrideWithValue(MockAuthService()),
          // Override notification service to prevent Firebase interactions
          notificationServiceProvider
              .overrideWithValue(MockNotificationService()),
          // Override the stream to return our logged-in user
          currentUserStreamProvider
              .overrideWith((ref) => Stream.value(mockUser)),
          // Mock active cycle to show populated dashboard
          activeCycleProvider.overrideWithValue(mockCycle),
          // Ensure cycles stream returns list containing our mock cycle
          cyclesStreamProvider.overrideWith((ref) => Stream.value([mockCycle])),
        ],
        child: const MyApp(),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // 1. Home Screen (Dashboard)
    await binding.takeScreenshot('01_home_screen');
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Define scrollable (SingleChildScrollView in Home)
    final homeScrollable = find.byType(SingleChildScrollView);

    // 2. Calendar Screen
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('02_calendar_screen');

    // 3. Insights Screen (Statistics)
    await tester.tap(find.byIcon(Icons.bar_chart));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('03_insights_screen');

    // 4. Wellness Journal List
    await tester.tap(find.byIcon(Icons.favorite_outline));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('04_wellness_screen');

    // 5. Wellness Journal Entry (Form)
    final addIcon = find.byIcon(Icons.add);
    if (addIcon.evaluate().isNotEmpty) {
      await tester.tap(addIcon.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await binding.takeScreenshot('05_wellness_entry_screen');
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
    }

    // 6. Profile Screen
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('06_profile_screen');

    // 7. Movies/Entertainment (via Home -> Quick Actions)
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Helper to scroll and tap
    Future<void> scrollAndTap(String text) async {
      final finder = find.text(text);
      await tester.scrollUntilVisible(finder, 500.0,
          scrollable: homeScrollable);
      await tester.pumpAndSettle();
      await tester.tap(finder);
    }

    await scrollAndTap('Movies');
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await binding.takeScreenshot('07_movie_screen');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 8. Log Period Screen
    await scrollAndTap('Log Period');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('08_log_period_screen');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 9. Pregnancy Tracking
    await scrollAndTap('Pregnancy');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('09_pregnancy_tracking_screen');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 10. Fertility Tracking
    await scrollAndTap('Fertility');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('10_fertility_tracking_screen');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 11. Skincare Tracking
    await scrollAndTap('Skincare');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('11_skincare_tracking_screen');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 12. Community/Groups
    await scrollAndTap('Join forum');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('12_community_groups_screen');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 13. Subscription Screen
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    final subTile = find.text('Subscription');
    if (subTile.evaluate().isNotEmpty) {
      await tester.tap(subTile);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await binding.takeScreenshot('13_subscription_screen');
      await tester.pageBack();
    }
  });
}
