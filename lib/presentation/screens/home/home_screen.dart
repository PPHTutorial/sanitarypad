import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../core/widgets/femcare_bottom_nav.dart';

/// Home screen - Blank dashboard for users to add their data
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCycle = ref.watch(activeCycleProvider);

    return Scaffold(
      extendBodyBehindAppBar: false, // Keep AppBar on top but transparent
      backgroundColor: Colors.transparent, // Use theme background
      appBar: AppBar(
        title: const Text('FemCare+'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              context.go('/red-flag-alerts');
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
            // Welcome Message
            _buildWelcomeCard(context),
            ResponsiveConfig.heightBox(16),

            // Cycle Status Card (only if cycle exists)
            if (activeCycle != null) ...[
              _buildCycleStatusCard(context, ref, activeCycle),
              ResponsiveConfig.heightBox(16),
            ],

            // Quick Actions
            _buildQuickActions(context),
            ResponsiveConfig.heightBox(16),

            // Get Started Section (if no data)
            if (activeCycle == null) _buildGetStartedSection(context),
          ],
        ),
      ),
      bottomNavigationBar: const FemCareBottomNav(currentRoute: '/home'),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to FemCare+',
              style: ResponsiveConfig.textStyle(
                size: 24,
                weight: FontWeight.bold,
                color: AppTheme.primaryPink,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Start tracking your health and wellness journey today.',
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

  Widget _buildCycleStatusCard(
    BuildContext context,
    WidgetRef ref,
    cycle,
  ) {
    final now = DateTime.now();
    final cycleDay = cycle.getCycleDay(now);

    return Card(
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Cycle',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    // Navigate to edit current cycle
                    context.push('/log-period', extra: cycle);
                  },
                ),
              ],
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
                        'Started ${_formatDate(cycle.startDate)}',
                        style: ResponsiveConfig.textStyle(
                          size: 14,
                          color: AppTheme.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
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
          ),
        ),
        ResponsiveConfig.heightBox(12),
        // First Row: Period & Pad
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
                icon: Icons.sanitizer,
                label: 'Pad Change',
                onTap: () => context.go('/pad-management'),
              ),
            ),
          ],
        ),
        ResponsiveConfig.heightBox(12),
        // Second Row: Wellness & Calendar
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.favorite_outline,
                label: 'Wellness',
                onTap: () => context.go('/wellness-journal-list'),
              ),
            ),
            ResponsiveConfig.widthBox(12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.calendar_today,
                label: 'Calendar',
                onTap: () => context.go('/calendar'),
              ),
            ),
          ],
        ),
        ResponsiveConfig.heightBox(12),
        // Third Row: Pregnancy & Fertility
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.child_care,
                label: 'Pregnancy',
                onTap: () => context.go('/pregnancy-tracking'),
              ),
            ),
            ResponsiveConfig.widthBox(12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.egg,
                label: 'Fertility',
                onTap: () => context.go('/fertility-tracking'),
              ),
            ),
          ],
        ),
        ResponsiveConfig.heightBox(12),
        // Fourth Row: Skincare
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.face,
                label: 'Skincare',
                onTap: () => context.go('/skincare-tracking'),
              ),
            ),
            ResponsiveConfig.widthBox(12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.insights,
                label: 'Insights',
                onTap: () => context.go('/insights'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGetStartedSection(BuildContext context) {
    return Card(
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: ResponsiveConfig.padding(all: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rocket_launch,
                  color: AppTheme.primaryPink,
                  size: ResponsiveConfig.iconSize(28),
                ),
                ResponsiveConfig.widthBox(12),
                Text(
                  'Get Started',
                  style: ResponsiveConfig.textStyle(
                    size: 20,
                    weight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(16),
            Text(
              'Start tracking your menstrual cycle to unlock personalized insights and predictions.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            ElevatedButton.icon(
              onPressed: () => context.go('/log-period'),
              icon: const Icon(Icons.add),
              label: const Text('Log Your First Period'),
              style: ElevatedButton.styleFrom(
                padding: ResponsiveConfig.padding(vertical: 16, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
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
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).cardColor
              : AppTheme.palePink,
          borderRadius: ResponsiveConfig.borderRadius(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkGray
                : AppTheme.lightPink,
            width: 1,
          ),
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
                color: AppTheme.primaryPink,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
