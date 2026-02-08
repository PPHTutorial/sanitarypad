// Part 2: Overview Tab for Nutrition Tracking Screen
// This file contains the Overview, Meals, Recipes, Goals, and Insights tabs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sanitarypad/core/config/responsive_config.dart';
import 'package:sanitarypad/core/theme/app_theme.dart';
import 'package:sanitarypad/models/nutrition_models.dart';
import 'package:sanitarypad/services/nutrition_service.dart';
import 'package:sanitarypad/presentation/screens/nutrition/nutrition_location_search_screen.dart';
import 'package:sanitarypad/presentation/widgets/ads/eco_ad_wrapper.dart';
import 'package:go_router/go_router.dart';

// ============================================================================
// OVERVIEW TAB
// ============================================================================
class OverviewTab extends ConsumerWidget {
  final String userId;
  final DateTime selectedDate;

  const OverviewTab({super.key, required this.userId, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(nutritionGoalsProvider(userId));
    final mealsAsync = ref.watch(todayMealsProvider(userId));
    final waterAsync = ref.watch(todayWaterProvider(userId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveConfig.heightBox(16),
          // Date Header
          _DateHeader(date: selectedDate),
          const SizedBox(height: 16),

          // Calories Card
          goalsAsync.when(
            data: (goals) => mealsAsync.when(
              data: (meals) {
                final summary = DailyNutritionSummary.fromMeals(
                  selectedDate,
                  meals,
                  waterAsync.value ?? 0,
                );
                return _CaloriesCard(summary: summary, goals: goals);
              },
              loading: () => _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
            ),
            loading: () => _LoadingCard(),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          const SizedBox(height: 16),

          // Macros Chart
          goalsAsync.when(
            data: (goals) => mealsAsync.when(
              data: (meals) {
                final summary =
                    DailyNutritionSummary.fromMeals(selectedDate, meals, 0);
                return _MacrosCard(summary: summary, goals: goals);
              },
              loading: () => _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
            ),
            loading: () => _LoadingCard(),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          const SizedBox(height: 16),

          // Water Intake Card
          goalsAsync.when(
            data: (goals) => waterAsync.when(
              data: (water) => _WaterCard(
                  currentMl: water,
                  goalMl: goals.waterMl,
                  userId: userId,
                  ref: ref),
              loading: () => _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
            ),
            loading: () => _LoadingCard(),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          const SizedBox(height: 16),

          // Meal Breakdown
          mealsAsync.when(
            data: (meals) => _MealBreakdownCard(meals: meals),
            loading: () => _LoadingCard(),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          const SizedBox(height: 24),

          // Wellness Finder Card
          _WellnessFinderCard(),
          const SizedBox(height: 16),

          // Community Card
          _NutritionCommunityCard(),
          const SizedBox(height: 16),
          const EcoAdWrapper(adType: AdType.banner),
          const SizedBox(height: 80), // FAB space
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    return Row(
      children: [
        Icon(FontAwesomeIcons.calendarDay,
            size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          isToday ? 'Today' : DateFormat('EEEE, MMM d').format(date),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _CaloriesCard extends StatelessWidget {
  final DailyNutritionSummary summary;
  final NutritionGoals goals;
  const _CaloriesCard({required this.summary, required this.goals});

  @override
  Widget build(BuildContext context) {
    final percentage =
        (summary.totalCalories / goals.dailyCalories * 100).clamp(0, 150);
    final remaining = goals.dailyCalories - summary.totalCalories;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPink,
            AppTheme.primaryPink.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Calories',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${summary.totalCalories}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 4),
                        child: Text('/ ${goals.dailyCalories}',
                            style:
                                const TextStyle(color: Colors.white70, fontSize: 16)),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 4,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                    Text('${percentage.toInt()}%',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    remaining > 0 ? Icons.local_fire_department : Icons.warning,
                    color: Colors.white,
                    size: 18),
                const SizedBox(width: 8),
                Text(
                  remaining > 0
                      ? '$remaining cal remaining'
                      : '${-remaining} cal over goal',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacrosCard extends StatelessWidget {
  final DailyNutritionSummary summary;
  final NutritionGoals goals;
  const _MacrosCard({required this.summary, required this.goals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Macros',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _MacroItem(
                      label: 'Protein',
                      value: summary.totalProtein,
                      goal: goals.proteinGrams,
                      color: Theme.of(context).colorScheme.primary,
                      unit: 'g')),
              const SizedBox(width: 12),
              Expanded(
                  child: _MacroItem(
                      label: 'Carbs',
                      value: summary.totalCarbs,
                      goal: goals.carbGrams,
                      color: Theme.of(context).colorScheme.primary,
                      unit: 'g')),
              const SizedBox(width: 12),
              Expanded(
                  child: _MacroItem(
                      label: 'Fat',
                      value: summary.totalFat,
                      goal: goals.fatGrams,
                      color: Theme.of(context).colorScheme.primary,
                      unit: 'g')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final Color color;
  final String unit;
  const _MacroItem(
      {required this.label,
      required this.value,
      required this.goal,
      required this.color,
      required this.unit});

  @override
  Widget build(BuildContext context) {
    final percentage = goal > 0 ? (value / goal).clamp(0, 1.5) : 0.0;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: percentage.toDouble(),
                strokeWidth: 6,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            Text('${value.toInt()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Text('${goal.toInt()}$unit',
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

class _WaterCard extends ConsumerWidget {
  final int currentMl;
  final int goalMl;
  final String userId;
  final WidgetRef ref;
  const _WaterCard(
      {required this.currentMl,
      required this.goalMl,
      required this.userId,
      required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glasses = (currentMl / 250).floor();
    final goalGlasses = (goalMl / 250).ceil();
    final percentage =
        goalMl > 0 ? (currentMl / goalMl * 100).clamp(0, 150) : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(FontAwesomeIcons.droplet,
                      color: AppTheme.primaryPink, size: 18),
                  ResponsiveConfig.widthBox(8),
                  const Text('Water Intake',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${percentage.toInt()}%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          ResponsiveConfig.heightBox(16),
          Text('$currentMl / $goalMl ml',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ResponsiveConfig.heightBox(8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0, 1).toDouble(),
              minHeight: 10,
              backgroundColor: AppTheme.primaryPink.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryPink),
            ),
          ),
          ResponsiveConfig.heightBox(24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
                goalGlasses,
                (i) => Icon(
                      FontAwesomeIcons.glassWater,
                      size: 20,
                      color: i < glasses
                          ? AppTheme.primaryPink
                          : AppTheme.primaryPink.withOpacity(0.3),
                    )),
          ),
          ResponsiveConfig.heightBox(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _QuickWaterButton(
                  label: '+250ml', onTap: () => _logWater(250, context)),
              ResponsiveConfig.widthBox(8),
              _QuickWaterButton(
                  label: '+500ml', onTap: () => _logWater(500, context)),
              ResponsiveConfig.widthBox(8),
              _QuickWaterButton(
                  label: '+750ml', onTap: () => _logWater(750, context)),
            ],
          ),
        ],
      ),
    );
  }

  void _logWater(int ml, BuildContext context) async {
    await ref.read(nutritionServiceProvider).logWater(userId, ml);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${ml}ml water 💧')),
      );
    }
  }
}

class _QuickWaterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickWaterButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Theme.of(context).colorScheme.secondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label,
          style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
    );
  }
}

class _MealBreakdownCard extends StatelessWidget {
  final List<MealEntry> meals;
  const _MealBreakdownCard({required this.meals});

  @override
  Widget build(BuildContext context) {
    final mealsByType = <MealType, List<MealEntry>>{};
    for (final meal in meals) {
      mealsByType.putIfAbsent(meal.type, () => []).add(meal);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today\'s Meals',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (meals.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(FontAwesomeIcons.utensils,
                        size: 40, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No meals logged yet',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ...MealType.values.map((type) {
              final typeMeals = mealsByType[type] ?? [];
              if (typeMeals.isEmpty) return const SizedBox.shrink();
              final totalCals = typeMeals.fold(0, (sum, m) => sum + m.calories);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _mealColor(context, type).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(type.icon, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(type.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                              '${typeMeals.length} item${typeMeals.length > 1 ? 's' : ''}',
                              style:
                                  const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Text('$totalCals cal',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _mealColor(BuildContext context, MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Theme.of(context).colorScheme.primary;
      case MealType.lunch:
        return Theme.of(context).colorScheme.secondary;
      case MealType.dinner:
        return Theme.of(context).colorScheme.primary.withOpacity(0.7);
      case MealType.snack:
        return Theme.of(context).colorScheme.secondary.withOpacity(0.7);
    }
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _WellnessFinderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wellness Finder',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.location_on_outlined, color: AppTheme.primaryPink),
              ],
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Find pharmacies, supermarkets, and eateries nearby to support your health.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const NutritionLocationSearchScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Find wellness spots'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionCommunityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Community',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Connect with others, share recipes, and join wellness groups.',
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
                  onPressed: () => context.push('/groups', extra: 'nutrition'),
                  icon: const FaIcon(FontAwesomeIcons.users, size: 16),
                  label: const Text('Join nutrition forum'),
                ),
                ResponsiveConfig.heightBox(8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/events', extra: 'nutrition'),
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
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
