import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sanitarypad/core/theme/app_theme.dart';
import 'package:sanitarypad/core/config/responsive_config.dart';
import 'package:sanitarypad/models/workout_models.dart';
import 'package:sanitarypad/services/workout_service.dart';
import 'package:sanitarypad/services/video_feed_service.dart';
import 'package:sanitarypad/services/video_overlay_service.dart';
import 'package:sanitarypad/services/credit_manager.dart';

class WorkoutProgramScreen extends ConsumerWidget {
  final WorkoutProgram program;
  final String userId;

  const WorkoutProgramScreen({
    super.key,
    required this.program,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrolledAsync = ref.watch(enrolledProgramIdsProvider(userId));
    final isEnrolled = enrolledAsync.value?.contains(program.id) ?? false;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(program.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (program.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: program.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.primaryPink.withOpacity(0.1),
                        child: const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primaryPink)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.primaryPink.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            FontAwesomeIcons.dumbbell,
                            color: AppTheme.primaryPink.withOpacity(0.2),
                            size: 80,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(color: AppTheme.primaryPink),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    children: [
                      _Badge(
                          label: program.difficulty.displayName,
                          icon: Icons.speed,
                          color: Colors.orange),
                      const SizedBox(width: 12),
                      _Badge(
                          label: '${program.durationWeeks} Weeks',
                          icon: Icons.calendar_today,
                          color: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text('About the Program',
                      style: ResponsiveConfig.textStyle(
                          size: 18, weight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(program.description,
                      style: ResponsiveConfig.textStyle(
                          size: 14, color: Colors.grey[600])),
                  const SizedBox(height: 24),

                  // Goals
                  Text('What you\'ll achieve',
                      style: ResponsiveConfig.textStyle(
                          size: 18, weight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...program.goals.map((goal) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 12),
                            Text(goal,
                                style: ResponsiveConfig.textStyle(size: 14)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 32),

                  // Schedule/Workouts
                  Text('Weekly Schedule',
                      style: ResponsiveConfig.textStyle(
                          size: 18, weight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (program.schedule.isEmpty)
                    const Text('Schedule details coming soon...',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.grey))
                  else
                    ...program.schedule.map((day) => _DayCard(
                          day: day,
                          programName: program.name,
                        )),

                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (isEnrolled) {
            await ref
                .read(workoutServiceProvider)
                .unenrollFromProgram(userId, program.id);
          } else {
            await ref
                .read(workoutServiceProvider)
                .enrollInProgram(userId, program.id);
          }
        },
        backgroundColor: isEnrolled ? Colors.grey : AppTheme.primaryPink,
        label: Text(isEnrolled ? 'UNENROLL' : 'START PROGRAM',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        icon: Icon(isEnrolled ? Icons.close : Icons.play_arrow),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Badge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final ProgramDay day;
  final String programName;
  const _DayCard({required this.day, required this.programName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap:
            day.exercises.isEmpty ? null : () => _showDayDetails(context, day),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${day.dayNumber}',
                      style: const TextStyle(
                          color: AppTheme.primaryPink,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(day.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (day.isRestDay)
                      const Text('Rest Day',
                          style: TextStyle(color: Colors.grey, fontSize: 12))
                    else
                      Text(
                          '${day.estimatedDuration.inMinutes} mins • ${day.exercises.length} Exercises',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              if (!day.isRestDay)
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayDetails(BuildContext context, ProgramDay day) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPink.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      'Day ${day.dayNumber}',
                      style: const TextStyle(
                        color: AppTheme.primaryPink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day.title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          '${day.estimatedDuration.inMinutes} mins • ${day.exercises.length} Exercises',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colorScheme.outline.withOpacity(0.03)),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: day.exercises.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1, color: colorScheme.outline.withOpacity(0.03)),
                itemBuilder: (context, index) {
                  final exercise = day.exercises[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            //borderRadius: BorderRadius.circular(8),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (exercise.sets != null)
                                    _DetailBadge(
                                      text: '${exercise.sets} Sets',
                                      color: Colors.blue,
                                    ),
                                  if (exercise.reps != null) ...[
                                    const SizedBox(width: 8),
                                    _DetailBadge(
                                      text: '${exercise.reps} Reps',
                                      color: Colors.purple,
                                    ),
                                  ],
                                  if (exercise.duration != null) ...[
                                    const SizedBox(width: 8),
                                    _DetailBadge(
                                      text: '${exercise.duration!.inSeconds}s',
                                      color: Colors.orange,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showExerciseVideos(
                              context, programName, day.title, exercise.name),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(FontAwesomeIcons.video,
                                size: 16, color: AppTheme.primaryPink),
                          ),
                        ),
                        ResponsiveConfig.widthBox(8)
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseVideos(BuildContext context, String programName,
      String dayTitle, String exerciseName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            Consumer(builder: (context, ref, child) {
          // Construct query based on user request: program + day + exercise
          final query = '$exerciseName $programName $dayTitle';
          final videosAsync = ref.watch(workoutVideoSearchProvider(query));

          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Related Videos',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: videosAsync.when(
                  data: (videos) {
                    if (videos.isEmpty) {
                      return const Center(child: Text('No videos found'));
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: videos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final video = videos[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () async {
                              final creditManager =
                                  ref.read(creditManagerProvider);
                              final hasCredits =
                                  await creditManager.requestCredit(
                                context,
                                ActionType.videoWatch,
                              );

                              if (hasCredits) {
                                await creditManager
                                    .consumeCredits(ActionType.videoWatch);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ref
                                      .read(videoOverlayProvider.notifier)
                                      .playVideo(video.videoId);
                                }
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: video.thumbnailUrl,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.error)),
                                      ),
                                      const Center(
                                        child: Icon(Icons.play_circle_fill,
                                            color: Colors.white, size: 48),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.7),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${video.duration.inMinutes}:${(video.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        video.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        video.channelName ?? 'Unknown Channel',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) =>
                      Center(child: Text('Error: $err', maxLines: 2)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _DetailBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
