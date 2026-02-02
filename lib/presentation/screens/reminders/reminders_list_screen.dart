import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../services/reminder_service.dart';
import 'create_reminder_dialog.dart';

/// Screen to view, edit, and delete scheduled reminders
class RemindersListScreen extends ConsumerWidget {
  const RemindersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final reminderService = ReminderService();
    final remindersStream = reminderService.getUserReminders(user.userId);

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Reminders'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await showDialog(
                  context: context,
                  builder: (context) => CreateReminderDialog(
                    userId: user.userId,
                  ),
                );
                if (result == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reminder created')),
                  );
                }
              },
              tooltip: 'Create reminder',
            ),
          ],
        ),
        body: StreamBuilder<List<Reminder>>(
          stream: remindersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppTheme.errorRed),
                    ResponsiveConfig.heightBox(16),
                    Text(
                      'Error loading reminders',
                      style: ResponsiveConfig.textStyle(size: 16),
                    ),
                    ResponsiveConfig.heightBox(8),
                    Text(
                      snapshot.error.toString(),
                      style: ResponsiveConfig.textStyle(
                        size: 12,
                        color: AppTheme.mediumGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final reminders = snapshot.data ?? [];

            if (reminders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: AppTheme.mediumGray,
                    ),
                    ResponsiveConfig.heightBox(16),
                    Text(
                      'No reminders scheduled',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.w600,
                      ),
                    ),
                    ResponsiveConfig.heightBox(8),
                    Text(
                      'Tap the + button to create a reminder',
                      style: ResponsiveConfig.textStyle(
                        size: 14,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: ResponsiveConfig.padding(all: 16),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                final isPast = reminder.scheduledTime.isBefore(DateTime.now());
                final repeatInterval = reminder.metadata?['repeat'] as String?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: ResponsiveConfig.padding(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          isPast ? AppTheme.mediumGray : AppTheme.primaryPink,
                      child: Icon(
                        isPast ? Icons.notifications_off : Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      reminder.title,
                      style: ResponsiveConfig.textStyle(
                        size: 16,
                        weight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveConfig.heightBox(4),
                        if (reminder.description != null)
                          Text(
                            reminder.description!,
                            style: ResponsiveConfig.textStyle(
                              size: 14,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ResponsiveConfig.heightBox(4),
                        Text(
                          DateFormat('MMM d, y • h:mm a')
                              .format(reminder.scheduledTime),
                          style: ResponsiveConfig.textStyle(
                            size: 12,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                        if (repeatInterval != null && repeatInterval != 'none')
                          Text(
                            'Repeats: ${repeatInterval == 'custom' ? 'Every ${reminder.metadata?['customIntervalDays'] ?? 1} days' : repeatInterval}',
                            style: ResponsiveConfig.textStyle(
                              size: 12,
                              color: AppTheme.primaryPink,
                            ),
                          ),
                        if (isPast)
                          Text(
                            'Past due',
                            style: ResponsiveConfig.textStyle(
                              size: 12,
                              color: AppTheme.errorRed,
                            ),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                          onTap: () async {
                            await Future.delayed(
                                const Duration(milliseconds: 100));
                            if (!context.mounted) return;
                            final result = await showDialog(
                              context: context,
                              builder: (context) => CreateReminderDialog(
                                reminder: reminder,
                                userId: user.userId,
                              ),
                            );
                            if (result == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Reminder updated')),
                              );
                            }
                          },
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(
                                reminder.isActive
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(reminder.isActive ? 'Pause' : 'Resume'),
                            ],
                          ),
                          onTap: () async {
                            await Future.delayed(
                                const Duration(milliseconds: 100));
                            final updatedReminder = Reminder(
                              id: reminder.id,
                              userId: reminder.userId,
                              type: reminder.type,
                              title: reminder.title,
                              description: reminder.description,
                              scheduledTime: reminder.scheduledTime,
                              isActive: !reminder.isActive,
                              metadata: reminder.metadata,
                            );
                            await reminderService
                                .updateReminder(updatedReminder);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    reminder.isActive
                                        ? 'Reminder paused'
                                        : 'Reminder resumed',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete,
                                  size: 20, color: AppTheme.errorRed),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: AppTheme.errorRed)),
                            ],
                          ),
                          onTap: () async {
                            await Future.delayed(
                                const Duration(milliseconds: 100));
                            if (!context.mounted) return;

                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Reminder'),
                                content: Text(
                                  'Are you sure you want to delete "${reminder.title}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.errorRed,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && reminder.id != null) {
                              await reminderService
                                  .deleteReminder(reminder.id!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Reminder deleted')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
