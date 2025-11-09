import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;

/// Home screen - Main dashboard
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCycle = ref.watch(activeCycleProvider);
    final predictionsAsync = ref.watch(cyclePredictionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('FemCare+'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.go('/profile');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cycle Status Card
            _buildCycleStatusCard(
                context, ref, activeCycle, predictionsAsync.value),
            ResponsiveConfig.heightBox(16),

            // Quick Actions
            _buildQuickActions(context),
            ResponsiveConfig.heightBox(16),

            // Today's Wellness
            _buildTodaysWellness(context),
            ResponsiveConfig.heightBox(16),

            // Upcoming Reminders
            _buildReminders(context),
            ResponsiveConfig.heightBox(16),

            // Quick Tips
            _buildQuickTips(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildCycleStatusCard(
    BuildContext context,
    WidgetRef ref,
    cycle,
    predictions,
  ) {
    if (cycle == null) {
      return Card(
        child: Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cycle Status',
                style: ResponsiveConfig.textStyle(
                  size: 18,
                  weight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              ResponsiveConfig.heightBox(12),
              Text(
                'No cycle data yet. Log your first period to get started!',
                style: ResponsiveConfig.textStyle(
                  size: 14,
                  color: AppTheme.mediumGray,
                ),
              ),
              ResponsiveConfig.heightBox(12),
              ElevatedButton(
                onPressed: () => context.go('/log-period'),
                child: const Text('Log Period'),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final cycleDay = cycle.getCycleDay(now);
    final phase =
        app_date_utils.DateUtils.getCyclePhase(cycle.startDate, cycleDay);
    final daysUntilPeriod = predictions?.isNotEmpty == true
        ? (predictions![0]['predictedStartDate'] as DateTime)
            .difference(now)
            .inDays
        : null;

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cycle Status',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryPink,
                  size: ResponsiveConfig.iconSize(24),
                ),
                ResponsiveConfig.widthBox(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day $cycleDay of Cycle',
                        style: ResponsiveConfig.textStyle(
                          size: 16,
                          weight: FontWeight.w600,
                        ),
                      ),
                      ResponsiveConfig.heightBox(4),
                      Text(
                        phase.replaceFirst(phase[0], phase[0].toUpperCase()),
                        style: ResponsiveConfig.textStyle(
                          size: 14,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                if (daysUntilPeriod != null) ...[
                  Text(
                    '$daysUntilPeriod days',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      weight: FontWeight.w600,
                      color: AppTheme.primaryPink,
                    ),
                  ),
                  ResponsiveConfig.widthBox(4),
                  Text(
                    'until period',
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      color: AppTheme.mediumGray,
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

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: ResponsiveConfig.textStyle(
            size: 18,
            weight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        ResponsiveConfig.heightBox(12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.water_drop,
                label: 'Log Period',
                onTap: () => context.go('/log-period'),
              ),
            ),
            ResponsiveConfig.widthBox(12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.medical_services_outlined,
                label: 'Log Symptom',
                onTap: () {
                  // Navigate to symptom logging
                },
              ),
            ),
          ],
        ),
        ResponsiveConfig.heightBox(12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.sanitizer,
                label: 'Pad Change',
                onTap: () => context.go('/pad-management'),
              ),
            ),
            ResponsiveConfig.widthBox(12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.favorite_outline,
                label: 'Wellness',
                onTap: () => context.go('/wellness-journal'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: ResponsiveConfig.borderRadius(12),
      child: Container(
        padding: ResponsiveConfig.padding(all: 16),
        decoration: BoxDecoration(
          color: AppTheme.palePink,
          borderRadius: ResponsiveConfig.borderRadius(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryPink,
              size: ResponsiveConfig.iconSize(32),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              label,
              style: ResponsiveConfig.textStyle(
                size: 14,
                weight: FontWeight.w500,
                color: AppTheme.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysWellness(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Wellness",
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            _buildWellnessItem(
              context,
              icon: Icons.mood,
              label: 'Mood',
              value: '😊 Happy',
            ),
            ResponsiveConfig.heightBox(12),
            _buildWellnessItem(
              context,
              icon: Icons.water_drop_outlined,
              label: 'Hydration',
              value: '6/8 glasses',
            ),
            ResponsiveConfig.heightBox(12),
            _buildWellnessItem(
              context,
              icon: Icons.bedtime_outlined,
              label: 'Sleep',
              value: '7.5 hours',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWellnessItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryPink,
          size: ResponsiveConfig.iconSize(20),
        ),
        ResponsiveConfig.widthBox(12),
        Text(
          label,
          style: ResponsiveConfig.textStyle(
            size: 14,
            color: AppTheme.mediumGray,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: ResponsiveConfig.textStyle(
            size: 14,
            weight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReminders(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Reminders',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            _buildReminderItem(
              context,
              'Pad change in 2 hours',
              Icons.sanitizer,
            ),
            ResponsiveConfig.heightBox(8),
            _buildReminderItem(
              context,
              'Period starts in 3 days',
              Icons.calendar_today,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderItem(
    BuildContext context,
    String text,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryPink,
          size: ResponsiveConfig.iconSize(20),
        ),
        ResponsiveConfig.widthBox(12),
        Expanded(
          child: Text(
            text,
            style: ResponsiveConfig.textStyle(
              size: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTips(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Tip',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            ResponsiveConfig.heightBox(12),
            Text(
              'During your follicular phase, focus on strength training. Your body is primed for building muscle!',
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

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/calendar');
            break;
          case 2:
            context.go('/insights');
            break;
          case 3:
            context.go('/wellness');
            break;
          case 4:
            context.go('/profile');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.insights_outlined),
          activeIcon: Icon(Icons.insights),
          label: 'Insights',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline),
          activeIcon: Icon(Icons.favorite),
          label: 'Wellness',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
