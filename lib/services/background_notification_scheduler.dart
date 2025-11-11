import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'notification_service.dart';
import 'reminder_service.dart';
import 'auth_service.dart';
import 'cycle_service.dart';
import 'pad_service.dart';
import 'fertility_service.dart';
import 'notification_settings_service.dart';

Timer? _globalCheckTimer;

/// Start periodic check with configurable interval
Future<void> _startPeriodicCheck(ServiceInstance service) async {
  final settingsService = NotificationSettingsService();
  final interval = await settingsService.getCheckInterval();

  // Cancel existing timer if any
  _globalCheckTimer?.cancel();

  _globalCheckTimer = Timer.periodic(interval, (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Service is running in foreground
      }
    }

    try {
      final notificationService = NotificationService();

      // Initialize notification service
      await notificationService.initialize();

      // Check and fire due notifications
      await notificationService.checkAndFireDueNotifications();

      print('✅ Background service: Checked for due notifications');
    } catch (e, stackTrace) {
      print('❌ Error in background service: $e');
      print('Stack trace: $stackTrace');
    }

    // Re-check interval in case user changed it
    final newInterval = await settingsService.getCheckInterval();
    if (newInterval != interval) {
      print('🔄 Notification check interval changed, restarting timer...');
      timer.cancel();
      await _startPeriodicCheck(service);
    }
  });

  // Also check immediately
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.checkAndFireDueNotifications();
  } catch (e) {
    print('⚠️ Error in initial notification check: $e');
  }
}

/// Background service entry point
/// This runs even when the app is closed
@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and above
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Start periodic check with configurable interval
  await _startPeriodicCheck(service);

  return true;
}

/// Service for scheduling background tasks to ensure notifications fire reliably
/// even when the app is completely closed
class BackgroundNotificationScheduler {
  final NotificationService _notificationService = NotificationService();
  final ReminderService _reminderService = ReminderService();
  final AuthService _authService = AuthService();
  final CycleService _cycleService = CycleService();
  final PadService _padService = PadService();
  final FertilityService _fertilityService = FertilityService();

  /// Initialize background service
  Future<void> initialize() async {
    try {
      final service = FlutterBackgroundService();

      // Initialize the service
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: true,
          isForegroundMode: false, // Run in background, not foreground
          notificationChannelId: 'femcare_background_service',
          initialNotificationTitle: 'FemCare+',
          initialNotificationContent: 'Monitoring your reminders',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onStart,
          onBackground: onStart,
        ),
      );

      print('✅ Background service initialized');

      // Start the service
      await service.startService();

      print('✅ Background service started');

      // Reschedule notifications on app start
      await rescheduleAllNotifications();
    } catch (e, stackTrace) {
      print('❌ Error initializing background service: $e');
      print('Stack trace: $stackTrace');
      // Don't fail app initialization if background service fails
      // Notifications will still work via flutter_local_notifications
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

      // Check and fire any due notifications immediately
      await _notificationService.checkAndFireDueNotifications();

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

  /// Reschedule period prediction reminders
  Future<void> _reschedulePeriodPredictions(String userId) async {
    try {
      final cycles = await _cycleService.getCycles();
      if (cycles.isEmpty) return;

      final latestCycle = cycles.first;

      // Calculate next period start based on cycle length
      final avgCycleLength =
          cycles.take(6).map((c) => c.cycleLength).reduce((a, b) => a + b) /
              cycles.length;
      DateTime nextPeriodStart = latestCycle.startDate;
      final today = DateTime.now();

      while (nextPeriodStart.isBefore(today) ||
          nextPeriodStart.isAtSameMomentAs(today)) {
        nextPeriodStart =
            nextPeriodStart.add(Duration(days: avgCycleLength.round()));
      }

      final reminderDate = nextPeriodStart.subtract(const Duration(days: 1));

      if (reminderDate.isAfter(DateTime.now())) {
        await _reminderService.createPeriodPredictionReminder(
          userId: userId,
          predictedDate: nextPeriodStart,
        );
        print('✅ Period prediction reminder rescheduled');
      }
    } catch (e) {
      print('⚠️ Error rescheduling period predictions: $e');
    }
  }

  /// Reschedule pad change reminders
  Future<void> _reschedulePadReminders(String userId) async {
    try {
      final pads = await _padService.getPadChanges(limit: 1);
      if (pads.isEmpty) return;

      final lastPad = pads.first;
      final nextReminderTime = lastPad.changeTime.add(
        const Duration(hours: 4), // Default 4 hours
      );

      if (nextReminderTime.isAfter(DateTime.now())) {
        await _reminderService.createPadChangeReminder(
          userId: userId,
          scheduledTime: nextReminderTime,
        );
        print('✅ Pad change reminder rescheduled');
      }
    } catch (e) {
      print('⚠️ Error rescheduling pad reminders: $e');
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

      // Convert stream to list (take first snapshot)
      final fertilityEntriesSnapshot = await fertilityEntriesStream.first;
      final fertilityEntries = fertilityEntriesSnapshot;

      final prediction = await _fertilityService.predictOvulation(
        userId,
        cycles,
        fertilityEntries,
      );

      final reminderDate =
          prediction.predictedOvulation.subtract(const Duration(days: 1));

      if (reminderDate.isAfter(DateTime.now())) {
        // Create fertility reminder via reminder service
        await _reminderService.createCustomReminder(
          userId: userId,
          title: 'Fertile Window Approaching',
          description:
              'Your fertile window is predicted to start soon. Track your symptoms for better predictions.',
          scheduledTime: reminderDate,
          metadata: {
            'type': 'fertility',
            'predictedOvulation':
                prediction.predictedOvulation.toIso8601String(),
          },
        );
        print('✅ Fertility notification rescheduled');
      }
    } catch (e) {
      print('⚠️ Error rescheduling fertility notifications: $e');
    }
  }

  /// Stop the background service
  Future<void> stopService() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (isRunning) {
        service.invoke('stopService');
        print('✅ Background service stopped');
      }
    } catch (e) {
      print('⚠️ Error stopping background service: $e');
    }
  }
}
