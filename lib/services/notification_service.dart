import 'dart:async';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../core/constants/app_constants.dart';
import 'notification_settings_service.dart';

/// Notification service
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  Timer? _notificationCheckerTimer;

  /// Initialize notifications
  Future<void> initialize() async {
    try {
      await _configureLocalTimezone();

      // Request permission
      await _requestPermission();
      print('✅ Permissions requested');

      // Initialize local notifications
      await _initializeLocalNotifications();
      print('✅ Local notifications initialized');

      // Configure Firebase Messaging
      await _configureFirebaseMessaging();
      print('✅ Firebase Messaging configured');

      // Start periodic notification checker
      _startNotificationChecker();
      print('✅ Notification checker started');
    } catch (e) {
      print('❌ Error initializing notifications: $e');
      print('Stack trace: ${e.toString()}');
      rethrow;
    }
  }

  /// Start periodic notification checker
  void _startNotificationChecker() async {
    // Cancel existing timer if any
    _notificationCheckerTimer?.cancel();

    // Load configurable interval (for in-app checks, use half the background interval for faster response)
    final settingsService = NotificationSettingsService();
    settingsService.getCheckInterval().then((interval) {
      // For in-app, check more frequently (half the background interval, minimum 30 seconds)
      final inAppInterval = Duration(
        seconds: (interval.inSeconds / 2).clamp(30, 300).toInt(),
      );

      _notificationCheckerTimer = Timer.periodic(
        inAppInterval,
        (_) => _checkAndFireDueNotifications(),
      );
    });

    // Also check immediately
    _checkAndFireDueNotifications();
  }

  /// Stop notification checker
  void stopNotificationChecker() {
    _notificationCheckerTimer?.cancel();
    _notificationCheckerTimer = null;
  }

  /// Check and fire any due notifications (public method for manual triggering)
  Future<void> checkAndFireDueNotifications() async {
    await _checkAndFireDueNotifications();
  }

  /// Check and fire any due notifications (internal)
  Future<void> _checkAndFireDueNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ No user logged in, skipping notification check');
        return;
      }

      final now = DateTime.now();
      print('🔍 Checking due notifications for user: ${user.uid}');
      print('   Current time: $now');

      // Get all active reminders that are due
      final remindersSnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.collectionReminders)
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .where('scheduledTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      print('   Found ${remindersSnapshot.docs.length} due reminders');

      for (final doc in remindersSnapshot.docs) {
        final reminderData = doc.data();
        final scheduledTime =
            (reminderData['scheduledTime'] as Timestamp).toDate();
        final title = reminderData['title'] as String? ?? 'Reminder';
        final body = reminderData['description'] as String? ?? '';
        final reminderId = doc.id;
        final repeatInterval = reminderData['metadata']?['repeat'] as String?;
        final customIntervalDays =
            reminderData['metadata']?['customIntervalDays'] as int?;

        // Calculate notification ID (same as in reminder_service.dart)
        final notificationId = reminderId.hashCode.abs() % 2147483647;

        print('   📬 Firing due reminder: $title');
        print('      Scheduled: $scheduledTime');
        print('      Now: $now');
        print('      Overdue by: ${now.difference(scheduledTime)}');

        // Fire the notification immediately
        await showImmediateNotification(
          title: title,
          body: body,
          payload: reminderId,
        );

        // Cancel the scheduled notification if it exists
        await cancelNotification(notificationId);

        // Handle repeating reminders
        if (repeatInterval != null && repeatInterval != 'none') {
          DateTime nextScheduledTime;
          if (repeatInterval == 'daily') {
            nextScheduledTime = scheduledTime.add(const Duration(days: 1));
          } else if (repeatInterval == 'weekly') {
            nextScheduledTime = scheduledTime.add(const Duration(days: 7));
          } else if (repeatInterval == 'monthly') {
            nextScheduledTime = DateTime(
              scheduledTime.year,
              scheduledTime.month + 1,
              scheduledTime.day,
              scheduledTime.hour,
              scheduledTime.minute,
            );
          } else if (repeatInterval == 'custom' && customIntervalDays != null) {
            nextScheduledTime =
                scheduledTime.add(Duration(days: customIntervalDays));
          } else {
            // Unknown repeat interval, deactivate the reminder
            await doc.reference.update({'isActive': false});
            continue;
          }

          // Ensure next scheduled time is in the future
          if (nextScheduledTime.isBefore(now)) {
            // Calculate the next valid occurrence
            while (nextScheduledTime.isBefore(now)) {
              if (repeatInterval == 'daily') {
                nextScheduledTime =
                    nextScheduledTime.add(const Duration(days: 1));
              } else if (repeatInterval == 'weekly') {
                nextScheduledTime =
                    nextScheduledTime.add(const Duration(days: 7));
              } else if (repeatInterval == 'monthly') {
                nextScheduledTime = DateTime(
                  nextScheduledTime.year,
                  nextScheduledTime.month + 1,
                  nextScheduledTime.day,
                  nextScheduledTime.hour,
                  nextScheduledTime.minute,
                );
              } else if (repeatInterval == 'custom' &&
                  customIntervalDays != null) {
                nextScheduledTime =
                    nextScheduledTime.add(Duration(days: customIntervalDays));
              } else {
                break;
              }
            }
          }

          // Update the reminder with the next scheduled time
          await doc.reference.update({
            'scheduledTime': Timestamp.fromDate(nextScheduledTime),
          });

          // Reschedule the notification
          await scheduleNotification(
            id: notificationId,
            title: title,
            body: body,
            scheduledDate: nextScheduledTime,
            payload: reminderId,
            repeatInterval: repeatInterval,
            customIntervalDays: customIntervalDays,
          );

          print('      ✅ Rescheduled for: $nextScheduledTime');
        } else {
          // One-time reminder, deactivate it
          await doc.reference.update({'isActive': false});
          print('      ✅ Deactivated one-time reminder');
        }
      }

      print('✅ Notification check completed');
    } catch (e, stackTrace) {
      print('❌ Error checking due notifications: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    print('📱 Notification permission status: $notificationStatus');

    if (notificationStatus.isDenied) {
      print('⚠️ Notification permission denied');
      await openAppSettings();
    } else if (notificationStatus.isGranted) {
      print('✅ Notification permission granted');
    }

    // Request exact alarm permission for Android 12+ (API 31+)
    if (Platform.isAndroid) {
      try {
        // Check exact alarm permission status (Android 12+)
        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        print('📱 Exact alarm permission status: $exactAlarmStatus');

        if (!exactAlarmStatus.isGranted) {
          final requested = await Permission.scheduleExactAlarm.request();
          print('📱 Exact alarm permission requested: $requested');
          if (!requested.isGranted) {
            // guide users to system settings
            await openAppSettings();
          }
        } else {
          print('✅ Exact alarm permission granted');
        }
      } catch (e) {
        // Permission might not be available on older Android versions
        print('⚠️ Exact alarm permission not available: $e');
      }
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (initialized == true) {
      print('✅ Local notifications plugin initialized successfully');

      // Create notification channel for Android
      if (Platform.isAndroid) {
        const androidChannel = AndroidNotificationChannel(
          'femcare_channel',
          'FemCare Notifications',
          description: 'Notifications for FemCare+ app',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(androidChannel);
        print('✅ Android notification channel created');
      }
    } else {
      print('❌ Failed to initialize local notifications plugin');
      throw Exception('Failed to initialize local notifications');
    }
  }

  /// Configure Firebase Messaging
  Future<void> _configureFirebaseMessaging() async {
    // Request FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      // Save token to backend
      // await saveTokenToBackend(token);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle notification when app is opened from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Handle background message
  void _handleBackgroundMessage(RemoteMessage message) {
    // Navigate to appropriate screen based on message data
    // This will be handled by the app's navigation system
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'femcare_channel',
      'FemCare Notifications',
      channelDescription: 'Notifications for FemCare+ app',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use a valid 32-bit integer ID (max: 2,147,483,647)
    final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;
    await _localNotifications.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show an immediate local notification (used for testing/instant alerts)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    // Navigate to appropriate screen
  }

  /// Schedule local notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String? repeatInterval, // 'none', 'daily', 'weekly', 'monthly', or 'custom'
    int? customIntervalDays, // For custom repeat interval
  }) async {
    print('📅 Scheduling notification:');
    print('   ID: $id');
    print('   Title: $title');
    print('   Scheduled (local): $scheduledDate');
    print('   Now (local): ${DateTime.now()}');
    print('   Difference: ${scheduledDate.difference(DateTime.now())}');

    const androidDetails = AndroidNotificationDetails(
      'femcare_channel',
      'FemCare Notifications',
      channelDescription: 'Notifications for FemCare+ app',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      enableLights: true,
      channelShowBadge: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Determine the appropriate scheduling mode based on permissions
    AndroidScheduleMode scheduleMode =
        AndroidScheduleMode.inexactAllowWhileIdle;

    if (Platform.isAndroid) {
      try {
        // Check if exact alarm permission is granted (Android 12+)
        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        if (exactAlarmStatus.isGranted) {
          scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
          print('✅ Using exact alarm scheduling');
        } else {
          // Fallback to inexact scheduling if permission not granted
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
          print(
              '⚠️ Exact alarm permission not granted, using inexact scheduling');
        }
      } catch (e) {
        // Fallback to inexact scheduling on error (e.g., on older Android versions)
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        print('⚠️ Error checking exact alarm permission: $e');
      }
    }

    final scheduledTZ = _convertToTZDateTime(scheduledDate);
    final nowTZ = tz.TZDateTime.now(tz.local);
    print('   Scheduled (TZ): $scheduledTZ');
    print('   Now (TZ): $nowTZ');
    print('   TZ difference: ${scheduledTZ.difference(nowTZ)}');

    // Ensure scheduled time is in the future
    if (scheduledTZ.isBefore(nowTZ)) {
      print('❌ Scheduled time is in the past!');
      throw Exception('Scheduled time must be in the future');
    }

    try {
      // Handle repeating notifications
      if (repeatInterval != null && repeatInterval != 'none') {
        // For repeating notifications, use matchDateTimeComponents
        await _localNotifications.zonedSchedule(
          id,
          title,
          body,
          scheduledTZ,
          details,
          payload: payload,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: _getDateTimeComponents(repeatInterval),
        );
        print(
            '✅ Repeating notification scheduled: $title (${repeatInterval}) at $scheduledTZ (ID: $id)');
      } else {
        // One-time notification
        await _localNotifications.zonedSchedule(
          id,
          title,
          body,
          scheduledTZ,
          details,
          payload: payload,
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('✅ Notification scheduled: $title at $scheduledTZ (ID: $id)');
      }

      final pending = await _localNotifications.pendingNotificationRequests();
      final found = pending.where((p) => p.id == id).isNotEmpty;
      if (found) {
        print('✅ Verified pending notification with ID $id exists');
      } else {
        print('⚠️ WARNING: Pending notifications do not contain ID $id');
        for (final request in pending) {
          print('   Pending -> ID: ${request.id}, Title: ${request.title}');
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error scheduling notification: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get DateTimeComponents for repeating notifications
  DateTimeComponents? _getDateTimeComponents(String? repeatInterval) {
    switch (repeatInterval) {
      case 'daily':
        return DateTimeComponents.time;
      case 'weekly':
        return DateTimeComponents.dayOfWeekAndTime;
      case 'monthly':
        return DateTimeComponents.dayOfMonthAndTime;
      default:
        return null;
    }
  }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    print('✅ All notifications cancelled');
  }

  /// Get all pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  /// Convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  Future<void> _configureLocalTimezone() async {
    tz.initializeTimeZones();
    try {
      final locationName = await _detectLocalTimezone();
      tz.setLocalLocation(tz.getLocation(locationName));
      print('✅ Timezone initialized: $locationName');
    } catch (e) {
      print('⚠️ Unable to determine local timezone automatically: $e');
      final fallback = _timezoneFromOffset(DateTime.now().timeZoneOffset);
      try {
        tz.setLocalLocation(tz.getLocation(fallback));
        print('✅ Timezone fallback applied: $fallback');
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
        print('⚠️ Falling back to UTC timezone');
      }
    }
  }

  Future<String> _detectLocalTimezone() async {
    // Try to use native Android / iOS timezone via platform channel if available.
    // When not available, throw so we can fall back to offset mapping.
    if (Platform.isAndroid || Platform.isIOS) {
      // On modern Android/iOS, DateTime.now().timeZoneName often matches IANA names.
      final name = DateTime.now().timeZoneName;
      if (name.contains('/')) {
        return name;
      }
      throw Exception('Non-IANA timezone name: $name');
    }
    return 'UTC';
  }

  String _timezoneFromOffset(Duration offset) {
    final locations = tz.timeZoneDatabase.locations;
    for (final entry in locations.entries) {
      final location = entry.value;
      final currentOffset = tz.TZDateTime.now(location).timeZoneOffset;
      if (currentOffset == offset) {
        return entry.key;
      }
    }

    // Fallback to Etc/GMT format (note reversed sign convention)
    final hours = offset.inHours;
    final invertedHours = -hours;
    final sign = invertedHours >= 0 ? '+' : '-';
    final hourString = invertedHours.abs().toString().padLeft(2, '0');
    return 'Etc/GMT$sign$hourString';
  }

  /// Get FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}
