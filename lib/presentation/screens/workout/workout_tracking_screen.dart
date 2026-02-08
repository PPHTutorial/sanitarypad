// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sanitarypad/core/providers/auth_provider.dart';
import 'package:sanitarypad/core/theme/app_theme.dart';
import 'package:sanitarypad/models/workout_models.dart';
import 'package:sanitarypad/services/workout_service.dart';
import 'package:sanitarypad/services/video_feed_service.dart';
import 'package:sanitarypad/services/workout_export_service.dart';
import 'package:sanitarypad/presentation/screens/workout/workout_center_search_screen.dart';
import 'package:sanitarypad/presentation/screens/workout/widgets/workout_tabs.dart';
import 'package:sanitarypad/presentation/screens/workout/exercise_log_form_screen.dart';
import 'package:sanitarypad/services/credit_manager.dart';
import 'package:sanitarypad/core/widgets/back_button_handler.dart';
import 'package:sanitarypad/core/config/responsive_config.dart';
import 'package:sanitarypad/presentation/widgets/ads/eco_ad_wrapper.dart';

/// Workout Tracking Screen with 5 tabs: Overview, Workouts, Log, Programs, Progress
class WorkoutTrackingScreen extends ConsumerStatefulWidget {
  const WorkoutTrackingScreen({super.key});

  @override
  ConsumerState<WorkoutTrackingScreen> createState() =>
      _WorkoutTrackingScreenState();
}

class _WorkoutTrackingScreenState extends ConsumerState<WorkoutTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = [
    'Overview',
    'Workouts',
    'Log',
    'Programs',
    'Progress'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    ref.read(videoFeedServiceProvider).initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.userId;

    if (userId == null) {
      return Scaffold(
          body: Center(child: Text('Please log in to track workouts')));
    }

    return BackButtonHandler(
      fallbackRoute: '/home',
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text('Workout', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () => context.go('/home')),
          actions: [
            IconButton(
              icon: Icon(Icons.add_circle_outline),
              tooltip: 'Quick Actions',
              onPressed: () => _showQuickActions(context, userId),
            ),
          ],
          bottom: _buildModernTabBar(context),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            //ResponsiveConfig.heightBox(16),
            _WorkoutOverviewTab(userId: userId),
            WorkoutsTab(userId: userId),
            LogTab(userId: userId),
            ProgramsTab(userId: userId),
            ProgressTab(userId: userId),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernTabBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: TabBar(
        dividerColor: AppTheme.darkGray.withOpacity(0.2),
        controller: _tabController,
        labelStyle: ResponsiveConfig.textStyle(
          size: 14,
          weight: FontWeight.w600,
        ),
        unselectedLabelStyle: ResponsiveConfig.textStyle(
          size: 14,
          weight: FontWeight.w500,
        ),
        indicatorColor: AppTheme.primaryPink,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryPink,
        unselectedLabelColor: AppTheme.mediumGray,
        tabs: const [
          Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
          Tab(text: 'Workouts', icon: Icon(Icons.fitness_center_outlined)),
          Tab(text: 'Log', icon: Icon(Icons.list_alt_outlined)),
          Tab(text: 'Programs', icon: Icon(Icons.event_note_outlined)),
          Tab(text: 'Progress', icon: Icon(Icons.show_chart_outlined)),
        ],
      ),
    );
  }

  void _showQuickActions(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quick Actions',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickActionButton(
                    icon: FontAwesomeIcons.dumbbell,
                    label: 'Log Exercise',
                    color: AppTheme.primaryPink,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ExerciseLogFormScreen(userId: userId)));
                    }),
                _QuickActionButton(
                    icon: FontAwesomeIcons.play,
                    label: 'Start Workout',
                    color: AppTheme.primaryPink,
                    onTap: () {
                      Navigator.pop(context);
                      _startQuickWorkout(context, userId);
                    }),
                _QuickActionButton(
                    icon: FontAwesomeIcons.camera,
                    label: 'Progress Photo',
                    color: AppTheme.primaryPink,
                    onTap: () {
                      Navigator.pop(context);
                      _takeProgressPhoto(context, userId);
                    }),
                _QuickActionButton(
                    icon: FontAwesomeIcons.filePdf,
                    label: 'Export Data',
                    color: AppTheme.primaryPink,
                    onTap: () {
                      Navigator.pop(context);
                      _exportWorkoutData(context, userId);
                    }),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _startQuickWorkout(BuildContext context, String userId) async {
    final service = ref.read(workoutServiceProvider);

    // Check if user is enrolled in any programs
    final enrolledIds =
        await ref.read(enrolledProgramIdsProvider(userId).future);
    String sessionName = 'Quick Workout';
    ExerciseCategory category = ExerciseCategory.other;
    WorkoutDifficulty difficulty = WorkoutDifficulty.intermediate;
    List<ExerciseEntry> exercises = [];

    if (enrolledIds.isNotEmpty) {
      // Pick the first enrolled program for simplicity, or we could let user choose
      final programId = enrolledIds.first;
      final programs = await ref.read(availableProgramsProvider.future);
      final program = programs.firstWhere((p) => p.id == programId);
      final progress =
          await service.getEnrolledProgramProgress(userId, programId);

      if (progress != null) {
        final dayIndex = progress['currentDayIndex'] as int;
        if (dayIndex < program.schedule.length) {
          final day = program.schedule[dayIndex];
          sessionName = '${program.name}: ${day.title}';
          category = program.category;
          difficulty = program.difficulty;

          // Suggest exercises from this day
          // Note: We create them with loggedAt = now but they aren't 'saved' until logged individually
          // However, for the 'ActiveSessionCard' to show them, we might need a different approach
          // Actually, let's just use the program info to name the session for now.
        }
      }
    }

    final session = WorkoutSession(
      id: '',
      name: sessionName,
      category: category,
      difficulty: difficulty,
      startedAt: DateTime.now(),
      exercises: exercises,
      totalDuration: Duration.zero,
      totalCaloriesBurned: 0,
      isCompleted: false,
    );
    await service.startWorkoutSession(userId, session);

    // Switch to Log tab (index 2)
    _tabController.animateTo(2);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Workout started: $sessionName 💪'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _takeProgressPhoto(BuildContext context, String userId) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      await ref
          .read(workoutServiceProvider)
          .uploadProgressPhoto(userId, File(image.path));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Progress photo saved! 📸')));
      }
    }
  }

  Future<void> _exportWorkoutData(BuildContext context, String userId) async {
    final creditManager = ref.read(creditManagerProvider);
    final hasCredits = await creditManager.requestCredit(
      context,
      ActionType.export,
    );

    if (hasCredits) {
      await creditManager.consumeCredits(ActionType.export);
      final sessions = await ref.read(recentSessionsProvider(userId).future);
      await WorkoutExportService().exportWorkoutHistoryAsPdf(sessions);
    }
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ============================================================================
// OVERVIEW TAB
// ============================================================================
class _WorkoutOverviewTab extends ConsumerWidget {
  final String userId;
  const _WorkoutOverviewTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(workoutStatsProvider(userId));
    final goalsAsync = ref.watch(workoutGoalsProvider(userId));
    final sessionsAsync = ref.watch(recentSessionsProvider(userId));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak Card
          ResponsiveConfig.heightBox(24),
          statsAsync.when(
            data: (stats) => _StreakCard(
                currentStreak: stats['currentStreak'] ?? 0,
                longestStreak: stats['longestStreak'] ?? 0,
                totalWorkouts: stats['totalWorkouts'] ?? 0),
            loading: () => _LoadingCard(),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          SizedBox(height: 16),

          // Weekly Progress
          goalsAsync.when(
            data: (goals) => FutureBuilder<WeeklyWorkoutSummary>(
              future: ref
                  .read(workoutServiceProvider)
                  .getWeeklySummary(userId, _getWeekStart()),
              builder: (context, snapshot) {
                final summary = snapshot.data ??
                    WeeklyWorkoutSummary.empty(_getWeekStart());
                return _WeeklyProgressCard(summary: summary, goals: goals);
              },
            ),
            loading: () => _LoadingCard(),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          SizedBox(height: 16),

          // Gamification Section
          _GamificationSection(userId: userId),
          SizedBox(height: 24),

          // Gym Search Card
          _FindGymCard(),
          SizedBox(height: 16),

          // Community Card
          _WorkoutCommunityCard(),
          SizedBox(height: 16),
          SizedBox(height: 16),

          // Recent Workouts
          Text('Recent Workouts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          sessionsAsync.when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16)),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(FontAwesomeIcons.dumbbell,
                            size: 40, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No workouts yet',
                            style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('Start your fitness journey today!',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                  children: sessions
                      .take(3)
                      .map((s) => _RecentWorkoutCard(session: s))
                      .toList());
            },
            loading: () => _LoadingCard(),
            error: (e, _) => _ErrorCard(message: e.toString()),
          ),
          SizedBox(height: 16),
          const EcoAdWrapper(adType: AdType.banner),
          SizedBox(height: 80),
        ],
      ),
    );
  }

  DateTime _getWeekStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - now.weekday + 1);
  }
}

class _StreakCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final int totalWorkouts;
  const _StreakCard(
      {required this.currentStreak,
      required this.longestStreak,
      required this.totalWorkouts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primaryPink,
          AppTheme.primaryPink.withOpacity(0.7)
        ]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StreakStat(
              value: '$currentStreak',
              label: 'Current\nStreak',
              icon: FontAwesomeIcons.fire),
          Container(width: 1, height: 50, color: Colors.white30),
          _StreakStat(
              value: '$longestStreak',
              label: 'Longest\nStreak',
              icon: FontAwesomeIcons.trophy),
          Container(width: 1, height: 50, color: Colors.white30),
          _StreakStat(
              value: '$totalWorkouts',
              label: 'Total\nWorkouts',
              icon: FontAwesomeIcons.dumbbell),
        ],
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StreakStat(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  final WeeklyWorkoutSummary summary;
  final WorkoutGoals goals;
  const _WeeklyProgressCard({required this.summary, required this.goals});

  @override
  Widget build(BuildContext context) {
    final workoutPercent = goals.workoutsPerWeek > 0
        ? (summary.workoutsCompleted / goals.workoutsPerWeek * 100)
            .clamp(0.0, 100.0)
        : 0.0;
    final caloriePercent = goals.weeklyCaloriesBurnGoal > 0
        ? (summary.totalCaloriesBurned / goals.weeklyCaloriesBurnGoal * 100)
            .clamp(0.0, 100.0)
        : 0.0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _ProgressRing(
                      label: 'Workouts',
                      value: summary.workoutsCompleted,
                      goal: goals.workoutsPerWeek,
                      percent: workoutPercent,
                      color: Theme.of(context).colorScheme.secondary)),
              SizedBox(width: 24),
              Expanded(
                  child: _ProgressRing(
                      label: 'Calories',
                      value: summary.totalCaloriesBurned,
                      goal: goals.weeklyCaloriesBurnGoal,
                      percent: caloriePercent,
                      color: Theme.of(context).colorScheme.primary)),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Time', style: TextStyle(color: Colors.grey)),
              Text(_formatDuration(summary.totalDuration),
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

class _ProgressRing extends StatelessWidget {
  final String label;
  final int value;
  final int goal;
  final double percent;
  final Color color;
  const _ProgressRing(
      {required this.label,
      required this.value,
      required this.goal,
      required this.percent,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                  value: percent / 100,
                  strokeWidth: 8,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(color)),
            ),
            Column(
              children: [
                Text('$value',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('/ $goal',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _RecentWorkoutCard extends StatelessWidget {
  final WorkoutSession session;
  const _RecentWorkoutCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: colorScheme.onPrimary,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(
              FontAwesomeIcons.dumbbell,
              color: AppTheme.primaryPink,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.name,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(DateFormat('MMM d, h:mm a').format(session.startedAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${session.totalCaloriesBurned} cal',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryPink)),
              Text(_formatDuration(session.totalDuration),
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    return '${minutes}m';
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16)),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _FindGymCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Fitness Centers',
                  style: ResponsiveConfig.textStyle(
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.map_outlined, color: AppTheme.primaryPink),
              ],
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Find gyms, studios, and workout centers near you to level up your training.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkoutCenterSearchScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Find centers near me'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutCommunityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: ResponsiveConfig.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Community',
              style: ResponsiveConfig.textStyle(
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
            ResponsiveConfig.heightBox(8),
            Text(
              'Share your gains, ask experts, and join regional fitness challenges.',
              style: ResponsiveConfig.textStyle(
                size: 14,
                color: AppTheme.mediumGray,
              ),
            ),
            ResponsiveConfig.heightBox(16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.push('/groups', extra: 'workout'),
                  icon: const FaIcon(FontAwesomeIcons.users, size: 16),
                  label: const Text('Join fitness forum'),
                ),
                ResponsiveConfig.heightBox(8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/events', extra: 'workout'),
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: const Text('Upcoming events'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GamificationSection extends StatelessWidget {
  final String userId;
  const _GamificationSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gamification',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GamificationCard(
                title: 'Challenges',
                subtitle: 'Join & compete',
                icon: Icons.emoji_events,
                color: Colors.orange,
                onTap: () => context.push('/workout-challenges', extra: userId),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _GamificationCard(
                title: 'Trophies',
                subtitle: 'Your rewards',
                icon: Icons.workspace_premium,
                color: Colors.blue,
                onTap: () =>
                    context.push('/workout-achievements', extra: userId),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GamificationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GamificationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 12),
            Text(title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: colorScheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(Icons.error, color: colorScheme.error),
          SizedBox(width: 12),
          Expanded(
              child: Text(message, style: TextStyle(color: colorScheme.error))),
        ],
      ),
    );
  }
}
