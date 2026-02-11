import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/responsive_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/wellness_model.dart';
import '../../../../services/wellness_service.dart';

/// Premium detail preview dialog for a wellness journal entry
class WellnessJournalDetailDialog extends StatelessWidget {
  final WellnessModel entry;
  final VoidCallback? onDeleted;

  const WellnessJournalDetailDialog({
    super.key,
    required this.entry,
    this.onDeleted,
  });

  static Future<void> show(
    BuildContext context, {
    required WellnessModel entry,
    VoidCallback? onDeleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WellnessJournalDetailDialog(
        entry: entry,
        onDeleted: onDeleted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.mediumGray.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: ResponsiveConfig.padding(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE').format(entry.date),
                          style: ResponsiveConfig.textStyle(
                            size: 14,
                            color: AppTheme.mediumGray,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(entry.date),
                          style: ResponsiveConfig.textStyle(
                            size: 22,
                            weight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Edit Button
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push('/wellness-journal', extra: entry);
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPink.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: AppTheme.primaryPink,
                              size: 20,
                            ),
                          ),
                        ),
                        // Delete Button
                        IconButton(
                          onPressed: () => _confirmDelete(context),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: AppTheme.errorRed,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 24),

              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding:
                      ResponsiveConfig.padding(horizontal: 20, vertical: 8),
                  children: [
                    // Mood Section
                    _buildSectionHeader('Mood & Energy'),
                    ResponsiveConfig.heightBox(12),
                    _buildMoodCard(),
                    ResponsiveConfig.heightBox(20),

                    // Emotions
                    if (entry.mood.emotions.isNotEmpty) ...[
                      _buildSectionHeader('Emotions'),
                      ResponsiveConfig.heightBox(8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.mood.emotions.map((emotion) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryPink.withOpacity(0.15),
                                  AppTheme.accentCoral.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryPink.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              emotion,
                              style: ResponsiveConfig.textStyle(
                                size: 13,
                                weight: FontWeight.w600,
                                color: AppTheme.primaryPink,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      ResponsiveConfig.heightBox(20),
                    ],

                    // Stats Grid
                    _buildSectionHeader('Daily Stats'),
                    ResponsiveConfig.heightBox(12),
                    _buildStatsGrid(),
                    ResponsiveConfig.heightBox(20),

                    // Mental Health
                    if (_hasMentalHealthData()) ...[
                      _buildSectionHeader('Mental Health'),
                      ResponsiveConfig.heightBox(12),
                      _buildMentalHealthCard(),
                      ResponsiveConfig.heightBox(20),
                    ],

                    // Exercise
                    if (entry.exercise != null) ...[
                      _buildSectionHeader('Exercise'),
                      ResponsiveConfig.heightBox(12),
                      _buildExerciseCard(),
                      ResponsiveConfig.heightBox(20),
                    ],

                    // Journal
                    if (entry.journal != null && entry.journal!.isNotEmpty) ...[
                      _buildSectionHeader('Journal'),
                      ResponsiveConfig.heightBox(12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkGray.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.mediumGray.withOpacity(0.15),
                          ),
                        ),
                        child: Text(
                          entry.journal!,
                          style: ResponsiveConfig.textStyle(
                            size: 14,
                            color: AppTheme.darkGray,
                            height: 1.6,
                          ),
                        ),
                      ),
                      ResponsiveConfig.heightBox(20),
                    ],

                    // Photos
                    if (entry.photoUrls != null &&
                        entry.photoUrls!.isNotEmpty) ...[
                      _buildSectionHeader(
                          'Photos (${entry.photoUrls!.length})'),
                      ResponsiveConfig.heightBox(12),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: entry.photoUrls!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: entry.photoUrls![index],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 120,
                                  height: 120,
                                  color: AppTheme.mediumGray.withOpacity(0.1),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      ResponsiveConfig.heightBox(20),
                    ],

                    // PMS Related
                    if (entry.mood.pmsRelated == true) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCoral.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentCoral.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppTheme.accentCoral, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'PMS-related entry',
                              style: ResponsiveConfig.textStyle(
                                size: 13,
                                weight: FontWeight.w600,
                                color: AppTheme.accentCoral,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ResponsiveConfig.heightBox(20),
                    ],

                    ResponsiveConfig.heightBox(40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: ResponsiveConfig.textStyle(
        size: 16,
        weight: FontWeight.w700,
        color: AppTheme.darkGray,
      ),
    );
  }

  Widget _buildMoodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPink.withOpacity(0.08),
            AppTheme.accentCoral.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPink.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          // Big Emoji
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPink.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                entry.mood.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Energy',
                      style: ResponsiveConfig.textStyle(
                        size: 13,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(5, (i) {
                      return Icon(
                        Icons.bolt,
                        size: 18,
                        color: i < entry.mood.energyLevel
                            ? AppTheme.primaryPink
                            : AppTheme.mediumGray.withOpacity(0.3),
                      );
                    }),
                  ],
                ),
                if (entry.mood.description != null &&
                    entry.mood.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.mood.description!,
                    style: ResponsiveConfig.textStyle(
                      size: 14,
                      color: AppTheme.darkGray,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            icon: Icons.local_drink,
            label: 'Hydration',
            value: '${entry.hydration.waterGlasses}/${entry.hydration.goal}',
            subtitle: 'glasses',
            color: Colors.blue,
            progress: entry.hydration.progress.clamp(0.0, 1.0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            icon: Icons.bedtime,
            label: 'Sleep',
            value: '${entry.sleep.hours.toStringAsFixed(1)}h',
            subtitle: 'Quality ${entry.sleep.quality}/5',
            color: Colors.indigo,
            progress: (entry.sleep.quality / 5).clamp(0.0, 1.0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            icon: Icons.restaurant,
            label: 'Appetite',
            value: entry.appetite.level,
            subtitle: entry.appetite.notes ?? '',
            color: AppTheme.successGreen,
            progress: entry.appetite.level == 'high'
                ? 1.0
                : entry.appetite.level == 'normal'
                    ? 0.66
                    : 0.33,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: ResponsiveConfig.textStyle(
              size: 16,
              weight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: ResponsiveConfig.textStyle(
              size: 11,
              color: AppTheme.mediumGray,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasMentalHealthData() {
    return entry.mood.stressLevel != null ||
        entry.mood.anxietyLevel != null ||
        entry.mood.depressionLevel != null ||
        (entry.mood.mentalHealthNotes != null &&
            entry.mood.mentalHealthNotes!.isNotEmpty);
  }

  Widget _buildMentalHealthCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mediumGray.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          if (entry.mood.stressLevel != null)
            _buildLevelRow('Stress', entry.mood.stressLevel!, Colors.orange),
          if (entry.mood.anxietyLevel != null) ...[
            const SizedBox(height: 12),
            _buildLevelRow('Anxiety', entry.mood.anxietyLevel!, Colors.purple),
          ],
          if (entry.mood.depressionLevel != null) ...[
            const SizedBox(height: 12),
            _buildLevelRow(
                'Depression', entry.mood.depressionLevel!, Colors.blueGrey),
          ],
          if (entry.mood.mentalHealthNotes != null &&
              entry.mood.mentalHealthNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              entry.mood.mentalHealthNotes!,
              style: ResponsiveConfig.textStyle(
                size: 13,
                color: AppTheme.mediumGray,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelRow(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: ResponsiveConfig.textStyle(
              size: 13,
              weight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 10,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(
                value >= 7 ? AppTheme.errorRed : color,
              ),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value/10',
          style: ResponsiveConfig.textStyle(
            size: 13,
            weight: FontWeight.bold,
            color: value >= 7 ? AppTheme.errorRed : color,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard() {
    final exercise = entry.exercise!;
    final intensityColor = exercise.intensity == 'vigorous'
        ? AppTheme.errorRed
        : exercise.intensity == 'moderate'
            ? AppTheme.accentCoral
            : AppTheme.successGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: intensityColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: intensityColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: intensityColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fitness_center, color: intensityColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.type,
                  style: ResponsiveConfig.textStyle(
                    size: 16,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${exercise.duration} min',
                      style: ResponsiveConfig.textStyle(
                        size: 13,
                        color: AppTheme.mediumGray,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: intensityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        exercise.intensity,
                        style: ResponsiveConfig.textStyle(
                          size: 11,
                          weight: FontWeight.w700,
                          color: intensityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Entry?'),
        content: Text(
          'Are you sure you want to delete this wellness entry for ${DateFormat('MMM dd, yyyy').format(entry.date)}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Close bottom sheet
              try {
                await WellnessService().deleteWellnessEntry(entry.entryId);
                onDeleted?.call();
              } catch (e) {
                debugPrint('Error deleting entry: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
