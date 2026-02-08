// Nutrition Tabs Part 3: Goals and Insights tabs

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sanitarypad/models/nutrition_models.dart';
import 'package:sanitarypad/services/nutrition_service.dart';

// ============================================================================
// GOALS TAB
// ============================================================================
class GoalsTab extends ConsumerStatefulWidget {
  final String userId;
  const GoalsTab({super.key, required this.userId});

  @override
  ConsumerState<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends ConsumerState<GoalsTab> {
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _waterController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _carbsController = TextEditingController();
    _fatController = TextEditingController();
    _waterController = TextEditingController();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(nutritionGoalsProvider(widget.userId));

    return goalsAsync.when(
      data: (goals) {
        if (!_isEditing) {
          _caloriesController.text = goals.dailyCalories.toString();
          _proteinController.text = goals.proteinGrams.toInt().toString();
          _carbsController.text = goals.carbGrams.toInt().toString();
          _fatController.text = goals.fatGrams.toInt().toString();
          _waterController.text = goals.waterMl.toString();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Your Goals',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  if (!_isEditing)
                    TextButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    )
                  else
                    Row(
                      children: [
                        TextButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: const Text('Cancel')),
                        const SizedBox(width: 8),
                        ElevatedButton(
                            onPressed: _saveGoals, child: const Text('Save')),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Calories Goal
              _GoalCard(
                icon: FontAwesomeIcons.fire,
                color: Theme.of(context).colorScheme.primary,
                title: 'Daily Calories',
                subtitle: 'Your target calorie intake',
                controller: _caloriesController,
                unit: 'cal',
                isEditing: _isEditing,
              ),
              const SizedBox(height: 16),

              // Macros Goals
              const Text('Macronutrients',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _MacroGoalCard(
                          title: 'Protein',
                          controller: _proteinController,
                          color: Theme.of(context).colorScheme.primary,
                          isEditing: _isEditing)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _MacroGoalCard(
                          title: 'Carbs',
                          controller: _carbsController,
                          color: Theme.of(context).colorScheme.secondary,
                          isEditing: _isEditing)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _MacroGoalCard(
                          title: 'Fat',
                          controller: _fatController,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.6),
                          isEditing: _isEditing)),
                ],
              ),
              const SizedBox(height: 24),

              // Water Goal
              _GoalCard(
                icon: FontAwesomeIcons.droplet,
                color: Theme.of(context).colorScheme.secondary,
                title: 'Daily Water',
                subtitle: 'Stay hydrated!',
                controller: _waterController,
                unit: 'ml',
                isEditing: _isEditing,
              ),
              const SizedBox(height: 24),

              // Preset Goals
              if (!_isEditing) ...[
                const Text('Quick Presets',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _PresetCard(
                  title: 'Weight Loss',
                  description: '1500 cal, high protein',
                  onTap: () => _applyPreset(const NutritionGoals(
                      dailyCalories: 1500,
                      proteinGrams: 80,
                      carbGrams: 120,
                      fatGrams: 50,
                      waterMl: 3000)),
                ),
                _PresetCard(
                  title: 'Maintenance',
                  description: '2000 cal, balanced macros',
                  onTap: () => _applyPreset(const NutritionGoals(
                      dailyCalories: 2000,
                      proteinGrams: 50,
                      carbGrams: 250,
                      fatGrams: 65,
                      waterMl: 2500)),
                ),
                _PresetCard(
                  title: 'Muscle Gain',
                  description: '2500 cal, high protein',
                  onTap: () => _applyPreset(const NutritionGoals(
                      dailyCalories: 2500,
                      proteinGrams: 120,
                      carbGrams: 300,
                      fatGrams: 80,
                      waterMl: 3500)),
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  void _applyPreset(NutritionGoals preset) {
    setState(() {
      _caloriesController.text = preset.dailyCalories.toString();
      _proteinController.text = preset.proteinGrams.toInt().toString();
      _carbsController.text = preset.carbGrams.toInt().toString();
      _fatController.text = preset.fatGrams.toInt().toString();
      _waterController.text = preset.waterMl.toString();
      _isEditing = true;
    });
  }

  Future<void> _saveGoals() async {
    final goals = NutritionGoals(
      dailyCalories: int.tryParse(_caloriesController.text) ?? 2000,
      proteinGrams: double.tryParse(_proteinController.text) ?? 50,
      carbGrams: double.tryParse(_carbsController.text) ?? 250,
      fatGrams: double.tryParse(_fatController.text) ?? 65,
      waterMl: int.tryParse(_waterController.text) ?? 2500,
    );

    await ref.read(nutritionServiceProvider).setGoals(widget.userId, goals);
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Goals saved!')));
  }
}

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final String unit;
  final bool isEditing;

  const _GoalCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.unit,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          if (isEditing)
            SizedBox(
              width: 100,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  suffixText: unit,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            )
          else
            Text('${controller.text} $unit',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _MacroGoalCard extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final Color color;
  final bool isEditing;

  const _MacroGoalCard(
      {required this.title,
      required this.controller,
      required this.color,
      required this.isEditing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 8),
          if (isEditing)
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: 'g',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            )
          else
            Text('${controller.text}g',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const _PresetCard(
      {required this.title, required this.description, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(FontAwesomeIcons.lightbulb,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================================
// INSIGHTS TAB
// ============================================================================
class InsightsTab extends ConsumerWidget {
  final String userId;
  const InsightsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(nutritionServiceProvider).getCalorieTrend(userId, 7),
      builder: (context, trendSnapshot) {
        return FutureBuilder<Map<String, double>>(
          future: ref
              .read(nutritionServiceProvider)
              .getWeeklyAverages(userId, _getWeekStart()),
          builder: (context, avgSnapshot) {
            final trend = trendSnapshot.data ?? [];
            final averages = avgSnapshot.data ?? {};

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weekly Trend Chart
                  const Text('7-Day Calorie Trend',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: trend.isEmpty
                        ? const Center(
                            child: Text('No data yet',
                                style: TextStyle(color: Colors.grey)))
                        : _CalorieTrendChart(data: trend),
                  ),
                  const SizedBox(height: 24),

                  // Weekly Averages
                  const Text('Weekly Averages',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _AverageCard(
                              title: 'Calories',
                              value: (averages['avgCalories'] ?? 0)
                                  .toInt()
                                  .toString(),
                              unit: 'cal/day',
                              color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _AverageCard(
                              title: 'Protein',
                              value: (averages['avgProtein'] ?? 0)
                                  .toInt()
                                  .toString(),
                              unit: 'g/day',
                              color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _AverageCard(
                              title: 'Carbs',
                              value: (averages['avgCarbs'] ?? 0)
                                  .toInt()
                                  .toString(),
                              unit: 'g/day',
                              color: Theme.of(context).colorScheme.secondary)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _AverageCard(
                              title: 'Fat',
                              value:
                                  (averages['avgFat'] ?? 0).toInt().toString(),
                              unit: 'g/day',
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.6))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // AI Insights (simulated)
                  const Text('AI Insights',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _InsightCard(
                    icon: FontAwesomeIcons.lightbulb,
                    color: Theme.of(context).colorScheme.primary,
                    title: 'Stay Consistent',
                    description:
                        'Tracking your meals regularly helps you understand your eating patterns better.',
                  ),
                  _InsightCard(
                    icon: FontAwesomeIcons.droplet,
                    color: Theme.of(context).colorScheme.secondary,
                    title: 'Hydration Reminder',
                    description:
                        'Aim for at least 8 glasses of water daily for optimal health.',
                  ),
                  _InsightCard(
                    icon: FontAwesomeIcons.utensils,
                    color: Theme.of(context).colorScheme.primary,
                    title: 'Balance Your Macros',
                    description:
                        'Include protein, carbs, and healthy fats in each meal for sustained energy.',
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        );
      },
    );
  }

  DateTime _getWeekStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - now.weekday + 1);
  }
}

class _CalorieTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _CalorieTrendChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = data
        .asMap()
        .entries
        .map((e) =>
            FlSpot(e.key.toDouble(), (e.value['calories'] as int).toDouble()))
        .toList();
    final maxY = spots.isEmpty
        ? 3000.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final date = data[index]['date'] as DateTime;
                  return Text(DateFormat('E').format(date),
                      style: const TextStyle(fontSize: 10, color: Colors.grey));
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _AverageCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;
  const _AverageCard(
      {required this.title,
      required this.value,
      required this.unit,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(unit, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _InsightCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
