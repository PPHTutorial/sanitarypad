import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sanitarypad/firebase_options.dart';

/// Firebase initialization service
class FirebaseService {
  static FirebaseAnalytics? _analytics;
  static FirebaseCrashlytics? _crashlytics;

  /// Initialize Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Analytics
      _analytics = FirebaseAnalytics.instance;

      // Initialize Crashlytics
      _crashlytics = FirebaseCrashlytics.instance;

      // Enable Crashlytics collection in debug mode (optional)
      if (FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled) {
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };
      }
    } catch (e) {
      // Handle initialization error
      // In production, you might want to log this
      rethrow;
    }
  }

  /// Get Firebase Analytics instance
  static FirebaseAnalytics get analytics {
    if (_analytics == null) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _analytics!;
  }

  /// Get Firebase Crashlytics instance
  static FirebaseCrashlytics get crashlytics {
    if (_crashlytics == null) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _crashlytics!;
  }

  /// Log event to Analytics
  static Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics?.logEvent(
        name: name,
        parameters:
            parameters?.map((key, value) => MapEntry(key, value as Object)),
      );
    } catch (e) {
      // Silently fail analytics logging
    }
  }

  /// Set user property
  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      // Silently fail
    }
  }

  /// Record error to Crashlytics
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics?.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      // Silently fail
    }
  }
}
