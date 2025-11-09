import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/pregnancy_service.dart';
import '../../../data/models/pregnancy_model.dart';
import '../../../core/widgets/back_button_handler.dart';

/// Pregnancy tracking screen
class PregnancyTrackingScreen extends ConsumerStatefulWidget {
  const PregnancyTrackingScreen({super.key});

  @override
  ConsumerState<PregnancyTrackingScreen> createState() =>
      _PregnancyTrackingScreenState();
}

class _PregnancyTrackingScreenState
    extends ConsumerState<PregnancyTrackingScreen> {
  final _pregnancyService = PregnancyService();

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
        fallbackRoute: '/home',
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Pregnancy Tracking'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  context.push('/pregnancy-form');
                },
              ),
            ],
          ),
          body: FutureBuilder<Pregnancy?>(
            future: _pregnancyService.getActivePregnancy(user.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final pregnancy = snapshot.data;

              if (pregnancy == null) {
                return _buildEmptyState(context);
              }

              return _buildPregnancyView(context, pregnancy);
            },
          ),
        ));
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.child_care,
              size: ResponsiveConfig.iconSize(80),
              color: AppTheme.mediumGray,
            ),
            ResponsiveConfig.heightBox(24),
            Text(
              'No Active Pregnancy',
              style: ResponsiveConfig.textStyle(
                size: 24,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Start tracking your pregnancy journey',
              style: ResponsiveConfig.textStyle(
                size: 16,
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            ResponsiveConfig.heightBox(32),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/pregnancy-form');
              },
              icon: const Icon(Icons.add),
              label: const Text('Start Tracking'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPregnancyView(BuildContext context, Pregnancy pregnancy) {
    final milestones = _pregnancyService.getUpcomingMilestones(pregnancy);
    final completedMilestones =
        _pregnancyService.getCompletedMilestones(pregnancy);
    final currentMilestone = _pregnancyService.getCurrentMilestone(pregnancy);

    return SingleChildScrollView(
      padding: ResponsiveConfig.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress Card
          _buildProgressCard(pregnancy),
          ResponsiveConfig.heightBox(16),

          // Current Week Card
          _buildCurrentWeekCard(pregnancy, currentMilestone),
          ResponsiveConfig.heightBox(16),

          // Due Date Card
          _buildDueDateCard(pregnancy),
          ResponsiveConfig.heightBox(16),

          // Upcoming Milestones
          if (milestones.isNotEmpty) ...[
            Text(
              'Upcoming Milestones',
              style: ResponsiveConfig.textStyle(
                size: 20,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            ...milestones.take(3).map((milestone) {
              return _buildMilestoneCard(milestone, pregnancy);
            }).toList(),
            ResponsiveConfig.heightBox(16),
          ],

          // Completed Milestones
          if (completedMilestones.isNotEmpty) ...[
            Text(
              'Completed Milestones',
              style: ResponsiveConfig.textStyle(
                size: 20,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            ...completedMilestones.take(3).map((milestone) {
              return _buildMilestoneCard(milestone, pregnancy,
                  isCompleted: true);
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard(Pregnancy pregnancy) {
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
                  'Pregnancy Progress',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${pregnancy.progressPercentage.toStringAsFixed(0)}%',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                    color: AppTheme.primaryPink,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(16),
            LinearProgressIndicator(
              value: pregnancy.progressPercentage / 100,
              backgroundColor: AppTheme.palePink,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPink),
              minHeight: 8,
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Trimester ${pregnancy.trimester}',
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

  Widget _buildCurrentWeekCard(
    Pregnancy pregnancy,
    PregnancyMilestone? milestone,
  ) {
    return Card(
      color: AppTheme.lightPink,
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Week ${pregnancy.currentWeek}, Day ${pregnancy.currentDay}',
              style: ResponsiveConfig.textStyle(
                size: 24,
                weight: FontWeight.bold,
              ),
            ),
            if (milestone != null) ...[
              ResponsiveConfig.heightBox(8),
              Text(
                milestone.title,
                style: ResponsiveConfig.textStyle(
                  size: 16,
                  weight: FontWeight.w600,
                ),
              ),
              ResponsiveConfig.heightBox(4),
              Text(
                milestone.description,
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateCard(Pregnancy pregnancy) {
    final daysUntilDue = pregnancy.dueDate != null
        ? pregnancy.dueDate!.difference(DateTime.now()).inDays
        : 0;

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
                  'Due Date',
                  style: ResponsiveConfig.textStyle(
                    size: 14,
                    color: AppTheme.mediumGray,
                  ),
                ),
                ResponsiveConfig.heightBox(4),
                Text(
                  pregnancy.dueDate != null
                      ? '${pregnancy.dueDate!.day}/${pregnancy.dueDate!.month}/${pregnancy.dueDate!.year}'
                      : 'N/A',
                  style: ResponsiveConfig.textStyle(
                    size: 20,
                    weight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (daysUntilDue > 0)
              Container(
                padding: ResponsiveConfig.padding(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  borderRadius: ResponsiveConfig.borderRadius(8),
                ),
                child: Text(
                  '$daysUntilDue days to go',
                  style: ResponsiveConfig.textStyle(
                    size: 14,
                    weight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneCard(
    PregnancyMilestone milestone,
    Pregnancy pregnancy, {
    bool isCompleted = false,
  }) {
    final weeksUntil = milestone.week - pregnancy.currentWeek;

    return Card(
      margin: ResponsiveConfig.margin(bottom: 8),
      color: isCompleted ? AppTheme.lightPink : null,
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.circle_outlined,
          color: isCompleted ? AppTheme.successGreen : AppTheme.primaryPink,
        ),
        title: Text(milestone.title),
        subtitle: Text(milestone.description),
        trailing: isCompleted
            ? null
            : Text(
                weeksUntil > 0 ? '$weeksUntil weeks' : 'This week',
                style: ResponsiveConfig.textStyle(
                  size: 12,
                  color: AppTheme.mediumGray,
                ),
              ),
      ),
    );
  }
}
