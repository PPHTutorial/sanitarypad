import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/notification_service.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../reminders/create_reminder_dialog.dart';

/// Notification settings screen
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  final _notificationService = NotificationService();
  bool _notificationsEnabled = true;
  bool _periodReminders = true;
  bool _padChangeReminders = true;
  bool _wellnessReminders = true;
  bool _customReminders = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load from user settings
    setState(() {
      _notificationsEnabled = true;
      _periodReminders = true;
      _padChangeReminders = true;
      _wellnessReminders = true;
      _customReminders = true;
    });
  }

  Future<void> _requestPermissions() async {
    try {
      await _notificationService.initialize();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification permissions granted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
        ),
        body: SingleChildScrollView(
          padding: ResponsiveConfig.padding(all: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Enable Notifications
              Card(
                child: SwitchListTile(
                  title: const Text('Enable Notifications'),
                  subtitle: const Text(
                    'Receive reminders and important updates',
                  ),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    if (value) {
                      _requestPermissions();
                    }
                  },
                ),
              ),
              ResponsiveConfig.heightBox(16),

              if (_notificationsEnabled) ...[
                // Period Reminders
                Card(
                  child: SwitchListTile(
                    title: const Text('Period Reminders'),
                    subtitle: const Text(
                      'Get notified when your period is predicted to start',
                    ),
                    value: _periodReminders,
                    onChanged: (value) {
                      setState(() => _periodReminders = value);
                    },
                  ),
                ),
                ResponsiveConfig.heightBox(12),

                // Pad Change Reminders
                Card(
                  child: SwitchListTile(
                    title: const Text('Pad Change Reminders'),
                    subtitle: const Text(
                      'Reminders to change your sanitary pad',
                    ),
                    value: _padChangeReminders,
                    onChanged: (value) {
                      setState(() => _padChangeReminders = value);
                    },
                  ),
                ),
                ResponsiveConfig.heightBox(12),

                // Wellness Reminders
                Card(
                  child: SwitchListTile(
                    title: const Text('Wellness Check Reminders'),
                    subtitle: const Text(
                      'Daily reminders to log your wellness',
                    ),
                    value: _wellnessReminders,
                    onChanged: (value) {
                      setState(() => _wellnessReminders = value);
                    },
                  ),
                ),
                ResponsiveConfig.heightBox(12),

                // Custom Reminders
                Card(
                  child: SwitchListTile(
                    title: const Text('Custom Reminders'),
                    subtitle: const Text(
                      'Enable custom reminders you create',
                    ),
                    value: _customReminders,
                    onChanged: (value) {
                      setState(() => _customReminders = value);
                    },
                  ),
                ),
                ResponsiveConfig.heightBox(24),

                // View Reminders Button
                OutlinedButton.icon(
                  onPressed: () => context.push('/reminders'),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('View All Reminders'),
                ),
                ResponsiveConfig.heightBox(12),

                // Create Reminder Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final userAsync = ref.read(currentUserStreamProvider);
                    final user = userAsync.value;
                    if (user == null) return;

                    final result = await showDialog(
                      context: context,
                      builder: (context) => CreateReminderDialog(
                        userId: user.userId,
                        defaultType: 'custom',
                        defaultTitle: 'Custom Reminder',
                      ),
                    );

                    if (result == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reminder created successfully'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_alarm),
                  label: const Text('Create Reminder'),
                ),
                ResponsiveConfig.heightBox(12),

                // Test Notification Button
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await _notificationService.showImmediateNotification(
                        title: 'Test Notification',
                        body: 'This is a test notification from FemCare+',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification sent'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.notifications),
                  label: const Text('Send Test Notification'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
