import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logger/web.dart';

import '../../../core/config/responsive_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/skincare_model.dart';
import '../../../data/models/wellness_model.dart';
import '../../../services/reminder_service.dart';
import '../../../services/skincare_service.dart';
import '../reminders/create_reminder_dialog.dart';
import 'skincare_product_management_screen.dart' show ProductInventoryView;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../services/ads_service.dart';

class SkincareTrackingScreen extends ConsumerStatefulWidget {
  const SkincareTrackingScreen({super.key});

  @override
  ConsumerState<SkincareTrackingScreen> createState() =>
      _SkincareTrackingScreenState();
}

class _SkincareTrackingScreenState extends ConsumerState<SkincareTrackingScreen>
    with TickerProviderStateMixin {
  final _skincareService = SkincareService();
  late final SkincareEnhancedService _enhancedService;
  final _reminderService = ReminderService();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _enhancedService = SkincareEnhancedService(FirebaseFirestore.instance);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final journalStream = _enhancedService.getSkinJournalEntries(user.userId);
    final acneStream = _enhancedService.getAcneEntries(user.userId);
    final uvStream = _enhancedService.getUVIndexEntries(user.userId);
    final goalStream = _enhancedService.getSkinGoals(user.userId);
    final productStream = _skincareService.getUserProducts(user.userId);
    final routineTemplateStream =
        _enhancedService.getRoutineTemplates(user.userId);
    final hydrationStream = FirebaseFirestore.instance
        .collection(AppConstants.collectionWellnessEntries)
        .where('userId', isEqualTo: user.userId)
        .orderBy('date', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WellnessModel.fromFirestore(doc))
              .toList(),
        );

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SkinCare+ Hub'),
          actions: [
            _buildAppBarAction(user.userId),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: _buildModernTabSwitcher(context),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(
              userId: user.userId,
              enhancedService: _enhancedService,
              skinTypeStream: _enhancedService.watchSkinType(user.userId),
              productStream: productStream,
              acneStream: acneStream,
              uvStream: uvStream,
              goalStream: goalStream,
              journalStream: journalStream,
              hydrationStream: hydrationStream,
              reminderService: _reminderService,
              onAddGoal: () => _showGoalSheet(context, user.userId),
              onAddProduct: () => context.push('/skincare-product-form'),
              onManageProducts: () =>
                  _openProductManager(context, view: ProductInventoryView.all),
              onOpenProductCategory: (view) =>
                  _openProductManager(context, view: view),
              onLogHydration: () => context.push('/wellness-journal'),
              onViewHydrationLogs: () => context.push('/wellness-journal-list'),
              onAnalyzeSkin: () => _showRewardedAnalysis(context),
              onLogAcne: () => _showAcneSheet(context, user.userId),
              onLogUV: () => _showUVSheet(context, user.userId),
            ),
            _JournalTab(
              userId: user.userId,
              journalStream: journalStream,
              onLogJournal: () => _showJournalSheet(context, user.userId),
            ),
            _RoutineTab(
              userId: user.userId,
              routineEntriesStream: _skincareService.getEntries(
                user.userId,
                DateTime.now().subtract(const Duration(days: 60)),
                DateTime.now().add(const Duration(days: 30)),
              ),
              routineTemplatesStream: routineTemplateStream,
              onCreateTemplate: () =>
                  _showRoutineTemplateSheet(context, user.userId),
              onIngredientSearch: () => _showIngredientSearchSheet(context),
              onScheduleReminder: () => _scheduleRoutineReminder(user.userId),
            ),
            _InsightsTab(
              userId: user.userId,
              journalStream: journalStream,
              acneStream: acneStream,
              uvStream: uvStream,
              hydrationStream: hydrationStream,
              routineEntriesStream: _skincareService.getEntries(
                user.userId,
                DateTime.now().subtract(const Duration(days: 90)),
                DateTime.now(),
              ),
              onIngredientSearch: () => _showIngredientSearchSheet(context),
            ),
          ],
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
        Tab(text: 'Overview', icon: FaIcon(FontAwesomeIcons.chartPie)),
        Tab(text: 'Journal', icon: FaIcon(FontAwesomeIcons.bookOpen)),
        Tab(text: 'Routines', icon: FaIcon(FontAwesomeIcons.wandMagicSparkles)),
        Tab(text: 'Insights', icon: FaIcon(FontAwesomeIcons.chartLine)),
      ],
    );
  }

  Widget _buildAppBarAction(String userId) {
    switch (_tabController.index) {
      case 0:
        return IconButton(
          icon: const FaIcon(FontAwesomeIcons.circlePlus),
          tooltip: 'Quick Actions',
          onPressed: () => _showQuickActionsSheet(context, userId),
        );
      case 1:
        return IconButton(
          icon: const FaIcon(FontAwesomeIcons.penToSquare),
          tooltip: 'Log Journal',
          onPressed: () => _showJournalSheet(context, userId),
        );
      case 2:
        return IconButton(
          icon: const FaIcon(FontAwesomeIcons.wandMagicSparkles),
          tooltip: 'New Routine',
          onPressed: () => _showRoutineTemplateSheet(context, userId),
        );
      case 3:
        return IconButton(
          icon: const FaIcon(FontAwesomeIcons.listCheck),
          tooltip: 'Quick Actions',
          onPressed: () => _showQuickActionsSheet(context, userId),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showRewardedAnalysis(BuildContext context) {
    AdsService().showRewardedAd(
      onUserEarnedReward: (reward) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Reward earned: ${reward.amount} ${reward.type}! Unlocking analysis...')),
        );
        // Logic to trigger analysis could go here
      },
    );
  }

  Future<void> _scheduleHydrationReminder(String userId) async {
    final result = await showDialog(
      context: context,
      builder: (context) => CreateReminderDialog(
        userId: userId,
        defaultType: 'hydration',
        defaultTitle: 'Hydration Reminder',
        defaultDescription: 'Drink water to keep your skin plump and healthy!',
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hydration reminder scheduled.')),
      );
    }
  }

  void _openProductManager(BuildContext context,
      {ProductInventoryView view = ProductInventoryView.all}) {
    context.push('/skincare/products', extra: view);
  }

  Future<void> _scheduleRoutineReminder(String userId) async {
    final result = await showDialog(
      context: context,
      builder: (context) => CreateReminderDialog(
        userId: userId,
        defaultType: 'skincare_routine',
        defaultTitle: 'Skincare Routine',
        defaultDescription: 'Time for your FemCare+ routine.',
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine reminder scheduled.')),
      );
    }
  }

  Future<void> _showSkinTypeSheet(BuildContext context, String userId) async {
    final concernsController = TextEditingController();
    final notesController = TextEditingController();

    double dry = 5;
    double oily = 5;
    double combo = 5;
    double sensitive = 5;
    String primaryType = 'combination';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skin Type Analyzer',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveConfig.heightBox(38),
                    DropdownButtonFormField<String>(
                      value: primaryType,
                      decoration:
                          const InputDecoration(labelText: 'Primary skin type'),
                      items: const [
                        DropdownMenuItem(
                            value: 'normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'dry', child: Text('Dry')),
                        DropdownMenuItem(value: 'oily', child: Text('Oily')),
                        DropdownMenuItem(
                            value: 'combination', child: Text('Combination')),
                        DropdownMenuItem(
                            value: 'sensitive', child: Text('Sensitive')),
                      ],
                      onChanged: (value) =>
                          setState(() => primaryType = value ?? 'combination'),
                    ),
                    ResponsiveConfig.heightBox(12),
                    _SliderInput(
                      label: 'Dry score',
                      initialValue: dry,
                      onChanged: (value) => setState(() => dry = value),
                    ),
                    _SliderInput(
                      label: 'Oily score',
                      initialValue: oily,
                      onChanged: (value) => setState(() => oily = value),
                    ),
                    _SliderInput(
                      label: 'Combination score',
                      initialValue: combo,
                      onChanged: (value) => setState(() => combo = value),
                    ),
                    _SliderInput(
                      label: 'Sensitive score',
                      initialValue: sensitive,
                      onChanged: (value) => setState(() => sensitive = value),
                    ),
                    TextField(
                      controller: concernsController,
                      decoration: const InputDecoration(
                        labelText: 'Key concerns (comma separated)',
                      ),
                    ),
                    ResponsiveConfig.heightBox(12),
                    TextField(
                      controller: notesController,
                      decoration:
                          const InputDecoration(labelText: 'Analysis notes'),
                      maxLines: 2,
                    ),
                    ResponsiveConfig.heightBox(20),
                    ElevatedButton(
                      onPressed: () async {
                        final skinType = SkinType(
                          userId: userId,
                          primaryType: primaryType,
                          typeScores: {
                            'dry': dry,
                            'oily': oily,
                            'combination': combo,
                            'sensitive': sensitive,
                          },
                          concerns: concernsController.text.trim().isEmpty
                              ? null
                              : concernsController.text.trim(),
                          analysisNotes: notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                          analyzedAt: DateTime.now(),
                        );
                        await _enhancedService.saveSkinType(skinType);
                        if (mounted) Navigator.of(context).pop();
                      },
                      child: const Text('Save skin profile'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showJournalSheet(BuildContext context, String userId) async {
    final formKey = GlobalKey<FormState>();
    final notesController = TextEditingController();
    final concernsController = TextEditingController();
    final sleepController = TextEditingController();
    double hydration = 5;
    double oiliness = 5;
    String? condition;
    DateTime selectedDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New journal entry',
                    style: ResponsiveConfig.textStyle(
                      size: 18,
                      weight: FontWeight.bold,
                    ),
                  ),
                  ResponsiveConfig.heightBox(38),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const FaIcon(FontAwesomeIcons.calendarDays),
                    title:
                        Text(DateFormat('EEEE, MMM d, y').format(selectedDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        selectedDate = picked;
                        setState(() {});
                      }
                    },
                  ),
                  ResponsiveConfig.heightBox(12),
                  DropdownButtonFormField<String>(
                    value: condition,
                    decoration: const InputDecoration(labelText: 'Skin feel'),
                    items: const [
                      DropdownMenuItem(
                          value: 'balanced', child: Text('Balanced')),
                      DropdownMenuItem(value: 'dry', child: Text('Dry')),
                      DropdownMenuItem(value: 'oily', child: Text('Oily')),
                      DropdownMenuItem(
                          value: 'sensitive', child: Text('Sensitive/Red')),
                    ],
                    onChanged: (value) => condition = value,
                  ),
                  ResponsiveConfig.heightBox(12),
                  _SliderInput(
                    label: 'Hydration level',
                    initialValue: hydration,
                    onChanged: (value) => hydration = value,
                  ),
                  ResponsiveConfig.heightBox(12),
                  _SliderInput(
                    label: 'Oiliness level',
                    initialValue: oiliness,
                    onChanged: (value) => oiliness = value,
                  ),
                  ResponsiveConfig.heightBox(12),
                  TextField(
                    controller: sleepController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sleep hours'),
                  ),
                  ResponsiveConfig.heightBox(12),
                  TextField(
                    controller: concernsController,
                    decoration: const InputDecoration(
                      labelText: 'Concerns (comma separated)',
                    ),
                  ),
                  ResponsiveConfig.heightBox(12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 3,
                  ),
                  ResponsiveConfig.heightBox(20),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final entry = SkinJournalEntry(
                        userId: userId,
                        date: selectedDate,
                        skinCondition: condition,
                        hydrationLevel: hydration.round(),
                        oilinessLevel: oiliness.round(),
                        concerns: concernsController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        sleepHours: sleepController.text.trim().isEmpty
                            ? null
                            : int.tryParse(sleepController.text.trim()),
                        createdAt: DateTime.now(),
                      );
                      await _enhancedService.logSkinJournal(entry);
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Save entry'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRoutineTemplateSheet(
    BuildContext context,
    String userId,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final skinTypeController = TextEditingController();
    final concernsController = TextEditingController();
    final productsController = TextEditingController();
    final notesController = TextEditingController();
    String routineType = 'morning';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create routine template',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveConfig.heightBox(38),
                    TextFormField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Routine name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Required'
                              : null,
                    ),
                    ResponsiveConfig.heightBox(12),
                    DropdownButtonFormField<String>(
                      value: routineType,
                      decoration:
                          const InputDecoration(labelText: 'Routine time'),
                      items: const [
                        DropdownMenuItem(
                            value: 'morning', child: Text('Morning')),
                        DropdownMenuItem(
                            value: 'evening', child: Text('Evening')),
                        DropdownMenuItem(
                            value: 'weekly', child: Text('Weekly treatment')),
                      ],
                      onChanged: (value) => routineType = value ?? 'morning',
                    ),
                    ResponsiveConfig.heightBox(12),
                    TextFormField(
                      controller: skinTypeController,
                      decoration:
                          const InputDecoration(labelText: 'Target skin type'),
                    ),
                    ResponsiveConfig.heightBox(12),
                    TextField(
                      controller: concernsController,
                      decoration: const InputDecoration(
                        labelText: 'Target concerns (comma separated)',
                      ),
                    ),
                    ResponsiveConfig.heightBox(12),
                    TextField(
                      controller: productsController,
                      decoration: const InputDecoration(
                        labelText: 'Product IDs or names (comma separated)',
                      ),
                    ),
                    ResponsiveConfig.heightBox(12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      maxLines: 2,
                    ),
                    ResponsiveConfig.heightBox(20),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final template = RoutineTemplate(
                          userId: userId,
                          name: nameController.text.trim(),
                          skinType: skinTypeController.text.trim().isEmpty
                              ? 'all'
                              : skinTypeController.text.trim(),
                          concerns: concernsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList(),
                          routineType: routineType,
                          productIds: productsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList(),
                          notes: notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                          createdAt: DateTime.now(),
                        );
                        await _enhancedService.saveRoutineTemplate(template);
                        if (mounted) Navigator.of(context).pop();
                      },
                      child: const Text('Save routine'),
                    ),
                  ],
                ),
              ),
            ));
      },
    );
  }

  Future<void> _showQuickActionsSheet(
    BuildContext context,
    String userId,
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
                  leading: const FaIcon(FontAwesomeIcons.magnifyingGlassChart),
                  title: const Text('Analyze Skin Type'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showSkinTypeSheet(context, userId);
                  },
                ),
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.cartPlus),
                  title: const Text('Add Product'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/skincare-product-form');
                  },
                ),
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.wandMagicSparkles),
                  title: const Text('Create Routine'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showRoutineTemplateSheet(context, userId);
                  },
                ),
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.faceSadTear),
                  title: const Text('Log Acne Breakout'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAcneSheet(context, userId);
                  },
                ),
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.solidSun),
                  title: const Text('Log UV Index'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showUVSheet(context, userId);
                  },
                ),
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.flag),
                  title: const Text('Add Skin Goal'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showGoalSheet(context, userId);
                  },
                ),
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.glassWaterDroplet),
                  title: const Text('Schedule Hydration Reminder'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _scheduleHydrationReminder(userId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showIngredientSearchSheet(BuildContext context) async {
    final searchController = TextEditingController();
    String query = '';
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              Future<void> performSearch(String value) async {
                setState(() {
                  loading = true;
                });

                // Simulate an async search (replace with your actual search logic)
                await Future.delayed(const Duration(seconds: 2));

                setState(() {
                  query = value.trim();
                  loading = false;
                });
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Ingredients Dictionary",
                    style: ResponsiveConfig.textStyle(
                        size: 25, weight: FontWeight.w900),
                  ),
                  ResponsiveConfig.heightBox(24),
                  TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search ingredient',
                        suffixIcon: IconButton(
                          icon: const FaIcon(FontAwesomeIcons.magnifyingGlass),
                          onPressed: () => loading
                              ? null
                              : performSearch(searchController.text.trim()),
                        ),
                      ),
                      onSubmitted: (value) =>
                          loading ? null : performSearch(value.trim())),
                  ResponsiveConfig.heightBox(16),
                  SizedBox(
                    height: ResponsiveConfig.screenHeight * 0.55,
                    child: FutureBuilder<String>(
                      future: _enhancedService.getAIIngredients(ref, query),
                      builder: (context, snapshot) {
                        final ingredients = snapshot.data;
                        Logger().t(ingredients);
                        setState(() {
                          loading = false;
                        });

                        if (ingredients == null) {
                          return Text(query.isEmpty
                              ? 'Enter an ingredient name to see details.'
                              : 'No ingredient found for "$query".');
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          // Show loading spinner while waiting
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          // Show error message if something went wrong
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        return SingleChildScrollView(
                          child: MarkdownBody(data: ingredients),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showAcneSheet(BuildContext context, String userId) async {
    final formKey = GlobalKey<FormState>();
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    final treatmentController = TextEditingController();
    String type = 'papule';
    double severity = 3;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Log breakout',
                    style: ResponsiveConfig.textStyle(
                      size: 18,
                      weight: FontWeight.bold,
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'papule', child: Text('Papule')),
                      DropdownMenuItem(
                          value: 'pustule', child: Text('Pustule')),
                      DropdownMenuItem(value: 'cyst', child: Text('Cyst')),
                      DropdownMenuItem(
                          value: 'whitehead', child: Text('Whitehead')),
                      DropdownMenuItem(
                          value: 'blackhead', child: Text('Blackhead')),
                    ],
                    onChanged: (value) => type = value ?? 'papule',
                  ),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  Slider(
                    value: severity,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: 'Severity ${severity.round()}',
                    onChanged: (value) => setState(() => severity = value),
                  ),
                  TextField(
                    controller: treatmentController,
                    decoration: const InputDecoration(
                      labelText: 'Treatment used (optional)',
                    ),
                  ),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 2,
                  ),
                  ResponsiveConfig.heightBox(20),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final entry = AcneEntry(
                        userId: userId,
                        date: DateTime.now(),
                        location: locationController.text.trim(),
                        type: type,
                        severity: severity.round(),
                        treatmentUsed: treatmentController.text.trim().isEmpty
                            ? null
                            : treatmentController.text.trim(),
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      await _enhancedService.logAcneEntry(entry);
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Save breakout'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showUVSheet(BuildContext context, String userId) async {
    final formKey = GlobalKey<FormState>();
    final indexController = TextEditingController();
    final notesController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Log UV index',
                    style: ResponsiveConfig.textStyle(
                      size: 18,
                      weight: FontWeight.bold,
                    ),
                  ),
                  TextFormField(
                    controller: indexController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'UV index (0-12)'),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null) return 'Enter a number';
                      if (parsed < 0 || parsed > 12) {
                        return 'UV index must be 0-12';
                      }
                      return null;
                    },
                  ),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                        labelText: 'Protection used (optional)'),
                  ),
                  ResponsiveConfig.heightBox(20),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final entry = UVIndexEntry(
                        userId: userId,
                        date: DateTime.now(),
                        uvIndex: int.parse(indexController.text.trim()),
                        protectionUsed: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      await _enhancedService.logUVIndex(entry);
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Save UV log'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showGoalSheet(BuildContext context, String userId) async {
    final formKey = GlobalKey<FormState>();
    final goalController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime targetDate = DateTime.now().add(const Duration(days: 30));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add skin goal',
                    style: ResponsiveConfig.textStyle(
                      size: 18,
                      weight: FontWeight.bold,
                    ),
                  ),
                  TextFormField(
                    controller: goalController,
                    decoration: const InputDecoration(labelText: 'Goal'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                        labelText: 'Description (optional)'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const FaIcon(FontAwesomeIcons.calendarDays),
                    title: Text(DateFormat('MMM d, y').format(targetDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: targetDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        targetDate = picked;
                        setState(() {});
                      }
                    },
                  ),
                  ResponsiveConfig.heightBox(20),
                  ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final goal = SkinGoal(
                        userId: userId,
                        goal: goalController.text.trim(),
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        targetDate: targetDate,
                        createdAt: DateTime.now(),
                      );
                      await _enhancedService.createSkinGoal(goal);
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Save goal'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------- Overview Tab Widget ----------

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.userId,
    required this.enhancedService,
    required this.skinTypeStream,
    required this.productStream,
    required this.acneStream,
    required this.uvStream,
    required this.goalStream,
    required this.journalStream,
    required this.hydrationStream,
    required this.reminderService,
    required this.onAnalyzeSkin,
    required this.onLogAcne,
    required this.onLogUV,
    required this.onAddGoal,
    required this.onAddProduct,
    required this.onManageProducts,
    required this.onOpenProductCategory,
    required this.onLogHydration,
    required this.onViewHydrationLogs,
  });

  final String userId;
  final SkincareEnhancedService enhancedService;
  final Stream<SkinType?> skinTypeStream;
  final Stream<List<SkincareProduct>> productStream;
  final Stream<List<AcneEntry>> acneStream;
  final Stream<List<UVIndexEntry>> uvStream;
  final Stream<List<SkinGoal>> goalStream;
  final Stream<List<SkinJournalEntry>> journalStream;
  final Stream<List<WellnessModel>> hydrationStream;
  final ReminderService reminderService;
  final VoidCallback onAnalyzeSkin;
  final VoidCallback onLogAcne;
  final VoidCallback onLogUV;
  final VoidCallback onAddGoal;
  final VoidCallback onAddProduct;
  final VoidCallback onManageProducts;
  final void Function(ProductInventoryView view) onOpenProductCategory;
  final VoidCallback onLogHydration;
  final VoidCallback onViewHydrationLogs;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StreamBuilder<SkinType?>(
            stream: skinTypeStream,
            builder: (context, snapshot) {
              return _SkinTypeCard(
                skinType: snapshot.data,
                onAnalyze: onAnalyzeSkin,
              );
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<WellnessModel>>(
            stream: hydrationStream,
            builder: (context, hydrationSnapshot) {
              return StreamBuilder<List<SkinJournalEntry>>(
                stream: journalStream,
                builder: (context, journalSnapshot) {
                  final hydrationLogs = _mergeHydrationLogs(
                    hydrationSnapshot.data ?? [],
                    journalSnapshot.data ?? [],
                  );
                  final isLoading = (hydrationSnapshot.connectionState ==
                              ConnectionState.waiting ||
                          journalSnapshot.connectionState ==
                              ConnectionState.waiting) &&
                      hydrationLogs.isEmpty;
                  return _HydrationCard(
                    hydrationLogs: hydrationLogs,
                    isLoading: isLoading,
                    onSchedule: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (context) => CreateReminderDialog(
                          userId: userId,
                          defaultType: 'hydration',
                          defaultTitle: 'Hydration Reminder',
                          defaultDescription: 'Sip water to keep skin plump!',
                        ),
                      );

                      if (result == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hydration reminder scheduled.'),
                          ),
                        );
                      }
                    },
                    onLogHydration: onLogHydration,
                    onViewHydrationLogs: onViewHydrationLogs,
                  );
                },
              );
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<SkincareProduct>>(
            stream: productStream,
            builder: (context, snapshot) {
              return _InventoryCard(
                products: snapshot.data ?? [],
                onAddProduct: onAddProduct,
                onManageProducts: onManageProducts,
                onOpenCategory: onOpenProductCategory,
              );
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<AcneEntry>>(
            stream: acneStream,
            builder: (context, snapshot) {
              return _AcneCard(
                entries: snapshot.data ?? [],
                onLogAcne: onLogAcne,
              );
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<UVIndexEntry>>(
            stream: uvStream,
            builder: (context, snapshot) {
              return _UVOverviewCard(
                entries: snapshot.data ?? [],
                onLogUV: onLogUV,
              );
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<SkinGoal>>(
            stream: goalStream,
            builder: (context, snapshot) {
              return _GoalCard(
                goals: snapshot.data ?? [],
                onAddGoal: onAddGoal,
              );
            },
          ),
          ResponsiveConfig.heightBox(16),
          const _BeautyTipsCard(),
          ResponsiveConfig.heightBox(16),
          const _CommunityCard(),
        ],
      ),
    );
  }
}

// ---------- Journal Tab Widget ----------

class _JournalTab extends StatelessWidget {
  const _JournalTab({
    required this.userId,
    required this.journalStream,
    required this.onLogJournal,
  });

  final String userId;
  final Stream<List<SkinJournalEntry>> journalStream;
  final VoidCallback onLogJournal;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SkinJournalEntry>>(
      stream: journalStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return _EmptyState(
            icon: Icons.book_outlined,
            title: 'No journal entries yet',
            message:
                'Log how your skin feels, hydration, sleep, and notes to begin.',
            actionLabel: 'Log journal',
            onAction: onLogJournal,
          );
        }

        return ListView.builder(
          padding: ResponsiveConfig.padding(all: 16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Card(
              margin: ResponsiveConfig.margin(bottom: 12),
              child: Padding(
                padding: ResponsiveConfig.padding(all: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d, y').format(entry.date),
                          style: ResponsiveConfig.textStyle(
                            size: 16,
                            weight: FontWeight.bold,
                          ),
                        ),
                        if (entry.skinCondition != null)
                          Chip(
                            label: Text(
                              entry.skinCondition!,
                              style: ResponsiveConfig.textStyle(
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: AppTheme.primaryPink,
                          ),
                      ],
                    ),
                    ResponsiveConfig.heightBox(8),
                    Text(
                      'Hydration: ${entry.hydrationLevel ?? '-'} • Oiliness: ${entry.oilinessLevel ?? '-'}',
                    ),
                    if (entry.sleepHours != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                            'Sleep: ${entry.sleepHours} h • Stress: ${entry.stressLevel ?? 'N/A'}'),
                      ),
                    if (entry.concerns.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Concerns: ${entry.concerns.join(', ')}'),
                      ),
                    if (entry.notes != null && entry.notes!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(entry.notes!),
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

// ---------- Routine Tab Widget ----------

class _RoutineTab extends StatelessWidget {
  const _RoutineTab({
    required this.userId,
    required this.routineEntriesStream,
    required this.routineTemplatesStream,
    required this.onCreateTemplate,
    required this.onIngredientSearch,
    required this.onScheduleReminder,
  });

  final String userId;
  final Stream<List<SkincareEntry>> routineEntriesStream;
  final Stream<List<RoutineTemplate>> routineTemplatesStream;
  final VoidCallback onCreateTemplate;
  final VoidCallback onIngredientSearch;
  final VoidCallback onScheduleReminder;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RoutineReminderCard(onSchedule: onScheduleReminder),
          ResponsiveConfig.heightBox(16),
          _IngredientScannerCard(onSearch: onIngredientSearch),
          ResponsiveConfig.heightBox(16),
          const _ClimateAdjusterCard(),
          ResponsiveConfig.heightBox(16),
          const _DermatologistCard(),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<RoutineTemplate>>(
            stream: routineTemplatesStream,
            builder: (context, snapshot) {
              final templates = snapshot.data ?? [];
              if (templates.isEmpty) {
                return _EmptyState(
                  icon: Icons.auto_fix_high_outlined,
                  title: 'No saved templates',
                  message:
                      'Build personalized routines for different skin goals.',
                  actionLabel: 'Create template',
                  onAction: onCreateTemplate,
                );
              }
              return Column(
                children: templates.map(_RoutineTemplateCard.new).toList(),
              );
            },
          ),
          ResponsiveConfig.heightBox(16),
          StreamBuilder<List<SkincareEntry>>(
            stream: routineEntriesStream,
            builder: (context, snapshot) {
              final entries = snapshot.data ?? [];
              if (entries.isEmpty) {
                return const SizedBox.shrink();
              }
              return _RoutineHistoryCard(entries: entries);
            },
          ),
        ],
      ),
    );
  }
}

// ---------- Insights Tab Widget ----------

class _InsightsTab extends StatelessWidget {
  const _InsightsTab({
    required this.userId,
    required this.journalStream,
    required this.acneStream,
    required this.uvStream,
    required this.hydrationStream,
    required this.routineEntriesStream,
    required this.onIngredientSearch,
  });

  final String userId;
  final Stream<List<SkinJournalEntry>> journalStream;
  final Stream<List<AcneEntry>> acneStream;
  final Stream<List<UVIndexEntry>> uvStream;
  final Stream<List<WellnessModel>> hydrationStream;
  final Stream<List<SkincareEntry>> routineEntriesStream;
  final VoidCallback onIngredientSearch;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SkinJournalEntry>>(
      stream: journalStream,
      builder: (context, journalSnapshot) {
        final journals = journalSnapshot.data ?? [];
        return StreamBuilder<List<AcneEntry>>(
          stream: acneStream,
          builder: (context, acneSnapshot) {
            final acneEntries = acneSnapshot.data ?? [];
            return StreamBuilder<List<UVIndexEntry>>(
              stream: uvStream,
              builder: (context, uvSnapshot) {
                final uvEntries = uvSnapshot.data ?? [];
                return StreamBuilder<List<SkincareEntry>>(
                  stream: routineEntriesStream,
                  builder: (context, routineSnapshot) {
                    final routines = routineSnapshot.data ?? [];
                    return SingleChildScrollView(
                      padding: ResponsiveConfig.padding(all: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HealthScoreCard(
                            journals: journals,
                            acneEntries: acneEntries,
                          ),
                          ResponsiveConfig.heightBox(16),
                          StreamBuilder<List<WellnessModel>>(
                            stream: hydrationStream,
                            builder: (context, hydrationSnapshot) {
                              final hydrationLogs = _mergeHydrationLogs(
                                hydrationSnapshot.data ?? [],
                                journals,
                              );
                              return _HydrationTrendChart(
                                hydrationLogs: hydrationLogs,
                                onInsightTapped: onIngredientSearch,
                              );
                            },
                          ),
                          ResponsiveConfig.heightBox(16),
                          _SleepWellnessCard(journals: journals),
                          ResponsiveConfig.heightBox(16),
                          _RecommendationCard(
                            journals: journals,
                            routines: routines,
                          ),
                          ResponsiveConfig.heightBox(16),
                          _IngredientDictionaryCard(
                              onSearch: onIngredientSearch),
                          ResponsiveConfig.heightBox(16),
                          const _AIDermatologistCard(),
                          ResponsiveConfig.heightBox(16),
                          const _ARPreviewCard(),
                          ResponsiveConfig.heightBox(16),
                          const _CommunityCard(),
                          ResponsiveConfig.heightBox(16),
                          if (uvEntries.isNotEmpty)
                            _UVAnalyticsCard(entries: uvEntries),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// ---------- Shared Widgets & Helpers ----------

class _SliderInput extends StatelessWidget {
  const _SliderInput({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  final String label;
  final double initialValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        double value = initialValue;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label),
                Text(value.toStringAsFixed(1)),
              ],
            ),
            Slider(
              value: value,
              min: 0,
              max: 10,
              divisions: 20,
              label: value.toStringAsFixed(1),
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

class _SkinTypeCard extends StatelessWidget {
  const _SkinTypeCard({
    required this.skinType,
    required this.onAnalyze,
  });

  final SkinType? skinType;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    if (skinType == null) {
      return Card(
        child: Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.science_outlined,
                      color: AppTheme.primaryPink),
                  ResponsiveConfig.widthBox(8),
                  Text(
                    'Skin Type Analyzer',
                    style: ResponsiveConfig.textStyle(
                      size: 18,
                      weight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ResponsiveConfig.heightBox(8),
              Text(
                'Analyze your skin type to unlock personalized routines, product recommendations and ingredient alerts.',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              ),
              ResponsiveConfig.heightBox(12),
              ElevatedButton(
                onPressed: onAnalyze,
                child: const Text('Analyze skin now'),
              ),
            ],
          ),
        ),
      );
    }

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
                  'Skin Type Profile',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    skinType!.primaryType.toUpperCase(),
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
            _TypeScoreBar(label: 'Dry', value: skinType!.typeScores['dry']),
            _TypeScoreBar(label: 'Oily', value: skinType!.typeScores['oily']),
            _TypeScoreBar(
                label: 'Combination',
                value: skinType!.typeScores['combination']),
            _TypeScoreBar(
                label: 'Sensitive', value: skinType!.typeScores['sensitive']),
            ResponsiveConfig.heightBox(12),
            Text(
              'Analyzed ${DateFormat('MMM d, y').format(skinType!.analyzedAt)}',
              style: ResponsiveConfig.textStyle(
                size: 12,
                color: AppTheme.mediumGray,
              ),
            ),
            if (skinType!.concerns != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Concerns: ${skinType!.concerns}'),
              ),
            if (skinType!.analysisNotes != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(skinType!.analysisNotes!),
              ),
            ResponsiveConfig.heightBox(12),
            OutlinedButton(
              onPressed: onAnalyze,
              child: const Text('Re-analyze skin'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeScoreBar extends StatelessWidget {
  const _TypeScoreBar({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final display = (value ?? 0).clamp(0, 10);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: display / 10,
              backgroundColor: AppTheme.primaryPink.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryPink,
              ),
              minHeight: 8,
            ),
          ),
          ResponsiveConfig.widthBox(8),
          Text(display.toStringAsFixed(1)),
        ],
      ),
    );
  }
}

class _HydrationCard extends StatelessWidget {
  const _HydrationCard({
    required this.hydrationLogs,
    required this.isLoading,
    required this.onSchedule,
    required this.onLogHydration,
    required this.onViewHydrationLogs,
  });

  final List<_HydrationLogEntry> hydrationLogs;
  final bool isLoading;
  final VoidCallback onSchedule;
  final VoidCallback onLogHydration;
  final VoidCallback onViewHydrationLogs;

  @override
  Widget build(BuildContext context) {
    final hasLogs = hydrationLogs.isNotEmpty;
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop_outlined,
                    color: AppTheme.primaryPink),
                ResponsiveConfig.widthBox(8),
                Text(
                  'Hydration Tracker',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Stay hydrated to keep your skin barrier happy. Log glasses to visualize progress.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (!hasLogs)
              const _HydrationEmptyState()
            else ...[
              ResponsiveConfig.heightBox(8),
              Column(
                children: hydrationLogs.take(3).map((entry) {
                  final date = DateFormat('MMM d').format(entry.date);
                  final glasses = entry.waterGlasses;
                  final goal = entry.goal;
                  final remaining = (goal - glasses).clamp(0, goal);
                  final metGoal = glasses >= goal;
                  final statusText = metGoal
                      ? 'Goal met'
                      : '$remaining glass${remaining == 1 ? '' : 'es'} to goal';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryPink.withOpacity(0.12),
                      child: Text(
                        glasses.toString(),
                        style: ResponsiveConfig.textStyle(
                          size: 14,
                          weight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('$date • $glasses / $goal glasses'),
                    subtitle: Text(
                      statusText,
                      style: ResponsiveConfig.textStyle(
                        size: 12,
                        color: metGoal
                            ? AppTheme.primaryPink
                            : AppTheme.mediumGray,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            ResponsiveConfig.heightBox(16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: onSchedule,
                  icon: const Icon(Icons.alarm_add_outlined),
                  label: const Text('Schedule reminder'),
                ),
                FilledButton.icon(
                  onPressed: onLogHydration,
                  icon: const Icon(Icons.water_drop_outlined),
                  label: const Text('Log hydration'),
                ),
                TextButton.icon(
                  onPressed: onViewHydrationLogs,
                  icon: const Icon(Icons.list_alt_outlined),
                  label: const Text('View logs'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.products,
    required this.onAddProduct,
    required this.onManageProducts,
    required this.onOpenCategory,
  });

  final List<SkincareProduct> products;
  final VoidCallback onAddProduct;
  final VoidCallback onManageProducts;
  final void Function(ProductInventoryView view) onOpenCategory;

  @override
  Widget build(BuildContext context) {
    final brands = products
        .where((p) => (p.brand ?? '').trim().isNotEmpty)
        .map((p) => p.brand!.trim().toLowerCase())
        .toSet()
        .length;
    final totalAmount = products.fold<double>(
      0.0,
      (sum, product) => sum + (product.price ?? 0.0),
    );
    final expiringSoon =
        products.where((p) => p.isExpiringSoon || p.isExpired).length;

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
                  'Product Inventory',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppTheme.primaryPink,
                  onPressed: onAddProduct,
                  tooltip: 'Add product',
                ),
              ],
            ),
            ResponsiveConfig.heightBox(12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InventoryStatTile(
                        icon: Icons.inventory_2_outlined,
                        label: 'Active products',
                        value: products.length.toString(),
                        onTap: () =>
                            onOpenCategory(ProductInventoryView.active),
                      ),
                    ),
                    ResponsiveConfig.widthBox(12),
                    Expanded(
                      child: _InventoryStatTile(
                        icon: Icons.local_offer_outlined,
                        label: 'Brands',
                        value: brands.toString(),
                        onTap: () =>
                            onOpenCategory(ProductInventoryView.brands),
                      ),
                    ),
                  ],
                ),
                ResponsiveConfig.heightBox(12),
                Row(
                  children: [
                    Expanded(
                      child: _InventoryStatTile(
                        icon: Icons.attach_money_outlined,
                        label: 'Total amount',
                        value: totalAmount == 0
                            ? '\$0'
                            : '\$${totalAmount.toStringAsFixed(2)}',
                        onTap: () =>
                            onOpenCategory(ProductInventoryView.totalValue),
                      ),
                    ),
                    ResponsiveConfig.widthBox(12),
                    Expanded(
                      child: _InventoryStatTile(
                        icon: Icons.alarm_on_outlined,
                        label: 'Expiring soon',
                        value: expiringSoon.toString(),
                        onTap: () =>
                            onOpenCategory(ProductInventoryView.expiringSoon),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ResponsiveConfig.heightBox(16),
            if (products.isEmpty)
              Text(
                'No products added yet. Track your cleansers, treatments and sunscreens to monitor expiry dates.',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              )
            else ...[
              Column(
                children: products.take(3).map((product) {
                  return _ProductPreviewTile(
                    product: product,
                    onManage: onManageProducts,
                  );
                }).toList(),
              ),
              if (products.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+ ${products.length - 3} more products in inventory',
                    style: ResponsiveConfig.textStyle(
                      size: 12,
                      color: AppTheme.mediumGray,
                    ),
                  ),
                ),
            ],
            ResponsiveConfig.heightBox(16),
            Row(
              children: [
                /* FilledButton.icon(
                  onPressed: onAddProduct,
                  icon: const Icon(Icons.add),
                  label: const Text('Add product'),
                ),
                ResponsiveConfig.widthBox(12),
                 */
                OutlinedButton.icon(
                  onPressed: onManageProducts,
                  icon: const Icon(Icons.manage_search_outlined),
                  label: const Text('Manage inventory'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPreviewTile extends StatelessWidget {
  const _ProductPreviewTile({
    required this.product,
    required this.onManage,
  });

  final SkincareProduct product;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (product.brand?.isNotEmpty == true) {
      subtitleParts.add(product.brand!);
    }
    subtitleParts.add(product.category.replaceAll('_', ' ').toUpperCase());
    if (product.expirationDate != null) {
      subtitleParts.add(
        'Expires ${DateFormat('MMM d').format(product.expirationDate!)}',
      );
    }

    return ListTile(
      onTap: onManage,
      contentPadding: EdgeInsets.zero,
      leading: product.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            )
          : Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppTheme.primaryPink,
              ),
            ),
      title: Text(
        product.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        subtitleParts.join(' • '),
        style: ResponsiveConfig.textStyle(
          size: 12,
          color: AppTheme.mediumGray,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.launch_outlined),
        tooltip: 'Open inventory manager',
        onPressed: onManage,
      ),
    );
  }
}

class _InventoryStatTile extends StatelessWidget {
  const _InventoryStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: ResponsiveConfig.borderRadius(16),
      onTap: onTap,
      child: Ink(
        padding: ResponsiveConfig.padding(all: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryPink.withOpacity(0.08),
          borderRadius: ResponsiveConfig.borderRadius(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryPink),
            ResponsiveConfig.heightBox(8),
            Text(
              value,
              style: ResponsiveConfig.textStyle(
                size: 20,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(4),
            Text(
              label,
              style: ResponsiveConfig.textStyle(
                size: 12,
                color: AppTheme.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcneCard extends StatelessWidget {
  const _AcneCard({
    required this.entries,
    required this.onLogAcne,
  });

  final List<AcneEntry> entries;
  final VoidCallback onLogAcne;

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
                  'Acne & Pimple Tracker',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Chip(
                      label: Text('${entries.length} logged'),
                      backgroundColor: AppTheme.primaryPink.withOpacity(0.15),
                    ),
                    /* ResponsiveConfig.widthBox(8),
                    IconButton(
                      icon: const Icon(Icons.healing_outlined),
                      color: AppTheme.primaryPink,
                      onPressed: onLogAcne,
                      tooltip: 'Log breakout',
                    ), */
                  ],
                ),
              ],
            ),
            ResponsiveConfig.heightBox(12),
            if (entries.isEmpty)
              Text(
                'Log breakouts with severity and treatment to spot triggers quickly.',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              )
            else
              ...entries.take(3).map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.healing_outlined,
                        color: entry.severity >= 3
                            ? AppTheme.warningOrange
                            : AppTheme.primaryPink,
                      ),
                      title: Text(
                        DateFormat('MMM d').format(entry.date),
                      ),
                      subtitle: Text(
                        '${entry.type} • Severity ${entry.severity} • ${entry.location}',
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _UVOverviewCard extends StatelessWidget {
  const _UVOverviewCard({
    required this.entries,
    required this.onLogUV,
  });

  final List<UVIndexEntry> entries;
  final VoidCallback onLogUV;

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
                  'UV Index Monitor',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.sunny_snowing),
                  color: AppTheme.primaryPink,
                  onPressed: onLogUV,
                  tooltip: 'Log UV index',
                ),
              ],
            ),
            ResponsiveConfig.heightBox(8),
            if (entries.isEmpty)
              Text(
                'Log daily UV index to keep sunscreen habits on track.',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              )
            else
              Wrap(
                spacing: 8,
                children: entries.take(4).map((entry) {
                  final risk = entry.uvIndex <= 2
                      ? 'Low'
                      : entry.uvIndex <= 5
                          ? 'Moderate'
                          : entry.uvIndex <= 7
                              ? 'High'
                              : 'Very high';
                  return Chip(
                    avatar: const Icon(Icons.sunny, size: 16),
                    label: Text(
                      '${DateFormat('MMM d').format(entry.date)} • UV ${entry.uvIndex} ($risk)',
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goals,
    required this.onAddGoal,
  });

  final List<SkinGoal> goals;
  final VoidCallback onAddGoal;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
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
                    'Skin Goal Planner',
                    style: ResponsiveConfig.textStyle(
                      size: 18,
                      weight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flag_outlined),
                    color: AppTheme.primaryPink,
                    onPressed: onAddGoal,
                    tooltip: 'Add goal',
                  ),
                ],
              ),
              ResponsiveConfig.heightBox(8),
              Text(
                'Set actionable goals (e.g. "Reduce hyperpigmentation by June") to stay consistent.',
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
                  'Skin Goal Planner',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.flag_outlined),
                  color: AppTheme.primaryPink,
                  onPressed: onAddGoal,
                  tooltip: 'Add goal',
                ),
              ],
            ),
            ResponsiveConfig.heightBox(12),
            ...goals.take(3).map((goal) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  goal.status == 'achieved'
                      ? Icons.check_circle
                      : Icons.flag_outlined,
                  color: goal.status == 'achieved'
                      ? AppTheme.successGreen
                      : AppTheme.primaryPink,
                ),
                title: Text(goal.goal),
                subtitle: Text(
                  'Target: ${DateFormat('MMM d, y').format(goal.targetDate)} • Status: ${goal.status}',
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BeautyTipsCard extends StatelessWidget {
  const _BeautyTipsCard();

  @override
  Widget build(BuildContext context) {
    final tips = [
      'Layer products from thinnest to thickest consistency for optimal absorption.',
      'Apply sunscreen (SPF 30+) every morning, even on cloudy days.',
      'Introduce only one new active every two weeks to monitor reactions.',
      'Sleep on silk pillowcases to reduce friction-induced wrinkles.',
    ];

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Beauty Tips & Guides',
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
                    const Icon(Icons.check,
                        size: 18, color: AppTheme.primaryPink),
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

class _CommunityCard extends StatelessWidget {
  const _CommunityCard();

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
              'Share progress, ask dermatologists, and join climate-based skincare groups.',
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
                  onPressed: () => context.push('/groups', extra: 'skincare'),
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Join forum'),
                ),
                ResponsiveConfig.heightBox(8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/events', extra: 'skincare'),
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

class _RoutineReminderCard extends StatelessWidget {
  const _RoutineReminderCard({required this.onSchedule});

  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Routine Reminders',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Never miss AM/PM steps—schedule reminders tied to your routine templates.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            OutlinedButton.icon(
              onPressed: onSchedule,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Schedule routine alerts'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientScannerCard extends StatelessWidget {
  const _IngredientScannerCard({required this.onSearch});

  final VoidCallback onSearch;

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
                  'Ingredient Scanner',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: onSearch,
                ),
              ],
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Scan labels or search the dictionary for benefits, comedogenic ratings, and cautionary pairings.',
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

class _ClimateAdjusterCard extends StatelessWidget {
  const _ClimateAdjusterCard();

  @override
  Widget build(BuildContext context) {
    final tips = [
      'Humid day? Swap to gel moisturizers and mattifying SPF.',
      'Dry air? Layer hydrating serum with ceramide cream.',
      'Cold night? Seal routine with occlusive balm to prevent transepidermal water loss.',
    ];

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Climate-Based Adjuster',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'FemCare+ checks local weather to suggest seasonal adjustments automatically.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_outlined,
                        size: 18, color: AppTheme.primaryPink),
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

class _DermatologistCard extends StatelessWidget {
  const _DermatologistCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dermatologist Consultation',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Book virtual consultations or export your journal to share with your dermatologist.',
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
                  onPressed: () {},
                  icon: const Icon(Icons.video_call_outlined),
                  label: const Text('Book video call'),
                ),
                ResponsiveConfig.heightBox(8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Export journal'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineTemplateCard extends StatelessWidget {
  const _RoutineTemplateCard(this.template);

  final RoutineTemplate template;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: ResponsiveConfig.margin(bottom: 12),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  template.name,
                  style: ResponsiveConfig.textStyle(
                    size: 16,
                    weight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    template.routineType.toUpperCase(),
                    style: ResponsiveConfig.textStyle(
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppTheme.primaryPink,
                ),
              ],
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Skin type: ${template.skinType} • Concerns: ${template.concerns.isEmpty ? 'general' : template.concerns.join(', ')}',
              style: ResponsiveConfig.textStyle(
                size: 13,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(6),
            Text(
              template.productIds.isEmpty
                  ? 'Add product IDs to this routine for deeper insights.'
                  : 'Products: ${template.productIds.join(' → ')}',
            ),
            if (template.notes != null && template.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Notes: ${template.notes}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoutineHistoryCard extends StatelessWidget {
  const _RoutineHistoryCard({required this.entries});

  final List<SkincareEntry> entries;

  @override
  Widget build(BuildContext context) {
    final recent = entries.take(5).toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Routine Logs',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            ...recent.map((entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline,
                      color: AppTheme.primaryPink),
                  title: Text(
                    '${DateFormat('MMM d').format(entry.date)} • ${entry.timeOfDay}',
                  ),
                  subtitle: entry.productsUsed.isEmpty
                      ? null
                      : Text(
                          '${entry.productsUsed.length} product(s) logged',
                        ),
                )),
          ],
        ),
      ),
    );
  }
}

class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({required this.journals, required this.acneEntries});

  final List<SkinJournalEntry> journals;
  final List<AcneEntry> acneEntries;

  @override
  Widget build(BuildContext context) {
    final hydrationValues = journals
        .where((e) => e.hydrationLevel != null)
        .map((e) => e.hydrationLevel!.toDouble())
        .toList();
    final hydrationScore = hydrationValues.isNotEmpty
        ? hydrationValues.reduce((a, b) => a + b) / hydrationValues.length
        : 0;
    final acneScore = acneEntries.isEmpty
        ? 10
        : max(
            0,
            10 -
                acneEntries.map((e) => e.severity).reduce((a, b) => a + b) /
                    max(1, acneEntries.length));
    final overall = ((hydrationScore + acneScore) / 20) * 100;

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skin Health Score',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            Center(
              child: SizedBox(
                height: 150,
                width: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(150, 150),
                      painter: _SkinHealthScorePainter(
                        progress: overall / 100,
                        backgroundColor: AppTheme.palePink,
                        progressColor: AppTheme.primaryPink,
                        strokeWidth: 12,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${overall.toStringAsFixed(0)}%',
                          style: ResponsiveConfig.textStyle(
                            size: 28,
                            weight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'healthy',
                          style: ResponsiveConfig.textStyle(
                            size: 12,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ResponsiveConfig.heightBox(12),
            Text(
              'Hydration score: ${hydrationScore.toStringAsFixed(1)} / 10 • Acne score: ${acneScore.toStringAsFixed(1)} / 10',
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

class _HydrationTrendChart extends StatelessWidget {
  const _HydrationTrendChart({
    required this.hydrationLogs,
    this.onInsightTapped,
  });

  final List<_HydrationLogEntry> hydrationLogs;
  final VoidCallback? onInsightTapped;

  @override
  Widget build(BuildContext context) {
    final data = hydrationLogs.where((entry) => entry.waterGlasses > 0).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (data.length < 2) {
      return const _HydrationEmptyState();
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].waterGlasses.toDouble()));
    }

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hydration Progress',
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
                          final index = spot.spotIndex;
                          final entry = data[index];
                          return LineTooltipItem(
                            '${DateFormat('MMM d').format(entry.date)}\nHydration: ${entry.waterGlasses}/${entry.goal}',
                            ResponsiveConfig.textStyle(
                              size: 12,
                              color: Colors.white,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: const FlGridData(
                    show: true,
                    horizontalInterval: 2,
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: max(1, (spots.length / 4).floor()).toDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            DateFormat('MMMd').format(data[index].date),
                            style: ResponsiveConfig.textStyle(size: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
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
                  minY: 0,
                  maxY: data.map((entry) => entry.goal.toDouble()).fold<double>(
                          8, (prev, element) => max(prev, element)) +
                      1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
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

class _SleepWellnessCard extends StatelessWidget {
  const _SleepWellnessCard({required this.journals});

  final List<SkinJournalEntry> journals;

  @override
  Widget build(BuildContext context) {
    final sleepValues = journals
        .where((entry) => entry.sleepHours != null)
        .map((entry) => entry.sleepHours!.toDouble())
        .toList();
    final avg = sleepValues.isNotEmpty
        ? sleepValues.reduce((a, b) => a + b) / sleepValues.length
        : 0.0;

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sleep & Wellness Tracker',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Average sleep duration: ${avg.toStringAsFixed(1)} hours. Aim for 7-8 hrs for optimal barrier repair.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            if (sleepValues.isNotEmpty)
              Wrap(
                spacing: 8,
                children: journals
                    .where((entry) => entry.sleepHours != null)
                    .take(6)
                    .map(
                      (entry) => Chip(
                        avatar: const Icon(Icons.nightlight_outlined, size: 16),
                        label: Text(
                          '${DateFormat('MMMd').format(entry.date)} • ${entry.sleepHours} h',
                        ),
                      ),
                    )
                    .toList(),
              )
            else
              Text(
                'Add sleep hours in your journal to discover correlations with flare ups.',
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

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.journals,
    required this.routines,
  });

  final List<SkinJournalEntry> journals;
  final List<SkincareEntry> routines;

  @override
  Widget build(BuildContext context) {
    final drynessTrend = journals.any(
      (entry) => entry.skinCondition?.contains('dry') ?? false,
    );
    final acneTrend = journals.any(
      (entry) => entry.concerns.any((concern) => concern.contains('acne')),
    );
    final dullTrend = journals.any(
      (entry) => entry.concerns.any((concern) => concern.contains('dull')),
    );

    final recommendations = <String>[];
    if (drynessTrend) {
      recommendations
          .add('Introduce hyaluronic acid serum and seal with ceramide cream.');
    }
    if (acneTrend) {
      recommendations.add(
          'Alternate salicylic acid cleanser with gentle hydrating cleanser.');
    }
    if (dullTrend) {
      recommendations
          .add('Add vitamin C each morning and gentle exfoliation weekly.');
    }
    if (recommendations.isEmpty) {
      recommendations.add(
          'Skin logs look balanced. Maintain sunscreen and hydration—log any new concerns.');
    }

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendation Engine',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            ...recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: AppTheme.primaryPink, size: 18),
                    ResponsiveConfig.widthBox(8),
                    Expanded(child: Text(rec)),
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

class _IngredientDictionaryCard extends StatelessWidget {
  const _IngredientDictionaryCard({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingredient Dictionary',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Search 1,000+ cosmetic ingredients with benefits, comedogenic ratings, and pregnancy safety.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            OutlinedButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search),
              label: const Text('Open dictionary'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AIDermatologistCard extends StatelessWidget {
  const _AIDermatologistCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Dermatologist Assistant',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            const Text(
              'A Dermatologist persona system prompt, risk-free medical compliance version and a FemCare+ branded tone version, chat your FemCare AI now.',
            ),
            ResponsiveConfig.heightBox(12),
            ElevatedButton.icon(
              onPressed: () {
                context.push("/ai-chat/dermatologist");
              },
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('Ask FermCare+'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ARPreviewCard extends StatelessWidget {
  const _ARPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AR Skin Preview',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            const Text(
              'Preview routine results with augmented reality overlays and shade matching (beta).',
            ),
            ResponsiveConfig.heightBox(12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.view_in_ar_outlined),
              label: const Text('Preview (beta)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UVAnalyticsCard extends StatelessWidget {
  const _UVAnalyticsCard({required this.entries});

  final List<UVIndexEntry> entries;

  @override
  Widget build(BuildContext context) {
    final average = entries
            .map((entry) => entry.uvIndex.toDouble())
            .reduce((a, b) => a + b) /
        entries.length;
    final highDays = entries.where((entry) => entry.uvIndex >= 6).length;

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UV Analytics',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Average UV: ${average.toStringAsFixed(1)} • High UV days: $highDays',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            const Text(
              'Apply broad spectrum SPF 30+ when UV > 3 and reapply every two hours outdoors.',
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

/// Custom painter for skin health score circular progress
class _SkinHealthScorePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color backgroundColor;

  _SkinHealthScorePainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_SkinHealthScorePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _HydrationEmptyState extends StatelessWidget {
  const _HydrationEmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Text(
          'Log hydration metrics for at least two days to unlock hydration trends.',
          style: ResponsiveConfig.textStyle(
            size: 14,
            color: AppTheme.mediumGray,
          ),
        ),
      ),
    );
  }
}

class _HydrationLogEntry {
  final DateTime date;
  final int waterGlasses;
  final int goal;

  const _HydrationLogEntry({
    required this.date,
    required this.waterGlasses,
    required this.goal,
  });
}

List<_HydrationLogEntry> _mergeHydrationLogs(
  List<WellnessModel> wellnessLogs,
  List<SkinJournalEntry> journalLogs,
) {
  final combined = <_HydrationLogEntry>[];

  for (final entry in wellnessLogs) {
    final glasses = entry.hydration.waterGlasses;
    if (glasses <= 0) continue;
    combined.add(
      _HydrationLogEntry(
        date: entry.date,
        waterGlasses: glasses,
        goal: entry.hydration.goal,
      ),
    );
  }

  for (final entry in journalLogs) {
    final hydrationLevel = entry.hydrationLevel;
    if (hydrationLevel == null || hydrationLevel <= 0) continue;
    combined.add(
      _HydrationLogEntry(
        date: entry.date,
        waterGlasses: hydrationLevel,
        goal: 8,
      ),
    );
  }

  combined.sort((a, b) => b.date.compareTo(a.date));
  return combined;
}
