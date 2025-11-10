import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import 'notification_service.dart';

/// Reminder model
class Reminder {
  final String? id;
  final String userId;
  final String type;
  final String title;
  final String? description;
  final DateTime scheduledTime;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  Reminder({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.description,
    required this.scheduledTime,
    this.isActive = true,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map, String id) {
    return Reminder(
      id: id,
      userId: map['userId'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      scheduledTime: (map['scheduledTime'] as Timestamp).toDate(),
      isActive: map['isActive'] as bool? ?? true,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Reminder service for managing notifications
class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Create a reminder
  Future<String> createReminder(Reminder reminder) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.collectionReminders)
          .add(reminder.toMap());

      // Schedule local notification
      if (reminder.isActive && reminder.scheduledTime.isAfter(DateTime.now())) {
        // Use a valid 32-bit integer ID (max: 2,147,483,647)
        final notificationId = docRef.id.hashCode.abs() % 2147483647;
        await _notificationService.scheduleNotification(
          id: notificationId,
          title: reminder.title,
          body: reminder.description ?? '',
          scheduledDate: reminder.scheduledTime,
        );
      }

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update a reminder
  Future<void> updateReminder(Reminder reminder) async {
    if (reminder.id == null) {
      throw Exception('Reminder ID is required for update');
    }

    try {
      await _firestore
          .collection(AppConstants.collectionReminders)
          .doc(reminder.id)
          .update(reminder.toMap());

      // Update local notification
      if (reminder.isActive && reminder.scheduledTime.isAfter(DateTime.now())) {
        // Use a valid 32-bit integer ID (max: 2,147,483,647)
        final notificationId = reminder.id!.hashCode.abs() % 2147483647;
        await _notificationService.scheduleNotification(
          id: notificationId,
          title: reminder.title,
          body: reminder.description ?? '',
          scheduledDate: reminder.scheduledTime,
        );
      } else {
        final notificationId = reminder.id!.hashCode.abs() % 2147483647;
        await _notificationService.cancelNotification(notificationId);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a reminder
  Future<void> deleteReminder(String reminderId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionReminders)
          .doc(reminderId)
          .delete();

      // Cancel local notification
      // Use a valid 32-bit integer ID (max: 2,147,483,647)
      final notificationId = reminderId.hashCode.abs() % 2147483647;
      await _notificationService.cancelNotification(notificationId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user reminders
  Stream<List<Reminder>> getUserReminders(String userId) {
    return _firestore
        .collection(AppConstants.collectionReminders)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('scheduledTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Reminder.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Create pad change reminder
  Future<String> createPadChangeReminder({
    required String userId,
    required DateTime scheduledTime,
  }) async {
    return await createReminder(
      Reminder(
        userId: userId,
        type: AppConstants.reminderPadChange,
        title: 'Time to change your pad',
        description: 'Remember to change your sanitary pad for hygiene',
        scheduledTime: scheduledTime,
        metadata: {'reminderHours': AppConstants.defaultPadChangeReminderHours},
      ),
    );
  }

  /// Create period prediction reminder
  Future<String> createPeriodPredictionReminder({
    required String userId,
    required DateTime predictedDate,
  }) async {
    return await createReminder(
      Reminder(
        userId: userId,
        type: AppConstants.reminderPeriodPrediction,
        title: 'Your period is predicted to start soon',
        description:
            'Based on your cycle history, your period may start around ${predictedDate.toString().split(' ')[0]}',
        scheduledTime: predictedDate.subtract(const Duration(days: 1)),
        metadata: {'predictedDate': predictedDate.toIso8601String()},
      ),
    );
  }

  /// Create wellness check reminder
  Future<String> createWellnessCheckReminder({
    required String userId,
    required DateTime scheduledTime,
  }) async {
    return await createReminder(
      Reminder(
        userId: userId,
        type: AppConstants.reminderWellnessCheck,
        title: 'Daily Wellness Check',
        description: 'Take a moment to log your wellness today',
        scheduledTime: scheduledTime,
      ),
    );
  }

  /// Create custom reminder
  Future<String> createCustomReminder({
    required String userId,
    required String title,
    String? description,
    required DateTime scheduledTime,
    Map<String, dynamic>? metadata,
  }) async {
    return await createReminder(
      Reminder(
        userId: userId,
        type: AppConstants.reminderCustom,
        title: title,
        description: description,
        scheduledTime: scheduledTime,
        metadata: metadata,
      ),
    );
  }
}
