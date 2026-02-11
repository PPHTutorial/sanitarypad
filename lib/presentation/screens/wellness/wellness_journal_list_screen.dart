import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/wellness_service.dart';
import '../../../data/models/wellness_model.dart';
import 'package:sanitarypad/presentation/widgets/ads/eco_ad_wrapper.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../core/widgets/empty_state.dart';
import 'widgets/wellness_journal_detail_dialog.dart';

/// Wellness journal list screen - displays recent wellness entries
class WellnessJournalListScreen extends ConsumerStatefulWidget {
  const WellnessJournalListScreen({super.key});

  @override
  ConsumerState<WellnessJournalListScreen> createState() =>
      _WellnessJournalListScreenState();
}

class _WellnessJournalListScreenState
    extends ConsumerState<WellnessJournalListScreen> {
  final _wellnessService = WellnessService();

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BackButtonHandler(
      fallbackRoute: '/wellness',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Wellness Journal'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                context.push('/wellness-journal');
              },
              tooltip: 'Add Entry',
            ),
          ],
        ),
        body: StreamBuilder<List<WellnessModel>>(
          stream: _wellnessService.watchWellnessEntries(user.userId, limit: 50),
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
                      'Error: ${snapshot.error}',
                      style: ResponsiveConfig.textStyle(
                        size: 14,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              );
            }

            final entries = snapshot.data ?? [];

            if (entries.isEmpty) {
              return EmptyState(
                title: 'No Wellness Entries',
                icon: Icons.self_improvement,
                message: 'Start tracking your wellness journey',
                actionLabel: 'Add Entry',
                onAction: () {
                  context.push('/wellness-journal');
                },
              );
            }

            return ListView.builder(
              padding: ResponsiveConfig.padding(all: 16),
              itemCount: entries.length + (entries.length > 2 ? 1 : 0),
              itemBuilder: (context, index) {
                if (entries.length > 2 && index == 2) {
                  return const EcoAdWrapper(adType: AdType.native);
                }
                final actualIndex =
                    (entries.length > 2 && index > 2) ? index - 1 : index;
                final entry = entries[actualIndex];
                return _buildEntryCard(context, entry);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, WellnessModel entry) {
    return Card(
      margin: ResponsiveConfig.margin(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => WellnessJournalDetailDialog.show(context, entry: entry),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: ResponsiveConfig.padding(all: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPink.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        entry.mood.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMM d').format(entry.date),
                            style: ResponsiveConfig.textStyle(
                              size: 18,
                              weight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            DateFormat('h:mm a').format(entry.date),
                            style: ResponsiveConfig.textStyle(
                              size: 13,
                              color: AppTheme.mediumGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (entry.mood.pmsRelated == true)
                      _buildBadge('PMS', AppTheme.accentCoral),
                  ],
                ),

                ResponsiveConfig.heightBox(20),

                // 2. Primary Stats Grid (2x2)
                Row(
                  children: [
                    Expanded(
                      child: _buildDashboardItem(
                        icon: Icons.bolt,
                        label: 'Energy',
                        value: '${entry.mood.energyLevel}/5',
                        color: Colors.amber.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDashboardItem(
                        icon: Icons.local_drink,
                        label: 'Hydration',
                        value: '${entry.hydration.waterGlasses} gl',
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDashboardItem(
                        icon: Icons.bedtime,
                        label: 'Sleep',
                        value: '${entry.sleep.hours.toStringAsFixed(1)}h',
                        color: Colors.indigo.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDashboardItem(
                        icon: Icons.restaurant,
                        label: 'Appetite',
                        value: entry.appetite.level.toUpperCase(),
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),

                // 3. Sleep Schedule Detail (if available)
                if (entry.sleep.bedtime != null ||
                    entry.sleep.wakeTime != null) ...[
                  ResponsiveConfig.heightBox(16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 16, color: Colors.indigo.shade300),
                        const SizedBox(width: 12),
                        if (entry.sleep.bedtime != null)
                          Text(
                            'Bed: ${DateFormat('h:mm a').format(entry.sleep.bedtime!)}',
                            style: ResponsiveConfig.textStyle(
                                size: 12, color: AppTheme.darkGray),
                          ),
                        if (entry.sleep.bedtime != null &&
                            entry.sleep.wakeTime != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward,
                                size: 12, color: Colors.grey.shade400),
                          ),
                        if (entry.sleep.wakeTime != null)
                          Text(
                            'Wake: ${DateFormat('h:mm a').format(entry.sleep.wakeTime!)}',
                            style: ResponsiveConfig.textStyle(
                                size: 12, color: AppTheme.darkGray),
                          ),
                      ],
                    ),
                  ),
                ],

                // 4. Exercise Detail (if available)
                if (entry.exercise != null) ...[
                  ResponsiveConfig.heightBox(12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.infoBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fitness_center,
                            size: 16, color: AppTheme.infoBlue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${entry.exercise!.type} • ${entry.exercise!.intensity}',
                            style: ResponsiveConfig.textStyle(
                                size: 13,
                                weight: FontWeight.w600,
                                color: AppTheme.darkGray),
                          ),
                        ),
                        Text(
                          '${entry.exercise!.duration} min',
                          style: ResponsiveConfig.textStyle(
                              size: 13,
                              weight: FontWeight.bold,
                              color: AppTheme.infoBlue),
                        ),
                      ],
                    ),
                  ),
                ],

                // 5. Mental Health Detail (if indicators exist)
                if (entry.mood.stressLevel != null ||
                    entry.mood.anxietyLevel != null) ...[
                  ResponsiveConfig.heightBox(16),
                  Row(
                    children: [
                      if (entry.mood.stressLevel != null)
                        Expanded(
                          child: _buildMiniMetric(
                            'Stress',
                            entry.mood.stressLevel!,
                            Colors.orange,
                          ),
                        ),
                      if (entry.mood.stressLevel != null &&
                          entry.mood.anxietyLevel != null)
                        const SizedBox(width: 12),
                      if (entry.mood.anxietyLevel != null)
                        Expanded(
                          child: _buildMiniMetric(
                            'Anxiety',
                            entry.mood.anxietyLevel!,
                            Colors.purple,
                          ),
                        ),
                    ],
                  ),
                ],

                // 6. Emotions
                if (entry.mood.emotions.isNotEmpty) ...[
                  ResponsiveConfig.heightBox(20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.mood.emotions
                        .map((e) => _buildBadge(
                            e, AppTheme.primaryPink.withOpacity(0.8)))
                        .toList(),
                  ),
                ],

                // 7. Photos (if available)
                if (entry.photoUrls != null && entry.photoUrls!.isNotEmpty) ...[
                  ResponsiveConfig.heightBox(16),
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: entry.photoUrls!.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return Container(
                          width: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(entry.photoUrls![index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // 8. Journal Preview
                if (entry.journal != null && entry.journal!.isNotEmpty) ...[
                  ResponsiveConfig.heightBox(20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Text(
                      entry.journal!,
                      style: ResponsiveConfig.textStyle(
                        size: 14,
                        color: AppTheme.darkGray,
                        height: 1.5,
                      ).copyWith(fontStyle: FontStyle.italic),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                // 9. Alerts
                if (entry.mood.hasConcerningIndicators) ...[
                  ResponsiveConfig.heightBox(16),
                  _buildAlertBox('Elevated levels detected'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: ResponsiveConfig.textStyle(
                  size: 11, color: AppTheme.mediumGray),
            ),
            Text(
              '$value/10',
              style: ResponsiveConfig.textStyle(
                  size: 11, weight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: value / 10,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: ResponsiveConfig.textStyle(
                  size: 11,
                  color: color.withOpacity(0.7),
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: ResponsiveConfig.textStyle(
              size: 15,
              weight: FontWeight.w800,
              color: AppTheme.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: ResponsiveConfig.textStyle(
          size: 12,
          weight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAlertBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: AppTheme.errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: ResponsiveConfig.textStyle(
                size: 12,
                color: AppTheme.errorRed,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
