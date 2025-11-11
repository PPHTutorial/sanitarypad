import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../services/wellness_service.dart';
import '../../../data/models/wellness_model.dart';
import '../../../core/widgets/back_button_handler.dart';
import '../../../core/widgets/empty_state.dart';

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
                // Navigate to form for creating new entry
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
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
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
      margin: ResponsiveConfig.margin(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to form for editing existing entry
          context.push('/wellness-journal', extra: entry);
        },
        child: Padding(
          padding: ResponsiveConfig.padding(all: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy').format(entry.date),
                    style: ResponsiveConfig.textStyle(
                      size: 18,
                      weight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      context.push('/wellness-journal', extra: entry);
                    },
                    tooltip: 'Edit',
                  ),
                ],
              ),
              ResponsiveConfig.heightBox(12),

              // Quick Stats
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildStatChip(
                    Icons.local_drink,
                    '${entry.hydration.waterGlasses} glasses',
                    AppTheme.primaryPink,
                  ),
                  _buildStatChip(
                    Icons.bedtime,
                    '${entry.sleep.hours.toStringAsFixed(1)}h',
                    AppTheme.accentCoral,
                  ),
                  _buildStatChip(
                    Icons.mood,
                    entry.mood.emoji,
                    AppTheme.successGreen,
                  ),
                  if (entry.exercise != null)
                    _buildStatChip(
                      Icons.fitness_center,
                      '${entry.exercise!.duration}min',
                      AppTheme.infoBlue,
                    ),
                ],
              ),
              ResponsiveConfig.heightBox(12),

              // Mood Description
              if (entry.mood.description != null &&
                  entry.mood.description!.isNotEmpty)
                Text(
                  entry.mood.description!,
                  style: ResponsiveConfig.textStyle(
                    size: 14,
                    color: AppTheme.mediumGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              // Journal Preview
              if (entry.journal != null && entry.journal!.isNotEmpty) ...[
                ResponsiveConfig.heightBox(8),
                Text(
                  entry.journal!,
                  style: ResponsiveConfig.textStyle(
                    size: 14,
                    color: AppTheme.mediumGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Photo Count
              if (entry.photoUrls != null && entry.photoUrls!.isNotEmpty) ...[
                ResponsiveConfig.heightBox(8),
                Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      size: 16,
                      color: AppTheme.mediumGray,
                    ),
                    ResponsiveConfig.widthBox(4),
                    Text(
                      '${entry.photoUrls!.length} photo${entry.photoUrls!.length > 1 ? 's' : ''}',
                      style: ResponsiveConfig.textStyle(
                        size: 12,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: ResponsiveConfig.padding(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          ResponsiveConfig.widthBox(6),
          Text(
            label,
            style: ResponsiveConfig.textStyle(
              size: 12,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
