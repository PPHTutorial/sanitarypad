import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../core/widgets/femcare_bottom_nav.dart';
import '../../../data/models/cycle_model.dart';

class CyclesMainScreen extends ConsumerWidget {
  const CyclesMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCycle = ref.watch(activeCycleProvider);
    final cyclesAsync = ref.watch(cyclesStreamProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cycles Hub'),
          actions: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.gear, size: 20),
              onPressed: () => context.push('/cycle-settings'),
              tooltip: 'Settings',
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.clockRotateLeft, size: 20),
              onPressed: () => context.push('/cycles-list'),
              tooltip: 'Cycle History',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: ResponsiveConfig.padding(all: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeCycle != null) ...[
                _buildCyclePhaseCard(context, activeCycle),
                ResponsiveConfig.heightBox(24),
              ] else
                _buildNoCycleCard(context),
              _buildQuickActions(context),
              ResponsiveConfig.heightBox(24),
              _buildSettingsSection(context),
              ResponsiveConfig.heightBox(24),
              _buildHistorySection(context, cyclesAsync),
            ],
          ),
        ),
        bottomNavigationBar:
            const FemCareBottomNav(currentRoute: '/cycles-main'),
      ),
    );
  }

  Widget _buildCyclePhaseCard(BuildContext context, dynamic cycle) {
    final now = DateTime.now();
    final cycleDay = cycle.getCycleDay(now);

    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 20),
        child: Column(
          children: [
            Row(
              children: [
                FaIcon(FontAwesomeIcons.calendarDay,
                    color: AppTheme.primaryPink),
                ResponsiveConfig.widthBox(12),
                Text(
                  'Current Phase',
                  style: ResponsiveConfig.textStyle(
                      size: 18, weight: FontWeight.bold),
                ),
              ],
            ),
            ResponsiveConfig.heightBox(20),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: (cycleDay / 28).clamp(0.0, 1.0),
                      strokeWidth: 12,
                      backgroundColor: AppTheme.lightPink,
                      color: AppTheme.primaryPink,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        'Day',
                        style: ResponsiveConfig.textStyle(
                            size: 14, color: AppTheme.mediumGray),
                      ),
                      Text(
                        '$cycleDay',
                        style: ResponsiveConfig.textStyle(
                            size: 32,
                            weight: FontWeight.bold,
                            color: AppTheme.primaryPink),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCycleCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: ResponsiveConfig.padding(all: 24),
        child: Column(
          children: [
            FaIcon(FontAwesomeIcons.calendarPlus,
                size: 48, color: AppTheme.mediumGray),
            ResponsiveConfig.heightBox(16),
            const Text('No active cycle tracking'),
            ResponsiveConfig.heightBox(16),
            ElevatedButton(
              onPressed: () => context.push('/log-period'),
              child: const Text('Start Tracking'),
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
        const Text('Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ResponsiveConfig.heightBox(12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                context,
                icon: FontAwesomeIcons.droplet,
                label: 'Log Period',
                onTap: () => context.push('/log-period'),
              ),
            ),
            ResponsiveConfig.widthBox(12),
            Expanded(
              child: _buildActionTile(
                context,
                icon: FontAwesomeIcons.toiletPaper,
                label: 'Pads',
                onTap: () => context.push('/pad-management'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      color: AppTheme.palePink,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              FaIcon(icon, color: AppTheme.primaryPink),
              ResponsiveConfig.heightBox(8),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.primaryPink,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Preferences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ResponsiveConfig.heightBox(12),
        Card(
          elevation: 0,
          borderOnForeground: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.mediumGray.withOpacity(0.1)),
          ),
          child: ListTile(
            leading: const FaIcon(FontAwesomeIcons.gear,
                size: 20, color: AppTheme.primaryPink),
            title: const Text('Cycle Settings'),
            subtitle: const Text('Length, reminders, and predictions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/cycle-settings'),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(
      BuildContext context, AsyncValue<List<CycleModel>> cyclesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => context.push('/cycles-list'),
              child: const Text('See All'),
            ),
          ],
        ),
        ResponsiveConfig.heightBox(8),
        cyclesAsync.when(
          data: (cycles) {
            if (cycles.isEmpty) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No history yet'),
              ));
            }
            final recentCycles = cycles.take(3).toList();
            return Column(
              children: recentCycles
                  .map((cycle) => _buildCycleHistoryCard(context, cycle))
                  .toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error: $err'),
        ),
      ],
    );
  }

  Widget _buildCycleHistoryCard(BuildContext context, CycleModel cycle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: ResponsiveConfig.borderRadius(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.primaryPink.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/log-period', extra: cycle),
        borderRadius: ResponsiveConfig.borderRadius(16),
        child: Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.lightPink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.calendarCheck,
                    color: AppTheme.primaryPink,
                    size: 20,
                  ),
                ),
              ),
              ResponsiveConfig.widthBox(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('MMM dd').format(cycle.startDate)} - ${cycle.endDate != null ? DateFormat('MMM dd').format(cycle.endDate!) : 'Ongoing'}',
                      style: ResponsiveConfig.textStyle(
                        size: 15,
                        weight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cycle.cycleLength} Days • ${cycle.flowIntensity.toUpperCase()} FLOW',
                      style: ResponsiveConfig.textStyle(
                        size: 12,
                        color: AppTheme.mediumGray,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.mediumGray),
            ],
          ),
        ),
      ),
    );
  }
}
