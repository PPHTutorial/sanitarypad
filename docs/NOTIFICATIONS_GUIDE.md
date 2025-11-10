# Notifications System Guide

## Overview

The FemCare+ app uses a comprehensive notification system that automatically schedules reminders based on user data input. Notifications are triggered by various user actions and data entries.

## How Notifications Work

### 1. **Automatic Notification Scheduling**

The app automatically schedules notifications when users:
- **Log a period cycle**: Schedules period prediction reminders
- **Change a pad**: Schedules pad change reminders (every 4 hours by default)
- **Track fertility**: Schedules fertile window notifications
- **Log wellness entries**: Schedules daily wellness check reminders

### 2. **Notification Types**

#### **Period Prediction Notifications**
- **When**: 1 day before predicted period start
- **Trigger**: When a new cycle is logged or updated
- **Message**: "Your period is predicted to start soon"
- **Calculation**: Based on average cycle length from user's cycle history

#### **Pad Change Reminders**
- **When**: Every 4 hours (configurable)
- **Trigger**: When a pad change is logged
- **Message**: "Time to change your pad"
- **Logic**: 
  - If last change was >4 hours ago: Immediate reminder (5 minutes)
  - Otherwise: Reminder scheduled for 4 hours from last change

#### **Wellness Check Reminders**
- **When**: Daily at 9:00 AM (configurable)
- **Trigger**: Automatically scheduled daily
- **Message**: "Daily Wellness Check - Take a moment to log your wellness today"

#### **Fertility Window Notifications**
- **When**: 1 day before fertile window starts
- **Trigger**: When fertility entries are logged
- **Message**: "Fertile Window Approaching"
- **Calculation**: Based on ovulation prediction from cycle and fertility data

### 3. **Notification Flow**

```
User Action → Service Method → Notification Scheduler → Reminder Service → Local Notification
```

**Example: User logs a period**
1. User logs period in `LogPeriodScreen`
2. `CycleService.createCycle()` is called
3. After cycle is saved, `NotificationSchedulerService.onCycleCreated()` is called
4. Scheduler calculates next predicted period date
5. Creates reminder via `ReminderService.createPeriodPredictionReminder()`
6. `ReminderService` schedules local notification via `NotificationService.scheduleNotification()`
7. Notification appears at scheduled time

### 4. **Notification Service Architecture**

#### **NotificationService**
- Handles local notifications (flutter_local_notifications)
- Handles Firebase Cloud Messaging (FCM)
- Manages notification permissions
- Schedules and cancels notifications

#### **ReminderService**
- Manages reminder data in Firestore
- Creates, updates, and deletes reminders
- Links reminders to notifications
- Provides helper methods for common reminder types

#### **NotificationSchedulerService**
- Automatically schedules notifications based on user data
- Monitors data changes and reschedules notifications
- Initializes all notifications when app starts or user logs in
- Handles notification lifecycle management

### 5. **Initialization**

Notifications are initialized in two places:

1. **App Startup** (`main.dart`):
   ```dart
   final notificationService = NotificationService();
   await notificationService.initialize();
   ```

2. **After User Login**:
   - `NotificationSchedulerService.initialize()` is called
   - Schedules all notifications based on current user data
   - Happens automatically when user data is available

### 6. **User Settings**

Users can control notifications in **Settings → Notification Settings**:
- Enable/disable all notifications
- Toggle specific notification types:
  - Period Reminders
  - Pad Change Reminders
  - Wellness Check Reminders
  - Custom Reminders

### 7. **Notification Data Flow**

```
┌─────────────────┐
│  User Action    │
│  (Log Cycle)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  CycleService   │
│  createCycle()  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ NotificationScheduler   │
│ onCycleCreated()        │
└────────┬────────────────┘
         │
         ▼
┌─────────────────┐
│ ReminderService │
│ createReminder()│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│NotificationService│
│scheduleNotification()│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Local Notification│
│ (Scheduled)     │
└─────────────────┘
```

### 8. **Notification Timing Examples**

#### **Period Prediction**
- User logs period on Jan 1 (28-day cycle)
- Next period predicted: Jan 29
- Notification scheduled: Jan 28 (1 day before)

#### **Pad Change**
- User changes pad at 10:00 AM
- Next reminder scheduled: 2:00 PM (4 hours later)
- If user changes pad at 3:00 PM, reminder reschedules to 7:00 PM

#### **Wellness Check**
- Scheduled daily at 9:00 AM
- Repeats every day until disabled

#### **Fertility Window**
- User logs fertility data
- Ovulation predicted: Feb 15
- Fertile window: Feb 10-15
- Notification scheduled: Feb 9 (1 day before)

### 9. **Best Practices**

1. **Always check user settings** before scheduling notifications
2. **Cancel old reminders** before creating new ones to avoid duplicates
3. **Handle errors gracefully** - notification failures shouldn't break app functionality
4. **Reschedule on data updates** - when cycles/pads are updated, reschedule notifications
5. **Respect user preferences** - honor notification settings from user profile

### 10. **Testing Notifications**

To test notifications:
1. Go to **Settings → Notification Settings**
2. Tap "Send Test Notification"
3. Notification will appear in 2 seconds

Or:
1. Log a period cycle
2. Check that period prediction reminder is scheduled
3. Change a pad
4. Check that pad change reminder is scheduled

### 11. **Troubleshooting**

**Notifications not appearing?**
- Check notification permissions in device settings
- Verify notifications are enabled in app settings
- Check that scheduled time is in the future
- Ensure app has necessary permissions

**Duplicate notifications?**
- Old reminders may not be canceled properly
- Check `_cancelRemindersByType()` is called before creating new reminders

**Notifications at wrong time?**
- Check device timezone settings
- Verify notification scheduling uses correct timezone
- Check that `tz.initializeTimeZones()` is called

## Code Examples

### Scheduling a Notification After Cycle Creation

```dart
// In CycleService.createCycle()
await _storageService.saveDocument(...);

// Schedule notifications
try {
  final scheduler = NotificationSchedulerService();
  await scheduler.onCycleCreated(user.uid);
} catch (e) {
  print('Error scheduling notifications: $e');
}
```

### Creating a Custom Reminder

```dart
final reminderService = ReminderService();
await reminderService.createCustomReminder(
  userId: userId,
  title: 'Custom Reminder',
  description: 'This is a custom reminder',
  scheduledTime: DateTime.now().add(Duration(hours: 2)),
  metadata: {'custom': 'data'},
);
```

### Checking Notification Status

```dart
final notificationService = NotificationService();
final token = await notificationService.getToken();
print('FCM Token: $token');
```

## Summary

The notification system in FemCare+ is designed to be:
- **Automatic**: Schedules based on user data without manual intervention
- **Intelligent**: Calculates timing based on user's historical data
- **User-friendly**: Respects user preferences and settings
- **Reliable**: Handles errors gracefully and doesn't break app functionality
- **Flexible**: Supports multiple notification types and custom reminders

