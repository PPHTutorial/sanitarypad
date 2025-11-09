import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../services/cycle_service.dart';

/// Calendar screen with cycle visualization
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final cyclesAsync = ref.watch(cyclesStreamProvider);
    final cycles = cyclesAsync.value ?? [];

    // Build event markers for calendar
    final eventMarkers = _buildEventMarkers(cycles);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.go('/log-period');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          Card(
            margin: ResponsiveConfig.margin(all: 16),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  app_date_utils.DateUtils.isToday(day),
              calendarFormat: _calendarFormat,
              eventLoader: (day) => eventMarkers[day] ?? [],
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppTheme.lightPink,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  borderRadius: ResponsiveConfig.borderRadius(8),
                ),
                formatButtonTextStyle: const TextStyle(color: Colors.white),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
              },
            ),
          ),

          // Selected Date Details
          Expanded(
            child: _buildSelectedDateDetails(context, _selectedDay, cycles),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<CycleEvent>> _buildEventMarkers(List cycles) {
    final markers = <DateTime, List<CycleEvent>>{};

    for (final cycle in cycles) {
      // Mark period days
      final periodEnd = cycle.endDate ??
          cycle.startDate.add(Duration(days: cycle.periodLength - 1));
      for (var i = 0; i <= periodEnd.difference(cycle.startDate).inDays; i++) {
        final date = app_date_utils.DateUtils.startOfDay(
          cycle.startDate.add(Duration(days: i)),
        );
        markers[date] = [
          ...(markers[date] ?? []),
          CycleEvent(type: 'period', cycle: cycle),
        ];
      }

      // Mark ovulation (approximately day 14)
      final ovulationDate = app_date_utils.DateUtils.calculateOvulationDate(
        cycle.startDate,
        cycle.cycleLength,
      );
      final ovulationDay = app_date_utils.DateUtils.startOfDay(ovulationDate);
      markers[ovulationDay] = [
        ...(markers[ovulationDay] ?? []),
        CycleEvent(type: 'ovulation', cycle: cycle),
      ];
    }

    return markers;
  }

  Widget _buildSelectedDateDetails(
    BuildContext context,
    DateTime date,
    List cycles,
  ) {
    // Find cycle for this date
    final cycleForDate = cycles.firstWhere(
      (cycle) {
        final periodEnd = cycle.endDate ??
            cycle.startDate.add(Duration(days: cycle.periodLength - 1));
        return date
                .isAfter(cycle.startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(periodEnd.add(const Duration(days: 1)));
      },
      orElse: () => null,
    );

    return Card(
      margin: ResponsiveConfig.margin(all: 16),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              app_date_utils.DateUtils.formatDate(date),
              style: ResponsiveConfig.textStyle(
                size: 20,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            if (cycleForDate != null) ...[
              _buildDetailItem(
                context,
                icon: Icons.water_drop,
                label: 'Period Day',
                value: 'Day ${cycleForDate.getCycleDay(date)}',
                color: AppTheme.primaryPink,
              ),
              ResponsiveConfig.heightBox(12),
              _buildDetailItem(
                context,
                icon: Icons.speed,
                label: 'Flow',
                value: cycleForDate.flowIntensity.toUpperCase(),
              ),
              if (cycleForDate.symptoms.isNotEmpty) ...[
                ResponsiveConfig.heightBox(12),
                _buildDetailItem(
                  context,
                  icon: Icons.medical_services,
                  label: 'Symptoms',
                  value: cycleForDate.symptoms.join(', '),
                ),
              ],
              if (cycleForDate.mood != null) ...[
                ResponsiveConfig.heightBox(12),
                _buildDetailItem(
                  context,
                  icon: Icons.mood,
                  label: 'Mood',
                  value: cycleForDate.mood!,
                ),
              ],
            ] else
              Text(
                'No cycle data for this date',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              ),
            if (cycleForDate != null) ...[
              ResponsiveConfig.heightBox(16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to edit cycle screen
                        context.go('/log-period');
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  ResponsiveConfig.widthBox(12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Cycle'),
                            content: const Text(
                              'Are you sure you want to delete this cycle entry?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.errorRed,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) {
                          try {
                            final cycleService = CycleService();
                            await cycleService
                                .deleteCycle(cycleForDate.cycleId);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cycle deleted successfully'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              ResponsiveConfig.heightBox(16),
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/log-period');
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Entry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color ?? AppTheme.primaryPink,
          size: ResponsiveConfig.iconSize(20),
        ),
        ResponsiveConfig.widthBox(12),
        Text(
          '$label: ',
          style: ResponsiveConfig.textStyle(
            size: 14,
            color: AppTheme.mediumGray,
          ),
        ),
        Text(
          value,
          style: ResponsiveConfig.textStyle(
            size: 14,
            weight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Cycle event marker
class CycleEvent {
  final String type;
  final dynamic cycle;

  CycleEvent({required this.type, required this.cycle});
}
