import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Exercise category enumeration
enum ExerciseCategory {
  cardio,
  strength,
  flexibility,
  yoga,
  hiit,
  pilates,
  sports,
  other,
}

extension ExerciseCategoryExtension on ExerciseCategory {
  String get displayName {
    switch (this) {
      case ExerciseCategory.cardio:
        return 'Cardio';
      case ExerciseCategory.strength:
        return 'Strength';
      case ExerciseCategory.flexibility:
        return 'Flexibility';
      case ExerciseCategory.yoga:
        return 'Yoga';
      case ExerciseCategory.hiit:
        return 'HIIT';
      case ExerciseCategory.pilates:
        return 'Pilates';
      case ExerciseCategory.sports:
        return 'Sports';
      case ExerciseCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case ExerciseCategory.cardio:
        return '🏃';
      case ExerciseCategory.strength:
        return '💪';
      case ExerciseCategory.flexibility:
        return '🤸';
      case ExerciseCategory.yoga:
        return '🧘';
      case ExerciseCategory.hiit:
        return '🔥';
      case ExerciseCategory.pilates:
        return '🩰';
      case ExerciseCategory.sports:
        return '⚽';
      case ExerciseCategory.other:
        return '🏋️';
    }
  }
}

/// Muscle group enumeration for targeted exercises
enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  core,
  glutes,
  quadriceps,
  hamstrings,
  calves,
  fullBody,
}

extension MuscleGroupExtension on MuscleGroup {
  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.glutes:
        return 'Glutes';
      case MuscleGroup.quadriceps:
        return 'Quadriceps';
      case MuscleGroup.hamstrings:
        return 'Hamstrings';
      case MuscleGroup.calves:
        return 'Calves';
      case MuscleGroup.fullBody:
        return 'Full Body';
    }
  }
}

/// Difficulty level for workouts
enum WorkoutDifficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

extension WorkoutDifficultyExtension on WorkoutDifficulty {
  String get displayName {
    switch (this) {
      case WorkoutDifficulty.beginner:
        return 'Beginner';
      case WorkoutDifficulty.intermediate:
        return 'Intermediate';
      case WorkoutDifficulty.advanced:
        return 'Advanced';
      case WorkoutDifficulty.expert:
        return 'Expert';
    }
  }

  String get icon {
    switch (this) {
      case WorkoutDifficulty.beginner:
        return '🌱';
      case WorkoutDifficulty.intermediate:
        return '🌿';
      case WorkoutDifficulty.advanced:
        return '🌳';
      case WorkoutDifficulty.expert:
        return '🏆';
    }
  }
}

/// Represents a single exercise entry logged by the user
class ExerciseEntry extends Equatable {
  final String id;
  final String? sessionId; // Link to a workout session
  final String exerciseName;
  final ExerciseCategory category;
  final List<MuscleGroup> muscleGroups;
  final int? sets;
  final int? reps;
  final double? weight;
  final Duration duration;
  final int caloriesBurned;
  final String? notes;
  final DateTime loggedAt;
  final DateTime createdAt;

  const ExerciseEntry({
    required this.id,
    this.sessionId,
    required this.exerciseName,
    required this.category,
    required this.muscleGroups,
    this.sets,
    this.reps,
    this.weight,
    required this.duration,
    required this.caloriesBurned,
    this.notes,
    required this.loggedAt,
    required this.createdAt,
  });

  factory ExerciseEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseEntry(
      id: doc.id,
      sessionId: data['sessionId'],
      exerciseName: data['exerciseName'] ?? '',
      category: ExerciseCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ExerciseCategory.other,
      ),
      muscleGroups: (data['muscleGroups'] as List?)
              ?.map((e) => MuscleGroup.values.firstWhere(
                    (m) => m.name == e,
                    orElse: () => MuscleGroup.fullBody,
                  ))
              .toList() ??
          [],
      sets: data['sets'],
      reps: data['reps'],
      weight: data['weight']?.toDouble(),
      duration: Duration(seconds: data['durationSeconds'] ?? 0),
      caloriesBurned: data['caloriesBurned'] ?? 0,
      notes: data['notes'],
      loggedAt: (data['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'exerciseName': exerciseName,
      'category': category.name,
      'muscleGroups': muscleGroups.map((e) => e.name).toList(),
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'durationSeconds': duration.inSeconds,
      'caloriesBurned': caloriesBurned,
      'notes': notes,
      'loggedAt': Timestamp.fromDate(loggedAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ExerciseEntry copyWith({
    String? id,
    String? sessionId,
    String? exerciseName,
    ExerciseCategory? category,
    List<MuscleGroup>? muscleGroups,
    int? sets,
    int? reps,
    double? weight,
    Duration? duration,
    int? caloriesBurned,
    String? notes,
    DateTime? loggedAt,
    DateTime? createdAt,
  }) {
    return ExerciseEntry(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseName: exerciseName ?? this.exerciseName,
      category: category ?? this.category,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      duration: duration ?? this.duration,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      notes: notes ?? this.notes,
      loggedAt: loggedAt ?? this.loggedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, sessionId, exerciseName, category, loggedAt];
}

/// Represents a complete workout session
class WorkoutSession extends Equatable {
  final String id;
  final String name;
  final String? description;
  final ExerciseCategory category;
  final WorkoutDifficulty difficulty;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<ExerciseEntry> exercises;
  final Duration totalDuration;
  final int totalCaloriesBurned;
  final bool isCompleted;
  final String? notes;
  final double? rating;

  const WorkoutSession({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.difficulty,
    required this.startedAt,
    this.completedAt,
    required this.exercises,
    required this.totalDuration,
    required this.totalCaloriesBurned,
    required this.isCompleted,
    this.notes,
    this.rating,
  });

  factory WorkoutSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutSession(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      category: ExerciseCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ExerciseCategory.other,
      ),
      difficulty: WorkoutDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => WorkoutDifficulty.beginner,
      ),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      exercises: const [], // Exercises are loaded separately
      totalDuration: Duration(seconds: data['totalDurationSeconds'] ?? 0),
      totalCaloriesBurned: data['totalCaloriesBurned'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      notes: data['notes'],
      rating: data['rating']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category.name,
      'difficulty': difficulty.name,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'totalDurationSeconds': totalDuration.inSeconds,
      'totalCaloriesBurned': totalCaloriesBurned,
      'isCompleted': isCompleted,
      'notes': notes,
      'rating': rating,
    };
  }

  WorkoutSession copyWith({
    String? id,
    String? name,
    String? description,
    ExerciseCategory? category,
    WorkoutDifficulty? difficulty,
    DateTime? startedAt,
    DateTime? completedAt,
    List<ExerciseEntry>? exercises,
    Duration? totalDuration,
    int? totalCaloriesBurned,
    bool? isCompleted,
    String? notes,
    double? rating,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      exercises: exercises ?? this.exercises,
      totalDuration: totalDuration ?? this.totalDuration,
      totalCaloriesBurned: totalCaloriesBurned ?? this.totalCaloriesBurned,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      rating: rating ?? this.rating,
    );
  }

  @override
  List<Object?> get props => [id, name, startedAt, isCompleted];
}

/// Structured workout program users can follow
class WorkoutProgram extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final ExerciseCategory category;
  final WorkoutDifficulty difficulty;
  final int durationWeeks;
  final int workoutsPerWeek;
  final List<String> goals;
  final List<ProgramDay> schedule;
  final int? currentDayIndex;
  final bool isEnrolled;
  final DateTime? enrolledAt;
  final int completedWorkouts;

  const WorkoutProgram({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.category,
    required this.difficulty,
    required this.durationWeeks,
    required this.workoutsPerWeek,
    required this.goals,
    required this.schedule,
    this.currentDayIndex,
    required this.isEnrolled,
    this.enrolledAt,
    required this.completedWorkouts,
  });

  factory WorkoutProgram.fromFirestore(DocumentSnapshot doc,
      {bool isEnrolled = false}) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutProgram(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      category: ExerciseCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ExerciseCategory.other,
      ),
      difficulty: WorkoutDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => WorkoutDifficulty.beginner,
      ),
      durationWeeks: data['durationWeeks'] ?? 4,
      workoutsPerWeek: data['workoutsPerWeek'] ?? 3,
      goals: List<String>.from(data['goals'] ?? []),
      schedule: (data['schedule'] as List?)
              ?.map((e) => ProgramDay.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentDayIndex: null,
      isEnrolled: isEnrolled,
      enrolledAt: null,
      completedWorkouts: 0,
    );
  }

  double get progressPercentage {
    final totalWorkouts = durationWeeks * workoutsPerWeek;
    if (totalWorkouts == 0) return 0;
    return (completedWorkouts / totalWorkouts * 100).clamp(0, 100);
  }

  @override
  List<Object?> get props => [id, name, isEnrolled];
}

/// Single day in a workout program
class ProgramDay {
  final int dayNumber;
  final String title;
  final String? description;
  final Duration estimatedDuration;
  final List<ProgramExercise> exercises;
  final bool isRestDay;

  const ProgramDay({
    required this.dayNumber,
    required this.title,
    this.description,
    required this.estimatedDuration,
    required this.exercises,
    required this.isRestDay,
  });

  factory ProgramDay.fromMap(Map<String, dynamic> data) {
    return ProgramDay(
      dayNumber: data['dayNumber'] ?? 1,
      title: data['title'] ?? '',
      description: data['description'],
      estimatedDuration: Duration(minutes: data['estimatedMinutes'] ?? 30),
      exercises: (data['exercises'] as List?)
              ?.map((e) => ProgramExercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      isRestDay: data['isRestDay'] ?? false,
    );
  }
}

/// Exercise within a program day
class ProgramExercise {
  final String name;
  final ExerciseCategory category;
  final int? sets;
  final int? reps;
  final Duration? duration;
  final String? instructions;
  final String? videoUrl;

  const ProgramExercise({
    required this.name,
    required this.category,
    this.sets,
    this.reps,
    this.duration,
    this.instructions,
    this.videoUrl,
  });

  factory ProgramExercise.fromMap(Map<String, dynamic> data) {
    return ProgramExercise(
      name: data['name'] ?? '',
      category: ExerciseCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ExerciseCategory.other,
      ),
      sets: data['sets'],
      reps: data['reps'],
      duration: data['durationSeconds'] != null
          ? Duration(seconds: data['durationSeconds'])
          : null,
      instructions: data['instructions'],
      videoUrl: data['videoUrl'],
    );
  }
}

/// Progress photo for tracking body transformation
class ProgressPhoto extends Equatable {
  final String id;
  final String imageUrl;
  final DateTime takenAt;
  final double? weight;
  final Map<String, double>? measurements;
  final String? notes;

  const ProgressPhoto({
    required this.id,
    required this.imageUrl,
    required this.takenAt,
    this.weight,
    this.measurements,
    this.notes,
  });

  factory ProgressPhoto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProgressPhoto(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      takenAt: (data['takenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weight: data['weight']?.toDouble(),
      measurements: data['measurements'] != null
          ? Map<String, double>.from(data['measurements'])
          : null,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'takenAt': Timestamp.fromDate(takenAt),
      'weight': weight,
      'measurements': measurements,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [id, imageUrl, takenAt];
}

/// Body measurements for progress tracking
class BodyMeasurements extends Equatable {
  final String id;
  final double? weight;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? biceps;
  final double? thighs;
  final double? calves;
  final double? bodyFatPercentage;
  final DateTime measuredAt;

  const BodyMeasurements({
    required this.id,
    this.weight,
    this.chest,
    this.waist,
    this.hips,
    this.biceps,
    this.thighs,
    this.calves,
    this.bodyFatPercentage,
    required this.measuredAt,
  });

  factory BodyMeasurements.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BodyMeasurements(
      id: doc.id,
      weight: data['weight']?.toDouble(),
      chest: data['chest']?.toDouble(),
      waist: data['waist']?.toDouble(),
      hips: data['hips']?.toDouble(),
      biceps: data['biceps']?.toDouble(),
      thighs: data['thighs']?.toDouble(),
      calves: data['calves']?.toDouble(),
      bodyFatPercentage: data['bodyFatPercentage']?.toDouble(),
      measuredAt:
          (data['measuredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'weight': weight,
      'chest': chest,
      'waist': waist,
      'hips': hips,
      'biceps': biceps,
      'thighs': thighs,
      'calves': calves,
      'bodyFatPercentage': bodyFatPercentage,
      'measuredAt': Timestamp.fromDate(measuredAt),
    };
  }

  @override
  List<Object?> get props => [id, measuredAt];
}

/// Workout goals set by user
class WorkoutGoals extends Equatable {
  final int workoutsPerWeek;
  final int minutesPerWorkout;
  final int weeklyCaloriesBurnGoal;
  final double? targetWeight;
  final List<ExerciseCategory> focusCategories;
  final List<String> personalGoals;

  const WorkoutGoals({
    required this.workoutsPerWeek,
    required this.minutesPerWorkout,
    required this.weeklyCaloriesBurnGoal,
    this.targetWeight,
    required this.focusCategories,
    required this.personalGoals,
  });

  factory WorkoutGoals.defaultGoals() {
    return const WorkoutGoals(
      workoutsPerWeek: 3,
      minutesPerWorkout: 45,
      weeklyCaloriesBurnGoal: 1500,
      focusCategories: [ExerciseCategory.cardio, ExerciseCategory.strength],
      personalGoals: [],
    );
  }

  factory WorkoutGoals.fromFirestore(Map<String, dynamic> data) {
    return WorkoutGoals(
      workoutsPerWeek: data['workoutsPerWeek'] ?? 3,
      minutesPerWorkout: data['minutesPerWorkout'] ?? 45,
      weeklyCaloriesBurnGoal: data['weeklyCaloriesBurnGoal'] ?? 1500,
      targetWeight: data['targetWeight']?.toDouble(),
      focusCategories: (data['focusCategories'] as List?)
              ?.map((e) => ExerciseCategory.values.firstWhere(
                    (c) => c.name == e,
                    orElse: () => ExerciseCategory.other,
                  ))
              .toList() ??
          [],
      personalGoals: List<String>.from(data['personalGoals'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workoutsPerWeek': workoutsPerWeek,
      'minutesPerWorkout': minutesPerWorkout,
      'weeklyCaloriesBurnGoal': weeklyCaloriesBurnGoal,
      'targetWeight': targetWeight,
      'focusCategories': focusCategories.map((e) => e.name).toList(),
      'personalGoals': personalGoals,
    };
  }

  @override
  List<Object?> get props =>
      [workoutsPerWeek, minutesPerWorkout, weeklyCaloriesBurnGoal];
}

/// Weekly workout summary
class WeeklyWorkoutSummary {
  final DateTime weekStart;
  final int workoutsCompleted;
  final Duration totalDuration;
  final int totalCaloriesBurned;
  final Map<ExerciseCategory, int> categoryMinutes;
  final int currentStreak;
  final int longestStreak;

  const WeeklyWorkoutSummary({
    required this.weekStart,
    required this.workoutsCompleted,
    required this.totalDuration,
    required this.totalCaloriesBurned,
    required this.categoryMinutes,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory WeeklyWorkoutSummary.empty(DateTime weekStart) {
    return WeeklyWorkoutSummary(
      weekStart: weekStart,
      workoutsCompleted: 0,
      totalDuration: Duration.zero,
      totalCaloriesBurned: 0,
      categoryMinutes: {},
      currentStreak: 0,
      longestStreak: 0,
    );
  }

  double getGoalPercentage(WorkoutGoals goals) {
    if (goals.workoutsPerWeek == 0) return 0;
    return (workoutsCompleted / goals.workoutsPerWeek * 100).clamp(0, 200);
  }

  double getCaloriesPercentage(WorkoutGoals goals) {
    if (goals.weeklyCaloriesBurnGoal == 0) return 0;
    return (totalCaloriesBurned / goals.weeklyCaloriesBurnGoal * 100)
        .clamp(0, 200);
  }
}

/// YouTube workout video metadata
class WorkoutVideo extends Equatable {
  final String videoId;
  final String title;
  final String? description;
  final String thumbnailUrl;
  final Duration duration;
  final ExerciseCategory category;
  final WorkoutDifficulty difficulty;
  final String? channelName;
  final int? viewCount;
  final bool isSaved;
  final DateTime? savedAt;

  const WorkoutVideo({
    required this.videoId,
    required this.title,
    this.description,
    required this.thumbnailUrl,
    required this.duration,
    required this.category,
    required this.difficulty,
    this.channelName,
    this.viewCount,
    required this.isSaved,
    this.savedAt,
    int? likes,
  });

  factory WorkoutVideo.fromYtDlp(Map<String, dynamic> data,
      {ExerciseCategory? category}) {
    return WorkoutVideo(
      videoId: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      thumbnailUrl: data['thumbnail'] ?? data['thumbnails']?[0]?['url'] ?? '',
      duration: Duration(seconds: data['duration'] ?? 0),
      category: category ?? ExerciseCategory.other,
      difficulty: WorkoutDifficulty.beginner,
      channelName: data['uploader'] ?? data['channel'],
      viewCount: data['view_count'],
      isSaved: false,
      savedAt: null,
    );
  }

  factory WorkoutVideo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutVideo(
      videoId: data['videoId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      duration: Duration(seconds: data['durationSeconds'] ?? 0),
      category: ExerciseCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ExerciseCategory.other,
      ),
      difficulty: WorkoutDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => WorkoutDifficulty.beginner,
      ),
      channelName: data['channelName'],
      viewCount: data['viewCount'],
      isSaved: true,
      savedAt: (data['savedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'videoId': videoId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': duration.inSeconds,
      'category': category.name,
      'difficulty': difficulty.name,
      'channelName': channelName,
      'viewCount': viewCount,
      'savedAt':
          savedAt != null ? Timestamp.fromDate(savedAt!) : Timestamp.now(),
    };
  }

  WorkoutVideo copyWith({
    String? videoId,
    String? title,
    String? description,
    String? thumbnailUrl,
    Duration? duration,
    ExerciseCategory? category,
    WorkoutDifficulty? difficulty,
    String? channelName,
    int? viewCount,
    bool? isSaved,
    DateTime? savedAt,
  }) {
    return WorkoutVideo(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      channelName: channelName ?? this.channelName,
      viewCount: viewCount ?? this.viewCount,
      isSaved: isSaved ?? this.isSaved,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  List<Object?> get props => [videoId, title];
}

/// Represents a fitness challenge for users
class WorkoutChallenge extends Equatable {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int creditReward;
  final String? trophyId;
  final Map<String, dynamic>
      requirement; // e.g. {'type': 'workout_count', 'count': 5, 'category': 'hiit'}
  final DateTime? deadline;
  final bool isGlobal;

  const WorkoutChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.creditReward,
    this.trophyId,
    required this.requirement,
    this.deadline,
    this.isGlobal = true,
  });

  factory WorkoutChallenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutChallenge(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🏆',
      creditReward: data['creditReward'] ?? 0,
      trophyId: data['trophyId'],
      requirement: Map<String, dynamic>.from(data['requirement'] ?? {}),
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      isGlobal: data['isGlobal'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'creditReward': creditReward,
      'trophyId': trophyId,
      'requirement': requirement,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'isGlobal': isGlobal,
    };
  }

  @override
  List<Object?> get props => [id, title];
}

/// Represents an achievement or trophy earned by the user
class WorkoutAchievement extends Equatable {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime earnedAt;
  final String? challengeId;

  const WorkoutAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.earnedAt,
    this.challengeId,
  });

  factory WorkoutAchievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutAchievement(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🥇',
      earnedAt: (data['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      challengeId: data['challengeId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'earnedAt': Timestamp.fromDate(earnedAt),
      'challengeId': challengeId,
    };
  }

  @override
  List<Object?> get props => [id, name];
}
