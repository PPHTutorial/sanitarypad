import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../data/models/pregnancy_model.dart';
import '../../../services/pregnancy_service.dart';
import '../../../services/reminder_service.dart';

class PregnancyTrackingScreen extends ConsumerStatefulWidget {
  const PregnancyTrackingScreen({super.key});

  @override
  ConsumerState<PregnancyTrackingScreen> createState() =>
      _PregnancyTrackingScreenState();
}

class _PregnancyTrackingScreenState
    extends ConsumerState<PregnancyTrackingScreen>
    with TickerProviderStateMixin {
  final _pregnancyService = PregnancyService();
  final _reminderService = ReminderService();
  late final TabController _tabController;

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
      child: FutureBuilder<Pregnancy?>(
        future: _pregnancyService.getActivePregnancy(user.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          final pregnancy = snapshot.data;
          if (pregnancy == null || pregnancy.id == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Pregnancy Tracking'),
              ),
              body: _EmptyState(
                icon: Icons.child_care_outlined,
                title: 'No Active Pregnancy',
                message:
                    'Start a pregnancy profile to unlock FemCare+ guidance.',
                actionLabel: 'Create pregnancy profile',
                onAction: () =>
                    Navigator.of(context).pushNamed('/pregnancy-form'),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/pregnancy-form'),
                icon: const Icon(Icons.add),
                label: const Text('Start Tracking'),
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
              title: const Text('Pregnancy Journey'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(72),
                child: _buildModernTabSwitcher(context),
              ),
            ),
            floatingActionButton:
                _buildFab(user.userId, pregnancyId, pregnancy),
            body: TabBarView(
              controller: _tabController,
              children: [
                _OverviewTab(
                  pregnancy: pregnancy,
                  kickStream: kickStream,
                  appointmentStream: appointmentStream,
                  medicationStream: medicationStream,
                  onScheduleKickReminder: () =>
                      _scheduleReminder(user.userId, 'kick_check'),
                ),
                _JournalTab(
                  pregnancy: pregnancy,
                  journalStream: journalStream,
                  weightStream: weightStream,
                  onLogJournal: () =>
                      _showJournalSheet(context, user.userId, pregnancyId),
                  onLogWeight: () =>
                      _showWeightSheet(context, user.userId, pregnancyId),
                ),
                _PlannerTab(
                  pregnancy: pregnancy,
                  appointmentStream: appointmentStream,
                  medicationStream: medicationStream,
                  checklistStream: checklistStream,
                  onAddAppointment: () =>
                      _showAppointmentSheet(context, user.userId, pregnancyId),
                  onAddMedication: () =>
                      _showMedicationSheet(context, user.userId, pregnancyId),
                  onAddChecklist: () =>
                      _showChecklistSheet(context, user.userId, pregnancyId),
                ),
                _InsightsTab(
                  pregnancy: pregnancy,
                  kickStream: kickStream,
                  contractionStream: contractionStream,
                  weightStream: weightStream,
                  journalStream: journalStream,
                  onLogKick: () =>
                      _showKickSheet(context, user.userId, pregnancyId),
                  onLogContraction: () =>
                      _showContractionSheet(context, user.userId, pregnancyId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernTabSwitcher(BuildContext context) {
    return TabBar(
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
      child: child,
    );
  }

  FloatingActionButton? _buildFab(
    String userId,
    String pregnancyId,
    Pregnancy pregnancy,
  ) {
    switch (_tabController.index) {
      case 0:
        return FloatingActionButton.extended(
          onPressed: () => _showKickSheet(context, userId, pregnancyId),
          icon: const Icon(Icons.favorite_outlined),
          label: const Text('Log kicks'),
        );
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => _showJournalSheet(context, userId, pregnancyId),
          icon: const Icon(Icons.edit_note_outlined),
          label: const Text('New journal'),
        );
      case 2:
        return FloatingActionButton.extended(
          onPressed: () => _showAppointmentSheet(context, userId, pregnancyId),
          icon: const Icon(Icons.event_available_outlined),
          label: const Text('Add appointment'),
        );
      case 3:
        return FloatingActionButton.extended(
          onPressed: () => _showContractionSheet(context, userId, pregnancyId),
          icon: const Icon(Icons.timer_outlined),
          label: const Text('Log contraction'),
        );
      default:
        return null;
    }
  }

  Future<void> _scheduleReminder(String userId, String type) async {
    final reminder = Reminder(
      userId: userId,
      type: type,
      title:
          type == 'kick_check' ? 'Kick counter reminder' : 'Pregnancy reminder',
      description: type == 'kick_check'
          ? 'Take a moment to count baby kicks.'
          : 'FemCare+ reminder',
      scheduledTime: DateTime.now().add(const Duration(minutes: 1)),
      metadata: const {'repeat': 'daily'},
    );
    await _reminderService.createReminder(reminder);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder scheduled.')),
    );
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
                  decoration: const InputDecoration(labelText: 'Kick count'),
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
                  onChanged: (value) => durationMinutes = value,
                ),
                ResponsiveConfig.heightBox(16),
                TextField(
                  controller: notesController,
                  decoration:
                      const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
                ),
                ResponsiveConfig.heightBox(24),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final entry = KickEntry(
                      userId: userId,
                      pregnancyId: pregnancyId,
                      date: DateTime.now(),
                      time: DateTime.now(),
                      kickCount: int.parse(countController.text.trim()),
                      duration: Duration(minutes: durationMinutes.round()),
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                      createdAt: DateTime.now(),
                    );
                    await _pregnancyService.logKickEntry(entry);
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save kicks'),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                      startTime = picked;
                      if (context.mounted) setState(() {});
                    }
                  },
                ),
                ResponsiveConfig.heightBox(16),
                _SliderInput(
                  label: 'Duration (minutes)',
                  initialValue: durationMinutes,
                  min: 1,
                  max: 10,
                  onChanged: (value) => durationMinutes = value,
                ),
                ResponsiveConfig.heightBox(16),
                _SliderInput(
                  label: 'Interval since last (minutes)',
                  initialValue: intervalMinutes,
                  min: 1,
                  max: 30,
                  onChanged: (value) => intervalMinutes = value,
                ),
                ResponsiveConfig.heightBox(16),
                _SliderInput(
                  label: 'Intensity',
                  initialValue: intensity,
                  min: 1,
                  max: 10,
                  onChanged: (value) => intensity = value,
                ),
                ResponsiveConfig.heightBox(16),
                TextField(
                  controller: notesController,
                  decoration:
                      const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
                ),
                ResponsiveConfig.heightBox(24),
                ElevatedButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final start = DateTime(now.year, now.month, now.day,
                        startTime.hour, startTime.minute);
                    final entry = ContractionEntry(
                      userId: userId,
                      pregnancyId: pregnancyId,
                      startTime: start,
                      endTime:
                          start.add(Duration(minutes: durationMinutes.round())),
                      duration: Duration(minutes: durationMinutes.round()),
                      interval: Duration(minutes: intervalMinutes.round()),
                      intensity: intensity.round(),
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                      createdAt: DateTime.now(),
                    );
                    await _pregnancyService.logContraction(entry);
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
                  title: Text(DateFormat('EEE, MMM d, y').format(selectedDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 280)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                      setState(() {});
                    }
                  },
                ),
                ResponsiveConfig.heightBox(16),
                DropdownButtonFormField<String>(
                  value: mood,
                  decoration: const InputDecoration(labelText: 'Mood'),
                  items: const [
                    DropdownMenuItem(value: 'happy', child: Text('Happy')),
                    DropdownMenuItem(value: 'calm', child: Text('Calm')),
                    DropdownMenuItem(value: 'anxious', child: Text('Anxious')),
                    DropdownMenuItem(value: 'tired', child: Text('Tired')),
                    DropdownMenuItem(value: 'excited', child: Text('Excited')),
                  ],
                  onChanged: (value) => mood = value,
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
                  decoration: const InputDecoration(labelText: 'Sleep hours'),
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
                          selectedDate = picked;
                          setState(() {});
                        }
                      },
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
                    TextField(
                      controller: notesController,
                      decoration:
                          const InputDecoration(labelText: 'Notes (optional)'),
                    ),
                    ResponsiveConfig.heightBox(20),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
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
                        final item = HospitalChecklistItem(
                          userId: userId,
                          pregnancyId: pregnancyId,
                          category: category,
                          item: itemController.text.trim(),
                          priority: priority,
                          createdAt: DateTime.now(),
                        );
                        await _pregnancyService.saveHospitalChecklistItem(item);
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

// --- Overview Tab ---

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.pregnancy,
    required this.kickStream,
    required this.appointmentStream,
    required this.medicationStream,
    required this.onScheduleKickReminder,
  });

  final Pregnancy pregnancy;
  final Stream<List<KickEntry>> kickStream;
  final Stream<List<PregnancyAppointment>> appointmentStream;
  final Stream<List<PregnancyMedication>> medicationStream;
  final VoidCallback onScheduleKickReminder;

  @override
  Widget build(BuildContext context) {
    final currentMilestone = PregnancyService().getCurrentMilestone(pregnancy);
    final dueDays = pregnancy.dueDate != null
        ? pregnancy.dueDate!.difference(DateTime.now()).inDays
        : null;

    return SingleChildScrollView(
      padding: ResponsiveConfig.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressCard(pregnancy: pregnancy, daysUntilDue: dueDays),
          ResponsiveConfig.heightBox(16),
          if (currentMilestone != null)
            _MilestoneCard(milestone: currentMilestone),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<KickEntry>>(
            stream: kickStream,
            builder: (context, snapshot) {
              return _KickSummaryCard(
                  entries: snapshot.data ?? [],
                  onSchedule: onScheduleKickReminder);
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<PregnancyAppointment>>(
            stream: appointmentStream,
            builder: (context, snapshot) {
              return _UpcomingAppointmentsCard(
                  appointments: snapshot.data ?? []);
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<PregnancyMedication>>(
            stream: medicationStream,
            builder: (context, snapshot) {
              return _MedicationReminderCard(medications: snapshot.data ?? []);
            },
          ),
          ResponsiveConfig.heightBox(16),
          const _DailyTipsCard(),
          ResponsiveConfig.heightBox(16),
          const _PartnerModeCard(),
          ResponsiveConfig.heightBox(16),
          const _BabyNameCard(),
          ResponsiveConfig.heightBox(16),
          const _NutritionPlannerCard(),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.pregnancy, required this.daysUntilDue});

  final Pregnancy pregnancy;
  final int? daysUntilDue;

  @override
  Widget build(BuildContext context) {
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
                  'Week ${pregnancy.currentWeek} · Day ${pregnancy.currentDay}',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text('Trimester ${pregnancy.trimester}'),
                  backgroundColor: AppTheme.primaryPink.withOpacity(0.15),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(12),
            LinearProgressIndicator(
              value: pregnancy.progressPercentage / 100,
              backgroundColor: AppTheme.palePink,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryPink,
              ),
              minHeight: 10,
            ),
            ResponsiveConfig.heightBox(12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Due date'),
                    Text(
                      pregnancy.dueDate != null
                          ? DateFormat('EEE, MMM d').format(pregnancy.dueDate!)
                          : 'Not set',
                      style: ResponsiveConfig.textStyle(
                        size: 16,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (daysUntilDue != null && daysUntilDue! >= 0)
                  Container(
                    padding:
                        ResponsiveConfig.padding(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPink,
                      borderRadius: ResponsiveConfig.borderRadius(12),
                    ),
                    child: Text(
                      '$daysUntilDue days to go',
                      style: ResponsiveConfig.textStyle(
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.milestone});

  final PregnancyMilestone milestone;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.lightPink,
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
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              milestone.description,
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
}

class _KickSummaryCard extends StatelessWidget {
  const _KickSummaryCard({required this.entries, required this.onSchedule});

  final List<KickEntry> entries;
  final VoidCallback onSchedule;

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
                    gridData: FlGridData(show: false),
                    barGroups: entries
                        .take(7)
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
                                borderRadius: BorderRadius.circular(4),
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

class _UpcomingAppointmentsCard extends StatelessWidget {
  const _UpcomingAppointmentsCard({required this.appointments});

  final List<PregnancyAppointment> appointments;

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
            Text(
              'Next appointments',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            if (upcoming.isEmpty)
              Text(
                'No upcoming appointments logged. Add your prenatal visits to stay organized.',
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

class _MedicationReminderCard extends StatelessWidget {
  const _MedicationReminderCard({required this.medications});

  final List<PregnancyMedication> medications;

  @override
  Widget build(BuildContext context) {
    final active = medications.where((med) => med.isActive).toList();
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medications & supplements',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            if (active.isEmpty)
              Text(
                'Log prenatal vitamins or prescriptions to receive reminders.',
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

class _DailyTipsCard extends StatelessWidget {
  const _DailyTipsCard();

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

class _PartnerModeCard extends StatelessWidget {
  const _PartnerModeCard();

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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Partner dashboard link copied (demo).'),
                  ),
                );
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

class _BabyNameCard extends StatelessWidget {
  const _BabyNameCard();

  @override
  Widget build(BuildContext context) {
    final names = [
      const BabyName(name: 'Amaia', gender: 'girl', meaning: 'night rain'),
      const BabyName(
          name: 'Sena', gender: 'girl', meaning: 'bringing heaven to earth'),
      const BabyName(name: 'Kwesi', gender: 'boy', meaning: 'born on Sunday'),
      const BabyName(name: 'Imani', gender: 'unisex', meaning: 'faith'),
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

class _NutritionPlannerCard extends StatelessWidget {
  const _NutritionPlannerCard();

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
  });

  final Pregnancy pregnancy;
  final Stream<List<PregnancyJournalEntry>> journalStream;
  final Stream<List<PregnancyWeightEntry>> weightStream;
  final VoidCallback onLogJournal;
  final VoidCallback onLogWeight;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _JournalHeader(pregnancy: pregnancy, onLogJournal: onLogJournal),
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
                  actionLabel: 'Log journal',
                  onAction: onLogJournal,
                );
              }
              return Column(
                children: entries.take(10).map(_JournalEntryTile.new).toList(),
              );
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<PregnancyWeightEntry>>(
            stream: weightStream,
            builder: (context, snapshot) {
              return _WeightTrendCard(
                  entries: snapshot.data ?? [], onLogWeight: onLogWeight);
            },
          ),
        ],
      ),
    );
  }
}

class _JournalHeader extends StatelessWidget {
  const _JournalHeader({required this.pregnancy, required this.onLogJournal});

  final Pregnancy pregnancy;
  final VoidCallback onLogJournal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
  const _WeightTrendCard({required this.entries, required this.onLogWeight});

  final List<PregnancyWeightEntry> entries;
  final VoidCallback onLogWeight;

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
                    gridData: FlGridData(show: false),
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
                        isCurved: true,
                        color: AppTheme.primaryPink,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
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
  });

  final Pregnancy pregnancy;
  final Stream<List<PregnancyAppointment>> appointmentStream;
  final Stream<List<PregnancyMedication>> medicationStream;
  final Stream<List<HospitalChecklistItem>> checklistStream;
  final VoidCallback onAddAppointment;
  final VoidCallback onAddMedication;
  final VoidCallback onAddChecklist;

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
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<PregnancyAppointment>>(
            stream: appointmentStream,
            builder: (context, snapshot) {
              return _AppointmentListCard(
                appointments: snapshot.data ?? [],
                emptyAction: onAddAppointment,
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
  });

  final Pregnancy pregnancy;
  final VoidCallback onAddAppointment;
  final VoidCallback onAddMedication;

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
            ResponsiveConfig.heightBox(12),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: onAddAppointment,
                  icon: const Icon(Icons.event_note_outlined),
                  label: const Text('New appointment'),
                ),
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
  });

  final List<PregnancyAppointment> appointments;
  final VoidCallback emptyAction;

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return _EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'No appointments yet',
        message:
            'Schedule prenatal check-ups and classes so the app can remind you.',
        actionLabel: 'Add appointment',
        onAction: emptyAction,
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
  });

  final List<PregnancyMedication> medications;
  final VoidCallback onAddMedication;

  @override
  Widget build(BuildContext context) {
    if (medications.isEmpty) {
      return _EmptyState(
        icon: Icons.medical_services_outlined,
        title: 'No medications tracked',
        message: 'Add prenatal vitamins or prescriptions to receive reminders.',
        actionLabel: 'Add medication',
        onAction: onAddMedication,
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
  const _HospitalChecklistCard({required this.items, required this.onAdd});

  final List<HospitalChecklistItem> items;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(
        icon: Icons.luggage_outlined,
        title: 'Hospital bag checklist',
        message: 'Create your hospital bag checklist so nothing is forgotten.',
        actionLabel: 'Add item',
        onAction: onAdd,
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
  });

  final Pregnancy pregnancy;
  final Stream<List<KickEntry>> kickStream;
  final Stream<List<ContractionEntry>> contractionStream;
  final Stream<List<PregnancyWeightEntry>> weightStream;
  final Stream<List<PregnancyJournalEntry>> journalStream;
  final VoidCallback onLogKick;
  final VoidCallback onLogContraction;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InsightsHeader(
              onLogKick: onLogKick, onLogContraction: onLogContraction),
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
          const _AIPregnancyAssistantCard(),
          ResponsiveConfig.heightBox(16),
          const _BirthPrepResourcesCard(),
        ],
      ),
    );
  }
}

class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader(
      {required this.onLogKick, required this.onLogContraction});

  final VoidCallback onLogKick;
  final VoidCallback onLogContraction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  style: ResponsiveConfig.textStyle(
                    size: 14,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
            Column(
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
      return _EmptyState(
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
              height: 200,
              child: LineChart(
                LineChartData(
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
                      isCurved: true,
                      color: AppTheme.primaryPink,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                  gridData: FlGridData(show: false),
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
      return _EmptyState(
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
      return _EmptyState(
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
      return _EmptyState(
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
  const _AIPregnancyAssistantCard();

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
            Text(
              'Chat with FemCare+ AI (beta) to interpret logs, plan prenatal visits, and get mindful prompts tailored to you.',
            ),
            ResponsiveConfig.heightBox(12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Open AI assistant'),
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
