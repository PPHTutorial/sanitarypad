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

class EventsListScreen extends ConsumerStatefulWidget {
  final String category; // 'pregnancy', 'fertility', 'skincare', 'all'

  const EventsListScreen({
    super.key,
    this.category = 'all',
  });

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> {
  final _eventService = EventService();

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final eventsStream = widget.category == 'all'
        ? _eventService.getUpcomingEvents()
        : _eventService.getEventsByCategory(widget.category);

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.category == 'all'
                ? 'Upcoming Events'
                : '${widget.category[0].toUpperCase()}${widget.category.substring(1)} Events',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Create Event',
              onPressed: () =>
                  context.push('/events/create', extra: widget.category),
            ),
          ],
        ),
        body: StreamBuilder<List<EventModel>>(
          stream: eventsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final events = snapshot.data ?? [];

            if (events.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 64,
                      color: AppTheme.mediumGray,
                    ),
                    ResponsiveConfig.heightBox(16),
                    Text(
                      'No upcoming events',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveConfig.heightBox(8),
                    Text(
                      'Create an event to get started!',
                      style: ResponsiveConfig.textStyle(
                        size: 14,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    ResponsiveConfig.heightBox(24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/events/create',
                          extra: widget.category),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Event'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: ResponsiveConfig.padding(all: 16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  margin: ResponsiveConfig.margin(bottom: 12),
                  child: ListTile(
                    contentPadding: ResponsiveConfig.padding(all: 16),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryPink.withOpacity(0.1),
                      child: const Icon(
                        Icons.event,
                        color: AppTheme.primaryPink,
                      ),
                    ),
                    title: Text(
                      event.title,
                      style: ResponsiveConfig.textStyle(
                        size: 16,
                        weight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveConfig.heightBox(4),
                        Text(
                          event.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ResponsiveConfig.textStyle(
                            size: 14,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                        ResponsiveConfig.heightBox(8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: AppTheme.mediumGray,
                            ),
                            ResponsiveConfig.widthBox(4),
                            Text(
                              DateFormat('MMM d, y • h:mm a')
                                  .format(event.startDate),
                              style: ResponsiveConfig.textStyle(
                                size: 12,
                                color: AppTheme.mediumGray,
                              ),
                            ),
                          ],
                        ),
                        if (event.maxAttendees > 0) ...[
                          ResponsiveConfig.heightBox(4),
                          Row(
                            children: [
                              const Icon(
                                Icons.people_outline,
                                size: 16,
                                color: AppTheme.mediumGray,
                              ),
                              ResponsiveConfig.widthBox(4),
                              Text(
                                '${event.attendeeCount}/${event.maxAttendees} attendees',
                                style: ResponsiveConfig.textStyle(
                                  size: 12,
                                  color: AppTheme.mediumGray,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () => context.push('/events/${event.id}'),
                    ),
                    onTap: () => context.push('/events/${event.id}'),
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
