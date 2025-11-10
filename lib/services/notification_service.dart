import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Notification service
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize notifications
  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure Firebase Messaging
    await _configureFirebaseMessaging();
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    if (notificationStatus.isDenied) {
      // Handle denied permission
    }

    // Request exact alarm permission for Android 12+ (API 31+)
    if (Platform.isAndroid) {
      try {
        // Check exact alarm permission status (Android 12+)
        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        if (exactAlarmStatus.isDenied || exactAlarmStatus.isPermanentlyDenied) {
          await Permission.scheduleExactAlarm.request();
        }
      } catch (e) {
        // Permission might not be available on older Android versions
        print('Exact alarm permission not available: $e');
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

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
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

    // Determine the appropriate scheduling mode based on permissions
    AndroidScheduleMode scheduleMode =
        AndroidScheduleMode.inexactAllowWhileIdle;

    if (Platform.isAndroid) {
      try {
        // Check if exact alarm permission is granted (Android 12+)
        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        if (exactAlarmStatus.isGranted) {
          scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
        } else {
          // Fallback to inexact scheduling if permission not granted
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
          print('Exact alarm permission not granted, using inexact scheduling');
        }
      } catch (e) {
        // Fallback to inexact scheduling on error (e.g., on older Android versions)
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        print('Error checking exact alarm permission: $e');
      }
    }

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      _convertToTZDateTime(scheduledDate),
      details,
      payload: payload,
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
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
