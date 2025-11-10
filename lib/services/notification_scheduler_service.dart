import '../core/constants/app_constants.dart';
import 'cycle_service.dart';
import 'pad_service.dart';
import 'reminder_service.dart';
import 'auth_service.dart';
import 'fertility_service.dart';

/// Service that automatically schedules notifications based on user data
class NotificationSchedulerService {
  final CycleService _cycleService = CycleService();
  final PadService _padService = PadService();
  final ReminderService _reminderService = ReminderService();
  final AuthService _authService = AuthService();

  /// Initialize notification scheduler
  /// Call this when app starts or user logs in
  Future<void> initialize() async {
    final user = _authService.currentUser;
    if (user == null) return;

    // Schedule all notifications based on current user data
    await scheduleAllNotifications(user.uid);
  }

  /// Schedule all notifications based on user data
  Future<void> scheduleAllNotifications(String userId) async {
    try {
      // Schedule period prediction notifications
      await _schedulePeriodPredictions(userId);

      // Schedule pad change reminders
      await _schedulePadChangeReminders(userId);

      // Schedule wellness check reminders
      await _scheduleWellnessReminders(userId);

      // Schedule fertility window notifications
      await _scheduleFertilityNotifications(userId);
    } catch (e) {
      // Handle errors silently to avoid disrupting app flow
      print('Error scheduling notifications: $e');
    }
  }

  /// Schedule period prediction notifications based on cycle history
  Future<void> _schedulePeriodPredictions(String userId) async {
    try {
      final cycles = await _cycleService.getCycles();
      if (cycles.isEmpty) {
        print('⚠️ No cycles found for period prediction');
        return;
      }

      // Get the most recent cycle
      final lastCycle = cycles.first;
      final nextPeriodStart = lastCycle.startDate
          .add(Duration(days: lastCycle.cycleLength.round()));

      // Only schedule if prediction is in the future
      if (nextPeriodStart.isAfter(DateTime.now())) {
        // Cancel existing period prediction reminders
        await _cancelRemindersByType(
            userId, AppConstants.reminderPeriodPrediction);

        // Create new reminder (scheduled 1 day before predicted period)
        final reminderDate = nextPeriodStart.subtract(const Duration(days: 1));
        if (reminderDate.isAfter(DateTime.now())) {
          await _reminderService.createPeriodPredictionReminder(
            userId: userId,
            predictedDate: nextPeriodStart,
          );
          print(
              '✅ Period prediction scheduled for: $nextPeriodStart (reminder: $reminderDate)');
        } else {
          print(
              '⚠️ Period prediction reminder date is in the past: $reminderDate');
        }
      } else {
        print('⚠️ Next period start is in the past: $nextPeriodStart');
      }
    } catch (e) {
      print('❌ Error scheduling period predictions: $e');
      print(e.toString());
    }
  }

  /// Schedule pad change reminders based on last pad change
  Future<void> _schedulePadChangeReminders(String userId) async {
    try {
      final pads = await _padService.getPadChanges(limit: 1);
      if (pads.isEmpty) {
        print('⚠️ No pad changes found for reminder scheduling');
        return;
      }

      final lastPad = pads.first;
      final hoursSinceChange =
          DateTime.now().difference(lastPad.changeTime).inHours;

      // If last change was more than 4 hours ago, schedule immediate reminder
      // Otherwise, schedule for 4 hours from last change
      DateTime reminderTime;
      if (hoursSinceChange >= AppConstants.defaultPadChangeReminderHours) {
        reminderTime = DateTime.now().add(const Duration(minutes: 5));
      } else {
        final hoursUntilReminder =
            AppConstants.defaultPadChangeReminderHours - hoursSinceChange;
        reminderTime = DateTime.now().add(Duration(hours: hoursUntilReminder));
      }

      // Only schedule if reminder time is in the future
      if (reminderTime.isAfter(DateTime.now())) {
        // Cancel existing pad change reminders
        await _cancelRemindersByType(userId, AppConstants.reminderPadChange);

        // Create new reminder
        await _reminderService.createPadChangeReminder(
          userId: userId,
          scheduledTime: reminderTime,
        );
        print('✅ Pad change reminder scheduled for: $reminderTime');
      } else {
        print('⚠️ Pad change reminder time is in the past: $reminderTime');
      }
    } catch (e) {
      print('❌ Error scheduling pad change reminders: $e');
      print(e.toString());
    }
  }

  /// Schedule daily wellness check reminders
  Future<void> _scheduleWellnessReminders(String userId) async {
    try {
      // Schedule for tomorrow at 9 AM (or user's preferred time)
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 9, 0);

      // Only schedule if tomorrow is in the future (should always be, but check anyway)
      if (tomorrow.isAfter(DateTime.now())) {
        // Cancel existing wellness reminders
        await _cancelRemindersByType(
            userId, AppConstants.reminderWellnessCheck);

        // Create new reminder
        await _reminderService.createWellnessCheckReminder(
          userId: userId,
          scheduledTime: tomorrow,
        );
        print('✅ Wellness reminder scheduled for: $tomorrow');
      } else {
        print('⚠️ Wellness reminder time is in the past: $tomorrow');
      }
    } catch (e) {
      print('❌ Error scheduling wellness reminders: $e');
      print(e.toString());
    }
  }

  /// Schedule fertility window notifications
  Future<void> _scheduleFertilityNotifications(String userId) async {
    try {
      final cycles = await _cycleService.getCycles();
      if (cycles.isEmpty) return;

      final fertilityService = FertilityService();

      // Get fertility entries
      final fertilityEntries = await fertilityService
          .getFertilityEntries(
            userId,
            DateTime.now().subtract(const Duration(days: 90)),
            DateTime.now(),
          )
          .first;

      // Predict ovulation
      final prediction = await fertilityService.predictOvulation(
        userId,
        cycles,
        fertilityEntries,
      );

      if (prediction.predictedOvulation.isAfter(DateTime.now())) {
        // Schedule notification 1 day before fertile window
        final reminderDate =
            prediction.fertileWindowStart.subtract(const Duration(days: 1));

        // Only schedule if reminder date is in the future
        if (reminderDate.isAfter(DateTime.now())) {
          // Cancel existing fertility reminders
          await _cancelRemindersByType(userId, 'fertility_window');

          // Create reminder
          await _reminderService.createCustomReminder(
            userId: userId,
            title: 'Fertile Window Approaching',
            description:
                'Your fertile window starts on ${_formatDate(prediction.fertileWindowStart)}',
            scheduledTime: reminderDate,
            metadata: {
              'type': 'fertility_window',
              'ovulationDate': prediction.predictedOvulation.toIso8601String(),
              'fertileWindowStart':
                  prediction.fertileWindowStart.toIso8601String(),
              'fertileWindowEnd': prediction.fertileWindowEnd.toIso8601String(),
            },
          );
          print('✅ Fertility reminder scheduled for: $reminderDate');
        } else {
          print('⚠️ Fertility reminder date is in the past: $reminderDate');
        }
      } else {
        print(
            '⚠️ Predicted ovulation is in the past: ${prediction.predictedOvulation}');
      }
    } catch (e) {
      print('Error scheduling fertility notifications: $e');
    }
  }

  /// Cancel reminders by type
  Future<void> _cancelRemindersByType(String userId, String type) async {
    try {
      final reminders = await _reminderService.getUserReminders(userId).first;

      for (final reminder in reminders) {
        if (reminder.type == type && reminder.id != null) {
          await _reminderService.deleteReminder(reminder.id!);
        }
      }
    } catch (e) {
      print('Error canceling reminders: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Called when a new cycle is created - reschedule period predictions
  Future<void> onCycleCreated(String userId) async {
    await _schedulePeriodPredictions(userId);
  }

  /// Called when a pad is changed - reschedule pad change reminders
  Future<void> onPadChanged(String userId) async {
    await _schedulePadChangeReminders(userId);
  }

  /// Called when wellness entry is created - reschedule wellness reminders if needed
  Future<void> onWellnessEntryCreated(String userId) async {
    // Wellness reminders are daily, so no need to reschedule
    // But we could check if user hasn't logged in a while and send a reminder
  }
}
