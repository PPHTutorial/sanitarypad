import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/cycle_provider.dart';
import '../../../services/cycle_service.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../core/widgets/empty_state.dart';

/// Cycles list screen - displays all saved cycles
class CyclesListScreen extends ConsumerStatefulWidget {
  const CyclesListScreen({super.key});

  @override
  ConsumerState<CyclesListScreen> createState() => _CyclesListScreenState();
}

class _CyclesListScreenState extends ConsumerState<CyclesListScreen> {
  final _cycleService = CycleService();

  Future<void> _deleteCycle(String cycleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cycle'),
        content:
            const Text('Are you sure you want to delete this cycle entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _cycleService.deleteCycle(cycleId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cycle deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cyclesAsync = ref.watch(cyclesStreamProvider);
    final cycles = cyclesAsync.value ?? [];

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('All Cycles'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                context.push('/log-period');
              },
              tooltip: 'Add New Cycle',
            ),
          ],
        ),
        body: SafeArea(
          bottom: true,
          top: false,
          child: cycles.isEmpty
              ? EmptyState(
                  title: 'No Cycles Yet',
                  icon: Icons.calendar_today_outlined,
                  message:
                      'Start tracking your menstrual cycle to see your history here',
                  actionLabel: 'Log Period',
                  onAction: () {
                    context.push('/log-period');
                  },
                )
              : ListView.builder(
                  padding: ResponsiveConfig.padding(all: 16),
                  itemCount: cycles.length,
                  itemBuilder: (context, index) {
                    final cycle = cycles[index];
                    return Card(
                      shadowColor: Colors.black.withValues(alpha: 0.08),
                      margin: ResponsiveConfig.margin(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          context.push('/log-period', extra: cycle);
                        },
                        child: Padding(
                          padding: ResponsiveConfig.padding(all: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Cycle ${cycles.length - index}',
                                          style: ResponsiveConfig.textStyle(
                                            size: 16,
                                            weight: FontWeight.bold,
                                          ),
                                        ),
                                        ResponsiveConfig.heightBox(4),
                                        Text(
                                          DateFormat('MMM dd, yyyy')
                                              .format(cycle.startDate),
                                          style: ResponsiveConfig.textStyle(
                                            size: 14,
                                            color: AppTheme.mediumGray,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () {
                                          context.push('/log-period',
                                              extra: cycle);
                                        },
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: AppTheme.errorRed,
                                        onPressed: () =>
                                            _deleteCycle(cycle.cycleId),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ResponsiveConfig.heightBox(12),
                              Row(
                                children: [
                                  _buildCycleInfo(
                                    icon: Icons.calendar_today,
                                    label: 'Cycle Length',
                                    value: '${cycle.cycleLength} days',
                                  ),
                                  ResponsiveConfig.widthBox(22),
                                  _buildCycleInfo(
                                    icon: Icons.water_drop,
                                    label: 'Period Length',
                                    value: '${cycle.periodLength} days',
                                  ),
                                ],
                              ),
                              ResponsiveConfig.heightBox(16),
                              Row(
                                children: [
                                  _buildCycleInfo(
                                    icon: Icons.speed,
                                    label: 'Flow',
                                    value: cycle.flowIntensity.toUpperCase(),
                                  ),
                                  if (cycle.symptoms.isNotEmpty) ...[
                                    ResponsiveConfig.widthBox(22),
                                    _buildCycleInfo(
                                      icon: Icons.medical_services,
                                      label: 'Symptoms',
                                      value: '${cycle.symptoms.length}',
                                    ),
                                  ],
                                ],
                              ),
                              if (cycle.notes != null &&
                                  cycle.notes!.isNotEmpty) ...[
                                ResponsiveConfig.heightBox(16),
                                Text(
                                  cycle.notes!,
                                  style: ResponsiveConfig.textStyle(
                                    size: 12,
                                    color: AppTheme.mediumGray,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildCycleInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: ResponsiveConfig.iconSize(20),
            color: AppTheme.primaryPink,
          ),
          ResponsiveConfig.widthBox(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: ResponsiveConfig.textStyle(
                    size: 12,
                    weight: FontWeight.w600,
                  ),
                ),
                Text(
                  label,
                  style: ResponsiveConfig.textStyle(
                    size: 10,
                    color: AppTheme.mediumGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
