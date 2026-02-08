import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sanitarypad/services/nutrition_service.dart';
import 'package:sanitarypad/core/providers/auth_provider.dart';
import 'package:sanitarypad/services/video_feed_service.dart';
import 'package:sanitarypad/services/credit_manager.dart';
import 'package:sanitarypad/services/nutrition_export_service.dart';
import 'package:sanitarypad/presentation/screens/nutrition/widgets/nutrition_tabs.dart';
import 'package:sanitarypad/presentation/screens/nutrition/widgets/nutrition_tabs_part2.dart';
import 'package:sanitarypad/presentation/screens/nutrition/widgets/nutrition_tabs_part3.dart';
import 'package:sanitarypad/presentation/screens/nutrition/meal_log_form_screen.dart';
import 'package:sanitarypad/core/widgets/back_button_handler.dart';
import 'package:sanitarypad/core/theme/app_theme.dart';
import 'package:sanitarypad/core/config/responsive_config.dart';

/// Nutrition Tracking Screen with 5 tabs: Overview, Meal Log, Recipes, Goals, Insights
class NutritionTrackingScreen extends ConsumerStatefulWidget {
  const NutritionTrackingScreen({super.key});

  @override
  ConsumerState<NutritionTrackingScreen> createState() =>
      _NutritionTrackingScreenState();
}

class _NutritionTrackingScreenState
    extends ConsumerState<NutritionTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  final List<String> _tabs = [
    'Overview',
    'Meals',
    'Recipes',
    'Goals',
    'Insights'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    // Initialize video feed service
    ref.read(videoFeedServiceProvider).initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.userId;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to track nutrition')),
      );
    }

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title:
              const Text('Nutrition', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.go('/home'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Quick Actions',
              onPressed: () => _showQuickActions(context, userId),
            ),
            IconButton(
              icon: const Icon(FontAwesomeIcons.calendarDay, size: 20),
              onPressed: () => _selectDate(context),
            ),
          ],
          bottom: _buildModernTabBar(context),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            OverviewTab(userId: userId, selectedDate: _selectedDate),
            MealsTab(
                userId: userId,
                selectedDate: _selectedDate,
                onAddMeal: () => _showMealForm(context, userId)),
            RecipesTab(userId: userId),
            GoalsTab(userId: userId),
            InsightsTab(userId: userId),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernTabBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: TabBar(
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
          Tab(text: 'Meals', icon: Icon(Icons.lunch_dining_outlined)),
          Tab(text: 'Recipes', icon: Icon(Icons.menu_book_outlined)),
          Tab(text: 'Goals', icon: Icon(Icons.track_changes)),
          Tab(text: 'Insights', icon: Icon(Icons.insights_outlined)),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showQuickActions(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quick Actions',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickActionButton(
                  icon: FontAwesomeIcons.utensils,
                  label: 'Log Meal',
                  color: AppTheme.primaryPink,
                  onTap: () {
                    Navigator.pop(context);
                    _showMealForm(context, userId);
                  },
                ),
                _QuickActionButton(
                  icon: FontAwesomeIcons.glassWater,
                  label: 'Log Water',
                  color: AppTheme.primaryPink,
                  onTap: () {
                    Navigator.pop(context);
                    _showWaterLogger(context, userId);
                  },
                ),
                _QuickActionButton(
                  icon: FontAwesomeIcons.bullseye,
                  label: 'Set Goals',
                  color: AppTheme.primaryPink,
                  onTap: () {
                    Navigator.pop(context);
                    _tabController.animateTo(3);
                  },
                ),
                _QuickActionButton(
                  icon: FontAwesomeIcons.filePdf,
                  label: 'Export Data',
                  color: AppTheme.primaryPink,
                  onTap: () {
                    Navigator.pop(context);
                    _exportNutritionData(context, userId);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showMealForm(BuildContext context, String userId) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MealLogFormScreen(userId: userId),
        ));
  }

  void _showWaterLogger(BuildContext context, String userId) {
    int waterAmount = 250;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Log Water Intake',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setModalState(
                        () => waterAmount = max(50, waterAmount - 50)),
                    icon: Icon(Icons.remove_circle,
                        size: 40,
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    children: [
                      Text('$waterAmount',
                          style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary)),
                      const Text('ml',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    onPressed: () => setModalState(() => waterAmount += 50),
                    icon: Icon(Icons.add_circle,
                        size: 40,
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [100, 200, 250, 500]
                    .map((ml) => ChoiceChip(
                          label: Text('${ml}ml'),
                          selected: waterAmount == ml,
                          onSelected: (_) =>
                              setModalState(() => waterAmount = ml),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(nutritionServiceProvider)
                      .logWater(userId, waterAmount);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logged $waterAmount ml')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
                child: const Text('Log Water',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportNutritionData(BuildContext context, String userId) async {
    final creditManager = ref.read(creditManagerProvider);
    final hasCredits = await creditManager.requestCredit(
      context,
      ActionType.export,
    );

    if (hasCredits) {
      await creditManager.consumeCredits(ActionType.export);
      final meals = await ref.read(todayMealsProvider(userId).future);
      await NutritionExportService().exportMealLogsAsPdf(meals);
    }
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
