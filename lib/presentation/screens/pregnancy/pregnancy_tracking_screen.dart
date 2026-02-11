import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_button_handler.dart';
import 'package:sanitarypad/presentation/widgets/ads/eco_ad_wrapper.dart';
import '../../../data/models/pregnancy_model.dart';
import '../../../services/pregnancy_service.dart';
import '../reminders/create_reminder_dialog.dart';
import '../../../services/credit_manager.dart';
import '../../../data/models/baby_model.dart';
import '../../../services/baby_service.dart';

class PregnancyTrackingScreen extends ConsumerStatefulWidget {
  const PregnancyTrackingScreen({super.key, this.pregnancyId});

  final String? pregnancyId;

  @override
  ConsumerState<PregnancyTrackingScreen> createState() =>
      _PregnancyTrackingScreenState();
}

class _PregnancyTrackingScreenState
    extends ConsumerState<PregnancyTrackingScreen>
    with TickerProviderStateMixin {
  final _pregnancyService = PregnancyService();
  final _babyService = BabyService();
  late TabController _tabController;

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

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: StreamBuilder<Pregnancy?>(
        stream: widget.pregnancyId != null
            ? _pregnancyService.watchPregnancyById(widget.pregnancyId!)
            : _pregnancyService.watchActivePregnancy(user.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Pregnancy Tracking')),
              body: Center(
                child: Padding(
                  padding: ResponsiveConfig.padding(all: 24),
                  child: Text(
                    'Unable to load pregnancy data right now. Please try again.',
                    style: ResponsiveConfig.textStyle(size: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          final pregnancy = snapshot.data;
          if (pregnancy == null || pregnancy.id == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Pregnancy Tracking'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.history_outlined),
                    tooltip: 'Pregnancy History',
                    onPressed: () => context.pushNamed('pregnancy-history'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Start Tracking',
                    onPressed: () => context.pushNamed('pregnancy-form'),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: ResponsiveConfig.padding(all: 16),
                child: Column(
                  children: [
                    StreamBuilder<List<Baby>>(
                      stream: _babyService.watchBabies(user.userId),
                      builder: (context, babiesSnapshot) {
                        final babies = babiesSnapshot.data ?? [];
                        if (babies.isEmpty) return const SizedBox.shrink();
                        return Column(
                          children: [
                            _MyBabiesSection(babies: babies),
                            const Divider(),
                            ResponsiveConfig.heightBox(16),
                          ],
                        );
                      },
                    ),
                    _EmptyState(
                      icon: Icons.child_care_outlined,
                      title: 'No Active Pregnancy',
                      message:
                          'Start a pregnancy profile to unlock FemCare+ guidance.',
                      actionLabel: 'Create pregnancy profile',
                      onAction: () => context.pushNamed('pregnancy-form'),
                    ),
                  ],
                ),
              ),
            );
          }

          final pregnancyId = pregnancy.id!;

          final kickStream =
              _pregnancyService.getKickEntries(user.userId, pregnancyId);
          final contractionStream =
              _pregnancyService.getContractionEntries(user.userId, pregnancyId);
          final appointmentStream =
              _pregnancyService.getAppointments(user.userId, pregnancyId);
          final medicationStream =
              _pregnancyService.getMedications(user.userId, pregnancyId);
          final journalStream =
              _pregnancyService.getJournalEntries(user.userId, pregnancyId);
          final weightStream =
              _pregnancyService.getWeightEntries(user.userId, pregnancyId);
          final checklistStream =
              _pregnancyService.getHospitalChecklist(user.userId, pregnancyId);

          return Scaffold(
            appBar: AppBar(
              title: widget.pregnancyId != null
                  ? const Text('Pregnancy Record')
                  : const Text('Pregnancy Tracking'),
              actions: [
                if (widget.pregnancyId == null)
                  IconButton(
                    icon: const Icon(Icons.history_outlined),
                    tooltip: 'Pregnancy History',
                    onPressed: () => context.pushNamed('pregnancy-history'),
                  ),
                if (!pregnancy.isCompleted && widget.pregnancyId == null)
                  IconButton(
                    icon: const Icon(Icons.analytics_outlined),
                    tooltip: 'Quick Actions',
                    onPressed: () => _showQuickActionsMenu(
                        context, user.userId, pregnancy.id!),
                  ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(72),
                child: _buildModernTabSwitcher(context),
              ),
            ),
            body: SafeArea(
              bottom: true,
              top: false,
              child: TabBarView(
                controller: _tabController,
                children: [
                  OverviewTab(
                    pregnancy: pregnancy,
                    kickStream: kickStream,
                    appointmentStream: appointmentStream,
                    medicationStream: medicationStream,
                    babyStream: _babyService.watchBabies(user.userId),
                    onScheduleKickReminder: () =>
                        _scheduleReminder(user.userId, 'kick_check'),
                    onAddAppointment: () => _showAppointmentSheet(
                        context, user.userId, pregnancyId),
                    onAddMedication: () =>
                        _showMedicationSheet(context, user.userId, pregnancyId),
                    isReadOnly: widget.pregnancyId != null,
                  ),
                  _JournalTab(
                    pregnancy: pregnancy,
                    journalStream: journalStream,
                    weightStream: weightStream,
                    onLogJournal: () =>
                        _showJournalSheet(context, user.userId, pregnancyId),
                    onLogWeight: () =>
                        _showWeightSheet(context, user.userId, pregnancyId),
                    isReadOnly: widget.pregnancyId != null,
                  ),
                  _PlannerTab(
                    pregnancy: pregnancy,
                    appointmentStream: appointmentStream,
                    medicationStream: medicationStream,
                    checklistStream: checklistStream,
                    onAddAppointment: () => _showAppointmentSheet(
                        context, user.userId, pregnancyId),
                    onAddMedication: () =>
                        _showMedicationSheet(context, user.userId, pregnancyId),
                    onAddChecklist: () =>
                        _showChecklistSheet(context, user.userId, pregnancyId),
                    isReadOnly: widget.pregnancyId != null,
                  ),
                  _InsightsTab(
                    pregnancy: pregnancy,
                    kickStream: kickStream,
                    contractionStream: contractionStream,
                    weightStream: weightStream,
                    journalStream: journalStream,
                    onLogKick: () =>
                        _showKickSheet(context, user.userId, pregnancyId),
                    onLogContraction: () => _showContractionSheet(
                        context, user.userId, pregnancyId),
                    isReadOnly: widget.pregnancyId != null,
                  ),
                ],
              ),
            ),
            bottomNavigationBar: const EcoAdWrapper(adType: AdType.banner),
          );
        },
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
        Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
        Tab(text: 'Journal', icon: Icon(Icons.book_outlined)),
        Tab(text: 'Planner', icon: Icon(Icons.event_note_outlined)),
        Tab(text: 'Insights', icon: Icon(Icons.insights_outlined)),
      ],
    );
  }

  Widget _sheetWrapper(BuildContext context, Widget child) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.90;
    final horizontalMargin = (screenWidth - dialogWidth) / 2;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: child,
      ),
    );
  }

  Future<void> _showQuickActionsMenu(
    BuildContext context,
    String userId,
    String pregnancyId,
  ) async {
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
                  leading: const Icon(Icons.favorite_outlined),
                  title: const Text('Log Kick'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showKickSheet(context, userId, pregnancyId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Log Contraction'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showContractionSheet(context, userId, pregnancyId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_note_outlined),
                  title: const Text('Log Journal Entry'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showJournalSheet(context, userId, pregnancyId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.monitor_weight_outlined),
                  title: const Text('Log Weight'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showWeightSheet(context, userId, pregnancyId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: const Text('Add Appointment'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAppointmentSheet(context, userId, pregnancyId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.medication_liquid_outlined),
                  title: const Text('Add Medication'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showMedicationSheet(context, userId, pregnancyId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.checklist_outlined),
                  title: const Text('Add Checklist Item'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showChecklistSheet(context, userId, pregnancyId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _scheduleReminder(String userId, String type) async {
    final result = await showDialog(
      context: context,
      builder: (context) => CreateReminderDialog(
        userId: userId,
        defaultType: type,
        defaultTitle: type == 'kick_check'
            ? 'Kick Counter Reminder'
            : 'Pregnancy Reminder',
        defaultDescription: type == 'kick_check'
            ? 'Take a moment to count baby kicks.'
            : 'FemCare+ reminder',
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder scheduled.')),
      );
    }
  }

  Future<void> _showKickSheet(
    BuildContext context,
    String userId,
    String pregnancyId,
  ) async {
    final formKey = GlobalKey<FormState>();
    final countController = TextEditingController();
    final notesController = TextEditingController();
    double durationMinutes = 10;

    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return _sheetWrapper(
                context,
                Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log baby kicks',
                        style: ResponsiveConfig.textStyle(
                          size: 18,
                          weight: FontWeight.bold,
                        ),
                      ),
                      ResponsiveConfig.heightBox(16),
                      TextFormField(
                        controller: countController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Kick count'),
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid number of kicks';
                          }
                          return null;
                        },
                      ),
                      ResponsiveConfig.heightBox(16),
                      _SliderInput(
                        label: 'Duration (minutes)',
                        initialValue: durationMinutes,
                        min: 5,
                        max: 60,
                        onChanged: (value) =>
                            setState(() => durationMinutes = value),
                      ),
                      ResponsiveConfig.heightBox(16),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                            labelText: 'Notes (optional)'),
                        maxLines: 2,
                      ),
                      ResponsiveConfig.heightBox(24),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          // Credit Check
                          final hasCredit = await ref
                              .read(creditManagerProvider)
                              .requestCredit(context, ActionType.pregnancy);
                          if (!hasCredit) return;

                          try {
                            final entry = KickEntry(
                              userId: userId,
                              pregnancyId: pregnancyId,
                              date: DateTime.now(),
                              time: DateTime.now(),
                              kickCount: int.parse(countController.text.trim()),
                              duration:
                                  Duration(minutes: durationMinutes.round()),
                              notes: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                              createdAt: DateTime.now(),
                            );

                            await _pregnancyService.logKickEntry(entry);
                            await ref
                                .read(creditManagerProvider)
                                .consumeCredits(ActionType.pregnancy);

                            if (!mounted) return;

                            Navigator.of(context).pop();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('✅ Saved ${entry.kickCount} kicks'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '❌ Error saving kicks: ${e.toString()}'),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Save kicks'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        });
  }

  Future<void> _showContractionSheet(
    BuildContext context,
    String userId,
    String pregnancyId,
  ) async {
    final formKey = GlobalKey<FormState>();
    final notesController = TextEditingController();
    TimeOfDay startTime = TimeOfDay.now();
    double durationMinutes = 1;
    double intervalMinutes = 10;
    double intensity = 5;

    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return _sheetWrapper(
                context,
                Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log contraction',
                        style: ResponsiveConfig.textStyle(
                          size: 18,
                          weight: FontWeight.bold,
                        ),
                      ),
                      ResponsiveConfig.heightBox(16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.access_time_outlined),
                        title: Text('Start: ${startTime.format(context)}'),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (picked != null) {
                            setState(() => startTime = picked);
                          }
                        },
                      ),
                      ResponsiveConfig.heightBox(16),
                      _SliderInput(
                        label: 'Duration (minutes)',
                        initialValue: durationMinutes,
                        min: 1,
                        max: 10,
                        onChanged: (value) =>
                            setState(() => durationMinutes = value),
                      ),
                      ResponsiveConfig.heightBox(16),
                      _SliderInput(
                        label: 'Interval since last (minutes)',
                        initialValue: intervalMinutes,
                        min: 1,
                        max: 30,
                        onChanged: (value) =>
                            setState(() => intervalMinutes = value),
                      ),
                      ResponsiveConfig.heightBox(16),
                      _SliderInput(
                        label: 'Intensity',
                        initialValue: intensity,
                        min: 1,
                        max: 10,
                        onChanged: (value) => setState(() => intensity = value),
                      ),
                      ResponsiveConfig.heightBox(16),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                            labelText: 'Notes (optional)'),
                        maxLines: 2,
                      ),
                      ResponsiveConfig.heightBox(24),
                      ElevatedButton(
                        onPressed: () async {
                          // Credit Check
                          final hasCredit = await ref
                              .read(creditManagerProvider)
                              .requestCredit(context, ActionType.pregnancy);
                          if (!hasCredit) return;

                          final now = DateTime.now();
                          final start = DateTime(now.year, now.month, now.day,
                              startTime.hour, startTime.minute);
                          final entry = ContractionEntry(
                            userId: userId,
                            pregnancyId: pregnancyId,
                            startTime: start,
                            endTime: start.add(
                                Duration(minutes: durationMinutes.round())),
                            duration:
                                Duration(minutes: durationMinutes.round()),
                            interval:
                                Duration(minutes: intervalMinutes.round()),
                            intensity: intensity.round(),
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                            createdAt: DateTime.now(),
                          );
                          await _pregnancyService.logContraction(entry);
                          await ref
                              .read(creditManagerProvider)
                              .consumeCredits(ActionType.pregnancy);

                          if (!mounted) return;
                          Navigator.of(context).pop();
                        },
                        child: const Text('Save contraction'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        });
  }

  Future<void> _showJournalSheet(
    BuildContext context,
    String userId,
    String pregnancyId,
  ) async {
    final formKey = GlobalKey<FormState>();
    final notesController = TextEditingController();
    final symptomsController = TextEditingController();
    final sleepController = TextEditingController();
    String? mood;
    DateTime selectedDate = DateTime.now();

    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return _sheetWrapper(
                context,
                Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'New journal entry',
                        style: ResponsiveConfig.textStyle(
                          size: 18,
                          weight: FontWeight.bold,
                        ),
                      ),
                      ResponsiveConfig.heightBox(16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text(
                            DateFormat('EEE, MMM d, y').format(selectedDate)),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 280)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                      ),
                      ResponsiveConfig.heightBox(16),
                      DropdownButtonFormField<String>(
                        value: mood,
                        decoration: const InputDecoration(labelText: 'Mood'),
                        items: const [
                          DropdownMenuItem(
                              value: 'happy', child: Text('Happy')),
                          DropdownMenuItem(value: 'calm', child: Text('Calm')),
                          DropdownMenuItem(
                              value: 'anxious', child: Text('Anxious')),
                          DropdownMenuItem(
                              value: 'tired', child: Text('Tired')),
                          DropdownMenuItem(
                              value: 'excited', child: Text('Excited')),
                        ],
                        onChanged: (value) => setState(() => mood = value),
                      ),
                      ResponsiveConfig.heightBox(16),
                      TextField(
                        controller: symptomsController,
                        decoration: const InputDecoration(
                          labelText: 'Symptoms (comma separated)',
                        ),
                      ),
                      ResponsiveConfig.heightBox(16),
                      TextField(
                        controller: sleepController,
                        decoration:
                            const InputDecoration(labelText: 'Sleep hours'),
                        keyboardType: TextInputType.number,
                      ),
                      ResponsiveConfig.heightBox(16),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(labelText: 'Notes'),
                        maxLines: 3,
                      ),
                      ResponsiveConfig.heightBox(24),
                      ElevatedButton(
                        onPressed: () async {
                          // Credit Check
                          final hasCredit = await ref
                              .read(creditManagerProvider)
                              .requestCredit(context, ActionType.pregnancy);
                          if (!hasCredit) return;

                          final entry = PregnancyJournalEntry(
                            userId: userId,
                            pregnancyId: pregnancyId,
                            date: selectedDate,
                            mood: mood,
                            symptoms: symptomsController.text
                                .split(',')
                                .map((e) => e.trim())
                                .where((e) => e.isNotEmpty)
                                .toList(),
                            journalText: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                            sleepHours: sleepController.text.trim().isEmpty
                                ? null
                                : int.tryParse(sleepController.text.trim()),
                            createdAt: DateTime.now(),
                          );
                          await _pregnancyService.saveJournalEntry(entry);
                          await ref
                              .read(creditManagerProvider)
                              .consumeCredits(ActionType.pregnancy);

                          if (!mounted) return;
                          Navigator.of(context).pop();
                        },
                        child: const Text('Save journal'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        });
  }

  Future<void> _showWeightSheet(
    BuildContext context,
    String userId,
    String pregnancyId,
  ) async {
    final formKey = GlobalKey<FormState>();
    final weightController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _sheetWrapper(
              context,
              Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Log weight',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveConfig.heightBox(16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.calendar_today_outlined),
                            title: Text(DateFormat('EEE, MMM d, y')
                                .format(selectedDate)),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 280)),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                selectedDate = picked;
                                setState(() {});
                              }
                            },
                          ),
                        ),
                        const Icon(Icons.edit_outlined, size: 24),
                      ],
                    ),
                    ResponsiveConfig.heightBox(16),
                    TextFormField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Weight (kg)'),
                      validator: (value) {
                        final parsed = double.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid weight';
                        }
                        return null;
                      },
                    ),
                    ResponsiveConfig.heightBox(16),
                    TextField(
                      controller: notesController,
                      decoration:
                          const InputDecoration(labelText: 'Notes (optional)'),
                    ),
                    ResponsiveConfig.heightBox(20),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        // Credit Check
                        final hasCredit = await ref
                            .read(creditManagerProvider)
                            .requestCredit(context, ActionType.pregnancy);
                        if (!hasCredit) return;

                        final entry = PregnancyWeightEntry(
                          userId: userId,
                          pregnancyId: pregnancyId,
                          date: selectedDate,
                          weight: double.parse(weightController.text.trim()),
                          notes: notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                          createdAt: DateTime.now(),
                        );
                        await _pregnancyService.logWeightEntry(entry);
                        await ref
                            .read(creditManagerProvider)
                            .consumeCredits(ActionType.pregnancy);

                        if (!mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: const Text('Save weight'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAppointmentSheet(
    BuildContext context,
    String userId,
    String pregnancyId,
  ) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final doctorController = TextEditingController();
    final locationController = TextEditingController();
    DateTime scheduledDate = DateTime.now().add(const Duration(days: 1));
    String? type;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _sheetWrapper(
              context,
              Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Schedule appointment',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveConfig.heightBox(16),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                    ResponsiveConfig.heightBox(16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(DateFormat('EEE, MMM d, y · h:mm a')
                          .format(scheduledDate)),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: scheduledDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 280)),
                        );
                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(scheduledDate),
                          );
                          if (pickedTime != null) {
                            scheduledDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute);
                            setState(() {});
                          }
                        }
                      },
                    ),
                    ResponsiveConfig.heightBox(16),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration:
                          const InputDecoration(labelText: 'Appointment type'),
                      items: const [
                        DropdownMenuItem(
                            value: 'checkup', child: Text('Check-up')),
                        DropdownMenuItem(
                            value: 'ultrasound', child: Text('Ultrasound')),
                        DropdownMenuItem(
                            value: 'test', child: Text('Lab test')),
                        DropdownMenuItem(
                            value: 'class', child: Text('Prenatal class')),
                      ],
                      onChanged: (value) => type = value,
                    ),
                    ResponsiveConfig.heightBox(16),
                    TextField(
                      controller: doctorController,
                      decoration: const InputDecoration(
                          labelText: 'Doctor / Provider (optional)'),
                    ),
                    ResponsiveConfig.heightBox(16),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                          labelText: 'Location (optional)'),
                    ),
                    ResponsiveConfig.heightBox(16),
                    TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Notes (optional)'),
                      maxLines: 3,
                    ),
                    ResponsiveConfig.heightBox(24),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        // Credit Check
                        final hasCredit = await ref
                            .read(creditManagerProvider)
                            .requestCredit(context, ActionType.pregnancy);
                        if (!hasCredit) return;

                        final appointment = PregnancyAppointment(
                          userId: userId,
                          pregnancyId: pregnancyId,
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          scheduledDate: scheduledDate,
                          location: locationController.text.trim().isEmpty
                              ? null
                              : locationController.text.trim(),
                          doctorName: doctorController.text.trim().isEmpty
                              ? null
                              : doctorController.text.trim(),
                          appointmentType: type,
                          createdAt: DateTime.now(),
                        );
                        await _pregnancyService.saveAppointment(appointment);
                        await ref
                            .read(creditManagerProvider)
                            .consumeCredits(ActionType.pregnancy);

                        if (!mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: const Text('Save appointment'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showMedicationSheet(
    BuildContext context,
    String userId,
    String pregnancyId,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final notesController = TextEditingController();
    String frequency = 'daily';
    DateTime startDate = DateTime.now();
    DateTime? endDate;
    final times = <int>[];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _sheetWrapper(
              context,
              Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add medication',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveConfig.heightBox(16),
                    TextFormField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Medication name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                    ResponsiveConfig.heightBox(16),
                    TextField(
                      controller: dosageController,
                      decoration: const InputDecoration(
                          labelText: 'Dosage (e.g. 100mg)'),
                    ),
                    ResponsiveConfig.heightBox(16),
                    DropdownButtonFormField<String>(
                      value: frequency,
                      decoration: const InputDecoration(labelText: 'Frequency'),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
                        DropdownMenuItem(
                            value: 'twice_daily', child: Text('Twice daily')),
                        DropdownMenuItem(
                            value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(
                            value: 'as_needed', child: Text('As needed')),
                      ],
                      onChanged: (value) => frequency = value ?? 'daily',
                    ),
                    ResponsiveConfig.heightBox(16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(
                          'Start: ${DateFormat('MMM d, y').format(startDate)}'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 7)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          startDate = picked;
                          setState(() {});
                        }
                      },
                    ),
                    ResponsiveConfig.heightBox(8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_busy_outlined),
                      title: Text(endDate == null
                          ? 'No end date'
                          : 'End: ${DateFormat('MMM d, y').format(endDate!)}'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? startDate,
                          firstDate: startDate,
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          endDate = picked;
                          setState(() {});
                        }
                      },
                    ),
                    ResponsiveConfig.heightBox(16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime:
                                    const TimeOfDay(hour: 8, minute: 0),
                              );
                              if (picked != null) {
                                final hour = picked.hour;
                                if (!times.contains(hour)) {
                                  setState(() => times.add(hour));
                                }
                              }
                            },
                            icon: const Icon(Icons.add_alarm_outlined),
                            label: const Text('Add reminder time'),
                          ),
                        ],
                      ),
                    ),
                    if (times.isNotEmpty) ...[
                      ResponsiveConfig.heightBox(8),
                      Wrap(
                        spacing: 6,
                        children: times
                            .map(
                              (hour) => Chip(
                                label: Text(
                                    '${hour.toString().padLeft(2, '0')}:00'),
                                onDeleted: () =>
                                    setState(() => times.remove(hour)),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    ResponsiveConfig.heightBox(16),
                    TextField(
                      controller: notesController,
                      decoration:
                          const InputDecoration(labelText: 'Notes (optional)'),
                    ),
                    ResponsiveConfig.heightBox(24),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        // Credit Check
                        final hasCredit = await ref
                            .read(creditManagerProvider)
                            .requestCredit(context, ActionType.pregnancy);
                        if (!hasCredit) return;

                        final medication = PregnancyMedication(
                          userId: userId,
                          pregnancyId: pregnancyId,
                          medicationName: nameController.text.trim(),
                          dosage: dosageController.text.trim().isEmpty
                              ? null
                              : dosageController.text.trim(),
                          frequency: frequency,
                          startDate: startDate,
                          endDate: endDate,
                          timesOfDay: times,
                          notes: notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                          createdAt: DateTime.now(),
                        );
                        await _pregnancyService.saveMedication(medication);
                        await ref
                            .read(creditManagerProvider)
                            .consumeCredits(ActionType.pregnancy);

                        if (!mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: const Text('Save medication'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showChecklistSheet(
    BuildContext context,
    String userId,
    String pregnancyId,
  ) async {
    final formKey = GlobalKey<FormState>();
    final itemController = TextEditingController();
    String category = 'documents';
    int priority = 3;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return _sheetWrapper(
              context,
              Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add hospital checklist item',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveConfig.heightBox(16),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: const [
                        DropdownMenuItem(
                            value: 'documents', child: Text('Documents')),
                        DropdownMenuItem(
                            value: 'personal', child: Text('Personal items')),
                        DropdownMenuItem(
                            value: 'baby', child: Text('Baby items')),
                        DropdownMenuItem(
                            value: 'comfort', child: Text('Comfort items')),
                      ],
                      onChanged: (value) {
                        category = value ?? 'documents';
                        setState(() {});
                      },
                    ),
                    ResponsiveConfig.heightBox(16),
                    TextFormField(
                      controller: itemController,
                      decoration: const InputDecoration(labelText: 'Item'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                    ResponsiveConfig.heightBox(16),
                    _SliderInput(
                      label: 'Priority',
                      initialValue: priority.toDouble(),
                      min: 1,
                      max: 5,
                      onChanged: (value) {
                        priority = value.round();
                        setState(() {});
                      },
                    ),
                    ResponsiveConfig.heightBox(24),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        // Credit Check
                        final hasCredit = await ref
                            .read(creditManagerProvider)
                            .requestCredit(context, ActionType.pregnancy);
                        if (!hasCredit) return;

                        final item = HospitalChecklistItem(
                          userId: userId,
                          pregnancyId: pregnancyId,
                          category: category,
                          item: itemController.text.trim(),
                          priority: priority,
                          createdAt: DateTime.now(),
                        );
                        await _pregnancyService.saveHospitalChecklistItem(item);
                        await ref
                            .read(creditManagerProvider)
                            .consumeCredits(ActionType.pregnancy);

                        if (!mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: const Text('Save item'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- Pregnancy Tabs ---

class OverviewTab extends StatefulWidget {
  const OverviewTab({
    super.key,
    required this.pregnancy,
    required this.kickStream,
    required this.appointmentStream,
    required this.medicationStream,
    required this.babyStream,
    required this.onScheduleKickReminder,
    required this.onAddAppointment,
    required this.onAddMedication,
    this.isReadOnly = false,
  });

  final Pregnancy pregnancy;
  final Stream<List<KickEntry>> kickStream;
  final Stream<List<PregnancyAppointment>> appointmentStream;
  final Stream<List<PregnancyMedication>> medicationStream;
  final Stream<List<Baby>> babyStream;

  final VoidCallback? onScheduleKickReminder;
  final VoidCallback? onAddAppointment;
  final VoidCallback? onAddMedication;
  final bool isReadOnly;

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  late int _selectedWeek;

  @override
  void initState() {
    super.initState();
    _selectedWeek = widget.pregnancy.currentWeek;
  }

  int _getTrimesterForWeek(int week) {
    if (week < 13) return 1;
    if (week < 27) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final milestones = PregnancyMilestone.getMilestones();
    final currentMilestone = milestones.firstWhere(
      (m) => m.week == _selectedWeek,
      orElse: () => milestones.firstWhere(
        (m) => m.week == widget.pregnancy.currentWeek,
        orElse: () => milestones.last,
      ),
    );
    final dueDays = widget.pregnancy.dueDate?.difference(DateTime.now()).inDays;

    return SingleChildScrollView(
      padding: ResponsiveConfig.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProgressCard(
            pregnancy: widget.pregnancy,
            daysUntilDue: dueDays,
            selectedWeek: _selectedWeek,
            onWeekSelected: (week) => setState(() => _selectedWeek = week),
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<Baby>>(
            stream: widget.babyStream,
            builder: (context, snapshot) {
              return _MyBabiesSection(babies: snapshot.data ?? []);
            },
          ),
          if (widget.pregnancy.currentWeek >= 36 &&
              !widget.isReadOnly &&
              widget.pregnancy.babyIds.isEmpty) ...[
            _ChildbirthCTA(pregnancy: widget.pregnancy),
            ResponsiveConfig.heightBox(16),
          ],
          PregnancyProgressionSection(
            currentWeek: _selectedWeek,
            trimester: _getTrimesterForWeek(_selectedWeek),
          ),
          ResponsiveConfig.heightBox(16),
          MilestoneCard(milestone: currentMilestone),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<KickEntry>>(
            stream: widget.kickStream,
            builder: (context, snapshot) {
              return KickSummaryCard(
                entries: snapshot.data ?? [],
                onSchedule: widget.onScheduleKickReminder,
                isReadOnly: widget.isReadOnly,
              );
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<PregnancyAppointment>>(
            stream: widget.appointmentStream,
            builder: (context, snapshot) {
              return UpcomingAppointmentsCard(
                appointments: snapshot.data ?? [],
                onAddAppointment: widget.onAddAppointment,
                isReadOnly: widget.isReadOnly,
              );
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<PregnancyMedication>>(
            stream: widget.medicationStream,
            builder: (context, snapshot) {
              return MedicationReminderCard(
                medications: snapshot.data ?? [],
                onAddMedication: widget.onAddMedication,
                isReadOnly: widget.isReadOnly,
              );
            },
          ),
          ResponsiveConfig.heightBox(16),
          const DailyTipsCard(),
          ResponsiveConfig.heightBox(16),
          if (!widget.isReadOnly) ...[
            PartnerModeCard(pregnancy: widget.pregnancy),
            ResponsiveConfig.heightBox(16),
          ],
          ResponsiveConfig.heightBox(16),
          const BabyNameCard(),
          ResponsiveConfig.heightBox(16),
          const NutritionPlannerCard(),
          ResponsiveConfig.heightBox(16),
          const CommunityCard(),
        ],
      ),
    );
  }
}

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.pregnancy,
    required this.daysUntilDue,
    required this.selectedWeek,
    required this.onWeekSelected,
  });

  final Pregnancy pregnancy;
  final int? daysUntilDue;
  final int selectedWeek;
  final ValueChanged<int> onWeekSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Week $selectedWeek',
                            style: ResponsiveConfig.textStyle(
                              size: 24,
                              weight: FontWeight.bold,
                            ),
                          ),
                          ResponsiveConfig.widthBox(8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                final now = DateTime.now();
                                final firstDate =
                                    now.subtract(const Duration(days: 280));
                                final lastDate =
                                    now.add(const Duration(days: 280));

                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: now,
                                  firstDate: firstDate,
                                  lastDate: lastDate,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: AppTheme.primaryPink,
                                          onPrimary: Colors.white,
                                          onSurface: AppTheme.darkGray,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (picked != null) {
                                  // Approximate week calculation based on conception/LMP logic
                                  // If we don't have LMP here easily, we can ask user to pick "Week Start Date"
                                  // BUT, simplest is to just let them pick a week number directly from a dialog
                                  // OR, just map the date to week if we had LMP.
                                  // Since we only have 'pregnancy' object, let's use its LMP to calculate the selected week from the picked date.
                                  final difference = picked.difference(
                                      pregnancy.lastMenstrualPeriod);
                                  final week = (difference.inDays / 7)
                                      .ceil()
                                      .clamp(1, 42);
                                  onWeekSelected(week);
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.calendar_month_outlined,
                                  color: AppTheme.primaryPink,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ResponsiveConfig.heightBox(4),
                      Text(
                        daysUntilDue != null
                            ? '$daysUntilDue days left to delivery'
                            : 'Day ${pregnancy.currentDay} of journey',
                        style: ResponsiveConfig.textStyle(
                          size: 14,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                      if (pregnancy.dueDate != null) ...[
                        ResponsiveConfig.heightBox(4),
                        Text(
                          'Expected: ${DateFormat('MMM d, yyyy').format(pregnancy.dueDate!)}',
                          style: ResponsiveConfig.textStyle(
                            size: 14,
                            weight: FontWeight.w600,
                            color: AppTheme.primaryPink,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      ResponsiveConfig.padding(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Trimester ${_getTrimester(selectedWeek)}',
                    style: ResponsiveConfig.textStyle(
                      size: 12,
                      weight: FontWeight.bold,
                      color: AppTheme.primaryPink,
                    ),
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (selectedWeek / 40).clamp(0.0, 1.0),
                backgroundColor: AppTheme.palePink,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryPink,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getTrimester(int week) {
    if (week < 13) return 1;
    if (week < 27) return 2;
    return 3;
  }
}

class _ChildbirthCTA extends StatelessWidget {
  const _ChildbirthCTA({required this.pregnancy});

  final Pregnancy pregnancy;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.primaryPink.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppTheme.primaryPink.withOpacity(0.2)),
      ),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Row(
          children: [
            Container(
              padding: ResponsiveConfig.padding(all: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.child_care_rounded,
                color: AppTheme.primaryPink,
                size: 32,
              ),
            ),
            ResponsiveConfig.widthBox(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time to meet your baby?',
                    style: ResponsiveConfig.textStyle(
                      size: 16,
                      weight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Record your childbirth details and start newborn tracking.',
                    style: ResponsiveConfig.textStyle(
                      size: 13,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
            ResponsiveConfig.widthBox(12),
            IconButton.filled(
              onPressed: () => context.pushNamed(
                'childbirth-form',
                extra: pregnancy,
              ),
              icon: const Icon(Icons.arrow_forward),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryPink,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyBabiesSection extends StatelessWidget {
  const _MyBabiesSection({required this.babies});
  final List<Baby> babies;

  @override
  Widget build(BuildContext context) {
    if (babies.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Babies',
          style: ResponsiveConfig.textStyle(
            size: 16,
            weight: FontWeight.bold,
          ),
        ),
        ResponsiveConfig.heightBox(12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: babies.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final baby = babies[index];
              return _BabyCard(baby: baby);
            },
          ),
        ),
        ResponsiveConfig.heightBox(16),
      ],
    );
  }
}

class _BabyCard extends StatelessWidget {
  const _BabyCard({required this.baby});
  final Baby baby;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.goNamed('baby-dashboard', pathParameters: {'id': baby.id!}),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: ResponsiveConfig.padding(all: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryPink.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryPink.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: ResponsiveConfig.padding(all: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.child_care_rounded,
                color: AppTheme.primaryPink,
                size: 24,
              ),
            ),
            ResponsiveConfig.widthBox(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    baby.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      weight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getBabyAge(baby.birthDate),
                    style: ResponsiveConfig.textStyle(
                      size: 11,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBabyAge(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    if (difference.inDays < 30) {
      return '${difference.inDays} days old';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months months old';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years years old';
    }
  }
}

class MilestoneCard extends StatelessWidget {
  const MilestoneCard({super.key, required this.milestone});

  final PregnancyMilestone milestone;

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MilestoneDetailsSheet(milestone: milestone),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.primaryPink,
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This week: ${milestone.title}',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              milestone.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showDetails(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: ResponsiveConfig.padding(horizontal: 16),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                child: Text(
                  'Read more',
                  style: ResponsiveConfig.textStyle(
                    size: 12,
                    weight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneDetailsSheet extends StatelessWidget {
  const _MilestoneDetailsSheet({required this.milestone});

  final PregnancyMilestone milestone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: ResponsiveConfig.padding(all: 24),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.softGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ResponsiveConfig.heightBox(24),
            Text(
              'Week ${milestone.week}',
              style: ResponsiveConfig.textStyle(
                size: 14,
                weight: FontWeight.bold,
                color: AppTheme.primaryPink,
              ),
            ),
            Text(
              milestone.title,
              style: ResponsiveConfig.textStyle(
                size: 24,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            if (milestone.content != null) ...[
              Text(
                milestone.content!,
                style: ResponsiveConfig.textStyle(
                  size: 16,
                  height: 1.5,
                ),
              ),
              ResponsiveConfig.heightBox(24),
            ],
            _buildSection('Precautions', milestone.precautions,
                Icons.warning_amber_rounded),
            _buildSection('What to Expect', milestone.expectations,
                Icons.visibility_outlined),
            _buildSection('Remedies', milestone.remedies,
                Icons.health_and_safety_outlined),
            if (milestone.notes != null) ...[
              ResponsiveConfig.heightBox(16),
              Container(
                padding: ResponsiveConfig.padding(all: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  borderRadius: ResponsiveConfig.borderRadius(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_alt_outlined,
                        size: 20, color: Colors.white),
                    ResponsiveConfig.widthBox(12),
                    Expanded(
                      child: Text(
                        milestone.notes!,
                        style: ResponsiveConfig.textStyle(
                          size: 14,
                          color: Colors.white,
                        ).copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ResponsiveConfig.heightBox(40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryPink),
            ResponsiveConfig.widthBox(8),
            Text(
              title,
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
          ],
        ),
        ResponsiveConfig.heightBox(12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      item,
                      style: ResponsiveConfig.textStyle(size: 15),
                    ),
                  ),
                ],
              ),
            )),
        ResponsiveConfig.heightBox(24),
      ],
    );
  }
}

class KickSummaryCard extends StatelessWidget {
  const KickSummaryCard({
    super.key,
    required this.entries,
    required this.onSchedule,
    this.isReadOnly = false,
  });

  final List<KickEntry> entries;
  final VoidCallback? onSchedule;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayEntries = entries
        .where((entry) => DateFormat('yyyy-MM-dd').format(entry.date) == today);
    final todayCount =
        todayEntries.fold<int>(0, (sum, entry) => sum + entry.kickCount);

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Builder(builder: (context) {
          final children = <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kick Counter',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                if (!isReadOnly && onSchedule != null)
                  ElevatedButton.icon(
                    onPressed: onSchedule,
                    icon: const Icon(Icons.alarm_add_outlined),
                    label: const Text('Remind me'),
                  ),
              ],
            ),
            ResponsiveConfig.heightBox(12),
            Text(
              todayEntries.isEmpty
                  ? 'No kicks logged today. Aim for 10 counts within 2 hours.'
                  : 'You logged $todayCount kicks today.',
            ),
          ];

          if (entries.isNotEmpty) {
            children.addAll([
              ResponsiveConfig.heightBox(12),
              SizedBox(
                height: 120,
                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: AppTheme.mediumGray.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    alignment: BarChartAlignment.spaceAround,
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(),
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= entries.length) {
                              return const SizedBox.shrink();
                            }
                            final entry = entries[index];
                            return Text(DateFormat('MMMd').format(entry.date));
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    barGroups: entries
                        .take(10)
                        .toList()
                        .asMap()
                        .entries
                        .map(
                          (item) => BarChartGroupData(
                            x: item.key,
                            barRods: [
                              BarChartRodData(
                                toY: item.value.kickCount.toDouble(),
                                width: 12,
                                color: AppTheme.primaryPink,
                                borderRadius: BorderRadius.circular(
                                    ResponsiveConfig.radius(4)),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ]);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );
        }),
      ),
    );
  }
}

class UpcomingAppointmentsCard extends StatelessWidget {
  const UpcomingAppointmentsCard({
    super.key,
    required this.appointments,
    required this.onAddAppointment,
    this.isReadOnly = false,
  });

  final List<PregnancyAppointment> appointments;
  final VoidCallback? onAddAppointment;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final upcoming = appointments
        .where(
            (appointment) => appointment.scheduledDate.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

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
                  'Next appointments',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                if (!isReadOnly && onAddAppointment != null)
                  IconButton(
                    icon: const Icon(Icons.event_outlined),
                    color: AppTheme.lightPink,
                    tooltip: 'Add Appointment',
                    onPressed: onAddAppointment,
                  ),
              ],
            ),
            ResponsiveConfig.heightBox(12),
            if (upcoming.isEmpty)
              Text(
                'No upcoming appointments logged. Add your prenatal visits to stay organized.\n\nTap the icon to add an appointment.',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              )
            else
              ...upcoming.take(3).map(
                    (appointment) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_available_outlined,
                          color: AppTheme.primaryPink),
                      title: Text(appointment.title),
                      subtitle: Text(
                        '${DateFormat('EEE, MMM d · h:mm a').format(appointment.scheduledDate)}${appointment.location != null ? ' • ${appointment.location}' : ''}',
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class MedicationReminderCard extends StatelessWidget {
  const MedicationReminderCard({
    super.key,
    required this.medications,
    required this.onAddMedication,
    this.isReadOnly = false,
  });

  final List<PregnancyMedication> medications;
  final VoidCallback? onAddMedication;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final active = medications.where((med) => med.isActive).toList();
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
                  'Medications & supplements',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                if (!isReadOnly && onAddMedication != null)
                  IconButton(
                    icon: const Icon(Icons.medication_liquid_outlined),
                    color: AppTheme.lightPink,
                    tooltip: 'Add Medication',
                    onPressed: onAddMedication,
                  ),
              ],
            ),
            ResponsiveConfig.heightBox(12),
            if (active.isEmpty)
              Text(
                'Log prenatal vitamins or prescriptions to receive reminders.\n\nTap the icon to add a medication or supplement.',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              )
            else
              ...active.take(3).map(
                    (med) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.medication_liquid_outlined,
                          color: AppTheme.primaryPink),
                      title: Text(med.medicationName),
                      subtitle: Text(
                        '${med.frequency.replaceAll('_', ' ')}${med.timesOfDay.isNotEmpty ? ' • ${med.timesOfDay.map((hour) => '${hour.toString().padLeft(2, '0')}:00').join(', ')}' : ''}',
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class DailyTipsCard extends StatelessWidget {
  const DailyTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = [
      'Stay hydrated—aim for eight glasses of water daily to support amniotic fluid.',
      'Practice pelvic floor exercises to prep for birth and recovery.',
      'Rest on your left side to improve blood flow to baby.',
      'Snack on protein and complex carbs to steady blood sugar.',
    ];

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily wellness tips',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.favorite,
                        size: 16, color: AppTheme.primaryPink),
                    ResponsiveConfig.widthBox(8),
                    Expanded(child: Text(tip)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PartnerModeCard extends StatelessWidget {
  const PartnerModeCard({super.key, required this.pregnancy});

  final Pregnancy pregnancy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Partner mode',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Share a read-only dashboard with your partner so they can follow kicks, appointments and reminders.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            OutlinedButton.icon(
              onPressed: () {
                final text =
                    'Follow our pregnancy journey on FemCare+! View our live dashboard here: https://femcare.app/pregnancy/partner/${pregnancy.id}\n\n'
                    'Don\'t have the app? Download it now:\n'
                    'Android: ${AppConstants.playStoreUrl}\n'
                    'iOS: ${AppConstants.appStoreUrl}';
                Share.share(text, subject: 'Our Pregnancy Journey');
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

class BabyNameCard extends StatelessWidget {
  const BabyNameCard({super.key});

  @override
  Widget build(BuildContext context) {
    final names = [
      const BabyName(name: 'Amaia', gender: 'girl', meaning: 'night rain'),
      const BabyName(
          name: 'Sena', gender: 'girl', meaning: 'bringing heaven to earth'),
      const BabyName(name: 'Kwesi', gender: 'boy', meaning: 'born on Sunday'),
      const BabyName(name: 'Imani', gender: 'unisex', meaning: 'faith'),
      const BabyName(name: 'Kwame', gender: 'boy', meaning: 'born on Saturday'),
      const BabyName(
          name: 'Liam', gender: 'boy', meaning: 'strong-willed warrior'),
      const BabyName(name: 'Sofia', gender: 'girl', meaning: 'wisdom'),
      const BabyName(
          name: 'Yuki', gender: 'unisex', meaning: 'snow or happiness'),
      const BabyName(name: 'Mateo', gender: 'boy', meaning: 'gift of God'),
      const BabyName(
          name: 'Amara',
          gender: 'girl',
          meaning: 'grace, immortal, or peaceful'),
      const BabyName(
          name: 'Kai', gender: 'unisex', meaning: 'sea, forgiveness, or food'),
    ];

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Baby name inspiration',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            ...names.map(
              (name) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.star_border,
                        color: AppTheme.primaryPink, size: 18),
                    ResponsiveConfig.widthBox(8),
                    Expanded(
                      child: Text(
                        '${name.name} (${name.gender}) · ${name.meaning ?? 'beautiful meaning'}',
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
}

class NutritionPlannerCard extends StatelessWidget {
  const NutritionPlannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = [
      'Breakfast: fortified cereal, yogurt, and berries for folate and calcium.',
      'Lunch: grilled salmon with quinoa and greens for omega-3s and iron.',
      'Snack: hummus with carrots for protein and beta carotene.',
      'Dinner: lentil stew with whole grains for fiber and energy.',
    ];

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition planner',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            ...plans.map(
              (plan) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.local_dining_outlined,
                        color: AppTheme.primaryPink, size: 18),
                    ResponsiveConfig.widthBox(8),
                    Expanded(child: Text(plan)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Journal Tab ---

class _JournalTab extends StatelessWidget {
  const _JournalTab({
    required this.pregnancy,
    required this.journalStream,
    required this.weightStream,
    required this.onLogJournal,
    required this.onLogWeight,
    this.isReadOnly = false,
  });

  final Pregnancy pregnancy;
  final Stream<List<PregnancyJournalEntry>> journalStream;
  final Stream<List<PregnancyWeightEntry>> weightStream;
  final VoidCallback onLogJournal;
  final VoidCallback onLogWeight;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _JournalHeader(
              pregnancy: pregnancy,
              onLogJournal: onLogJournal,
              isReadOnly: isReadOnly),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<PregnancyJournalEntry>>(
            stream: journalStream,
            builder: (context, snapshot) {
              final entries = snapshot.data ?? [];
              if (entries.isEmpty) {
                return _EmptyState(
                  icon: Icons.book_outlined,
                  title: 'No journals yet',
                  message:
                      'Log mood, symptoms and notes to track emotional wellbeing.',
                  actionLabel: isReadOnly ? null : 'Log journal',
                  onAction: isReadOnly ? null : onLogJournal,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: entries.take(10).map(_JournalEntryTile.new).toList(),
              );
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<PregnancyWeightEntry>>(
            stream: weightStream,
            builder: (context, snapshot) {
              return _WeightTrendCard(
                entries: snapshot.data ?? [],
                onLogWeight: onLogWeight,
                isReadOnly: isReadOnly,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _JournalHeader extends StatelessWidget {
  const _JournalHeader({
    required this.pregnancy,
    required this.onLogJournal,
    required this.isReadOnly,
  });

  final Pregnancy pregnancy;
  final VoidCallback onLogJournal;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How are you feeling?',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                ResponsiveConfig.heightBox(4),
                Text(
                  'Week ${pregnancy.currentWeek} · Trimester ${pregnancy.trimester}',
                  style: ResponsiveConfig.textStyle(
                    size: 14,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(12),
            if (!isReadOnly)
              ElevatedButton.icon(
                onPressed: onLogJournal,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Log journal'),
              ),
          ],
        ),
      ),
    );
  }
}

class _JournalEntryTile extends StatelessWidget {
  const _JournalEntryTile(this.entry);

  final PregnancyJournalEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: ResponsiveConfig.margin(bottom: 12),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEE, MMM d, y').format(entry.date),
              style: ResponsiveConfig.textStyle(
                size: 16,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(6),
            Text('Mood: ${entry.mood ?? 'Not set'}'),
            if (entry.symptoms.isNotEmpty)
              Text('Symptoms: ${entry.symptoms.join(', ')}'),
            if (entry.sleepHours != null)
              Text(
                  'Sleep: ${entry.sleepHours} h • Quality: ${entry.sleepQuality ?? 'N/A'}'),
            if (entry.journalText != null &&
                entry.journalText!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(entry.journalText!),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeightTrendCard extends StatelessWidget {
  const _WeightTrendCard({
    required this.entries,
    required this.onLogWeight,
    this.isReadOnly = false,
  });

  final List<PregnancyWeightEntry> entries;
  final VoidCallback onLogWeight;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final sorted = List<PregnancyWeightEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

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
                  'Weight tracker',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                if (!isReadOnly)
                  OutlinedButton.icon(
                    onPressed: onLogWeight,
                    icon: const Icon(Icons.monitor_weight_outlined),
                    label: const Text('Log weight'),
                  ),
              ],
            ),
            ResponsiveConfig.heightBox(12),
            if (sorted.length < 2)
              Text(
                'Log at least two weight entries to view progress.',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              )
            else
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: AppTheme.mediumGray.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) {
                          return spots.map((spot) {
                            final entry = sorted[spot.spotIndex];
                            return LineTooltipItem(
                              '${DateFormat('MMMd').format(entry.date)}\n${entry.weight.toStringAsFixed(1)} kg',
                              ResponsiveConfig.textStyle(
                                size: 12,
                                color: Colors.white,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: max(1, sorted.length / 4).toDouble(),
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= sorted.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              DateFormat('MMMd').format(sorted[index].date),
                              style: ResponsiveConfig.textStyle(size: 10),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) => Text(
                            value.toStringAsFixed(0),
                            style: ResponsiveConfig.textStyle(size: 10),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(),
                      topTitles: const AxisTitles(),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: sorted.asMap().entries.map((entry) {
                          return FlSpot(
                              entry.key.toDouble(), entry.value.weight);
                        }).toList(),
                        isCurved: false,
                        color: AppTheme.primaryPink,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.primaryPink.withOpacity(0.15),
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
}

// --- Planner Tab ---

class _PlannerTab extends StatelessWidget {
  const _PlannerTab({
    required this.pregnancy,
    required this.appointmentStream,
    required this.medicationStream,
    required this.checklistStream,
    required this.onAddAppointment,
    required this.onAddMedication,
    required this.onAddChecklist,
    this.isReadOnly = false,
  });

  final Pregnancy pregnancy;
  final Stream<List<PregnancyAppointment>> appointmentStream;
  final Stream<List<PregnancyMedication>> medicationStream;
  final Stream<List<HospitalChecklistItem>> checklistStream;
  final VoidCallback onAddAppointment;
  final VoidCallback onAddMedication;
  final VoidCallback onAddChecklist;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PlannerHeader(
            pregnancy: pregnancy,
            onAddAppointment: onAddAppointment,
            onAddMedication: onAddMedication,
            isReadOnly: isReadOnly,
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<PregnancyAppointment>>(
            stream: appointmentStream,
            builder: (context, snapshot) {
              return _AppointmentListCard(
                appointments: snapshot.data ?? [],
                emptyAction: onAddAppointment,
                isReadOnly: isReadOnly,
              );
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<PregnancyMedication>>(
            stream: medicationStream,
            builder: (context, snapshot) {
              return _MedicationListCard(
                medications: snapshot.data ?? [],
                onAddMedication: onAddMedication,
                isReadOnly: isReadOnly,
              );
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<HospitalChecklistItem>>(
            stream: checklistStream,
            builder: (context, snapshot) {
              return _HospitalChecklistCard(
                items: snapshot.data ?? [],
                onAdd: onAddChecklist,
                isReadOnly: isReadOnly,
              );
            },
          ),
          ResponsiveConfig.heightBox(16),
          const _LaborPreparationCard(),
        ],
      ),
    );
  }
}

class _PlannerHeader extends StatelessWidget {
  const _PlannerHeader({
    required this.pregnancy,
    required this.onAddAppointment,
    required this.onAddMedication,
    this.isReadOnly = false,
  });

  final Pregnancy pregnancy;
  final VoidCallback onAddAppointment;
  final VoidCallback onAddMedication;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Keep your third trimester organised',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Add appointments, medications, and hospital bag checklist items so FemCare+ can remind you.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            if (!isReadOnly)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onAddAppointment,
                    icon: const Icon(Icons.event_note_outlined),
                    label: const Text('New appointment'),
                  ),
                  ResponsiveConfig.heightBox(12),
                  OutlinedButton.icon(
                    onPressed: onAddMedication,
                    icon: const Icon(Icons.medication_outlined),
                    label: const Text('Add medication'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentListCard extends StatelessWidget {
  const _AppointmentListCard({
    required this.appointments,
    required this.emptyAction,
    this.isReadOnly = false,
  });

  final List<PregnancyAppointment> appointments;
  final VoidCallback emptyAction;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return _EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'No appointments yet',
        message:
            'Schedule prenatal check-ups and classes so the app can remind you.',
        actionLabel: isReadOnly ? null : 'Add appointment',
        onAction: isReadOnly ? null : emptyAction,
      );
    }

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: appointments.take(5).map((appointment) {
            final isPast = appointment.scheduledDate.isBefore(DateTime.now());
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isPast ? Icons.check_circle : Icons.event_available_outlined,
                color: isPast ? AppTheme.successGreen : AppTheme.primaryPink,
              ),
              title: Text(appointment.title),
              subtitle: Text(
                DateFormat('EEE, MMM d · h:mm a')
                    .format(appointment.scheduledDate),
              ),
              trailing: appointment.doctorName != null
                  ? Text(appointment.doctorName!.split(' ').first)
                  : null,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MedicationListCard extends StatelessWidget {
  const _MedicationListCard({
    required this.medications,
    required this.onAddMedication,
    this.isReadOnly = false,
  });

  final List<PregnancyMedication> medications;
  final VoidCallback onAddMedication;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    if (medications.isEmpty) {
      return _EmptyState(
        icon: Icons.medical_services_outlined,
        title: 'No medications tracked',
        message: 'Add prenatal vitamins or prescriptions to receive reminders.',
        actionLabel: isReadOnly ? null : 'Add medication',
        onAction: isReadOnly ? null : onAddMedication,
      );
    }

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: medications.take(5).map((med) {
            final until = med.endDate != null
                ? 'Until ${DateFormat('MMM d').format(med.endDate!)}'
                : 'Ongoing';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.medication_liquid_outlined,
                  color: AppTheme.primaryPink),
              title: Text(med.medicationName),
              subtitle: Text('${med.frequency.replaceAll('_', ' ')} • $until'),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _HospitalChecklistCard extends StatelessWidget {
  const _HospitalChecklistCard({
    required this.items,
    required this.onAdd,
    this.isReadOnly = false,
  });

  final List<HospitalChecklistItem> items;
  final VoidCallback onAdd;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(
        icon: Icons.luggage_outlined,
        title: 'Hospital bag checklist',
        message: 'Create your hospital bag checklist so nothing is forgotten.',
        actionLabel: isReadOnly ? null : 'Add item',
        onAction: isReadOnly ? null : onAdd,
      );
    }

    final grouped = <String, List<HospitalChecklistItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: ResponsiveConfig.textStyle(
                    size: 14,
                    weight: FontWeight.w700,
                  ),
                ),
                ResponsiveConfig.heightBox(6),
                ...entry.value.map((item) => Row(
                      children: [
                        Icon(
                          item.isChecked
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: item.isChecked
                              ? AppTheme.successGreen
                              : AppTheme.mediumGray,
                        ),
                        ResponsiveConfig.widthBox(8),
                        Expanded(child: Text(item.item)),
                      ],
                    )),
                ResponsiveConfig.heightBox(12),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _LaborPreparationCard extends StatelessWidget {
  const _LaborPreparationCard();

  @override
  Widget build(BuildContext context) {
    final tips = [
      'Finalize birth plan preferences and share with your care team.',
      'Practice breathing exercises and partner-supported relaxation.',
      'Pack hospital bag by week 36 with documents, clothes, and baby essentials.',
      'Install car seat and schedule pediatrician visit.',
    ];

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Labor preparation checklist',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppTheme.primaryPink, size: 18),
                    ResponsiveConfig.widthBox(8),
                    Expanded(child: Text(tip)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Insights Tab ---

class _InsightsTab extends StatelessWidget {
  const _InsightsTab({
    required this.pregnancy,
    required this.kickStream,
    required this.contractionStream,
    required this.weightStream,
    required this.journalStream,
    required this.onLogKick,
    required this.onLogContraction,
    this.isReadOnly = false,
  });

  final Pregnancy pregnancy;
  final Stream<List<KickEntry>> kickStream;
  final Stream<List<ContractionEntry>> contractionStream;
  final Stream<List<PregnancyWeightEntry>> weightStream;
  final Stream<List<PregnancyJournalEntry>> journalStream;
  final VoidCallback onLogKick;
  final VoidCallback onLogContraction;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InsightsHeader(
            onLogKick: onLogKick,
            onLogContraction: onLogContraction,
            isReadOnly: isReadOnly,
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<KickEntry>>(
            stream: kickStream,
            builder: (context, snapshot) {
              return _KickTrendCard(entries: snapshot.data ?? []);
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<ContractionEntry>>(
            stream: contractionStream,
            builder: (context, snapshot) {
              return _ContractionTrendCard(entries: snapshot.data ?? []);
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<PregnancyWeightEntry>>(
            stream: weightStream,
            builder: (context, snapshot) {
              return _WeightSummaryCard(entries: snapshot.data ?? []);
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<PregnancyJournalEntry>>(
            stream: journalStream,
            builder: (context, snapshot) {
              return _SleepPatternCard(entries: snapshot.data ?? []);
            },
          ),
          ResponsiveConfig.heightBox(16),
          _AIPregnancyAssistantCard(pregnancy: pregnancy),
          ResponsiveConfig.heightBox(16),
          const _BirthPrepResourcesCard(),
        ],
      ),
    );
  }
}

class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader({
    required this.onLogKick,
    required this.onLogContraction,
    this.isReadOnly = false,
  });

  final VoidCallback onLogKick;
  final VoidCallback onLogContraction;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    if (isReadOnly) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track patterns',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Log kicks and contractions to monitor active labor signs.',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 5,
                  style: ResponsiveConfig.textStyle(
                    size: 14,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: onLogKick,
                  icon: const Icon(Icons.favorite_outline),
                  label: const Text('Log kicks'),
                ),
                ResponsiveConfig.heightBox(8),
                OutlinedButton.icon(
                  onPressed: onLogContraction,
                  icon: const Icon(Icons.timer_outlined),
                  label: const Text('Log contraction'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KickTrendCard extends StatelessWidget {
  const _KickTrendCard({required this.entries});

  final List<KickEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyState(
        icon: Icons.favorite_outline,
        title: 'No kick data',
        message: 'Log kick sessions to monitor fetal movement patterns.',
      );
    }

    final grouped = <String, int>{};
    for (final entry in entries) {
      final key = DateFormat('yyyy-MM-dd').format(entry.date);
      grouped.update(key, (value) => value + entry.kickCount,
          ifAbsent: () => entry.kickCount);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final spots = sortedKeys.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), grouped[entry.value]!.toDouble());
    }).toList();

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kick pattern (last ${sortedKeys.length} days)',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: AppTheme.mediumGray.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots
                            .map((spot) {
                              final index = spot.spotIndex;
                              if (index < 0 || index >= sortedKeys.length) {
                                return null;
                              }
                              final date = DateTime.parse(sortedKeys[index]);
                              final kicks = grouped[sortedKeys[index]] ?? 0;
                              return LineTooltipItem(
                                '${DateFormat('MMM d').format(date)}\\n$kicks kicks',
                                ResponsiveConfig.textStyle(
                                  size: 12,
                                  color: Colors.white,
                                ),
                              );
                            })
                            .whereType<LineTooltipItem>()
                            .toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: AppTheme.primaryPink,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: max(1, sortedKeys.length / 4).toDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= sortedKeys.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            DateFormat('MMMd')
                                .format(DateTime.parse(sortedKeys[index])),
                            style: ResponsiveConfig.textStyle(size: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: ResponsiveConfig.textStyle(size: 10),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractionTrendCard extends StatelessWidget {
  const _ContractionTrendCard({required this.entries});

  final List<ContractionEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyState(
        icon: Icons.timer_outlined,
        title: 'No contractions logged',
        message:
            'Track contraction frequency and intensity as labor approaches.',
      );
    }

    final recent = entries.take(10).toList();
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent contractions',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            ...recent.map((entry) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer, color: AppTheme.primaryPink),
                title: Text(
                  '${DateFormat('EEE, MMM d · h:mm a').format(entry.startTime)} · ${entry.duration?.inMinutes ?? 0} min',
                ),
                subtitle: Text(
                  'Interval ${entry.interval?.inMinutes ?? 0} min · Intensity ${entry.intensity ?? '-'}',
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _WeightSummaryCard extends StatelessWidget {
  const _WeightSummaryCard({required this.entries});

  final List<PregnancyWeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _EmptyState(
        icon: Icons.monitor_weight_outlined,
        title: 'No weight data',
        message: 'Log weight from the journal tab to monitor healthy gain.',
      );
    }
    final latest = entries.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest weight',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              '${latest.weight.toStringAsFixed(1)} kg on ${DateFormat('MMM d, y').format(latest.date)}',
              style: ResponsiveConfig.textStyle(
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepPatternCard extends StatelessWidget {
  const _SleepPatternCard({required this.entries});

  final List<PregnancyJournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final sleepEntries =
        entries.where((entry) => entry.sleepHours != null).take(7).toList();
    if (sleepEntries.isEmpty) {
      return const _EmptyState(
        icon: Icons.nightlight_outlined,
        title: 'No sleep logs',
        message: 'Record sleep hours to spot fatigue patterns.',
      );
    }

    final average = sleepEntries
            .map((entry) => entry.sleepHours!.toDouble())
            .reduce((a, b) => a + b) /
        sleepEntries.length;

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sleep pattern (last ${sleepEntries.length} days)',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Average sleep: ${average.toStringAsFixed(1)} hours',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            Wrap(
              spacing: 8,
              children: sleepEntries.map((entry) {
                return Chip(
                  side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.05)),
                  avatar: const Icon(Icons.nightlight_round, size: 14),
                  label: Text(
                      '${DateFormat('MMMd').format(entry.date)} · ${entry.sleepHours} h'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AIPregnancyAssistantCard extends StatelessWidget {
  const _AIPregnancyAssistantCard({required this.pregnancy});

  final Pregnancy pregnancy;

  int _calculatePregnancyWeek() {
    if (pregnancy.dueDate == null) return 0;
    final now = DateTime.now();
    final dueDate = pregnancy.dueDate!;
    final weeksSinceLMP = 40 - ((dueDate.difference(now).inDays) / 7).ceil();
    return weeksSinceLMP.clamp(0, 40);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Pregnancy Assistant',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            const Text(
              'Chat with FemCare+ AI (beta) to interpret logs, plan prenatal visits, and get mindful prompts tailored to you.',
            ),
            ResponsiveConfig.heightBox(12),
            ElevatedButton.icon(
              onPressed: () {
                final chatContext = {
                  'pregnancyWeek': _calculatePregnancyWeek(),
                  'dueDate': pregnancy.dueDate?.toIso8601String(),
                  'currentWeek': pregnancy.currentWeek,
                  'trimester': pregnancy.trimester,
                };
                context.push('/ai-chat/pregnancy', extra: chatContext);
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Open FemCare+ assistant'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BirthPrepResourcesCard extends StatelessWidget {
  const _BirthPrepResourcesCard();

  @override
  Widget build(BuildContext context) {
    final resources = [
      'Prenatal class schedule and breathing exercise tutorials.',
      'Hospital bag checklist synced with partner and reminders.',
      'Labor positions and comfort techniques curated for you.',
      'Postpartum recovery guide to prepare for the fourth trimester.',
    ];

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Birth preparation resources',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            ...resources.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: AppTheme.primaryPink, size: 18),
                    ResponsiveConfig.widthBox(8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: ResponsiveConfig.padding(all: 24),
              decoration: BoxDecoration(
                color: AppTheme.lightPink.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: ResponsiveConfig.iconSize(56),
                color: AppTheme.primaryPink,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            Text(
              title,
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              message,
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SliderInput extends StatelessWidget {
  const _SliderInput({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.min = 0,
    this.max = 10,
  });

  final String label;
  final double initialValue;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    double value = initialValue;
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label),
                Text(min == 1 && max == 5
                    ? value.round().toString()
                    : value.toStringAsFixed(1)),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: max > min ? (max - min).round() : null,
              label: min == 1 && max == 5
                  ? value.round().toString()
                  : value.toStringAsFixed(1),
              onChanged: (newValue) {
                setState(() => value = newValue);
                onChanged(newValue);
              },
            ),
          ],
        );
      },
    );
  }
}

class CommunityCard extends StatelessWidget {
  const CommunityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community & Support Forum',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Get to interact with mothers and other pregnant women to share and gather experiences.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.push('/groups'),
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Join forum'),
                ),
                ResponsiveConfig.heightBox(8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/events'),
                  icon: const Icon(Icons.event_outlined),
                  label: const Text('Upcoming events'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PregnancyProgressionSection extends StatelessWidget {
  final int currentWeek;
  final int trimester;

  const PregnancyProgressionSection(
      {super.key, required this.currentWeek, required this.trimester});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: _WeeklyDevelopmentCard(
            week: currentWeek,
            trimester: trimester,
          ),
        ),
      ],
    );
  }
}

class _WeeklyDevelopmentCard extends StatefulWidget {
  final int week;
  final int trimester;

  const _WeeklyDevelopmentCard({
    required this.week,
    required this.trimester,
  });

  @override
  State<_WeeklyDevelopmentCard> createState() => _WeeklyDevelopmentCardState();
}

class _WeeklyDevelopmentCardState extends State<_WeeklyDevelopmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, String> trimester = {};

  @override
  Widget build(BuildContext context) {
    String week = widget.week.toString();

    if (widget.week < 5) {
      week = '4';
    }
    if (widget.week == 10) {
      week = '11';
    }
    if (widget.week == 36) {
      week = '35';
    }
    if (widget.week == 41) {
      week = '40';
    }
    final imageUrl =
        //'https://assets.nhs.uk/campaigns-cms-prod/images/banner-WBW-week-28.width-1440.jpg')""
        'https://assets.nhs.uk/campaigns-cms-prod/images/banner-WBW-week-$week.width-1440.jpg';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (rect) {
            return RadialGradient(
              colors: [
                Colors.black,
                Colors.black.withOpacity(0.8),
                Colors.transparent,
              ],
              stops: const [0.6, 0.8, 1.0],
              center: Alignment.center,
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: ResponsiveConfig.width(250),
            height: ResponsiveConfig.height(250),
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, error, stackTrace) {
              return Container(
                color: AppTheme.softGray,
                child: const Icon(Icons.image_not_supported),
              );
            },
          ),
        ),
        ResponsiveConfig.heightBox(8),
        Text(
          _getWeeklyTitle(widget.week),
          style: ResponsiveConfig.textStyle(
            size: 16,
            weight: FontWeight.bold,
            color: AppTheme.primaryPink,
          ),
          textAlign: TextAlign.center,
        ),
        ResponsiveConfig.heightBox(4),
        Text(
          'Trimester ${widget.trimester} • Week ${widget.week}',
          style: ResponsiveConfig.textStyle(
            size: 12,
            color: AppTheme.mediumGray,
          ),
        ),
      ],
    );
  }

  String _getWeeklyTitle(int week) {
    switch (week) {
      case 1:
      case 2:
      case 3:
        return 'Conception and implantation';
      case 4:
        return 'Early development';
      case 5:
        return 'Heart begins to beat';
      case 6:
        return 'Facial features forming';
      case 7:
        return 'Tiny hands and feet';
      case 8:
        return 'Moving in the womb';
      case 9:
        return 'Eyelids and ears';
      case 10:
        return 'Vital organs formed';
      case 11:
        return 'Fingers and toes';
      case 12:
        return 'Reflexes develop';
      case 13:
        return 'Fingerprints forming';
      case 14:
        return 'Squinting and grimacing';
      case 15:
        return 'Sensing light';
      case 16:
        return 'Sucking thumb';
      case 17:
        return 'Strengthening bones';
      case 18:
        return 'Feeling movement';
      case 19:
        return 'Sensory development';
      case 20:
        return 'Halfway point';
      case 21:
        return 'Swallowing';
      case 22:
        return 'Sense of touch';
      case 23:
        return 'Hearing sounds';
      case 24:
        return 'Viability milestone';
      case 25:
        return 'Responding to touch';
      case 26:
        return 'Eyes opening';
      case 27:
        return 'Inhaling amniotic fluid';
      case 28:
        return 'Dreaming and blinking';
      case 29:
        return 'Rapid brain growth';
      case 30:
        return 'Practicing breathing';
      case 31:
        return 'Focusing eyes';
      case 32:
        return 'Developing skin layers';
      case 33:
        return 'Immune system kicks in';
      case 34:
        return 'Turning head down';
      case 35:
        return 'Full hearing power';
      case 36:
        return 'Gaining fat for warmth';
      case 37:
        return 'Early full term';
      case 38:
        return 'Developing lungs';
      case 39:
        return 'Full term journey';
      case 40:
        return 'Ready for the world';
      case 41:
        return 'Wait is almost over';
      default:
        return 'Growing strong';
    }
  }
}
