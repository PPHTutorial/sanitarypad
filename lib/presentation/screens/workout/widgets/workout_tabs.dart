// Workout Tabs: Workouts, Log, Programs, Progress tabs

// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sanitarypad/models/workout_models.dart';
import 'package:sanitarypad/services/workout_service.dart';
import 'package:sanitarypad/services/video_feed_service.dart';
import 'package:sanitarypad/services/video_overlay_service.dart';
import 'package:sanitarypad/presentation/screens/workout/exercise_log_form_screen.dart';
import 'package:sanitarypad/presentation/screens/workout/workout_program_screen.dart';
import 'package:sanitarypad/services/credit_manager.dart';
import 'package:sanitarypad/core/theme/app_theme.dart';

// ============================================================================
// WORKOUTS TAB (Video Feed)
// ============================================================================
class WorkoutsTab extends ConsumerStatefulWidget {
  final String userId;
  const WorkoutsTab({super.key, required this.userId});

  @override
  ConsumerState<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends ConsumerState<WorkoutsTab> {
  VideoCategory _selectedCategory = VideoCategory.workout;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearch() async {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      final creditManager = ref.read(creditManagerProvider);
      final hasCredits = await creditManager.requestCredit(
        context,
        ActionType.workoutSearch,
      );

      if (hasCredits) {
        await creditManager.consumeCredits(ActionType.workoutSearch);
        setState(() {
          _isSearching = true;
        });
      }
    } else {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final videosAsync = _isSearching
        ? ref.watch(workoutVideoSearchProvider(_searchController.text))
        : ref.watch(workoutVideosByCategoryProvider(_selectedCategory));
    final savedVideosAsync =
        ref.watch(savedWorkoutVideosProvider(widget.userId));

    return CustomScrollView(
      slivers: [
        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search workouts (e.g. Abs, Yoga, HIIT)',
                prefixIcon: Icon(Icons.search, color: AppTheme.primaryPink),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (_) => _onSearch(),
              onChanged: (val) {
                if (val.isEmpty && _isSearching) {
                  setState(() => _isSearching = false);
                }
              },
            ),
          ),
        ),

        // Category Chips
        SliverToBoxAdapter(
          child: Container(
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                VideoCategory.workout,
                VideoCategory.yoga,
                VideoCategory.cardio,
                VideoCategory.strength,
                VideoCategory.hiit,
                VideoCategory.pilates,
              ]
                  .map((cat) => Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat.displayName),
                          selected: !_isSearching && _selectedCategory == cat,
                          onSelected: (_) {
                            _searchController.clear();
                            setState(() {
                              _selectedCategory = cat;
                              _isSearching = false;
                            });
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),

        // Saved Videos Section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Saved Workouts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        savedVideosAsync.when(
          data: (videos) {
            if (videos.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: const [
                        Icon(FontAwesomeIcons.bookmark,
                            color: Colors.grey, size: 32),
                        SizedBox(height: 8),
                        Text('No saved workouts yet',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              );
            }
            return SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: videos.length,
                  itemBuilder: (context, i) =>
                      _SavedVideoCard(video: videos[i]),
                ),
              ),
            );
          },
          loading: () => SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e')),
        ),

        // Video Feed Section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
                _isSearching
                    ? 'Search Results'
                    : '${_selectedCategory.displayName} Videos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        videosAsync.when(
          data: (videos) => SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) =>
                  _WorkoutVideoCard(video: videos[i], userId: widget.userId),
              childCount: videos.length,
            ),
          ),
          loading: () => SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator()))),
          error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Error loading videos: $e'))),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _SavedVideoCard extends StatelessWidget {
  final WorkoutVideo video;
  const _SavedVideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: video.thumbnailUrl,
              width: 200,
              height: 160,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 200,
                height: 160,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(Icons.video_library,
                      color: Colors.grey.withOpacity(0.5), size: 40),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [Colors.transparent, Colors.black87]),
            ),
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DifficultyBadge(difficulty: video.difficulty),
                SizedBox(height: 4),
                Text(video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                Text(_formatDuration(video.duration),
                    style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    return '$minutes min';
  }
}

class _DifficultyBadge extends StatelessWidget {
  final WorkoutDifficulty difficulty;
  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (difficulty) {
      case WorkoutDifficulty.beginner:
        color = Theme.of(context).colorScheme.secondary;
        break;
      case WorkoutDifficulty.intermediate:
        color = Theme.of(context).colorScheme.primaryContainer;
        break;
      case WorkoutDifficulty.advanced:
        color = Theme.of(context).colorScheme.primary;
        break;
      case WorkoutDifficulty.expert:
        color = Theme.of(context).colorScheme.onSurface;
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(difficulty.name.toUpperCase(),
          style: TextStyle(
              color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}

class _WorkoutVideoCard extends ConsumerStatefulWidget {
  final WorkoutVideo video;
  final String userId;
  const _WorkoutVideoCard({required this.video, required this.userId});

  @override
  ConsumerState<_WorkoutVideoCard> createState() => _WorkoutVideoCardState();
}

class _WorkoutVideoCardState extends ConsumerState<_WorkoutVideoCard> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.video.isSaved;
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final saved = await ref
        .read(workoutServiceProvider)
        .isVideoSaved(widget.userId, widget.video.videoId);
    if (mounted) setState(() => _isSaved = saved);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 100,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _playVideo(context),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(16)),
                  child: CachedNetworkImage(
                      imageUrl: widget.video.thumbnailUrl,
                      width: 120,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                          width: 120,
                          height: 100,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Icon(Icons.image_not_supported))),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(_formatDuration(widget.video.duration),
                        style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DifficultyBadge(difficulty: widget.video.difficulty),
                    SizedBox(height: 4),
                    Text(widget.video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    SizedBox(height: 4),
                    if (widget.video.channelName != null)
                      Text(widget.video.channelName!,
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color:
                      _isSaved ? Theme.of(context).colorScheme.primary : null),
              onPressed: _toggleSave,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _playVideo(BuildContext context) async {
    final creditManager = ref.read(creditManagerProvider);
    final hasCredits = await creditManager.requestCredit(
      context,
      ActionType.videoWatch,
    );

    if (hasCredits) {
      await creditManager.consumeCredits(ActionType.videoWatch);
      if (context.mounted) {
        ref.read(videoOverlayProvider.notifier).playVideo(widget.video.videoId);
      }
    }
  }

  Future<void> _toggleSave() async {
    final service = ref.read(workoutServiceProvider);
    if (_isSaved) {
      await service.unsaveVideo(widget.userId, widget.video.videoId);
    } else {
      await service.saveVideo(widget.userId, widget.video);
    }
    if (mounted) setState(() => _isSaved = !_isSaved);
  }
}

// ============================================================================
// LOG TAB
// ============================================================================
class LogTab extends ConsumerWidget {
  final String userId;
  const LogTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(todayExercisesProvider(userId));
    final activeSessionAsync = ref.watch(activeWorkoutSessionProvider(userId));

    return Column(
      children: [
        activeSessionAsync.when(
          data: (session) {
            if (session == null) return const SizedBox.shrink();
            // Filter exercises for this session
            final sessionExercises = exercisesAsync.value
                    ?.where((e) => e.sessionId == session.id)
                    .toList() ??
                [];
            return _ActiveSessionCard(
                session: session, userId: userId, exercises: sessionExercises);
          },
          loading: () => const SizedBox.shrink(),
          error: (e, _) => const SizedBox.shrink(),
        ),
        Expanded(
          child: exercisesAsync.when(
            data: (exercises) {
              // Only show exercises that are NOT part of the active session
              final activeSessionId = activeSessionAsync.value?.id;
              final standaloneExercises = exercises
                  .where((e) => e.sessionId != activeSessionId)
                  .toList();

              if (standaloneExercises.isEmpty && activeSessionId == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FontAwesomeIcons.clipboardList,
                          size: 60, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No exercises logged today',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ExerciseLogFormScreen(userId: userId))),
                        icon: Icon(Icons.add),
                        label: Text('Log Exercise'),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: standaloneExercises.length + 1,
                itemBuilder: (context, i) {
                  if (i == standaloneExercises.length) {
                    return SizedBox(height: 80);
                  }
                  return _ExerciseLogCard(
                      exercise: standaloneExercises[i], userId: userId);
                },
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}

class _ActiveSessionCard extends ConsumerWidget {
  final WorkoutSession session;
  final String userId;
  final List<ExerciseEntry> exercises;

  const _ActiveSessionCard(
      {required this.session, required this.userId, required this.exercises});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [
            Color(0xFFCC0066), // Deep Pink
            Color(0xFF99004C), // Darker Pink
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFCC0066).withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CURRENT SESSION',
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                        color: Colors.white.withOpacity(0.8),
                      )),
                  SizedBox(height: 4),
                  Text(
                    session.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(FontAwesomeIcons.personRunning,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
          SizedBox(height: 24),
          Center(
            child: _TimerWidget(startTime: session.startedAt, isSporty: true),
          ),
          SizedBox(height: 24),
          if (exercises.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white70, size: 16),
                  SizedBox(width: 8),
                  Text(
                    '${exercises.length} Exercises Completed',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ExerciseLogFormScreen(
                                userId: userId,
                                sessionId: session.id,
                              ))),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: Icon(Icons.add),
                  label: Text('LOG SET'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showEndWorkoutDialog(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFFCC0066),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: Icon(Icons.stop_circle),
                  label: Text('FINISH'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEndWorkoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('End Workout?'),
        content: Text('Are you finished with your current session?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('No')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(workoutServiceProvider)
                  .completeWorkoutSession(userId, session.id, session);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white),
            child: Text('Yes, Finish'),
          ),
        ],
      ),
    );
  }
}

class _TimerWidget extends StatefulWidget {
  final DateTime startTime;
  final bool isSporty;
  const _TimerWidget({required this.startTime, this.isSporty = false});

  @override
  State<_TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<_TimerWidget> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.startTime);
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds.remainder(60);
    final timeString = '$minutes:${seconds.toString().padLeft(2, '0')}';

    if (widget.isSporty) {
      return Text(
        timeString,
        style: TextStyle(
          fontFamily: 'Oswald',
          fontWeight: FontWeight.bold,
          fontSize: 48,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
      );
    }

    return Text(
      timeString,
      style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _ExerciseLogCard extends ConsumerWidget {
  final ExerciseEntry exercise;
  final String userId;
  const _ExerciseLogCard({required this.exercise, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(exercise.id),
      direction: DismissDirection.endToStart,
      background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20),
          color: Theme.of(context).colorScheme.error,
          child: Icon(Icons.delete, color: Colors.white)),
      onDismissed: (_) async {
        final exerciseToDelete = exercise;
        await ref
            .read(workoutServiceProvider)
            .deleteExercise(userId, exercise.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${exerciseToDelete.exerciseName} deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  await ref
                      .read(workoutServiceProvider)
                      .restoreExercise(userId, exerciseToDelete);
                },
              ),
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child: Text(exercise.category.icon,
                      style: TextStyle(fontSize: 22))),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.exerciseName,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      if (exercise.sets != null)
                        _StatChip(label: '${exercise.sets} sets'),
                      if (exercise.reps != null)
                        _StatChip(label: '${exercise.reps} reps'),
                      if (exercise.weight != null)
                        _StatChip(label: '${exercise.weight}kg'),
                      _StatChip(label: '${exercise.duration.inMinutes}min'),
                    ],
                  ),
                ],
              ),
            ),
            Text('${exercise.caloriesBurned} cal',
                // ignore: prefer_const_constructors
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  const _StatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 6),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: Theme.of(context).colorScheme.primary)),
    );
  }
}

// ============================================================================
// PROGRAMS TAB
// ============================================================================
class ProgramsTab extends ConsumerStatefulWidget {
  final String userId;
  const ProgramsTab({super.key, required this.userId});

  @override
  ConsumerState<ProgramsTab> createState() => _ProgramsTabState();
}

class _ProgramsTabState extends ConsumerState<ProgramsTab> {
  @override
  void initState() {
    super.initState();
    // Seed programs if they don't exist
    Future.microtask(() {
      ref.read(workoutServiceProvider).seedWorkoutPrograms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(availableProgramsProvider);
    final enrolledAsync = ref.watch(enrolledProgramIdsProvider(widget.userId));

    return programsAsync.when(
      data: (programs) {
        final enrolledIds = enrolledAsync.value ?? [];
        if (programs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(FontAwesomeIcons.dumbbell, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('No workout programs available',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: programs.length + 1,
          itemBuilder: (context, i) {
            if (i == programs.length) return SizedBox(height: 80);
            final program = programs[i];
            final isEnrolled = enrolledIds.contains(program.id);
            return _ProgramCard(
                program: program,
                isEnrolled: isEnrolled,
                userId: widget.userId);
          },
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ProgramCard extends ConsumerWidget {
  final WorkoutProgram program;
  final bool isEnrolled;
  final String userId;
  const _ProgramCard(
      {required this.program, required this.isEnrolled, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutProgramScreen(
              program: program,
              userId: userId,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        height: 250, // Fixed height for consistent layout
        child: Stack(
          children: [
            // Background Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: program.imageUrl ?? '',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Center(
                    child: Icon(
                      FontAwesomeIcons.dumbbell,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                      size: 60,
                    ),
                  ),
                ),
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8)
                    ]),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _DifficultyBadge(difficulty: program.difficulty),
                      Spacer(),
                      if (isEnrolled)
                        Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text('ENROLLED',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold))),
                    ],
                  ),
                  Spacer(),
                  Text(program.name,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(program.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(FontAwesomeIcons.calendarDays,
                          color: Colors.white70, size: 14),
                      SizedBox(width: 6),
                      Text('${program.durationWeeks} weeks',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      SizedBox(width: 16),
                      Icon(FontAwesomeIcons.clock,
                          color: Colors.white70, size: 14),
                      SizedBox(width: 6),
                      Text('${program.workoutsPerWeek}x/week',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                        backgroundColor: isEnrolled
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                        minimumSize: Size(double.infinity, 44)),
                    child: Text(isEnrolled ? 'Unenroll' : 'Start Program',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PROGRESS TAB
// ============================================================================
class ProgressTab extends ConsumerWidget {
  final String userId;
  const ProgressTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(progressPhotosProvider(userId));
    final measurementsAsync = ref.watch(measurementsProvider(userId));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Photos Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress Photos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _takePhoto(context, ref, userId),
                icon: Icon(Icons.add_a_photo, size: 18),
                label: Text('Add'),
              ),
            ],
          ),
          SizedBox(height: 12),
          photosAsync.when(
            data: (photos) {
              if (photos.isEmpty) {
                return Container(
                  height: 150,
                  decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16)),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(FontAwesomeIcons.camera,
                            size: 32, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No progress photos yet',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  itemBuilder: (context, i) =>
                      _ProgressPhotoCard(photo: photos[i]),
                ),
              );
            },
            loading: () => SizedBox(
                height: 150, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
          ),
          SizedBox(height: 24),

          // Body Measurements Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Body Measurements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _showMeasurementsForm(context, ref, userId),
                icon: Icon(Icons.add, size: 18),
                label: Text('Log'),
              ),
            ],
          ),
          SizedBox(height: 12),
          measurementsAsync.when(
            data: (measurements) {
              if (measurements.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16)),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(FontAwesomeIcons.ruler,
                            size: 32, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No measurements logged',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              final latest = measurements.first;
              return _MeasurementsCard(measurements: latest);
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
          SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _takePhoto(
      BuildContext context, WidgetRef ref, String userId) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      await ref
          .read(workoutServiceProvider)
          .uploadProgressPhoto(userId, File(image.path));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Photo saved!')));
      }
    }
  }

  void _showMeasurementsForm(
      BuildContext context, WidgetRef ref, String userId) {
    final weightController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log Measurements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final weight = double.tryParse(weightController.text);
                if (weight != null) {
                  await ref.read(workoutServiceProvider).logMeasurements(
                      userId,
                      BodyMeasurements(
                          id: '', measuredAt: DateTime.now(), weight: weight));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Measurements logged!')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50)),
              child: Text('Save'),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ProgressPhotoCard extends StatelessWidget {
  final ProgressPhoto photo;
  const _ProgressPhotoCard({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: photo.imageUrl,
              width: 120,
              height: 150,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 120,
                height: 150,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(Icons.image,
                      color: Colors.grey.withOpacity(0.5), size: 30),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [Colors.transparent, Colors.black54]),
            ),
            padding: EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('MMM d').format(photo.takenAt),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                if (photo.weight != null)
                  Text('${photo.weight}kg',
                      style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementsCard extends StatelessWidget {
  final BodyMeasurements measurements;
  const _MeasurementsCard({required this.measurements});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Latest: ${DateFormat('MMM d, yyyy').format(measurements.measuredAt)}',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          SizedBox(height: 12),
          if (measurements.weight != null)
            _MeasurementRow(
                label: 'Weight', value: '${measurements.weight} kg'),
          if (measurements.bodyFatPercentage != null)
            _MeasurementRow(
                label: 'Body Fat', value: '${measurements.bodyFatPercentage}%'),
          if (measurements.waist != null)
            _MeasurementRow(label: 'Waist', value: '${measurements.waist} cm'),
          if (measurements.hips != null)
            _MeasurementRow(label: 'Hips', value: '${measurements.hips} cm'),
        ],
      ),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  final String label;
  final String value;
  const _MeasurementRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey)),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
