import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'reminder_service.dart';
import 'auth_service.dart';
import 'cycle_service.dart';
import 'pad_service.dart';
import 'fertility_service.dart';

/// Background task callback for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('🔄 Background task started: $task');

      final scheduler = BackgroundNotificationScheduler();

      switch (task) {
        case 'rescheduleNotifications':
          await scheduler.rescheduleAllNotifications();
          break;
        case 'checkMissedNotifications':
          await scheduler.checkAndRescheduleMissedNotifications();
          break;
        default:
          print('⚠️ Unknown background task: $task');
      }

      print('✅ Background task completed: $task');
      return Future.value(true);
    } catch (e, stackTrace) {
      print('❌ Error in background task $task: $e');
      print('Stack trace: $stackTrace');
      return Future.value(false);
    }
  });
}

/// Service for scheduling background tasks to ensure notifications fire reliably
class BackgroundNotificationScheduler {
  final NotificationService _notificationService = NotificationService();
  final ReminderService _reminderService = ReminderService();
  final AuthService _authService = AuthService();
  final CycleService _cycleService = CycleService();
  final PadService _padService = PadService();
  final FertilityService _fertilityService = FertilityService();

  /// Initialize WorkManager and schedule periodic tasks
  Future<void> initialize() async {
    try {
      // Initialize WorkManager
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      print('✅ WorkManager initialized');

      // Schedule periodic task to check and reschedule notifications
      // This runs every 15 minutes to ensure notifications are still scheduled
      await Workmanager().registerPeriodicTask(
        'notificationCheck',
        'checkMissedNotifications',
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      print('✅ Periodic notification check task registered');

      // Schedule one-time task to reschedule all notifications on app start
      await Workmanager().registerOneOffTask(
        'rescheduleOnStart',
        'rescheduleNotifications',
        initialDelay: const Duration(seconds: 10),
        constraints: Constraints(
          networkType: NetworkType.not_required,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      print('✅ One-time reschedule task registered');
    } catch (e, stackTrace) {
      print('❌ Error initializing background scheduler: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Reschedule all notifications for the current user
  Future<void> rescheduleAllNotifications() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        print('⚠️ No user logged in, skipping notification reschedule');
        return;
      }

      print('🔄 Rescheduling all notifications for user: ${user.uid}');

      // Ensure notification service is initialized
      await _notificationService.initialize();

      // Reschedule all active reminders
      final remindersStream = _reminderService.getUserReminders(user.uid);
      final reminders = await remindersStream.first;
      final activeReminders = reminders.where((r) => r.isActive).toList();

      print(
          '📋 Found ${activeReminders.length} active reminders to reschedule');

      for (final reminder in activeReminders) {
        if (reminder.scheduledTime.isAfter(DateTime.now())) {
          try {
            final notificationId = reminder.id!.hashCode.abs() % 2147483647;
            final repeatInterval = reminder.metadata?['repeat'] as String?;
            final customIntervalDays =
                reminder.metadata?['customIntervalDays'] as int?;

            await _notificationService.scheduleNotification(
              id: notificationId,
              title: reminder.title,
              body: reminder.description ?? '',
              scheduledDate: reminder.scheduledTime,
              repeatInterval: repeatInterval,
              customIntervalDays: customIntervalDays,
            );
            print('✅ Rescheduled reminder: ${reminder.title}');
          } catch (e) {
            print('❌ Error rescheduling reminder ${reminder.id}: $e');
          }
        }
      }

      // Reschedule period predictions
      await _reschedulePeriodPredictions(user.uid);

      // Reschedule pad change reminders
      await _reschedulePadReminders(user.uid);

      // Reschedule fertility notifications
      await _rescheduleFertilityNotifications(user.uid);

      print('✅ All notifications rescheduled');
    } catch (e, stackTrace) {
      print('❌ Error rescheduling notifications: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Check for missed notifications and reschedule them
  Future<void> checkAndRescheduleMissedNotifications() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // Get all active reminders
      final remindersStream = _reminderService.getUserReminders(user.uid);
      final reminders = await remindersStream.first;
      final now = DateTime.now();

      for (final reminder in reminders) {
        if (!reminder.isActive) continue;

        // Check if reminder was supposed to fire in the last hour but didn't
        final timeDiff = now.difference(reminder.scheduledTime);
        if (timeDiff.inHours >= 0 && timeDiff.inHours <= 1) {
          // Reschedule if it's a repeating reminder
          final repeatInterval = reminder.metadata?['repeat'] as String?;
          if (repeatInterval != null && repeatInterval != 'none') {
            print(
                '🔄 Rescheduling missed repeating reminder: ${reminder.title}');
            await rescheduleAllNotifications();
            break;
          }
        }
      }
    } catch (e) {
      print('❌ Error checking missed notifications: $e');
    }
  }

  /// Reschedule period prediction notifications
  Future<void> _reschedulePeriodPredictions(String userId) async {
    try {
      final cycles = await _cycleService.getCycles();
      if (cycles.isEmpty) return;

      // Get the most recent cycle
      cycles.sort((a, b) => b.startDate.compareTo(a.startDate));
      final latestCycle = cycles.first;

      // Calculate next period start based on cycle length
      final nextPeriodStart =
          latestCycle.startDate.add(Duration(days: latestCycle.cycleLength));

      if (nextPeriodStart.isAfter(DateTime.now())) {
        final reminderDate = nextPeriodStart.subtract(const Duration(days: 1));

        if (reminderDate.isAfter(DateTime.now())) {
          final notificationId = 'period_${userId}'.hashCode.abs() % 2147483647;
          await _notificationService.scheduleNotification(
            id: notificationId,
            title: 'Period Reminder',
            body: 'Your period is predicted to start soon',
            scheduledDate: reminderDate,
          );
          print('✅ Period prediction notification rescheduled');
        }
      }
    } catch (e) {
      print('❌ Error rescheduling period predictions: $e');
    }
  }

  /// Reschedule pad change reminders
  Future<void> _reschedulePadReminders(String userId) async {
    try {
      final pads = await _padService.getPadChanges(limit: 1);
      if (pads.isEmpty) return;

      // Get the most recent pad change
      final latestPad = pads.first;

      final nextReminderTime =
          latestPad.changeTime.add(const Duration(hours: 4));
      if (nextReminderTime.isAfter(DateTime.now())) {
        final notificationId =
            'pad_${userId}_${latestPad.padId}'.hashCode.abs() % 2147483647;
        await _notificationService.scheduleNotification(
          id: notificationId,
          title: 'Pad Change Reminder',
          body: 'Time to change your pad',
          scheduledDate: nextReminderTime,
        );
        print('✅ Pad change reminder rescheduled');
      }
    } catch (e) {
      print('❌ Error rescheduling pad reminders: $e');
    }
  }

  /// Reschedule fertility notifications
  Future<void> _rescheduleFertilityNotifications(String userId) async {
    try {
      // Get cycles and fertility entries for prediction
      final cycles = await _cycleService.getCycles();
      if (cycles.isEmpty) return;

      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 90));
      final endDate = now.add(const Duration(days: 30));

      final fertilityEntriesStream = _fertilityService.getFertilityEntries(
        userId,
        startDate,
        endDate,
      );
      final fertilityEntries = await fertilityEntriesStream.first;

      if (fertilityEntries.isEmpty && cycles.isEmpty) return;

      final prediction = await _fertilityService.predictOvulation(
        userId,
        cycles,
        fertilityEntries,
      );

      if (prediction.predictedOvulation.isAfter(DateTime.now())) {
        final reminderDate =
            prediction.predictedOvulation.subtract(const Duration(days: 1));

        if (reminderDate.isAfter(DateTime.now())) {
          final notificationId =
              'fertility_${userId}'.hashCode.abs() % 2147483647;
          await _notificationService.scheduleNotification(
            id: notificationId,
            title: 'Fertile Window Approaching',
            body: 'Your fertile window is starting soon',
            scheduledDate: reminderDate,
          );
          print('✅ Fertility notification rescheduled');
        }
      }
    } catch (e) {
      print('❌ Error rescheduling fertility notifications: $e');
    }
  }

  /// Cancel all background tasks (useful for logout)
  Future<void> cancelAllTasks() async {
    try {
      await Workmanager().cancelByUniqueName('notificationCheck');
      await Workmanager().cancelByUniqueName('rescheduleOnStart');
      print('✅ All background tasks cancelled');
    } catch (e) {
      print('❌ Error cancelling background tasks: $e');
    }
  }
}
