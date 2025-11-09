import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/cycle_provider.dart';

/// Insights and analytics screen
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(cyclesStreamProvider);
    final cycles = cyclesAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: cycles.isEmpty
          ? _buildEmptyState(context)
          : FutureBuilder<Map<String, dynamic>>(
              future: _calculateStatistics(cycles),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data ?? {};
                return SingleChildScrollView(
                  padding: ResponsiveConfig.padding(all: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cycle Statistics
                      _buildStatisticsCard(context, stats),
                      ResponsiveConfig.heightBox(16),

                      // Cycle Length Chart
                      _buildCycleLengthChart(context, cycles),
                      ResponsiveConfig.heightBox(16),

                      // Pattern Recognition
                      _buildPatternsCard(context, cycles),
                      ResponsiveConfig.heightBox(16),

                      // Health Score
                      _buildHealthScoreCard(context),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_outlined,
              size: ResponsiveConfig.iconSize(64),
              color: AppTheme.mediumGray,
            ),
            ResponsiveConfig.heightBox(24),
            Text(
              'No Insights Yet',
              style: ResponsiveConfig.textStyle(
                size: 24,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Log at least 2 cycles to see insights and patterns',
              style: ResponsiveConfig.textStyle(
                size: 16,
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(
      BuildContext context, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cycle Statistics',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.w600,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Avg Cycle',
                    '${stats['averageCycleLength'] ?? 0} days',
                    Icons.calendar_today,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Avg Period',
                    '${stats['averagePeriodLength'] ?? 0} days',
                    Icons.water_drop,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total',
                    '${stats['totalCycles'] ?? 0} cycles',
                    Icons.timeline,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(16),
            _buildRegularityIndicator(
                context, stats['regularity'] as String? ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryPink,
          size: ResponsiveConfig.iconSize(24),
        ),
        ResponsiveConfig.heightBox(8),
        Text(
          value,
          style: ResponsiveConfig.textStyle(
            size: 16,
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
    );
  }

  Widget _buildRegularityIndicator(BuildContext context, String regularity) {
    Color color;
    String text;
    IconData icon;

    switch (regularity) {
      case 'very_regular':
        color = AppTheme.successGreen;
        text = 'Very Regular';
        icon = Icons.check_circle;
        break;
      case 'regular':
        color = AppTheme.infoBlue;
        text = 'Regular';
        icon = Icons.info;
        break;
      case 'irregular':
        color = AppTheme.warningOrange;
        text = 'Irregular';
        icon = Icons.warning;
        break;
      default:
        color = AppTheme.mediumGray;
        text = 'Insufficient Data';
        icon = Icons.help_outline;
    }

    return Container(
      padding: ResponsiveConfig.padding(all: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: ResponsiveConfig.borderRadius(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: ResponsiveConfig.iconSize(20)),
          ResponsiveConfig.widthBox(12),
          Text(
            text,
            style: ResponsiveConfig.textStyle(
              size: 14,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleLengthChart(BuildContext context, List cycles) {
    if (cycles.length < 2) {
      return const SizedBox.shrink();
    }

    final cycleLengths =
        cycles.take(6).map((c) => c.cycleLength.toDouble()).toList();
    final spots = cycleLengths.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cycle Length Trend',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.w600,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppTheme.primaryPink,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
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

  Widget _buildPatternsCard(BuildContext context, List cycles) {
    if (cycles.isEmpty) return const SizedBox.shrink();

    // Find most common symptoms
    final symptomCounts = <String, int>{};
    for (final cycle in cycles) {
      for (final symptom in cycle.symptoms) {
        symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
      }
    }

    final mostCommonSymptoms = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pattern Recognition',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.w600,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            if (mostCommonSymptoms.isNotEmpty)
              ...mostCommonSymptoms.take(3).map((entry) {
                return Padding(
                  padding: ResponsiveConfig.padding(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: AppTheme.primaryPink,
                        size: ResponsiveConfig.iconSize(20),
                      ),
                      ResponsiveConfig.widthBox(12),
                      Expanded(
                        child: Text(
                          'You often experience ${entry.key.replaceAll('_', ' ')}',
                          style: ResponsiveConfig.textStyle(
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList()
            else
              Text(
                'No patterns detected yet',
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

  Future<Map<String, dynamic>> _calculateStatistics(List cycles) async {
    if (cycles.isEmpty) {
      return {
        'averageCycleLength': 0,
        'averagePeriodLength': 0,
        'regularity': 'insufficient_data',
        'totalCycles': 0,
      };
    }

    int totalCycleLength = 0;
    for (final cycle in cycles) {
      totalCycleLength = (totalCycleLength + cycle.cycleLength) as int;
    }
    final averageCycleLength = (totalCycleLength / cycles.length).round();

    int totalPeriodLength = 0;
    for (final cycle in cycles) {
      totalPeriodLength = (totalPeriodLength + cycle.periodLength) as int;
    }
    final averagePeriodLength = (totalPeriodLength / cycles.length).round();

    String regularity = 'regular';
    if (cycles.length >= 3) {
      final cycleLengths = cycles.map((c) => c.cycleLength).toList();
      final minLength = cycleLengths.reduce((a, b) => a < b ? a : b);
      final maxLength = cycleLengths.reduce((a, b) => a > b ? a : b);
      final variation = maxLength - minLength;

      if (variation <= 7) {
        regularity = 'very_regular';
      } else if (variation <= 14) {
        regularity = 'regular';
      } else {
        regularity = 'irregular';
      }
    } else {
      regularity = 'insufficient_data';
    }

    return {
      'averageCycleLength': averageCycleLength,
      'averagePeriodLength': averagePeriodLength,
      'regularity': regularity,
      'totalCycles': cycles.length,
    };
  }

  Widget _buildHealthScoreCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wellness Score',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.w600,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: 0.85,
                  strokeWidth: 12,
                  backgroundColor: AppTheme.palePink,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryPink),
                ),
              ),
            ),
            ResponsiveConfig.heightBox(16),
            Center(
              child: Text(
                '85',
                style: ResponsiveConfig.textStyle(
                  size: 32,
                  weight: FontWeight.bold,
                  color: AppTheme.primaryPink,
                ),
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Center(
              child: Text(
                'Your wellness score',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
