import 'package:flutter/foundation.dart';
import '../firebase/firebase_service.dart';

/// Global error handler utility
class ErrorHandler {
  /// Handle and log errors
  static Future<void> handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) async {
    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('Error${context != null ? ' in $context' : ''}: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }

    // Record to Crashlytics in production
    try {
      await FirebaseService.recordError(
        error,
        stackTrace,
        reason: context,
        fatal: fatal,
      );
    } catch (e) {
      // Silently fail if Crashlytics is not available
      if (kDebugMode) {
        debugPrint('Failed to record error to Crashlytics: $e');
      }
    }
  }

  /// Handle Flutter framework errors
  static void handleFlutterError(FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    }

    // Record to Crashlytics
    FirebaseService.recordError(
      details.exception,
      details.stack,
      reason: details.context?.toString(),
      fatal: true,
    );
  }
}
