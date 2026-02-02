import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../core/widgets/femcare_bottom_nav.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../services/insights_service.dart';
import '../../../services/ads_service.dart';

/// Comprehensive insights and analytics screen
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  @override
  Widget build(BuildContext context) {
    final insightsService = ref.watch(insightsServiceProvider);
    final cyclesAsync = ref.watch(cyclesStreamProvider);
    final cycles = cyclesAsync.value ?? [];

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Insights'),
        ),
        bottomNavigationBar: const FemCareBottomNav(currentRoute: '/insights'),
        body: FutureBuilder<Map<String, dynamic>>(
          future: insightsService.getComprehensiveInsights(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: ResponsiveConfig.iconSize(64),
                      color: AppTheme.errorRed,
                    ),
                    ResponsiveConfig.heightBox(16),
                    Text(
                      'Error loading insights',
                      style: ResponsiveConfig.textStyle(
                        size: 18,
                        weight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveConfig.heightBox(8),
                    Text(
                      snapshot.error.toString(),
                      style: ResponsiveConfig.textStyle(
                        size: 14,
                        color: AppTheme.mediumGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final insights = snapshot.data ?? {};
            final hasAnyData = _hasAnyData(insights);

            if (!hasAnyData) {
              return _buildEmptyState(context);
            }

            return SingleChildScrollView(
              padding: ResponsiveConfig.padding(all: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Health Score
                  if (insights['overallHealth'] != null)
                    _buildOverallHealthScoreCard(
                      context,
                      insights['overallHealth'] as double,
                    ),
                  ResponsiveConfig.heightBox(16),
                  const NativeAdWidget(),
                  if (insights['overallHealth'] != null)
                    ResponsiveConfig.heightBox(16),

                  // Cycle Statistics
                  if (insights['cycles'] != null &&
                      (insights['cycles'] as Map)['hasData'] == true)
                    _buildCycleInsightsCard(
                      context,
                      insights['cycles'] as Map<String, dynamic>,
                      cycles,
                    ),
                  if (insights['cycles'] != null &&
                      (insights['cycles'] as Map)['hasData'] == true)
                    ResponsiveConfig.heightBox(16),

                  // Wellness Insights
                  if (insights['wellness'] != null &&
                      (insights['wellness'] as Map)['hasData'] == true)
                    _buildWellnessInsightsCard(
                      context,
                      insights['wellness'] as Map<String, dynamic>,
                    ),
                  if (insights['wellness'] != null &&
                      (insights['wellness'] as Map)['hasData'] == true)
                    ResponsiveConfig.heightBox(16),

                  // Fertility Insights
                  if (insights['fertility'] != null &&
                      (insights['fertility'] as Map)['hasData'] == true)
                    _buildFertilityInsightsCard(
                      context,
                      insights['fertility'] as Map<String, dynamic>,
                    ),
                  if (insights['fertility'] != null &&
                      (insights['fertility'] as Map)['hasData'] == true)
                    ResponsiveConfig.heightBox(16),

                  // Skincare Insights
                  if (insights['skincare'] != null &&
                      (insights['skincare'] as Map)['hasData'] == true)
                    _buildSkincareInsightsCard(
                      context,
                      insights['skincare'] as Map<String, dynamic>,
                    ),
                  if (insights['skincare'] != null &&
                      (insights['skincare'] as Map)['hasData'] == true)
                    ResponsiveConfig.heightBox(16),

                  // Pad Usage Insights
                  if (insights['pads'] != null &&
                      (insights['pads'] as Map)['hasData'] == true)
                    _buildPadInsightsCard(
                      context,
                      insights['pads'] as Map<String, dynamic>,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  bool _hasAnyData(Map<String, dynamic> insights) {
    return (insights['cycles'] as Map?)?['hasData'] == true ||
        (insights['wellness'] as Map?)?['hasData'] == true ||
        (insights['fertility'] as Map?)?['hasData'] == true ||
        (insights['skincare'] as Map?)?['hasData'] == true ||
        (insights['pads'] as Map?)?['hasData'] == true ||
        insights['overallHealth'] != null;
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
              'Start logging your cycles, wellness, and other health data to see comprehensive insights',
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

  Widget _buildOverallHealthScoreCard(
    BuildContext context,
    double score,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveConfig.borderRadius(16),
        side: BorderSide(color: AppTheme.mediumGray.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              context,
              title: 'Overall Health Score',
              icon: Icons.health_and_safety,
              color: _getScoreColor(score),
            ),
            ResponsiveConfig.heightBox(4),
            Center(
              child: _buildCustomHealthScoreCircle(score),
            ),
            ResponsiveConfig.heightBox(16),
            Center(
              child: Text(
                _getScoreMessage(score),
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                  weight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppTheme.successGreen;
    if (score >= 60) return AppTheme.infoBlue;
    if (score >= 40) return AppTheme.warningOrange;
    return AppTheme.errorRed;
  }

  String _getScoreMessage(double score) {
    if (score >= 80) return 'Excellent! Keep up the great work!';
    if (score >= 60) return 'Good! You\'re on the right track.';
    if (score >= 40) return 'Fair. Consider improving your wellness habits.';
    return 'Needs improvement. Focus on your health and wellness.';
  }

  Widget _buildCycleInsightsCard(
    BuildContext context,
    Map<String, dynamic> cycleData,
    List cycles,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveConfig.borderRadius(16),
        side: BorderSide(color: AppTheme.mediumGray.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              context,
              title: 'Cycle Statistics',
              icon: Icons.calendar_today,
              color: AppTheme.primaryPink,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    context,
                    label: 'Avg Cycle',
                    value: '${cycleData['averageCycleLength'] ?? 0}',
                    subtitle: 'DAYS',
                    icon: Icons.timeline,
                  ),
                ),
                ResponsiveConfig.widthBox(12),
                Expanded(
                  child: _buildStatTile(
                    context,
                    label: 'Avg Period',
                    value: '${cycleData['averagePeriodLength'] ?? 0}',
                    subtitle: 'DAYS',
                    icon: Icons.water_drop,
                  ),
                ),
                ResponsiveConfig.widthBox(12),
                Expanded(
                  child: _buildStatTile(
                    context,
                    label: 'History',
                    value: '${cycleData['totalCycles'] ?? 0}',
                    subtitle: 'CYCLES',
                    icon: Icons.history,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(20),
            _buildRegularityIndicator(
              context,
              cycleData['regularity'] as String? ?? '',
            ),
            if (cycles.length >= 2) ...[
              _buildDivider(),
              _buildCycleLengthChart(context, cycles),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWellnessInsightsCard(
    BuildContext context,
    Map<String, dynamic> wellnessData,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveConfig.borderRadius(16),
        side: BorderSide(color: AppTheme.mediumGray.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              context,
              title: 'Wellness Insights',
              icon: Icons.auto_awesome,
              color: AppTheme.infoBlue,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    context,
                    label: 'Hydration',
                    value:
                        '${wellnessData['averageHydration']?.toStringAsFixed(1) ?? '0'}',
                    subtitle: 'GLASSES',
                    icon: Icons.water_drop,
                    color: AppTheme.infoBlue,
                  ),
                ),
                ResponsiveConfig.widthBox(12),
                Expanded(
                  child: _buildStatTile(
                    context,
                    label: 'Sleep',
                    value:
                        '${wellnessData['averageSleep']?.toStringAsFixed(1) ?? '0'}',
                    subtitle: 'HOURS',
                    icon: Icons.bedtime,
                    color: AppTheme.lavender,
                  ),
                ),
                ResponsiveConfig.widthBox(12),
                Expanded(
                  child: _buildStatTile(
                    context,
                    label: 'Energy',
                    value:
                        '${wellnessData['averageEnergy']?.toStringAsFixed(1) ?? '0'}',
                    subtitle: '/ 5',
                    icon: Icons.bolt,
                    color: AppTheme.warningOrange,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(12),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    context,
                    label: 'Wellness Score',
                    value: '${wellnessData['wellnessScore']?.round() ?? 0}',
                    subtitle: '/ 100',
                    icon: Icons.star,
                  ),
                ),
                ResponsiveConfig.widthBox(12),
                Expanded(
                  child: _buildStatTile(
                    context,
                    label: 'Exercise',
                    value:
                        '${wellnessData['exerciseFrequency']?.toStringAsFixed(0) ?? '0'}%',
                    subtitle: 'CONSISTENCY',
                    icon: Icons.fitness_center,
                    color: AppTheme.successGreen,
                  ),
                ),
              ],
            ),
            if ((wellnessData['mostCommonMoods'] as List?)?.isNotEmpty ==
                true) ...[
              _buildDivider(),
              Text(
                'DOMINANT MOODS',
                style: ResponsiveConfig.textStyle(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppTheme.mediumGray,
                  letterSpacing: 0.5,
                ),
              ),
              ResponsiveConfig.heightBox(16),
              ...(wellnessData['mostCommonMoods'] as List)
                  .take(3)
                  .map((mood) => Padding(
                        padding: ResponsiveConfig.padding(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: ResponsiveConfig.padding(all: 6),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.primaryPink.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.mood,
                                size: ResponsiveConfig.iconSize(14),
                                color: AppTheme.primaryPink,
                              ),
                            ),
                            ResponsiveConfig.widthBox(12),
                            Expanded(
                              child: Text(
                                mood['emotion'],
                                style: ResponsiveConfig.textStyle(
                                  size: 15,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${mood['frequency']}%',
                              style: ResponsiveConfig.textStyle(
                                size: 14,
                                color: AppTheme.mediumGray,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFertilityInsightsCard(
    BuildContext context,
    Map<String, dynamic> fertilityData,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveConfig.borderRadius(16),
        side: BorderSide(color: AppTheme.mediumGray.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              context,
              title: 'Fertility Insights',
              icon: Icons.egg,
              color: AppTheme.primaryPink,
            ),
            if (fertilityData['averageBBT'] != null &&
                fertilityData['averageBBT'] > 0)
              _buildStatTile(
                context,
                label: 'Avg BBT',
                value:
                    '${fertilityData['averageBBT']?.toStringAsFixed(1) ?? '0'}°C',
                subtitle: 'MORNING BASELINE',
                icon: Icons.thermostat,
                color: AppTheme.warningOrange,
              ),
            if (fertilityData['ovulationPrediction'] != null) ...[
              if (fertilityData['averageBBT'] != null)
                ResponsiveConfig.heightBox(16),
              _buildStatTile(
                context,
                label: 'Predicted Ovulation',
                value: _formatDate(
                    fertilityData['ovulationPrediction'] as DateTime),
                subtitle: 'NEXT EXPECTED',
                icon: Icons.event,
              ),
            ],
            if (fertilityData['fertileWindow'] != null) ...[
              ResponsiveConfig.heightBox(12),
              _buildStatTile(
                context,
                label: 'Fertile Window',
                value:
                    '${_formatDate((fertilityData['fertileWindow'] as Map)['start'] as DateTime)} - ${_formatDate((fertilityData['fertileWindow'] as Map)['end'] as DateTime)}',
                subtitle: 'PEAK CHANCE',
                icon: Icons.wb_sunny_outlined,
                color: AppTheme.successGreen,
              ),
            ],
            if (fertilityData['confidence'] != null) ...[
              ResponsiveConfig.heightBox(12),
              Text(
                'PREDICTION CONFIDENCE: ${(fertilityData['confidence'] as double).toStringAsFixed(0)}%',
                style: ResponsiveConfig.textStyle(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppTheme.mediumGray.withValues(alpha: 0.6),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkincareInsightsCard(
    BuildContext context,
    Map<String, dynamic> skincareData,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveConfig.borderRadius(16),
        side: BorderSide(color: AppTheme.mediumGray.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              context,
              title: 'Skincare Insights',
              icon: Icons.face,
              color: AppTheme.lavender,
            ),
            Column(
              children: [
                _buildStatTile(
                  context,
                  label: 'Routines',
                  value: '${skincareData['totalRoutines'] ?? 0}',
                  subtitle: 'COMPLETED',
                  icon: Icons.spa,
                  color: AppTheme.lavender,
                ),
                ResponsiveConfig.heightBox(12),
                _buildStatTile(
                  context,
                  label: 'Products',
                  value: '${skincareData['totalProducts'] ?? 0}',
                  subtitle: 'IN INVENTORY',
                  icon: Icons.inventory_2,
                ),
                ResponsiveConfig.heightBox(12),
                _buildStatTile(
                  context,
                  label: 'Per Week',
                  value:
                      '${skincareData['averageRoutinesPerWeek']?.toStringAsFixed(1) ?? '0'}',
                  subtitle: 'FREQUENCY',
                  icon: Icons.calendar_view_week,
                  color: AppTheme.infoBlue,
                ),
              ],
            ),
            if (skincareData['expiringProducts'] != null &&
                skincareData['expiringProducts'] > 0) ...[
              ResponsiveConfig.heightBox(16),
              Container(
                padding: ResponsiveConfig.padding(all: 12),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withValues(alpha: 0.08),
                  borderRadius: ResponsiveConfig.borderRadius(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.warningOrange,
                      size: ResponsiveConfig.iconSize(20),
                    ),
                    ResponsiveConfig.widthBox(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expiring Products',
                            style: ResponsiveConfig.textStyle(
                              size: 14,
                              weight: FontWeight.bold,
                              color: AppTheme.warningOrange,
                            ),
                          ),
                          Text(
                            '${skincareData['expiringProducts']} items need your attention',
                            style: ResponsiveConfig.textStyle(
                              size: 12,
                              color:
                                  AppTheme.warningOrange.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPadInsightsCard(
    BuildContext context,
    Map<String, dynamic> padData,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveConfig.borderRadius(16),
        side: BorderSide(color: AppTheme.mediumGray.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              context,
              title: 'Pad Usage Insights',
              icon: Icons.medical_services,
              color: AppTheme.primaryPink,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    context,
                    label: 'Total Changes',
                    value: '${padData['totalChanges'] ?? 0}',
                    subtitle: 'LOGGED',
                    icon: Icons.swap_horiz,
                  ),
                ),
                ResponsiveConfig.widthBox(12),
                Expanded(
                  child: _buildStatTile(
                    context,
                    label: 'Per Day',
                    value:
                        '${padData['averageChangesPerDay']?.toStringAsFixed(1) ?? '0'}',
                    subtitle: 'DAILY AVG',
                    icon: Icons.today,
                    color: AppTheme.infoBlue,
                  ),
                ),
                if (padData['mostUsedType'] != null) ...[
                  ResponsiveConfig.widthBox(12),
                  Expanded(
                    child: _buildStatTile(
                      context,
                      label: 'Most Used',
                      value: padData['mostUsedType'] as String,
                      subtitle: 'PREFERENCE',
                      icon: Icons.star,
                      color: AppTheme.successGreen,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: ResponsiveConfig.padding(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: ResponsiveConfig.padding(all: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: ResponsiveConfig.borderRadius(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: ResponsiveConfig.iconSize(20),
            ),
          ),
          ResponsiveConfig.widthBox(12),
          Text(
            title,
            style: ResponsiveConfig.textStyle(
              size: 18,
              weight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: ResponsiveConfig.padding(vertical: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppTheme.mediumGray.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? color,
    String? subtitle,
  }) {
    final themeColor = color ?? AppTheme.primaryPink;
    return Container(
      padding: ResponsiveConfig.padding(all: 12),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.04),
        borderRadius: ResponsiveConfig.borderRadius(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: themeColor,
                size: ResponsiveConfig.iconSize(14),
              ),
              ResponsiveConfig.widthBox(6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: ResponsiveConfig.textStyle(
                    size: 11,
                    weight: FontWeight.w700,
                    color: AppTheme.mediumGray,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          ResponsiveConfig.heightBox(12),
          Text(
            value,
            style: ResponsiveConfig.textStyle(
              size: 18,
              weight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            ResponsiveConfig.heightBox(2),
            Text(
              subtitle,
              style: ResponsiveConfig.textStyle(
                size: 12,
                color: AppTheme.mediumGray,
              ),
            ),
          ],
        ],
      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cycle Length Trend',
          style: ResponsiveConfig.textStyle(
            size: 14,
            weight: FontWeight.w600,
          ),
        ),
        ResponsiveConfig.heightBox(8),
        SizedBox(
          height: 150,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.primaryPink,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCustomHealthScoreCircle(double score) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CustomPaint(
            size: const Size(220, 220),
            painter: _HealthScorePainter(
              progress: score / 100,
              backgroundColor: AppTheme.palePink,
              progressColor: _getScoreColor(score),
              strokeWidth: 16,
            ),
          ),
          // Score text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                score.round().toString(),
                style: ResponsiveConfig.textStyle(
                  size: 48,
                  weight: FontWeight.bold,
                  color: _getScoreColor(score),
                ),
              ),
              Text(
                '/ 100',
                style: ResponsiveConfig.textStyle(
                  size: 20,
                  color: AppTheme.mediumGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for health score circular progress
class _HealthScorePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _HealthScorePainter({
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

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_HealthScorePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
