import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../data/models/fertility_model.dart';
import '../../../services/fertility_service.dart';
import '../../../services/reminder_service.dart';

class FertilityTrackingScreen extends ConsumerStatefulWidget {
  const FertilityTrackingScreen({super.key});

  @override
  ConsumerState<FertilityTrackingScreen> createState() =>
      _FertilityTrackingScreenState();
}

class _FertilityTrackingScreenState
    extends ConsumerState<FertilityTrackingScreen>
    with TickerProviderStateMixin {
  final _fertilityService = FertilityService();
  final _reminderService = ReminderService();

  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;
    final cyclesAsync = ref.watch(cyclesStreamProvider);
    final cycles = cyclesAsync.value ?? [];

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final startRange = DateTime.now().subtract(const Duration(days: 210));
    final endRange = DateTime.now().add(const Duration(days: 210));

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fertility Tracking'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: _buildModernTabSwitcher(context),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(user.userId),
        body: StreamBuilder<List<FertilityEntry>>(
          stream: _fertilityService.getFertilityEntries(
            user.userId,
            startRange,
            endRange,
          ),
          builder: (context, entriesSnapshot) {
            if (entriesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final entries = entriesSnapshot.data ?? [];

            return FutureBuilder<FertilityPrediction>(
              future: _fertilityService.predictOvulation(
                user.userId,
                cycles,
                entries,
              ),
              builder: (context, predictionSnapshot) {
                final prediction = predictionSnapshot.data;

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(
                        context, user.userId, entries, prediction),
                    _buildCalendarTab(
                      context,
                      user.userId,
                      entries,
                      prediction,
                    ),
                    _buildLogsTab(context, user.userId, entries),
                    _buildInsightsTab(
                      context,
                      user.userId,
                      entries,
                      prediction,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernTabSwitcher(BuildContext context) {
    return TabBar(
      dividerColor: AppTheme.darkGray.withOpacity(0.2),
      controller: _tabController,
      labelStyle: ResponsiveConfig.textStyle(
        size: 14,
        weight: FontWeight.w600,
      ),
      unselectedLabelStyle: ResponsiveConfig.textStyle(
        size: 14,
        weight: FontWeight.w500,
      ),
      indicatorColor: AppTheme.primaryPink,
      indicatorWeight: 3,
      labelColor: AppTheme.primaryPink,
      unselectedLabelColor: AppTheme.mediumGray,
      tabs: const [
        Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
        Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Calendar'),
        Tab(icon: Icon(Icons.list_alt_outlined), text: 'Logs'),
        Tab(icon: Icon(Icons.insights_outlined), text: 'Insights'),
      ],
    );
  }

  FloatingActionButton? _buildFloatingActionButton(String userId) {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickActionsMenu(context, userId),
      icon: const Icon(Icons.add_circle_outline),
      label: const Text('Quick Actions'),
    );
  }

  Future<void> _showQuickActionsMenu(
      BuildContext context, String userId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: ResponsiveConfig.padding(all: 16),
                  child: Text(
                    'Quick Actions',
                    style: ResponsiveConfig.textStyle(
                      size: 18,
                      weight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Log Fertility Entry'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAddFertilityEntrySheet(context, userId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.spa_outlined),
                  title: const Text('Log Hormone Levels'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showLogHormoneDialog(context, userId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sentiment_satisfied_alt_outlined),
                  title: const Text('Log Mood & Energy'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showLogMoodDialog(context, userId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.healing_outlined),
                  title: const Text('Log Symptoms'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showLogSymptomDialog(context, userId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.medical_services_outlined),
                  title: const Text('Log Medication/Supplement'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showLogMedicationDialog(context, userId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: const Text('Log Intercourse Activity'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showLogIntercourseDialog(context, userId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.pregnant_woman_outlined),
                  title: const Text('Log Pregnancy Test'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showLogPregnancyTestDialog(context, userId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.alarm_add_outlined),
                  title: const Text('Schedule Ovulation Test'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showScheduleOvulationTestDialog(context, userId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.tips_and_updates_outlined),
                  title: const Text('Add Health Recommendation'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAddHealthRecommendationDialog(context, userId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    String userId,
    List<FertilityEntry> entries,
    FertilityPrediction? prediction,
  ) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (prediction != null) ...[
            _buildFertilityWindowCard(prediction),
            ResponsiveConfig.heightBox(16),
            _buildPregnancyProbabilityCard(
              userId: userId,
              prediction: prediction,
              entries: entries,
            ),
            ResponsiveConfig.heightBox(16),
          ],
          _buildTodaysEntryCard(context, userId, entries),
          ResponsiveConfig.heightBox(16),
          _buildUpcomingOvulationTests(userId),
          ResponsiveConfig.heightBox(16),
          _buildPeriodReminderCard(userId, prediction),
          ResponsiveConfig.heightBox(16),
          _buildHealthRecommendations(userId),
          ResponsiveConfig.heightBox(16),
          _buildSupportAndPartnerCards(),
        ],
      ),
    );
  }

  Widget _buildCalendarTab(
    BuildContext context,
    String userId,
    List<FertilityEntry> entries,
    FertilityPrediction? prediction,
  ) {
    return StreamBuilder<List<FertilitySymptom>>(
      stream: _fertilityService.getFertilitySymptoms(userId),
      builder: (context, symptomSnapshot) {
        final symptoms = symptomSnapshot.data ?? [];
        return StreamBuilder<List<IntercourseEntry>>(
          stream: _fertilityService.getIntercourseEntries(userId),
          builder: (context, intercourseSnapshot) {
            final intercourse = intercourseSnapshot.data ?? [];
            return StreamBuilder<List<PregnancyTestEntry>>(
              stream: _fertilityService.getPregnancyTests(userId),
              builder: (context, testSnapshot) {
                final tests = testSnapshot.data ?? [];
                final events = prediction != null
                    ? _fertilityService.buildCalendarEvents(
                        entries: entries,
                        prediction: prediction,
                        symptoms: symptoms,
                        intercourseEntries: intercourse,
                        pregnancyTests: tests,
                      )
                    : <DateTime, List<String>>{};

                final selectedKey = _selectedDay != null
                    ? DateTime(
                        _selectedDay!.year,
                        _selectedDay!.month,
                        _selectedDay!.day,
                      )
                    : DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                      );

                return Column(
                  children: [
                    Expanded(
                      child: TableCalendar(
                        firstDay:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        eventLoader: (day) =>
                            events[DateTime(day.year, day.month, day.day)] ??
                            [],
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: AppTheme.primaryPink.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: AppTheme.primaryPink,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: BoxDecoration(
                            color: AppTheme.accentCoral,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    _buildCalendarEventsList(
                      selectedKey,
                      events[selectedKey] ?? [],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLogsTab(
    BuildContext context,
    String userId,
    List<FertilityEntry> entries,
  ) {
    final chartData = _fertilityService.getBBTChartData(entries);

    return SingleChildScrollView(
      padding: ResponsiveConfig.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (chartData.isNotEmpty) ...[
            _buildBBTChart(chartData),
            ResponsiveConfig.heightBox(16),
          ],
          _buildCervicalMucusSection(entries),
          ResponsiveConfig.heightBox(16),
          _buildHormoneSection(userId),
          ResponsiveConfig.heightBox(16),
          _buildMoodEnergySection(userId),
          ResponsiveConfig.heightBox(16),
          _buildSymptomSection(userId),
          ResponsiveConfig.heightBox(16),
          _buildIntercourseSection(userId),
          ResponsiveConfig.heightBox(16),
          _buildPregnancyTestsSection(userId),
          ResponsiveConfig.heightBox(16),
          _buildMedicationSection(userId),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(
    BuildContext context,
    String userId,
    List<FertilityEntry> entries,
    FertilityPrediction? prediction,
  ) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (prediction != null) ...[
            _buildFertileWindowInsights(prediction),
            ResponsiveConfig.heightBox(16),
          ],
          _buildLifestyleRecommendations(userId),
          ResponsiveConfig.heightBox(16),
          _buildAnalyticsCards(entries, prediction),
          ResponsiveConfig.heightBox(16),
          _buildAIAssistantCard(),
          ResponsiveConfig.heightBox(16),
          _buildCommunityCard(),
        ],
      ),
    );
  }

  Widget _buildCalendarEventsList(DateTime day, List<String> events) {
    return Card(
      margin: ResponsiveConfig.margin(all: 16),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMMM d, y').format(day),
              style: ResponsiveConfig.textStyle(
                size: 16,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            if (events.isEmpty)
              Text(
                'No events logged for this day.',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              )
            else
              ...events.map(
                (event) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.brightness_1, size: 8),
                      ResponsiveConfig.widthBox(8),
                      Expanded(
                        child: Text(
                          event,
                          style: ResponsiveConfig.textStyle(size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFertilityWindowCard(FertilityPrediction prediction) {
    final isInWindow = prediction.isInFertileWindow(DateTime.now());
    final daysUntilOvulation =
        prediction.predictedOvulation.difference(DateTime.now()).inDays;

    return Card(
      color: isInWindow ? AppTheme.lightPink.withOpacity(0.5) : null,
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isInWindow
                          ? Icons.favorite
                          : Icons.favorite_border_outlined,
                      color: isInWindow
                          ? AppTheme.primaryPink
                          : AppTheme.mediumGray,
                    ),
                    ResponsiveConfig.widthBox(8),
                    Text(
                      'Fertile Window',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Chip(
                  label: Text(
                    isInWindow ? 'High Fertility' : 'Upcoming',
                    style: ResponsiveConfig.textStyle(
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryPink,
                ),
              ],
            ),
            ResponsiveConfig.heightBox(12),
            Text(
              '${DateFormat('MMM d').format(prediction.fertileWindowStart)} - ${DateFormat('MMM d').format(prediction.fertileWindowEnd)}',
              style: ResponsiveConfig.textStyle(
                size: 16,
                weight: FontWeight.w600,
              ),
            ),
            ResponsiveConfig.heightBox(6),
            Text(
              daysUntilOvulation >= 0
                  ? '$daysUntilOvulation days until ovulation'
                  : 'Ovulation window passed',
              style: ResponsiveConfig.textStyle(
                size: 13,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: prediction.methods.map((method) {
                final label = method
                    .replaceAll('_', ' ')
                    .split(' ')
                    .map((word) => word.isEmpty
                        ? word
                        : word[0].toUpperCase() + word.substring(1))
                    .join(' ');
                return Chip(
                  label: Text(label),
                  backgroundColor: AppTheme.accentCoral.withOpacity(0.8),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPregnancyProbabilityCard({
    required String userId,
    required FertilityPrediction prediction,
    required List<FertilityEntry> entries,
  }) {
    return StreamBuilder<List<IntercourseEntry>>(
      stream: _fertilityService.getIntercourseEntries(userId),
      builder: (context, snapshot) {
        final intercourseEntries = snapshot.data ?? [];
        final probability = _fertilityService.calculatePregnancyProbability(
          prediction: prediction,
          currentDate: DateTime.now(),
          intercourseEntries: intercourseEntries,
          fertilityEntries: entries,
        );

        return Card(
          child: Padding(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pregnancy Probability',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(probability * 100).toStringAsFixed(0)}%',
                      style: ResponsiveConfig.textStyle(
                        size: 24,
                        weight: FontWeight.bold,
                        color: AppTheme.primaryPink,
                      ),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(12),
                LinearProgressIndicator(
                  value: probability,
                  minHeight: 10,
                  backgroundColor: AppTheme.palePink,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryPink),
                ),
                ResponsiveConfig.heightBox(12),
                Text(
                  'Based on intercourse timing, cervical mucus, hormone tests, and basal body temperature data.',
                  style: ResponsiveConfig.textStyle(
                    size: 14,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodaysEntryCard(
    BuildContext context,
    String userId,
    List<FertilityEntry> entries,
  ) {
    final today = DateTime.now();
    final todayEntry = entries.firstWhere(
      (entry) => DateUtils.isSameDay(entry.date, today),
      orElse: () => FertilityEntry(
        userId: userId,
        date: today,
        createdAt: today,
      ),
    );

    return Card(
      child: InkWell(
        onTap: () => _showAddFertilityEntrySheet(context, userId,
            existingEntry: todayEntry.id != null ? todayEntry : null),
        child: Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Entry",
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveConfig.heightBox(8),
                    if (todayEntry.basalBodyTemperature != null)
                      _buildInfoRow(
                        icon: Icons.thermostat,
                        label: 'BBT',
                        value:
                            '${todayEntry.basalBodyTemperature!.toStringAsFixed(1)} °C',
                      ),
                    if (todayEntry.cervicalMucus != null)
                      _buildInfoRow(
                        icon: Icons.water_drop,
                        label: 'Cervical Mucus',
                        value: todayEntry.cervicalMucus!,
                      ),
                    if (todayEntry.lhTestPositive != null)
                      _buildInfoRow(
                        icon: Icons.science,
                        label: 'LH Test',
                        value: todayEntry.lhTestPositive!
                            ? 'Positive'
                            : 'Negative',
                        valueColor: todayEntry.lhTestPositive!
                            ? AppTheme.successGreen
                            : AppTheme.mediumGray,
                      ),
                    if (todayEntry.notes != null &&
                        todayEntry.notes!.isNotEmpty)
                      _buildInfoRow(
                        icon: Icons.note_alt_outlined,
                        label: 'Notes',
                        value: todayEntry.notes!,
                      ),
                    if (todayEntry.basalBodyTemperature == null &&
                        todayEntry.cervicalMucus == null &&
                        todayEntry.lhTestPositive == null)
                      Text(
                        'Tap to record your fertility indicators for today.',
                        style: ResponsiveConfig.textStyle(
                          size: 14,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.mediumGray),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingOvulationTests(String userId) {
    return StreamBuilder<List<OvulationTestReminder>>(
      stream: _fertilityService.getUpcomingOvulationTests(userId),
      builder: (context, snapshot) {
        final reminders = snapshot.data ?? [];
        return Card(
          child: Padding(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ovulation Test Reminders',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_alert),
                      tooltip: 'Schedule Reminders',
                      onPressed: () =>
                          _showScheduleOvulationTestDialog(context, userId),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(12),
                if (reminders.isEmpty)
                  Text(
                    'No ovulation test reminders scheduled. Tap the bell icon to create one.\n\nTap the icon to log an ovulation test.',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                  )
                else
                  ...reminders.map((reminder) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          const Icon(Icons.alarm, color: AppTheme.primaryPink),
                      title: Text(DateFormat('EEEE, MMM d y')
                          .format(reminder.scheduledDate)),
                      subtitle: Text(reminder.result != null
                          ? 'Result: ${reminder.result}'
                          : reminder.isCompleted
                              ? 'Completed'
                              : 'Pending test'),
                      trailing: reminder.isCompleted
                          ? const Icon(Icons.check_circle,
                              color: AppTheme.successGreen)
                          : IconButton(
                              icon: const Icon(Icons.done),
                              onPressed: () =>
                                  _fertilityService.updateOvulationTest(
                                OvulationTestReminder(
                                  id: reminder.id,
                                  userId: reminder.userId,
                                  scheduledDate: reminder.scheduledDate,
                                  result: 'taken',
                                  isCompleted: true,
                                  completedAt: DateTime.now(),
                                  notes: reminder.notes,
                                  createdAt: reminder.createdAt,
                                ),
                              ),
                            ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodReminderCard(
    String userId,
    FertilityPrediction? prediction,
  ) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Period Reminders',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_active_outlined),
                  tooltip: 'Schedule Period Reminder',
                  onPressed: prediction == null
                      ? null
                      : () => _schedulePeriodReminder(userId, prediction),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Get alerted before your next predicted period and ovulation windows. This helps you plan supplements, medications, and rest.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            if (prediction == null)
              Text(
                'Add cycle data to enable reminders.',
                style: ResponsiveConfig.textStyle(
                  size: 12,
                  color: AppTheme.errorRed,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthRecommendations(String userId) {
    return StreamBuilder<List<HealthRecommendation>>(
      stream: _fertilityService.getHealthRecommendations(userId),
      builder: (context, snapshot) {
        final recommendations = snapshot.data ?? [];
        return Card(
          child: Padding(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lifestyle Recommendations',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add Recommendation',
                      onPressed: () =>
                          _showAddHealthRecommendationDialog(context, userId),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(12),
                if (recommendations.isEmpty)
                  Text(
                    'Log hydration, nutrition, sleep, and stress tips tailored to your goals.\n\nTap the icon to log a recommendation.',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                  )
                else
                  ...recommendations.take(4).map((rec) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.lightbulb_outline,
                        color: rec.isCompleted
                            ? AppTheme.successGreen
                            : AppTheme.primaryPink,
                      ),
                      title: Text(rec.title),
                      subtitle: Text(rec.description),
                      trailing: Checkbox(
                        value: rec.isCompleted,
                        onChanged: (value) {
                          _fertilityService.updateHealthRecommendation(
                            rec.id!,
                            isCompleted: value,
                            completedAt: value == true ? DateTime.now() : null,
                          );
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportAndPartnerCards() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partner Mode',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                ResponsiveConfig.heightBox(8),
                Text(
                  'Share your fertility dashboard with your partner so that both of you can log symptoms, reminders, and schedule doctor visits together.',
                  style: ResponsiveConfig.textStyle(
                    size: 14,
                    color: AppTheme.mediumGray,
                  ),
                ),
                ResponsiveConfig.heightBox(12),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      const ClipboardData(text: 'Partner mode coming soon!'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Partner dashboard link copied (placeholder).'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Share dashboard link'),
                ),
              ],
            ),
          ),
        ),
        ResponsiveConfig.heightBox(12),
        Card(
          child: Padding(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need support?',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                ResponsiveConfig.heightBox(8),
                Text(
                  'Join the FemCare+ fertility community and support groups to share experiences, ask questions, and learn from others.',
                  style: ResponsiveConfig.textStyle(
                    size: 14,
                    color: AppTheme.mediumGray,
                  ),
                ),
                ResponsiveConfig.heightBox(12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/groups', extra: 'fertility'),
                      icon: const Icon(Icons.groups_outlined),
                      label: const Text('Join forum'),
                    ),
                    ResponsiveConfig.heightBox(8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/events', extra: 'fertility'),
                      icon: const Icon(Icons.event_outlined),
                      label: const Text('Upcoming events'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBBTChart(List<Map<String, dynamic>> data) {
    data.sort((a, b) => a['date'].compareTo(b['date']));
    final spots = data
        .map(
          (point) => FlSpot(
            point['date'].millisecondsSinceEpoch.toDouble(),
            (point['temperature'] as double),
          ),
        )
        .toList();

    if (spots.length < 2) {
      return Card(
        child: Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: Text(
            'Log at least two basal body temperature entries to see your chart.',
            style: ResponsiveConfig.textStyle(
              size: 14,
              color: AppTheme.mediumGray,
            ),
          ),
        ),
      );
    }

    final minX = spots.first.x;
    final maxX = spots.last.x;
    final temperatures = spots.map((spot) => spot.y).toList();
    final minY = temperatures.reduce(min) - 0.2;
    final maxY = temperatures.reduce(max) + 0.2;

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basal Body Temperature (BBT)',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            spot.x.toInt(),
                          );
                          return LineTooltipItem(
                            '${DateFormat('MMM d').format(date)}\n${spot.y.toStringAsFixed(2)} °C',
                            ResponsiveConfig.textStyle(
                              size: 12,
                              color: Colors.white,
                            ),
                          );
                        }).toList();
                      },
                      tooltipRoundedRadius: 8,
                    ),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toStringAsFixed(1)}°');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: (maxX - minX) / 4,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            value.toInt(),
                          );
                          return Transform.rotate(
                            angle: -pi / 4,
                            child: Text(DateFormat('MMM d').format(date)),
                          );
                        },
                      ),
                    ),
                  ),
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      dotData: FlDotData(show: true),
                      color: AppTheme.primaryPink,
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryPink.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCervicalMucusSection(List<FertilityEntry> entries) {
    final recentEntries = entries
        .where((entry) => entry.cervicalMucus != null)
        .toList()
        .reversed
        .take(10)
        .toList();

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cervical Mucus Tracker',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            if (recentEntries.isEmpty)
              Text(
                'Log cervical mucus observations to identify fertile patterns.\n\nTap the icon to log cervical mucus.',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              )
            else
              ...recentEntries.map((entry) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.water_drop_outlined,
                      color: AppTheme.primaryPink),
                  title: Text(DateFormat('MMM d, y').format(entry.date)),
                  subtitle: Text('Consistency: ${entry.cervicalMucus}'),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildHormoneSection(String userId) {
    return StreamBuilder<List<HormoneCycle>>(
      stream: _fertilityService.getHormoneCycles(userId),
      builder: (context, snapshot) {
        final cycles = snapshot.data ?? [];
        return Card(
          child: Padding(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hormone Cycle Insights',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_chart),
                      tooltip: 'Log Hormone Levels',
                      onPressed: () => _showLogHormoneDialog(context, userId),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(12),
                if (cycles.isEmpty)
                  Text(
                    'Track estrogen, progesterone, LH and FSH trends to improve prediction accuracy.\n\nTap the icon to log hormone levels.',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                  )
                else
                  ...cycles.take(5).map((cycle) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.timeline,
                          color: AppTheme.primaryPink),
                      title: Text(DateFormat('MMM d, y').format(cycle.date)),
                      subtitle: Text(
                        'Estrogen: ${cycle.estrogenLevel?.toStringAsFixed(0) ?? '--'} | Progesterone: ${cycle.progesteroneLevel?.toStringAsFixed(0) ?? '--'}',
                      ),
                      trailing: Text(
                        cycle.cyclePhase?.toUpperCase() ?? '',
                        style: ResponsiveConfig.textStyle(
                          size: 12,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodEnergySection(String userId) {
    return StreamBuilder<List<MoodEnergyEntry>>(
      stream: _fertilityService.getMoodEnergyEntries(userId),
      builder: (context, snapshot) {
        final moods = snapshot.data ?? [];
        return Card(
          child: Padding(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mood & Energy Tracker',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sentiment_satisfied_alt_outlined),
                      tooltip: 'Log Mood',
                      onPressed: () => _showLogMoodDialog(context, userId),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(12),
                if (moods.isEmpty)
                  Text(
                    'Track how you feel each day to discover hormonal patterns impacting mood, energy, or libido.\n\nTap the icon to log mood and energy.',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                  )
                else
                  ...moods.take(6).map((entry) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          const Icon(Icons.mood, color: AppTheme.primaryPink),
                      title: Text(DateFormat('MMM d').format(entry.date)),
                      subtitle: Text(
                        'Mood: ${entry.mood ?? '--'} | Energy: ${entry.energyLevel ?? '--'} | Stress: ${entry.stressLevel ?? '--'}',
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSymptomSection(String userId) {
    return StreamBuilder<List<FertilitySymptom>>(
      stream: _fertilityService.getFertilitySymptoms(userId),
      builder: (context, snapshot) {
        final symptoms = snapshot.data ?? [];
        return Card(
          child: Padding(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Symptom Logging',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Log Symptom',
                      onPressed: () => _showLogSymptomDialog(context, userId),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(12),
                if (symptoms.isEmpty)
                  Text(
                    'Log cramps, bloating, headaches, and more to correlate with cycle phases.\n\nTap the icon to log symptoms.',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                  )
                else
                  ...symptoms.take(6).map((symptom) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.healing_outlined,
                          color: AppTheme.primaryPink),
                      title: Text(DateFormat('MMM d, y').format(symptom.date)),
                      subtitle: Text(
                        'Symptoms: ${symptom.symptoms.join(', ')} | Pain level: ${symptom.painLevel ?? '--'}',
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntercourseSection(String userId) {
    return StreamBuilder<List<IntercourseEntry>>(
      stream: _fertilityService.getIntercourseEntries(userId),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        return Card(
          child: Padding(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Intimacy & Fertility Activity',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      tooltip: 'Log Activity',
                      onPressed: () =>
                          _showLogIntercourseDialog(context, userId),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(12),
                if (entries.isEmpty)
                  Text(
                    'Logging intercourse without protection within the fertile window increases prediction accuracy.\n\nTap the icon to log intercourse activity.',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                  )
                else
                  ...entries.take(6).map((entry) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        entry.usedProtection
                            ? Icons.shield_outlined
                            : Icons.favorite,
                        color: entry.usedProtection
                            ? AppTheme.mediumGray
                            : AppTheme.primaryPink,
                      ),
                      title: Text(DateFormat('MMM d, y').format(entry.date)),
                      subtitle: Text(entry.usedProtection
                          ? 'Protection used'
                          : 'No protection'),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPregnancyTestsSection(String userId) {
    return StreamBuilder<List<PregnancyTestEntry>>(
      stream: _fertilityService.getPregnancyTests(userId),
      builder: (context, snapshot) {
        final tests = snapshot.data ?? [];
        return Card(
          child: Padding(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pregnancy Test Tracker',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.biotech_outlined),
                      tooltip: 'Log Pregnancy Test',
                      onPressed: () =>
                          _showLogPregnancyTestDialog(context, userId),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(12),
                if (tests.isEmpty)
                  Text(
                    'Log pregnancy tests (positive, negative, invalid) to monitor testing history.\n\nTap the icon to log a pregnancy test.',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                  )
                else
                  ...tests.take(6).map((test) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        test.result == 'positive'
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: test.result == 'positive'
                            ? AppTheme.successGreen
                            : AppTheme.mediumGray,
                      ),
                      title: Text(DateFormat('MMM d, y').format(test.date)),
                      subtitle: Text(
                        'Result: ${test.result.toUpperCase()} | Brand: ${test.testBrand ?? 'N/A'}',
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMedicationSection(String userId) {
    return StreamBuilder<List<FertilityMedication>>(
      stream: _fertilityService.getActiveMedications(userId),
      builder: (context, snapshot) {
        final meds = snapshot.data ?? [];
        return Card(
          child: Padding(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Set Reminders',
                      style: ResponsiveConfig.textStyle(
                        size: 22,
                        weight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.medication_liquid_outlined),
                      tooltip: 'Log Medication',
                      onPressed: () =>
                          _showLogMedicationDialog(context, userId),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(8),
                Text(
                  'Medication & Supplement',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                ResponsiveConfig.heightBox(12),
                if (meds.isEmpty)
                  Text(
                    'Track prescribed medications and fertility supplements including dosage and frequency.\n\nTap the pill icon to log a medication or supplement.',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      color: AppTheme.mediumGray,
                    ),
                  )
                else
                  ...meds.map((med) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.medication_outlined,
                          color: AppTheme.primaryPink),
                      title: Text(
                          '${med.medicationName} (${med.dosage ?? 'N/A'})'),
                      subtitle: Text(
                          'Frequency: ${med.frequency} | Start: ${DateFormat('MMM d').format(med.startDate)}'),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFertileWindowInsights(FertilityPrediction prediction) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fertile Window Insights',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Predicted Ovulation',
              value: DateFormat('EEEE, MMM d')
                  .format(prediction.predictedOvulation),
            ),
            _buildInfoRow(
              icon: Icons.timelapse,
              label: 'Confidence',
              value:
                  '${(prediction.confidence * 100).toStringAsFixed(0)}% based on ${prediction.methods.length} tracking methods',
            ),
            ResponsiveConfig.heightBox(12),
            Text(
              'Tip: Track cervical mucus, LH tests, and basal temperature daily to maintain high prediction confidence.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifestyleRecommendations(String userId) {
    return StreamBuilder<List<HealthRecommendation>>(
      stream: _fertilityService.getHealthRecommendations(userId),
      builder: (context, snapshot) {
        final recs = snapshot.data ?? [];
        final active = recs.where((rec) => !(rec.isCompleted)).length;
        final completed = recs.where((rec) => rec.isCompleted).length;

        return Card(
          child: Padding(
            padding: ResponsiveConfig.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health & Lifestyle Coach',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                ResponsiveConfig.heightBox(12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatChip(
                        'Active Goals', active.toString(), Icons.flag),
                    _buildStatChip(
                        'Completed', completed.toString(), Icons.check_circle),
                    _buildStatChip(
                        'Categories',
                        recs
                            .map((rec) => rec.category)
                            .toSet()
                            .length
                            .toString(),
                        Icons.category_outlined),
                  ],
                ),
                ResponsiveConfig.heightBox(12),
                Text(
                  'Log dietary tweaks, hydration targets, mindfulness, or workout routines to boost fertility health.',
                  style: ResponsiveConfig.textStyle(
                    size: 14,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsCards(
    List<FertilityEntry> entries,
    FertilityPrediction? prediction,
  ) {
    final recentEntries = entries.take(30).toList();
    final intercourseCount =
        recentEntries.where((e) => e.intercourse == true).length;
    final positiveLH =
        recentEntries.where((e) => e.lhTestPositive == true).length;
    final eggWhiteCount =
        recentEntries.where((e) => e.cervicalMucus == 'egg-white').length;

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Dashboard',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildStatCard(
                  title: 'Intercourse (30d)',
                  value: intercourseCount.toString(),
                  icon: Icons.favorite,
                  color: AppTheme.primaryPink,
                ),
                _buildStatCard(
                  title: 'Positive LH Tests',
                  value: positiveLH.toString(),
                  icon: Icons.science_outlined,
                  color: AppTheme.accentCoral,
                ),
                _buildStatCard(
                  title: 'Fertile CM Days',
                  value: eggWhiteCount.toString(),
                  icon: Icons.water_drop_outlined,
                  color: AppTheme.successGreen,
                ),
                if (prediction != null)
                  _buildStatCard(
                    title: 'Next Ovulation',
                    value: DateFormat('MMM d')
                        .format(prediction.predictedOvulation),
                    icon: Icons.calendar_today_outlined,
                    color: AppTheme.primaryPink,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAssistantCard() {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Fertility Assistant',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Chat with FemCare+ AI (coming soon) to interpret hormone levels, understand chart patterns, and receive personalized guidance based on your logs.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'AI assistant will be available in a future update.'),
                  ),
                );
              },
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('Preview Assistant'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityCard() {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community & Support Groups',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Connect with other FemCare+ users, share journals, and participate in moderated support circles for TTC journeys.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.push('/groups', extra: 'fertility'),
                  icon: const Icon(Icons.groups),
                  label: const Text('Join Forum'),
                ),
                ResponsiveConfig.heightBox(8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/events', extra: 'fertility'),
                  icon: const Icon(Icons.event_outlined),
                  label: const Text('Upcoming Events'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppTheme.primaryPink),
      label: Text('$label: $value'),
      backgroundColor: AppTheme.primaryPink.withOpacity(0.1),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 150,
      padding: ResponsiveConfig.padding(all: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: ResponsiveConfig.borderRadius(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          ResponsiveConfig.heightBox(8),
          Text(
            title,
            style: ResponsiveConfig.textStyle(
              size: 12,
              color: color.withOpacity(0.7),
            ),
          ),
          ResponsiveConfig.heightBox(4),
          Text(
            value,
            style: ResponsiveConfig.textStyle(
              size: 20,
              weight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: ResponsiveConfig.padding(vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: ResponsiveConfig.iconSize(16), color: AppTheme.primaryPink),
          ResponsiveConfig.widthBox(8),
          Text(
            '$label: ',
            style: ResponsiveConfig.textStyle(
              size: 14,
              weight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddFertilityEntrySheet(
    BuildContext context,
    String userId, {
    FertilityEntry? existingEntry,
  }) async {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = existingEntry?.date ?? DateTime.now();
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(selectedDate),
    );
    final bbtController = TextEditingController(
      text: existingEntry?.basalBodyTemperature?.toString(),
    );
    String? cervicalMucus = existingEntry?.cervicalMucus;
    String? cervicalPosition = existingEntry?.cervicalPosition;
    bool? lhPositive = existingEntry?.lhTestPositive;
    bool? intercourse = existingEntry?.intercourse;
    final notesController = TextEditingController(text: existingEntry?.notes);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingEntry != null
                            ? 'Edit Fertility Entry'
                            : 'New Fertility Entry',
                        style: ResponsiveConfig.textStyle(
                          size: 18,
                          weight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  ResponsiveConfig.heightBox(16),
                  TextFormField(
                    controller: dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        selectedDate = pickedDate;
                        dateController.text =
                            DateFormat('yyyy-MM-dd').format(pickedDate);
                      }
                    },
                  ),
                  ResponsiveConfig.heightBox(16),
                  TextFormField(
                    controller: bbtController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Basal Body Temperature (°C)',
                      prefixIcon: Icon(Icons.thermostat),
                    ),
                  ),
                  ResponsiveConfig.heightBox(16),
                  DropdownButtonFormField<String>(
                    value: cervicalMucus,
                    decoration: const InputDecoration(
                      labelText: 'Cervical Mucus',
                      prefixIcon: Icon(Icons.water_drop),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'dry', child: Text('Dry')),
                      DropdownMenuItem(value: 'sticky', child: Text('Sticky')),
                      DropdownMenuItem(value: 'creamy', child: Text('Creamy')),
                      DropdownMenuItem(value: 'watery', child: Text('Watery')),
                      DropdownMenuItem(
                          value: 'egg-white', child: Text('Egg-white')),
                    ],
                    onChanged: (value) => cervicalMucus = value,
                  ),
                  ResponsiveConfig.heightBox(16),
                  DropdownButtonFormField<String>(
                    value: cervicalPosition,
                    decoration: const InputDecoration(
                      labelText: 'Cervical Position',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (value) => cervicalPosition = value,
                  ),
                  ResponsiveConfig.heightBox(16),
                  SwitchListTile(
                    title: const Text('LH Test Positive'),
                    value: lhPositive ?? false,
                    onChanged: (value) => setState(() => lhPositive = value),
                  ),
                  SwitchListTile(
                    title: const Text('Intercourse today'),
                    value: intercourse ?? false,
                    onChanged: (value) => setState(() => intercourse = value),
                  ),
                  ResponsiveConfig.heightBox(16),
                  TextFormField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  ResponsiveConfig.heightBox(24),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final entry = FertilityEntry(
                        id: existingEntry?.id,
                        userId: userId,
                        date: selectedDate,
                        basalBodyTemperature:
                            double.tryParse(bbtController.text.trim()),
                        cervicalMucus: cervicalMucus,
                        cervicalPosition: cervicalPosition,
                        lhTestPositive: lhPositive,
                        intercourse: intercourse,
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        createdAt: existingEntry?.createdAt ?? DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      try {
                        if (existingEntry != null && existingEntry.id != null) {
                          await _fertilityService.updateFertilityEntry(entry);
                        } else {
                          await _fertilityService.createFertilityEntry(entry);
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    },
                    child: Text(existingEntry != null ? 'Update' : 'Save'),
                  ),
                  ResponsiveConfig.heightBox(16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showScheduleOvulationTestDialog(
    BuildContext context,
    String userId,
  ) async {
    final formKey = GlobalKey<FormState>();
    DateTime scheduledDate = DateTime.now().add(const Duration(days: 1));
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Schedule Ovulation Test'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title:
                      Text(DateFormat('EEE, MMM d, y').format(scheduledDate)),
                  subtitle: const Text('Tap to change date'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: scheduledDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 120)),
                    );
                    if (picked != null) {
                      setState(() => scheduledDate = picked);
                    }
                  },
                ),
                ResponsiveConfig.heightBox(16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reminder = OvulationTestReminder(
                  userId: userId,
                  scheduledDate: scheduledDate,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                  createdAt: DateTime.now(),
                );
                await _fertilityService.scheduleOvulationTest(reminder);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Schedule'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _schedulePeriodReminder(
    String userId,
    FertilityPrediction? prediction,
  ) async {
    if (prediction == null) return;

    try {
      await _reminderService.createPeriodPredictionReminder(
        userId: userId,
        predictedDate:
            prediction.predictedOvulation.add(const Duration(days: 14)),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Period reminder scheduled.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling reminder: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showLogHormoneDialog(
      BuildContext context, String userId) async {
    final formKey = GlobalKey<FormState>();
    final estrogenController = TextEditingController();
    final progesteroneController = TextEditingController();
    final lhController = TextEditingController();
    final fshController = TextEditingController();
    String? phase;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Hormone Levels'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: estrogenController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Estrogen (relative)'),
                  ),
                  ResponsiveConfig.heightBox(16),
                  TextFormField(
                    controller: progesteroneController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Progesterone (relative)'),
                  ),
                  ResponsiveConfig.heightBox(16),
                  TextFormField(
                    controller: lhController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'LH (relative)'),
                  ),
                  ResponsiveConfig.heightBox(16),
                  TextFormField(
                    controller: fshController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'FSH (relative)'),
                  ),
                  ResponsiveConfig.heightBox(16),
                  DropdownButtonFormField<String>(
                    value: phase,
                    decoration: const InputDecoration(labelText: 'Cycle Phase'),
                    items: const [
                      DropdownMenuItem(
                          value: 'menstrual', child: Text('Menstrual')),
                      DropdownMenuItem(
                          value: 'follicular', child: Text('Follicular')),
                      DropdownMenuItem(
                          value: 'ovulation', child: Text('Ovulation')),
                      DropdownMenuItem(value: 'luteal', child: Text('Luteal')),
                    ],
                    onChanged: (value) => phase = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _fertilityService.logHormoneCycle(
                  HormoneCycle(
                    userId: userId,
                    date: DateTime.now(),
                    estrogenLevel: double.tryParse(estrogenController.text),
                    progesteroneLevel:
                        double.tryParse(progesteroneController.text),
                    lhLevel: double.tryParse(lhController.text),
                    fshLevel: double.tryParse(fshController.text),
                    cyclePhase: phase,
                    createdAt: DateTime.now(),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLogSymptomDialog(
      BuildContext context, String userId) async {
    final formKey = GlobalKey<FormState>();
    final symptomsController = TextEditingController();
    final painController = TextEditingController();
    final locationController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Symptoms'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: symptomsController,
                  decoration: const InputDecoration(
                    labelText: 'Symptoms (comma separated)',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter at least one symptom'
                      : null,
                ),
                ResponsiveConfig.heightBox(16),
                TextFormField(
                  controller: painController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Pain level (1-10)'),
                ),
                ResponsiveConfig.heightBox(16),
                TextFormField(
                  controller: locationController,
                  decoration:
                      const InputDecoration(labelText: 'Location (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await _fertilityService.logFertilitySymptom(
                  FertilitySymptom(
                    userId: userId,
                    date: DateTime.now(),
                    symptoms: symptomsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((element) => element.isNotEmpty)
                        .toList(),
                    painLevel: int.tryParse(painController.text),
                    location: locationController.text.trim().isEmpty
                        ? null
                        : locationController.text.trim(),
                    createdAt: DateTime.now(),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLogMoodDialog(BuildContext context, String userId) async {
    final formKey = GlobalKey<FormState>();
    String? mood;
    final energyController = TextEditingController();
    final stressController = TextEditingController();
    final libidoController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Mood & Energy'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: mood,
                    decoration: const InputDecoration(labelText: 'Mood'),
                    items: const [
                      DropdownMenuItem(value: 'happy', child: Text('Happy')),
                      DropdownMenuItem(value: 'calm', child: Text('Calm')),
                      DropdownMenuItem(
                          value: 'anxious', child: Text('Anxious')),
                      DropdownMenuItem(value: 'sad', child: Text('Sad')),
                      DropdownMenuItem(
                          value: 'irritable', child: Text('Irritable')),
                    ],
                    onChanged: (value) => mood = value,
                  ),
                  TextFormField(
                    controller: energyController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Energy level (1-10)'),
                  ),
                  ResponsiveConfig.heightBox(16),
                  TextFormField(
                    controller: stressController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Stress level (1-10)'),
                  ),
                  ResponsiveConfig.heightBox(16),
                  TextFormField(
                    controller: libidoController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Libido level (1-10)'),
                  ),
                  ResponsiveConfig.heightBox(16),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _fertilityService.logMoodEnergy(
                  MoodEnergyEntry(
                    userId: userId,
                    date: DateTime.now(),
                    mood: mood,
                    energyLevel: int.tryParse(energyController.text),
                    stressLevel: int.tryParse(stressController.text),
                    libidoLevel: int.tryParse(libidoController.text),
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    createdAt: DateTime.now(),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLogMedicationDialog(
      BuildContext context, String userId) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();
    final purposeController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Medication/Supplement'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a name'
                      : null,
                ),
                ResponsiveConfig.heightBox(16),
                TextFormField(
                  controller: dosageController,
                  decoration: const InputDecoration(labelText: 'Dosage'),
                ),
                ResponsiveConfig.heightBox(16),
                TextFormField(
                  controller: frequencyController,
                  decoration: const InputDecoration(
                      labelText: 'Frequency (e.g. daily)'),
                ),
                ResponsiveConfig.heightBox(16),
                TextFormField(
                  controller: purposeController,
                  decoration:
                      const InputDecoration(labelText: 'Purpose (optional)'),
                ),
                ResponsiveConfig.heightBox(16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await _fertilityService.addFertilityMedication(
                  FertilityMedication(
                    userId: userId,
                    medicationName: nameController.text.trim(),
                    dosage: dosageController.text.trim().isEmpty
                        ? null
                        : dosageController.text.trim(),
                    frequency: frequencyController.text.trim().isEmpty
                        ? 'daily'
                        : frequencyController.text.trim(),
                    purpose: purposeController.text.trim().isEmpty
                        ? null
                        : purposeController.text.trim(),
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    startDate: DateTime.now(),
                    createdAt: DateTime.now(),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLogIntercourseDialog(
      BuildContext context, String userId) async {
    bool usedProtection = false;
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Intercourse Activity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Protection used'),
                value: usedProtection,
                onChanged: (value) => setState(() => usedProtection = value),
              ),
              ResponsiveConfig.heightBox(16),
              TextField(
                controller: notesController,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _fertilityService.logIntercourse(
                  IntercourseEntry(
                    userId: userId,
                    date: DateTime.now(),
                    usedProtection: usedProtection,
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    createdAt: DateTime.now(),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLogPregnancyTestDialog(
      BuildContext context, String userId) async {
    String result = 'negative';
    final brandController = TextEditingController();
    final dpoController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Pregnancy Test'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: result,
                decoration: const InputDecoration(labelText: 'Result'),
                items: const [
                  DropdownMenuItem(value: 'positive', child: Text('Positive')),
                  DropdownMenuItem(value: 'negative', child: Text('Negative')),
                  DropdownMenuItem(value: 'invalid', child: Text('Invalid')),
                ],
                onChanged: (value) => result = value ?? 'negative',
              ),
              ResponsiveConfig.heightBox(16),
              TextField(
                controller: brandController,
                decoration: const InputDecoration(labelText: 'Test brand'),
              ),
              ResponsiveConfig.heightBox(16),
              TextField(
                controller: dpoController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Days past ovulation'),
              ),
              ResponsiveConfig.heightBox(16),
              TextField(
                controller: notesController,
                decoration:
                    const InputDecoration(labelText: 'Notes (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _fertilityService.logPregnancyTest(
                  PregnancyTestEntry(
                    userId: userId,
                    date: DateTime.now(),
                    result: result,
                    testBrand: brandController.text.trim().isEmpty
                        ? null
                        : brandController.text.trim(),
                    daysPastOvulation: int.tryParse(dpoController.text),
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                    createdAt: DateTime.now(),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddHealthRecommendationDialog(
    BuildContext context,
    String userId,
  ) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Lifestyle Tip'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a title'
                      : null,
                ),
                ResponsiveConfig.heightBox(16),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a description'
                      : null,
                ),
                ResponsiveConfig.heightBox(16),
                TextFormField(
                  controller: categoryController,
                  decoration:
                      const InputDecoration(labelText: 'Category (eg. diet)'),
                ),
                ResponsiveConfig.heightBox(16),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await _fertilityService.addHealthRecommendation(
                  HealthRecommendation(
                    userId: userId,
                    category: categoryController.text.trim().isEmpty
                        ? 'general'
                        : categoryController.text.trim(),
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    createdAt: DateTime.now(),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
