import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../data/models/event_model.dart';
import '../../../services/event_service.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final _eventService = EventService();
  bool _isRegistering = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Event Details'),
        ),
        body: FutureBuilder<EventModel?>(
          future: _eventService.getEvent(widget.eventId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    ResponsiveConfig.heightBox(16),
                    Text(
                      'Event not found',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveConfig.heightBox(16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            final event = snapshot.data!;

            return FutureBuilder<bool>(
              future: _eventService.isRegistered(widget.eventId, user.userId),
              builder: (context, registeredSnapshot) {
                final isRegistered = registeredSnapshot.data ?? false;
                final isFull = event.maxAttendees > 0 &&
                    event.attendeeCount >= event.maxAttendees;

                return SingleChildScrollView(
                  padding: ResponsiveConfig.padding(all: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: ResponsiveConfig.padding(all: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor:
                                        AppTheme.primaryPink.withOpacity(0.1),
                                    child: Icon(
                                      Icons.event,
                                      size: 32,
                                      color: AppTheme.primaryPink,
                                    ),
                                  ),
                                  ResponsiveConfig.widthBox(16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: ResponsiveConfig.textStyle(
                                            size: 20,
                                            weight: FontWeight.bold,
                                          ),
                                        ),
                                        ResponsiveConfig.heightBox(4),
                                        Text(
                                          DateFormat('EEEE, MMMM d, y • h:mm a')
                                              .format(event.startDate),
                                          style: ResponsiveConfig.textStyle(
                                            size: 14,
                                            color: AppTheme.mediumGray,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              ResponsiveConfig.heightBox(16),
                              Text(
                                event.description,
                                style: ResponsiveConfig.textStyle(size: 14),
                              ),
                              ResponsiveConfig.heightBox(16),
                              if (event.location != null) ...[
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        size: 16, color: AppTheme.mediumGray),
                                    ResponsiveConfig.widthBox(8),
                                    Text(
                                      event.location!,
                                      style: ResponsiveConfig.textStyle(
                                        size: 14,
                                        color: AppTheme.mediumGray,
                                      ),
                                    ),
                                  ],
                                ),
                                ResponsiveConfig.heightBox(8),
                              ],
                              if (event.isOnline &&
                                  event.onlineLink != null) ...[
                                Row(
                                  children: [
                                    Icon(Icons.link,
                                        size: 16, color: AppTheme.mediumGray),
                                    ResponsiveConfig.widthBox(8),
                                    Expanded(
                                      child: Text(
                                        event.onlineLink!,
                                        style: ResponsiveConfig.textStyle(
                                          size: 14,
                                          color: AppTheme.primaryPink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ResponsiveConfig.heightBox(8),
                              ],
                              if (event.maxAttendees > 0) ...[
                                Row(
                                  children: [
                                    Icon(Icons.people_outline,
                                        size: 16, color: AppTheme.mediumGray),
                                    ResponsiveConfig.widthBox(8),
                                    Text(
                                      '${event.attendeeCount}/${event.maxAttendees} attendees',
                                      style: ResponsiveConfig.textStyle(
                                        size: 14,
                                        color: AppTheme.mediumGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      ResponsiveConfig.heightBox(16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_isRegistering ||
                                  (isFull && !isRegistered))
                              ? null
                              : () async {
                                  setState(() => _isRegistering = true);
                                  try {
                                    if (isRegistered) {
                                      await _eventService.cancelRegistration(
                                        widget.eventId,
                                        user.userId,
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Registration cancelled'),
                                          ),
                                        );
                                        setState(() {});
                                      }
                                    } else {
                                      await _eventService.registerForEvent(
                                        widget.eventId,
                                        user.userId,
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Registered successfully'),
                                          ),
                                        );
                                        setState(() {});
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Error: ${e.toString()}'),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isRegistering = false);
                                    }
                                  }
                                },
                          icon: Icon(isRegistered
                              ? Icons.cancel
                              : Icons.event_available),
                          label: Text(_isRegistering
                              ? 'Processing...'
                              : isFull && !isRegistered
                                  ? 'Event Full'
                                  : isRegistered
                                      ? 'Cancel Registration'
                                      : 'Register for Event'),
                        ),
                      ),
                    ],
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
