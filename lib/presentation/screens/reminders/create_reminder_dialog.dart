import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/dialog_wrapper.dart';
import '../../../services/reminder_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/credit_manager.dart';

/// Dialog for creating/editing reminders with full customization
class CreateReminderDialog extends ConsumerStatefulWidget {
  final Reminder? reminder;
  final String userId;
  final String? defaultType;
  final String? defaultTitle;
  final String? defaultDescription;

  const CreateReminderDialog({
    super.key,
    this.reminder,
    required this.userId,
    this.defaultType,
    this.defaultTitle,
    this.defaultDescription,
  });

  @override
  ConsumerState<CreateReminderDialog> createState() =>
      _CreateReminderDialogState();
}

class _CreateReminderDialogState extends ConsumerState<CreateReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  String _repeatInterval = 'none'; // none, daily, weekly, monthly, custom
  int _customIntervalDays = 1;
  bool _enableSnooze = true;
  int _snoozeMinutes = 10;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      // Editing existing reminder
      _titleController.text = widget.reminder!.title;
      _descriptionController.text = widget.reminder!.description ?? '';
      _selectedDate = widget.reminder!.scheduledTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.reminder!.scheduledTime);
      _isActive = widget.reminder!.isActive;

      // Parse metadata for repeat and snooze
      final metadata = widget.reminder!.metadata ?? {};
      _repeatInterval = metadata['repeat'] ?? 'none';
      _customIntervalDays = metadata['customIntervalDays'] ?? 1;
      _enableSnooze = metadata['enableSnooze'] ?? true;
      _snoozeMinutes = metadata['snoozeMinutes'] ?? 10;
    } else {
      // Creating new reminder
      _titleController.text = widget.defaultTitle ?? '';
      _descriptionController.text = widget.defaultDescription ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime _getScheduledDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    // Credit Check
    final hasCredit = await ref
        .read(creditManagerProvider)
        .requestCredit(context, ActionType.notification);
    if (!hasCredit) return;

    final scheduledTime = _getScheduledDateTime();

    // Ensure scheduled time is in the future
    if (scheduledTime.isBefore(DateTime.now())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduled time must be in the future'),
        ),
      );
      return;
    }

    final reminder = Reminder(
      id: widget.reminder?.id,
      userId: widget.userId,
      type: widget.defaultType ?? widget.reminder?.type ?? 'custom',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      scheduledTime: scheduledTime,
      isActive: _isActive,
      metadata: {
        'repeat': _repeatInterval,
        if (_repeatInterval == 'custom')
          'customIntervalDays': _customIntervalDays,
        'enableSnooze': _enableSnooze,
        'snoozeMinutes': _snoozeMinutes,
      },
    );

    try {
      final reminderService = ReminderService();
      if (widget.reminder != null) {
        await reminderService.updateReminder(reminder);
      } else {
        await reminderService.createReminder(reminder);
      }

      await ref
          .read(creditManagerProvider)
          .consumeCredits(ActionType.notification);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.reminder != null ? 'Reminder updated' : 'Reminder scheduled',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DialogWrapper(
        child: Material(
      borderRadius: ResponsiveConfig.borderRadius(16),
      type: MaterialType.card,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: ResponsiveConfig.padding(all: 20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.reminder != null ? 'Edit Reminder' : 'Create Reminder',
                  style: ResponsiveConfig.textStyle(
                    size: 20,
                    weight: FontWeight.bold,
                  ),
                ),
                ResponsiveConfig.heightBox(24),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Reminder title',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                ResponsiveConfig.heightBox(16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional description',
                  ),
                  maxLines: 2,
                ),
                ResponsiveConfig.heightBox(16),

                // Date picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                      'Date: ${DateFormat('MMM d, y').format(_selectedDate)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
                ResponsiveConfig.heightBox(16),

                // Time picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_outlined),
                  title: Text('Time: ${_selectedTime.format(context)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (picked != null) {
                      setState(() => _selectedTime = picked);
                    }
                  },
                ),
                ResponsiveConfig.heightBox(16),

                // Repeat interval
                DropdownButtonFormField<String>(
                  value: _repeatInterval,
                  decoration: const InputDecoration(
                    labelText: 'Repeat',
                    icon: Icon(Icons.repeat_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('No repeat')),
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(
                        value: 'custom', child: Text('Custom interval')),
                  ],
                  onChanged: (value) =>
                      setState(() => _repeatInterval = value ?? 'none'),
                ),
                ResponsiveConfig.heightBox(16),

                // Custom interval days
                if (_repeatInterval == 'custom') ...[
                  TextFormField(
                    initialValue: _customIntervalDays.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Repeat every (days)',
                    ),
                    validator: (value) {
                      final days = int.tryParse(value ?? '');
                      if (days == null || days < 1) {
                        return 'Enter a valid number (1 or more)';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final days = int.tryParse(value);
                      if (days != null && days >= 1) {
                        setState(() => _customIntervalDays = days);
                      }
                    },
                  ),
                  ResponsiveConfig.heightBox(16),
                ],

                // Snooze options
                SwitchListTile(
                  title: const Text('Enable snooze'),
                  subtitle: const Text('Allow snoozing notifications'),
                  value: _enableSnooze,
                  onChanged: (value) => setState(() => _enableSnooze = value),
                ),
                if (_enableSnooze) ...[
                  ResponsiveConfig.heightBox(8),
                  TextFormField(
                    initialValue: _snoozeMinutes.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Snooze duration (minutes)',
                    ),
                    validator: (value) {
                      final minutes = int.tryParse(value ?? '');
                      if (minutes == null || minutes < 1) {
                        return 'Enter a valid number (1 or more)';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final minutes = int.tryParse(value);
                      if (minutes != null && minutes >= 1) {
                        setState(() => _snoozeMinutes = minutes);
                      }
                    },
                  ),
                  ResponsiveConfig.heightBox(16),
                ],

                // Active toggle
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Enable this reminder'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                ResponsiveConfig.heightBox(24),

                // Preview
                Card(
                  color: AppTheme.primaryPink.withOpacity(0.1),
                  child: Padding(
                    padding: ResponsiveConfig.padding(all: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview',
                          style: ResponsiveConfig.textStyle(
                            size: 14,
                            weight: FontWeight.w600,
                          ),
                        ),
                        ResponsiveConfig.heightBox(8),
                        Text(
                          'Scheduled: ${DateFormat('MMM d, y • h:mm a').format(_getScheduledDateTime())}',
                          style: ResponsiveConfig.textStyle(size: 12),
                        ),
                        if (_repeatInterval != 'none')
                          Text(
                            'Repeats: ${_repeatInterval == 'custom' ? 'Every $_customIntervalDays days' : _repeatInterval}',
                            style: ResponsiveConfig.textStyle(size: 12),
                          ),
                      ],
                    ),
                  ),
                ),
                ResponsiveConfig.heightBox(24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ResponsiveConfig.widthBox(8),
                    ElevatedButton(
                      onPressed: _saveReminder,
                      child:
                          Text(widget.reminder != null ? 'Update' : 'Create'),
                    ),
                  ],
                ),
              ]),
        ),
      ),
    ));
  }
}
