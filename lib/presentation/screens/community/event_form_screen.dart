import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../data/models/event_model.dart';
import '../../../services/event_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/credit_manager.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  final String? category;
  final String? groupId;
  final String? groupName;

  const EventFormScreen({
    super.key,
    this.category,
    this.groupId,
    this.groupName,
  });

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _onlineLinkController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  final _eventService = EventService();
  String _selectedCategory = 'general';
  bool _isOnline = false;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _selectedCategory = widget.category!;
    }
    if (widget.category == "all") _selectedCategory = "general";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _onlineLinkController.dispose();
    _maxAttendeesController.dispose();
    super.dispose();
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserStreamProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End date must be after start date')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Credit Check
      final hasCredit = await ref
          .read(creditManagerProvider)
          .requestCredit(context, ActionType.createEvent);
      if (!hasCredit) {
        setState(() => _isLoading = false);
        return;
      }

      final event = EventModel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        createdBy: user.userId,
        groupId: widget.groupId,
        startDate: startDateTime,
        endDate: endDateTime,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        onlineLink: _onlineLinkController.text.trim().isEmpty
            ? null
            : _onlineLinkController.text.trim(),
        isOnline: _isOnline,
        maxAttendees: _maxAttendeesController.text.trim().isEmpty
            ? 0
            : int.tryParse(_maxAttendeesController.text.trim()) ?? 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _eventService.createEvent(event);

      // Consume Credit
      await ref
          .read(creditManagerProvider)
          .consumeCredits(ActionType.createEvent);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Event'),
        ),
        body: SingleChildScrollView(
          padding: ResponsiveConfig.padding(all: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.groupId != null)
                  Card(
                    margin: ResponsiveConfig.margin(all: 0),
                    color: AppTheme.primaryPink.withOpacity(0.12),
                    child: Padding(
                      padding: ResponsiveConfig.padding(all: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.groups_outlined,
                              color: AppTheme.primaryPink),
                          ResponsiveConfig.widthBox(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Group event',
                                  style: ResponsiveConfig.textStyle(
                                    size: 14,
                                    weight: FontWeight.bold,
                                    color: AppTheme.primaryPink,
                                  ),
                                ),
                                ResponsiveConfig.heightBox(4),
                                Text(
                                  widget.groupName ?? 'Linked community',
                                  style: ResponsiveConfig.textStyle(size: 13),
                                ),
                                ResponsiveConfig.heightBox(4),
                                Text(
                                  'Members of this group will see and engage with this event first.',
                                  style: ResponsiveConfig.textStyle(
                                    size: 12,
                                    color: AppTheme.mediumGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (widget.groupId != null) ResponsiveConfig.heightBox(16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
                    hintText: 'Enter event title',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an event title';
                    }
                    return null;
                  },
                ),
                ResponsiveConfig.heightBox(16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe your event',
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                ResponsiveConfig.heightBox(16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(
                        value: 'pregnancy', child: Text('Pregnancy')),
                    DropdownMenuItem(
                        value: 'fertility', child: Text('Fertility')),
                    DropdownMenuItem(
                        value: 'skincare', child: Text('Skincare')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                ResponsiveConfig.heightBox(16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                      'Start Date: ${DateFormat('MMM d, y').format(_startDate)}'),
                  trailing: Text(_startTime.format(context)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _startDate = date;
                        // If end date is before new start date, update end date to match start date
                        if (_endDate.isBefore(_startDate)) {
                          _endDate = _startDate;
                        }
                      });
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: const Text('Start Time'),
                  trailing: Text(_startTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (time != null) {
                      setState(() => _startTime = time);
                    }
                  },
                ),
                ResponsiveConfig.heightBox(8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                      'End Date: ${DateFormat('MMM d, y').format(_endDate)}'),
                  trailing: Text(_endTime.format(context)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: _startDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: const Text('End Time'),
                  trailing: Text(_endTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (time != null) {
                      setState(() => _endTime = time);
                    }
                  },
                ),
                ResponsiveConfig.heightBox(16),
                SwitchListTile(
                  title: const Text('Online Event'),
                  subtitle: const Text('Event will be held online'),
                  value: _isOnline,
                  onChanged: (value) => setState(() => _isOnline = value),
                ),
                ResponsiveConfig.heightBox(16),
                if (!_isOnline)
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'Enter event location',
                    ),
                  ),
                if (_isOnline) ...[
                  ResponsiveConfig.heightBox(16),
                  TextFormField(
                    controller: _onlineLinkController,
                    decoration: const InputDecoration(
                      labelText: 'Online Link',
                      hintText: 'Enter meeting link (Zoom, Google Meet, etc.)',
                    ),
                  ),
                ],
                ResponsiveConfig.heightBox(16),
                TextFormField(
                  controller: _maxAttendeesController,
                  decoration: const InputDecoration(
                    labelText: 'Max Attendees (optional)',
                    hintText: 'Leave empty for unlimited',
                  ),
                  keyboardType: TextInputType.number,
                ),
                ResponsiveConfig.heightBox(24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveEvent,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
