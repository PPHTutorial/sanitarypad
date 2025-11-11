import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Service for managing notification-related settings
class NotificationSettingsService {
  /// Get notification check interval in minutes
  Future<int> getCheckIntervalMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(AppConstants.prefsKeyNotificationCheckInterval) ??
          AppConstants.defaultNotificationCheckInterval;
    } catch (e) {
      return AppConstants.defaultNotificationCheckInterval;
    }
  }

  /// Set notification check interval in minutes
  Future<bool> setCheckIntervalMinutes(int minutes) async {
    try {
      // Validate range
      if (minutes < AppConstants.minNotificationCheckInterval ||
          minutes > AppConstants.maxNotificationCheckInterval) {
        throw ArgumentError(
          'Interval must be between ${AppConstants.minNotificationCheckInterval} '
          'and ${AppConstants.maxNotificationCheckInterval} minutes',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      return await prefs.setInt(
        AppConstants.prefsKeyNotificationCheckInterval,
        minutes,
      );
    } catch (e) {
      return false;
    }
  }

  /// Get notification check interval as Duration
  Future<Duration> getCheckInterval() async {
    final minutes = await getCheckIntervalMinutes();
    return Duration(minutes: minutes);
  }
}
