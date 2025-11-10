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

/// Comprehensive insights and analytics screen
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  final _insightsService = InsightsService();

  @override
  Widget build(BuildContext context) {
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
          future: _insightsService.getComprehensiveInsights(),
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
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Health Score',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.w600,
              ),
            ),
            ResponsiveConfig.heightBox(24),
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
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryPink,
                  size: ResponsiveConfig.iconSize(24),
                ),
                ResponsiveConfig.widthBox(8),
                Text(
                  'Cycle Statistics',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Avg Cycle',
                    '${cycleData['averageCycleLength'] ?? 0} days',
                    Icons.timeline,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Avg Period',
                    '${cycleData['averagePeriodLength'] ?? 0} days',
                    Icons.water_drop,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total',
                    '${cycleData['totalCycles'] ?? 0} cycles',
                    Icons.history,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(16),
            _buildRegularityIndicator(
              context,
              cycleData['regularity'] as String? ?? '',
            ),
            if (cycles.length >= 2) ...[
              ResponsiveConfig.heightBox(16),
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
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: AppTheme.primaryPink,
                  size: ResponsiveConfig.iconSize(24),
                ),
                ResponsiveConfig.widthBox(8),
                Text(
                  'Wellness Insights',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Hydration',
                    '${wellnessData['averageHydration']?.toStringAsFixed(1) ?? '0'} glasses',
                    Icons.water_drop,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Sleep',
                    '${wellnessData['averageSleep']?.toStringAsFixed(1) ?? '0'} hrs',
                    Icons.bedtime,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Energy',
                    '${wellnessData['averageEnergy']?.toStringAsFixed(1) ?? '0'}/5',
                    Icons.bolt,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(36),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Wellness Score',
                    '${wellnessData['wellnessScore']?.round() ?? 0}/100',
                    Icons.star,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Exercise',
                    '${wellnessData['exerciseFrequency']?.toStringAsFixed(0) ?? '0'}%',
                    Icons.fitness_center,
                  ),
                ),
              ],
            ),
            if ((wellnessData['mostCommonMoods'] as List?)?.isNotEmpty ==
                true) ...[
              ResponsiveConfig.heightBox(24),
              Text(
                'Most Common Moods',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  weight: FontWeight.w600,
                ),
              ),
              ResponsiveConfig.heightBox(8),
              ...(wellnessData['mostCommonMoods'] as List)
                  .take(3)
                  .map((mood) => Padding(
                        padding: ResponsiveConfig.padding(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.mood,
                              size: ResponsiveConfig.iconSize(16),
                              color: AppTheme.primaryPink,
                            ),
                            ResponsiveConfig.widthBox(8),
                            Expanded(
                              child: Text(
                                '${mood['emotion']} (${mood['frequency']}%)',
                                style: ResponsiveConfig.textStyle(size: 14),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
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
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.egg,
                  color: AppTheme.primaryPink,
                  size: ResponsiveConfig.iconSize(24),
                ),
                ResponsiveConfig.widthBox(8),
                Text(
                  'Fertility Insights',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(16),
            if (fertilityData['averageBBT'] != null &&
                fertilityData['averageBBT'] > 0)
              _buildStatItem(
                context,
                'Avg BBT',
                '${fertilityData['averageBBT']?.toStringAsFixed(1) ?? '0'}°C',
                Icons.thermostat,
              ),
            if (fertilityData['ovulationPrediction'] != null) ...[
              ResponsiveConfig.heightBox(16),
              Text(
                'Predicted Ovulation',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  weight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              ResponsiveConfig.heightBox(4),
              Text(
                _formatDate(fertilityData['ovulationPrediction'] as DateTime),
                style: ResponsiveConfig.textStyle(
                  size: 16,
                  weight: FontWeight.bold,
                  color: AppTheme.primaryPink,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (fertilityData['fertileWindow'] != null) ...[
              ResponsiveConfig.heightBox(8),
              Text(
                'Fertile Window',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  weight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              ResponsiveConfig.heightBox(4),
              Text(
                '${_formatDate((fertilityData['fertileWindow'] as Map)['start'] as DateTime)} - ${_formatDate((fertilityData['fertileWindow'] as Map)['end'] as DateTime)}',
                style: ResponsiveConfig.textStyle(size: 14),
                textAlign: TextAlign.center,
              ),
            ],
            if (fertilityData['confidence'] != null) ...[
              ResponsiveConfig.heightBox(8),
              Text(
                'Confidence: ${(fertilityData['confidence'] as double).toStringAsFixed(0)}%',
                style: ResponsiveConfig.textStyle(
                  size: 12,
                  color: AppTheme.mediumGray,
                ),
                textAlign: TextAlign.center,
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
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.face,
                  color: AppTheme.primaryPink,
                  size: ResponsiveConfig.iconSize(24),
                ),
                ResponsiveConfig.widthBox(8),
                Text(
                  'Skincare Insights',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Routines',
                    '${skincareData['totalRoutines'] ?? 0}',
                    Icons.spa,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Products',
                    '${skincareData['totalProducts'] ?? 0}',
                    Icons.inventory_2,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Per Week',
                    '${skincareData['averageRoutinesPerWeek']?.toStringAsFixed(1) ?? '0'}',
                    Icons.calendar_view_week,
                  ),
                ),
              ],
            ),
            if (skincareData['expiringProducts'] != null &&
                skincareData['expiringProducts'] > 0) ...[
              ResponsiveConfig.heightBox(16),
              Container(
                padding: ResponsiveConfig.padding(all: 12),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.1),
                  borderRadius: ResponsiveConfig.borderRadius(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: AppTheme.warningOrange,
                      size: ResponsiveConfig.iconSize(20),
                    ),
                    ResponsiveConfig.widthBox(12),
                    Expanded(
                      child: Text(
                        '${skincareData['expiringProducts']} products expiring soon',
                        style: ResponsiveConfig.textStyle(
                          size: 14,
                          color: AppTheme.warningOrange,
                        ),
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
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medical_services,
                  color: AppTheme.primaryPink,
                  size: ResponsiveConfig.iconSize(24),
                ),
                ResponsiveConfig.widthBox(8),
                Text(
                  'Pad Usage Insights',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Changes',
                    '${padData['totalChanges'] ?? 0}',
                    Icons.swap_horiz,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Per Day',
                    '${padData['averageChangesPerDay']?.toStringAsFixed(1) ?? '0'}',
                    Icons.today,
                  ),
                ),
                if (padData['mostUsedType'] != null)
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Most Used',
                      padData['mostUsedType'] as String,
                      Icons.star,
                    ),
                  ),
              ],
            ),
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
