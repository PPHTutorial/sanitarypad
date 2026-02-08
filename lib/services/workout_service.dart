import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_models.dart';

/// Provider for WorkoutService
final workoutServiceProvider = Provider<WorkoutService>((ref) {
  return WorkoutService();
});

/// Workout Service - handles all workout-related Firestore operations
class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Helper methods for collection references
  CollectionReference<Map<String, dynamic>> _exercisesCollection(
      String userId) {
    return _firestore.collection('users/$userId/workout_exercises');
  }

  CollectionReference<Map<String, dynamic>> _sessionsCollection(String userId) {
    return _firestore.collection('users/$userId/workout_sessions');
  }

  CollectionReference<Map<String, dynamic>> _enrolledProgramsCollection(
      String userId) {
    return _firestore.collection('users/$userId/workout_enrolled_programs');
  }

  CollectionReference<Map<String, dynamic>> _progressPhotosCollection(
      String userId) {
    return _firestore.collection('users/$userId/workout_progress_photos');
  }

  CollectionReference<Map<String, dynamic>> _measurementsCollection(
      String userId) {
    return _firestore.collection('users/$userId/workout_measurements');
  }

  CollectionReference<Map<String, dynamic>> _savedVideosCollection(
      String userId) {
    return _firestore.collection('users/$userId/workout_saved_videos');
  }

  DocumentReference<Map<String, dynamic>> _goalsDoc(String userId) {
    return _firestore.doc('users/$userId/workout_settings/goals');
  }

  DocumentReference<Map<String, dynamic>> _statsDoc(String userId) {
    return _firestore.doc('users/$userId/workout_settings/stats');
  }

  // ============================================================================
  // EXERCISE LOGGING
  // ============================================================================

  /// Log a single exercise entry
  Future<void> logExercise(String userId, ExerciseEntry entry,
      {String? sessionId}) async {
    final entryToSave =
        sessionId != null ? entry.copyWith(sessionId: sessionId) : entry;
    await _exercisesCollection(userId).add(entryToSave.toFirestore());
  }

  /// Update an existing exercise entry
  Future<void> updateExercise(String userId, ExerciseEntry exercise) async {
    await _exercisesCollection(userId)
        .doc(exercise.id)
        .update(exercise.toFirestore());
  }

  /// Delete an exercise entry
  Future<void> deleteExercise(String userId, String exerciseId) async {
    await _exercisesCollection(userId).doc(exerciseId).delete();
  }

  /// Restore a deleted exercise entry
  Future<void> restoreExercise(String userId, ExerciseEntry exercise) async {
    await _exercisesCollection(userId)
        .doc(exercise.id)
        .set(exercise.toFirestore());
  }

  /// Watch exercises for a specific date
  Stream<List<ExerciseEntry>> watchExercises(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _exercisesCollection(userId)
        .where('loggedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('loggedAt', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('loggedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExerciseEntry.fromFirestore(doc))
            .toList());
  }

  /// Get exercises for a date range
  Future<List<ExerciseEntry>> getExercisesInRange(
      String userId, DateTime start, DateTime end) async {
    final snapshot = await _exercisesCollection(userId)
        .where('loggedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('loggedAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('loggedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ExerciseEntry.fromFirestore(doc))
        .toList();
  }

  // ============================================================================
  // WORKOUT SESSIONS
  // ============================================================================

  /// Start a new workout session
  Future<String> startWorkoutSession(
      String userId, WorkoutSession session) async {
    // Check for existing active sessions and complete them
    final activeSnapshot = await _sessionsCollection(userId)
        .where('isCompleted', isEqualTo: false)
        .get();

    for (final doc in activeSnapshot.docs) {
      await doc.reference.update({
        'isCompleted': true,
        'completedAt': Timestamp.now(),
        // We don't have exact duration here, but better to close it than have duplicates
      });
    }

    final docRef = await _sessionsCollection(userId).add(session.toFirestore());
    return docRef.id;
  }

  /// Complete a workout session
  Future<void> completeWorkoutSession(
      String userId, String sessionId, WorkoutSession session) async {
    final now = DateTime.now();

    // 1. Mark the specific session as completed
    final totalDuration = now.difference(session.startedAt);
    await _sessionsCollection(userId).doc(sessionId).update({
      'completedAt': Timestamp.now(),
      'isCompleted': true,
      'totalDurationSeconds': totalDuration.inSeconds,
    });

    // 2. SAFETY CHECK: Find and close ANY other active sessions to prevent timer bugs
    // This handles cases where the user might have multiple active sessions due to previous bugs
    final activeSnapshot = await _sessionsCollection(userId)
        .where('isCompleted', isEqualTo: false)
        .get();

    for (final doc in activeSnapshot.docs) {
      // Don't update the one we just updated (though query shouldn't return it ideally)
      if (doc.id != sessionId) {
        await doc.reference.update({
          'isCompleted': true,
          'completedAt': Timestamp.now(), // Close them with current time
          'notes': 'Auto-closed by system',
        });
      }
    }

    // Update streak (only once)
    await _updateStreak(userId);
  }

  /// Watch workout sessions
  Stream<List<WorkoutSession>> watchSessions(String userId, {int limit = 10}) {
    return _sessionsCollection(userId)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutSession.fromFirestore(doc))
            .toList());
  }

  /// Watch for an active workout session (not completed)
  Stream<WorkoutSession?> watchActiveSession(String userId) {
    return _sessionsCollection(userId)
        .where('isCompleted', isEqualTo: false)
        .orderBy('startedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty
            ? WorkoutSession.fromFirestore(snapshot.docs.first)
            : null);
  }

  /// Get completed sessions in date range
  Future<List<WorkoutSession>> getSessionsInRange(
      String userId, DateTime start, DateTime end) async {
    final snapshot = await _sessionsCollection(userId)
        .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startedAt', isLessThan: Timestamp.fromDate(end))
        .where('isCompleted', isEqualTo: true)
        .orderBy('startedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => WorkoutSession.fromFirestore(doc))
        .toList();
  }

  // ============================================================================
  // WORKOUT GOALS
  // ============================================================================

  /// Get user's workout goals
  Future<WorkoutGoals> getGoals(String userId) async {
    final doc = await _goalsDoc(userId).get();

    if (doc.exists && doc.data() != null) {
      return WorkoutGoals.fromFirestore(doc.data()!);
    }
    return WorkoutGoals.defaultGoals();
  }

  /// Watch user's workout goals
  Stream<WorkoutGoals> watchGoals(String userId) {
    return _goalsDoc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return WorkoutGoals.fromFirestore(doc.data()!);
      }
      return WorkoutGoals.defaultGoals();
    });
  }

  /// Update workout goals
  Future<void> setGoals(String userId, WorkoutGoals goals) async {
    await _goalsDoc(userId).set(goals.toFirestore());
  }

  // ============================================================================
  // WORKOUT PROGRAMS
  // ============================================================================

  /// Get available workout programs (public)
  Future<List<WorkoutProgram>> getAvailablePrograms() async {
    final snapshot =
        await _firestore.collection('workout_programs').orderBy('name').get();
    return snapshot.docs
        .map((doc) => WorkoutProgram.fromFirestore(doc))
        .toList();
  }

  /// Watch available programs
  Stream<List<WorkoutProgram>> watchAvailablePrograms() {
    return _firestore
        .collection('workout_programs')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutProgram.fromFirestore(doc))
            .toList());
  }

  /// Seed sample workout programs if none exist
  Future<void> seedWorkoutPrograms() async {
    final snapshot =
        await _firestore.collection('workout_programs').limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final programs = [
      {
        'name': 'Weight Loss Warrior',
        'description':
            'A 4-week high-intensity program designed to maximize calorie burn and improve cardiovascular health.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800',
        'category': 'hiit',
        'difficulty': 'intermediate',
        'durationWeeks': 4,
        'workoutsPerWeek': 4,
        'goals': ['Fat loss', 'Improved endurance', 'Full body toning'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Full Body Blast',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {'name': 'Burpees', 'category': 'hiit', 'sets': 4, 'reps': 12},
              {
                'name': 'Mountain Climbers',
                'category': 'hiit',
                'durationSeconds': 45
              },
              {
                'name': 'Jumping Jacks',
                'category': 'hiit',
                'durationSeconds': 60
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Active Recovery',
            'isRestDay': true,
            'estimatedMinutes': 20,
            'exercises': []
          },
          {
            'dayNumber': 3,
            'title': 'Core Crusher',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {'name': 'Plank', 'category': 'hiit', 'durationSeconds': 60},
              {
                'name': 'Bicycle Crunches',
                'category': 'hiit',
                'sets': 3,
                'reps': 20
              },
              {'name': 'Leg Raises', 'category': 'hiit', 'sets': 3, 'reps': 15},
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Lower Body Burn',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Squat Jumps',
                'category': 'hiit',
                'sets': 4,
                'reps': 15
              },
              {'name': 'Lunges', 'category': 'hiit', 'sets': 3, 'reps': 12},
              {
                'name': 'Glute Bridges',
                'category': 'hiit',
                'sets': 3,
                'reps': 20
              },
            ]
          },
          {
            'dayNumber': 5,
            'title': 'HIIT Cardio',
            'isRestDay': false,
            'estimatedMinutes': 35,
            'exercises': [
              {'name': 'High Knees', 'category': 'hiit', 'durationSeconds': 60},
              {'name': 'Butt Kicks', 'category': 'hiit', 'durationSeconds': 60},
              {'name': 'Sprints', 'category': 'hiit', 'durationSeconds': 30},
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Full Body Reset',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {'name': 'Pushups', 'category': 'hiit', 'sets': 3, 'reps': 15},
              {
                'name': 'Bodyweight Squats',
                'category': 'hiit',
                'sets': 3,
                'reps': 25
              },
              {'name': 'Plank Taps', 'category': 'hiit', 'durationSeconds': 60},
            ]
          },
        ]
      },
      {
        'name': 'Strength Starter',
        'description':
            'Master the fundamentals of strength training with this beginner-friendly 6-week program.',
        'imageUrl':
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
        'category': 'strength',
        'difficulty': 'beginner',
        'durationWeeks': 6,
        'workoutsPerWeek': 3,
        'goals': ['Build muscle', 'Learn proper form', 'Increase strength'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Upper Body Focus',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {
                'name': 'Pushups',
                'category': 'strength',
                'sets': 3,
                'reps': 10
              },
              {
                'name': 'Dumbbell Rows',
                'category': 'strength',
                'sets': 3,
                'reps': 12
              },
              {
                'name': 'Overhead Press',
                'category': 'strength',
                'sets': 3,
                'reps': 8
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 3,
            'title': 'Lower Body Focus',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Bodyweight Squats',
                'category': 'strength',
                'sets': 3,
                'reps': 20
              },
              {'name': 'Lunges', 'category': 'strength', 'sets': 3, 'reps': 12},
              {
                'name': 'Calf Raises',
                'category': 'strength',
                'sets': 3,
                'reps': 15
              },
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Full Body Foundations',
            'isRestDay': false,
            'estimatedMinutes': 55,
            'exercises': [
              {'name': 'Plank', 'category': 'strength', 'durationSeconds': 60},
              {
                'name': 'Glute Bridges',
                'category': 'strength',
                'sets': 3,
                'reps': 15
              },
              {
                'name': 'Bird Dog',
                'category': 'strength',
                'sets': 3,
                'reps': 10
              },
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Active Recovery Walk',
            'isRestDay': true,
            'estimatedMinutes': 30,
            'exercises': []
          },
        ]
      },
      {
        'name': 'Yoga Zenith',
        'description':
            'Find your balance and flexibility with this 4-week yoga journey for all levels.',
        'imageUrl':
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
        'category': 'yoga',
        'difficulty': 'beginner',
        'durationWeeks': 4,
        'workoutsPerWeek': 5,
        'goals': ['Flexibility', 'Stress reduction', 'Mind-body connection'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Morning Flow',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Sun Salutation',
                'category': 'yoga',
                'durationSeconds': 600
              },
              {'name': 'Cat-Cow', 'category': 'yoga', 'durationSeconds': 120},
              {
                'name': 'Downward Dog',
                'category': 'yoga',
                'durationSeconds': 180
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Balance & Focus',
            'isRestDay': false,
            'estimatedMinutes': 35,
            'exercises': [
              {'name': 'Tree Pose', 'category': 'yoga', 'durationSeconds': 300},
              {
                'name': 'Warrior II',
                'category': 'yoga',
                'durationSeconds': 300
              },
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Restorative Yoga',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Childs Pose',
                'category': 'yoga',
                'durationSeconds': 300
              },
              {
                'name': 'Cobra Pose',
                'category': 'yoga',
                'durationSeconds': 240
              },
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Meditation & Breath',
            'isRestDay': true,
            'estimatedMinutes': 20,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Power Flow',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Plank Flow',
                'category': 'yoga',
                'durationSeconds': 600
              },
              {
                'name': 'Crow Pose Practice',
                'category': 'yoga',
                'durationSeconds': 300
              },
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Mindful Movement',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Gentle Stretch',
                'category': 'yoga',
                'durationSeconds': 1800
              }
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Deep Relaxation',
            'isRestDay': true,
            'estimatedMinutes': 10,
            'exercises': []
          },
        ]
      },
      {
        'name': 'Marathon Milestone',
        'description':
            'A comprehensive 12-week program for intermediate runners aiming to complete their first marathon.',
        'imageUrl':
            'https://images.unsplash.com/photo-1530549387074-d56a99e142e0?w=800',
        'category': 'cardio',
        'difficulty': 'advanced',
        'durationWeeks': 12,
        'workoutsPerWeek': 5,
        'goals': ['Endurance', 'Pacing', 'Mental toughness'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Base Run',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Easy Pace Run',
                'category': 'cardio',
                'durationSeconds': 2400
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Cross Training',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Swimming or Cycling',
                'category': 'cardio',
                'durationSeconds': 2700
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Interval Sprints',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {
                'name': '400m Repeats',
                'category': 'cardio',
                'durationSeconds': 3000
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Tempo Run',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Race Pace Miles',
                'category': 'cardio',
                'durationSeconds': 3600
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Active Recovery',
            'isRestDay': true,
            'estimatedMinutes': 30,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Long Run',
            'isRestDay': false,
            'estimatedMinutes': 120,
            'exercises': [
              {
                'name': 'Endurance Miles',
                'category': 'cardio',
                'durationSeconds': 7200
              }
            ]
          },
        ]
      },
      {
        'name': 'Couch to 5K',
        'description':
            'Gradually build your running stamina from zero to five kilometers in just 8 weeks.',
        'imageUrl':
            'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=800',
        'category': 'cardio',
        'difficulty': 'beginner',
        'durationWeeks': 8,
        'workoutsPerWeek': 3,
        'goals': ['Consistency', 'Cardio health', 'Weight management'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Interval Walk/Run',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Run/Walk Intervals',
                'category': 'cardio',
                'durationSeconds': 1800
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 3,
            'title': 'Consistency Run',
            'isRestDay': false,
            'estimatedMinutes': 25,
            'exercises': [
              {
                'name': 'Steady Pace Jog',
                'category': 'cardio',
                'durationSeconds': 1500
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Endurance Walk',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Brisk Walk',
                'category': 'cardio',
                'durationSeconds': 2700
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Weekly Challenge',
            'isRestDay': false,
            'estimatedMinutes': 35,
            'exercises': [
              {
                'name': 'Final Week Sprint',
                'category': 'cardio',
                'durationSeconds': 2100
              }
            ]
          },
        ]
      },
      {
        'name': 'Powerlifting Peak',
        'description':
            'Maximize your Big Three: Squat, Bench, and Deadlift in this 10-week strength peak.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800',
        'category': 'strength',
        'difficulty': 'expert',
        'durationWeeks': 10,
        'workoutsPerWeek': 4,
        'goals': ['Max strength', 'Technical proficiency', 'Competition prep'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Heavy Squat Day',
            'isRestDay': false,
            'estimatedMinutes': 90,
            'exercises': [
              {
                'name': 'Back Squat',
                'category': 'strength',
                'sets': 5,
                'reps': 3
              }
            ]
          }
        ]
      },
      {
        'name': 'Kettlebell King',
        'description':
            'A versatile 6-week program focusing on explosive power and endurance using just kettlebells.',
        'imageUrl':
            'https://images.unsplash.com/photo-1526402369013-17865c697f2b?w=800',
        'category': 'strength',
        'difficulty': 'intermediate',
        'durationWeeks': 6,
        'workoutsPerWeek': 3,
        'goals': ['Functional strength', 'Fat loss', 'Power development'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Kettlebell Complex',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'KB Swings',
                'category': 'strength',
                'sets': 5,
                'reps': 20
              },
              {
                'name': 'KB Goblet Squats',
                'category': 'strength',
                'sets': 3,
                'reps': 15
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 3,
            'title': 'Kettlebell Power',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'KB Snatch',
                'category': 'strength',
                'sets': 4,
                'reps': 10
              },
              {
                'name': 'KB Clean and Press',
                'category': 'strength',
                'sets': 4,
                'reps': 8
              },
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Kettlebell Flow',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {
                'name': 'KB Windmill',
                'category': 'strength',
                'sets': 3,
                'reps': 8
              },
              {
                'name': 'KB Turkish Get-up',
                'category': 'strength',
                'sets': 3,
                'reps': 5
              },
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Active Recovery',
            'isRestDay': true,
            'estimatedMinutes': 25,
            'exercises': []
          },
        ]
      },
      {
        'name': 'Pilates Power',
        'description':
            'Build an unbreakable core and improve posture with this 8-week structured Pilates course.',
        'imageUrl':
            'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800',
        'category': 'pilates',
        'difficulty': 'beginner',
        'durationWeeks': 8,
        'workoutsPerWeek': 3,
        'goals': ['Core strength', 'Flexibility', 'Posture improvement'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Core Foundations',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'The Hundred',
                'category': 'pilates',
                'durationSeconds': 300
              },
              {
                'name': 'Single Leg Stretch',
                'category': 'pilates',
                'sets': 3,
                'reps': 15
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Flexibility & Flow',
            'isRestDay': false,
            'estimatedMinutes': 35,
            'exercises': [
              {
                'name': 'The Roll Up',
                'category': 'pilates',
                'sets': 3,
                'reps': 10
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 4,
            'title': 'Lower Body Focus',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Side Kick Series',
                'category': 'pilates',
                'sets': 3,
                'reps': 20
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Core Challenge',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Teaser Practice',
                'category': 'pilates',
                'sets': 4,
                'reps': 5
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Full Body Alignment',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {
                'name': 'Spine Stretch Forward',
                'category': 'pilates',
                'sets': 3,
                'reps': 12
              }
            ]
          },
        ]
      },
      {
        'name': 'HIIT Hardcore',
        'description':
            'Pure intensity. Push your limits with 4 weeks of maximum effort cardio and strength intervals.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517931900292-069f74567403?w=800',
        'category': 'hiit',
        'difficulty': 'advanced',
        'durationWeeks': 4,
        'workoutsPerWeek': 5,
        'goals': ['Maximum calorie burn', 'Efficiency', 'Stamina'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Death by Tabata',
            'isRestDay': false,
            'estimatedMinutes': 25,
            'exercises': [
              {
                'name': 'Burpee Intervals',
                'category': 'hiit',
                'sets': 8,
                'reps': 10
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Upper HIIT',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Mountain Climber Sprints',
                'category': 'hiit',
                'durationSeconds': 1800
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 4,
            'title': 'Lower HIIT',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {'name': 'Box Jumps', 'category': 'hiit', 'sets': 5, 'reps': 12}
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Core HIIT',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Plank Jacks',
                'category': 'hiit',
                'durationSeconds': 1800
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Final Push',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Full Body HIIT',
                'category': 'hiit',
                'durationSeconds': 2400
              }
            ]
          },
        ]
      },
      {
        'name': 'Swimming Sprint',
        'description':
            'Master the pool with this 12-week swimming program designed to improve stroke technique and speed.',
        'imageUrl':
            'https://images.unsplash.com/photo-1530549387074-d56a99e142e0?w=800',
        'category': 'cardio',
        'difficulty': 'beginner',
        'durationWeeks': 12,
        'workoutsPerWeek': 3,
        'goals': ['Stroke efficiency', 'Lung capacity', 'Full body endurance'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Technique Builder',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Freestyle Laps',
                'category': 'cardio',
                'durationSeconds': 3600
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 3,
            'title': 'Sprint Set',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': '50m Sprints',
                'category': 'cardio',
                'durationSeconds': 2700
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Endurance Set',
            'isRestDay': false,
            'estimatedMinutes': 75,
            'exercises': [
              {
                'name': 'Mixed Stroke Laps',
                'category': 'cardio',
                'durationSeconds': 4500
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Technique Clinic',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Drill Work',
                'category': 'cardio',
                'durationSeconds': 3600
              }
            ]
          },
        ]
      },
      {
        'name': 'Bodyweight Beast',
        'description':
            'No gym? No problem. Transform your physique with just your bodyweight in 8 weeks.',
        'imageUrl':
            'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=800',
        'category': 'strength',
        'difficulty': 'intermediate',
        'durationWeeks': 8,
        'workoutsPerWeek': 4,
        'goals': ['Muscle definition', 'Mobility', 'Strength without weights'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Upper Body Push',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Diamond Pushups',
                'category': 'strength',
                'sets': 4,
                'reps': 15
              },
              {
                'name': 'Bodyweight Dips',
                'category': 'strength',
                'sets': 3,
                'reps': 12
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 3,
            'title': 'Upper Body Pull',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {'name': 'Pullups', 'category': 'strength', 'sets': 4, 'reps': 8},
              {
                'name': 'Australian Pullups',
                'category': 'strength',
                'sets': 3,
                'reps': 12
              },
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Lower Body Foundations',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {'name': 'Squats', 'category': 'strength', 'sets': 4, 'reps': 20},
              {'name': 'Lunges', 'category': 'strength', 'sets': 3, 'reps': 15},
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Full Body Flow',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Mixed Movement',
                'category': 'other',
                'durationSeconds': 3600
              }
            ]
          },
        ]
      },
      {
        'name': 'Zen Master',
        'description':
            'Advanced yoga flows focusing on complex asanas and deep meditative practices over 12 weeks.',
        'imageUrl':
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
        'category': 'yoga',
        'difficulty': 'advanced',
        'durationWeeks': 12,
        'workoutsPerWeek': 6,
        'goals': [
          'Spiritual connection',
          'Inversion mastery',
          'Extreme flexibility'
        ],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Power Flow',
            'isRestDay': false,
            'estimatedMinutes': 75,
            'exercises': [
              {
                'name': 'Crow Pose to Tripod',
                'category': 'yoga',
                'durationSeconds': 600
              },
              {
                'name': 'Handstand Prep',
                'category': 'yoga',
                'durationSeconds': 600
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Advanced Balance',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'King Pigeon Flow',
                'category': 'yoga',
                'durationSeconds': 3600
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 4,
            'title': 'Strength & Vinyasa',
            'isRestDay': false,
            'estimatedMinutes': 80,
            'exercises': [
              {
                'name': 'Advanced Vinyasa',
                'category': 'yoga',
                'durationSeconds': 4800
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Restorative Session',
            'isRestDay': false,
            'estimatedMinutes': 90,
            'exercises': [
              {
                'name': 'Deep Tissues Release',
                'category': 'yoga',
                'durationSeconds': 5400
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Peak Pose Practice',
            'isRestDay': false,
            'estimatedMinutes': 90,
            'exercises': [
              {
                'name': 'Focus on Scorpion',
                'category': 'yoga',
                'durationSeconds': 5400
              }
            ]
          },
        ]
      },
      {
        'name': 'Cycling Circuit',
        'description':
            'A 6-week road cycling and stationary bike program to boost your FTP and lower body power.',
        'imageUrl':
            'https://images.unsplash.com/photo-1507398941214-57f1cca6cf61?w=800',
        'category': 'cardio',
        'difficulty': 'intermediate',
        'durationWeeks': 6,
        'workoutsPerWeek': 4,
        'goals': ['Leg strength', 'Cardio health', 'Speed endurance'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Climbing Repeats',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Hill Sprints',
                'category': 'cardio',
                'durationSeconds': 1800
              },
              {
                'name': 'High Cadence Work',
                'category': 'cardio',
                'durationSeconds': 1800
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Endurance Ride',
            'isRestDay': false,
            'estimatedMinutes': 90,
            'exercises': [
              {
                'name': 'Steady Power Output',
                'category': 'cardio',
                'durationSeconds': 5400
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 4,
            'title': 'Interval Training',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Sprint Sets',
                'category': 'cardio',
                'durationSeconds': 3600
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Active Recovery',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Light Spinning',
                'category': 'cardio',
                'durationSeconds': 2700
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Long Ride',
            'isRestDay': false,
            'estimatedMinutes': 180,
            'exercises': [
              {
                'name': 'Endurance Miles',
                'category': 'cardio',
                'durationSeconds': 10800
              }
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
        ]
      },
      {
        'name': 'Boxing Basics',
        'description':
            'Learn the sweet science. 4 weeks of footwork, punches, and conditioning for beginners.',
        'imageUrl':
            'https://images.unsplash.com/photo-1549719386-74dfcbf7dbed?w=800',
        'category': 'other',
        'difficulty': 'beginner',
        'durationWeeks': 4,
        'workoutsPerWeek': 3,
        'goals': ['Self-defense', 'Coordination', 'Fun cardio'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Jab-Cross Foundations',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Shadow Boxing',
                'category': 'other',
                'durationSeconds': 900
              },
              {
                'name': 'Heavy Bag Drill',
                'category': 'other',
                'durationSeconds': 1800
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Footwork & Agility',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Agility Ladder',
                'category': 'other',
                'durationSeconds': 2400
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 4,
            'title': 'Hook & Uppercut',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Combo Practice',
                'category': 'other',
                'durationSeconds': 2700
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Defense Skills',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Slip and Roll',
                'category': 'other',
                'durationSeconds': 2400
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Sparring Prep',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Speed Bag',
                'category': 'other',
                'durationSeconds': 3600
              }
            ]
          },
        ]
      },
      {
        'name': 'Ab Accelerator',
        'description':
            'A focused 4-week core-only program to build strength and reveal definition.',
        'imageUrl':
            'https://images.unsplash.com/photo-1571019623452-8d75c12615ef?w=800',
        'category': 'strength',
        'difficulty': 'beginner',
        'durationWeeks': 4,
        'workoutsPerWeek': 7,
        'goals': ['Six-pack prep', 'Core stability', 'Lower back health'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Core Ignition',
            'isRestDay': false,
            'estimatedMinutes': 15,
            'exercises': [
              {'name': 'Plank', 'category': 'strength', 'durationSeconds': 60},
              {
                'name': 'Hollow Body Hold',
                'category': 'strength',
                'durationSeconds': 60
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Side Core',
            'isRestDay': false,
            'estimatedMinutes': 15,
            'exercises': [
              {
                'name': 'Russian Twists',
                'category': 'strength',
                'sets': 3,
                'reps': 20
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Lower Core',
            'isRestDay': false,
            'estimatedMinutes': 15,
            'exercises': [
              {
                'name': 'Leg Raises',
                'category': 'strength',
                'sets': 3,
                'reps': 15
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Oblique Burn',
            'isRestDay': false,
            'estimatedMinutes': 15,
            'exercises': [
              {
                'name': 'Side Planks',
                'category': 'strength',
                'durationSeconds': 120
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Stability Core',
            'isRestDay': false,
            'estimatedMinutes': 15,
            'exercises': [
              {
                'name': 'Dead Bug',
                'category': 'strength',
                'sets': 3,
                'reps': 12
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Cardio Core',
            'isRestDay': false,
            'estimatedMinutes': 15,
            'exercises': [
              {
                'name': 'Mountain Climbers',
                'category': 'strength',
                'durationSeconds': 60
              }
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Full Core Blast',
            'isRestDay': false,
            'estimatedMinutes': 15,
            'exercises': [
              {
                'name': 'Bicycle Crunches',
                'category': 'strength',
                'sets': 3,
                'reps': 30
              }
            ]
          },
        ]
      },
      {
        'name': 'Flexibility Fixer',
        'description':
            'Combat the effects of sitting. 6 weeks to significantly improve your range of motion.',
        'imageUrl':
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
        'category': 'yoga',
        'difficulty': 'beginner',
        'durationWeeks': 6,
        'workoutsPerWeek': 3,
        'goals': ['Reduced pain', 'Better form', 'Relaxation'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Hip Opener',
            'isRestDay': false,
            'estimatedMinutes': 20,
            'exercises': [
              {
                'name': 'Pigeon Pose',
                'category': 'yoga',
                'durationSeconds': 300
              }
            ]
          }
        ]
      },
      {
        'name': 'Spartan Sprint Prep',
        'description':
            'Conquer any obstacle. 8 weeks of specialized training for your first OCR race.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517404212738-198301e9538c?w=800',
        'category': 'other',
        'difficulty': 'advanced',
        'durationWeeks': 8,
        'workoutsPerWeek': 4,
        'goals': ['Grip strength', 'Agility', 'Vertical power'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Thoracic Opening',
            'isRestDay': false,
            'estimatedMinutes': 15,
            'exercises': [
              {
                'name': 'Face Pulls',
                'category': 'strength',
                'sets': 3,
                'reps': 15
              },
              {
                'name': 'Wall Slides',
                'category': 'other',
                'sets': 3,
                'reps': 12
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Neck Relief',
            'isRestDay': false,
            'estimatedMinutes': 10,
            'exercises': [
              {'name': 'Chin Tucks', 'category': 'other', 'sets': 5, 'reps': 5}
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Lower Back Support',
            'isRestDay': false,
            'estimatedMinutes': 20,
            'exercises': [
              {
                'name': 'Bird Dog',
                'category': 'strength',
                'sets': 3,
                'reps': 10
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Hip Flexor Stretch',
            'isRestDay': false,
            'estimatedMinutes': 15,
            'exercises': [
              {
                'name': 'Couch Stretch',
                'category': 'yoga',
                'durationSeconds': 600
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Posture Check',
            'isRestDay': false,
            'estimatedMinutes': 10,
            'exercises': [
              {
                'name': 'Scapular Squeezes',
                'category': 'other',
                'sets': 3,
                'reps': 15
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Full Spine Reset',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Yoga for Posture',
                'category': 'yoga',
                'durationSeconds': 1800
              }
            ]
          },
        ]
      },
      {
        'name': 'Triathlete Training',
        'description':
            'The ultimate test of endurance. 16 weeks to prepare you for a sprint or Olympic distance triathlon.',
        'imageUrl':
            'https://images.unsplash.com/photo-1530549387074-d56a99e142e0?w=800',
        'category': 'cardio',
        'difficulty': 'expert',
        'durationWeeks': 16,
        'workoutsPerWeek': 6,
        'goals': [
          'Swim/Bike/Run mastery',
          'Transition speed',
          'Fueling strategy'
        ],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Brick Workout',
            'isRestDay': false,
            'estimatedMinutes': 90,
            'exercises': [
              {
                'name': 'Bike to Run',
                'category': 'cardio',
                'durationSeconds': 5400
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Swim Technique',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Stroke Drill',
                'category': 'cardio',
                'durationSeconds': 2700
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Long Bike',
            'isRestDay': false,
            'estimatedMinutes': 120,
            'exercises': [
              {
                'name': 'Steady Power',
                'category': 'cardio',
                'durationSeconds': 7200
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Interval Run',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Mile Repeats',
                'category': 'cardio',
                'durationSeconds': 3600
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Open Water Swim',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Endurance Laps',
                'category': 'cardio',
                'durationSeconds': 2400
              }
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
        ]
      },
      {
        'name': 'Barre Burn',
        'description':
            'Low-impact, high-intensity exercises inspired by ballet and pilates for lean muscle.',
        'imageUrl':
            'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800',
        'category': 'other',
        'difficulty': 'intermediate',
        'durationWeeks': 6,
        'workoutsPerWeek': 4,
        'goals': ['Endurance', 'Stability', 'Toning'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Lower Body Focus',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Plié Squats',
                'category': 'other',
                'sets': 4,
                'reps': 30
              }
            ]
          }
        ]
      },
      {
        'name': 'Mobility Magic',
        'description':
            'Open up your joints and move like you were meant to. 4 weeks of mobility flows.',
        'imageUrl':
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
        'category': 'yoga',
        'difficulty': 'beginner',
        'durationWeeks': 4,
        'workoutsPerWeek': 5,
        'goals': ['Joint health', 'Injury prevention', 'Ease of movement'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Daily Maintenance',
            'isRestDay': false,
            'estimatedMinutes': 15,
            'exercises': [
              {
                'name': 'Car Scapes',
                'category': 'other',
                'durationSeconds': 600
              },
              {
                'name': 'Hips & Ankles',
                'category': 'other',
                'durationSeconds': 300
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Thoracic Flow',
            'isRestDay': false,
            'estimatedMinutes': 20,
            'exercises': [
              {
                'name': 'Spine Mobility',
                'category': 'yoga',
                'durationSeconds': 1200
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Lower Body Opening',
            'isRestDay': false,
            'estimatedMinutes': 20,
            'exercises': [
              {
                'name': 'Hamstring Stretch',
                'category': 'yoga',
                'durationSeconds': 1200
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Shoulder Health',
            'isRestDay': false,
            'estimatedMinutes': 15,
            'exercises': [
              {
                'name': 'Rotator Cuff Flow',
                'category': 'other',
                'durationSeconds': 900
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Full Body Wakeup',
            'isRestDay': false,
            'estimatedMinutes': 25,
            'exercises': [
              {
                'name': 'Sunrise Mobility',
                'category': 'yoga',
                'durationSeconds': 1500
              }
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Deep Tissue Release',
            'isRestDay': true,
            'estimatedMinutes': 10,
            'exercises': []
          },
        ]
      },
      {
        'name': 'Strongman Strength',
        'description':
            'Move heavy objects through distance and time. 12 weeks of unconventional strength training.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517404212738-198301e9538c?w=800',
        'category': 'strength',
        'difficulty': 'expert',
        'durationWeeks': 12,
        'workoutsPerWeek': 4,
        'goals': ['Brute force', 'Grip strength', 'Work capacity'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Log Press and Carry',
            'isRestDay': false,
            'estimatedMinutes': 120,
            'exercises': [
              {
                'name': 'Farmer Walks',
                'category': 'strength',
                'sets': 4,
                'reps': 1
              },
              {
                'name': 'Log Press',
                'category': 'strength',
                'sets': 5,
                'reps': 3
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 3,
            'title': 'Deadlift & Drag',
            'isRestDay': false,
            'estimatedMinutes': 100,
            'exercises': [
              {
                'name': 'Axle Deadlift',
                'category': 'strength',
                'sets': 3,
                'reps': 5
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Overhead & Grip',
            'isRestDay': false,
            'estimatedMinutes': 110,
            'exercises': [
              {
                'name': 'Sandbag Carry',
                'category': 'strength',
                'sets': 4,
                'reps': 1
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Conditioning Day',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {'name': 'Sled Push', 'category': 'hiit', 'durationSeconds': 2400}
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
        ]
      },
      {
        'name': 'Kettlebell Flow',
        'description':
            'Fluid movement and strength combined into 6 weeks of kettlebell-focused flows.',
        'imageUrl':
            'https://images.unsplash.com/photo-1526402369013-17865c697f2b?w=800',
        'category': 'strength',
        'difficulty': 'intermediate',
        'durationWeeks': 6,
        'workoutsPerWeek': 4,
        'goals': ['Coordination', 'Dynamic strength', 'Flow state'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'The Flow Suite',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Halo to Snatch',
                'category': 'strength',
                'sets': 3,
                'reps': 12
              },
              {
                'name': 'KB Windmill Flow',
                'category': 'strength',
                'sets': 3,
                'reps': 8
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 3,
            'title': 'Explosive Flow',
            'isRestDay': false,
            'estimatedMinutes': 35,
            'exercises': [
              {
                'name': 'KB Swing to Catch',
                'category': 'strength',
                'sets': 5,
                'reps': 15
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Core & Stability',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Around the World',
                'category': 'strength',
                'sets': 3,
                'reps': 20
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Final Flow Challenge',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {
                'name': 'Timed KB Complex',
                'category': 'strength',
                'durationSeconds': 3000
              }
            ]
          },
        ]
      },
      {
        'name': 'Tabata Torch',
        'description':
            'High intensity, low volume. 4 weeks of scientifically proven fat burning intervals.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517931900292-069f74567403?w=800',
        'category': 'hiit',
        'difficulty': 'expert',
        'durationWeeks': 4,
        'workoutsPerWeek': 3,
        'goals': ['Fat loss', 'Improved VO2 Max', 'Time efficiency'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Tabata Sprints',
            'isRestDay': false,
            'estimatedMinutes': 20,
            'exercises': [
              {
                'name': 'Max Effort Sprints',
                'category': 'hiit',
                'sets': 8,
                'reps': 1
              },
              {
                'name': 'High Knee Recovery',
                'category': 'hiit',
                'durationSeconds': 300
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 3,
            'title': 'Tabata Bodyweight',
            'isRestDay': false,
            'estimatedMinutes': 20,
            'exercises': [
              {
                'name': 'Burpee Tabata',
                'category': 'hiit',
                'sets': 8,
                'reps': 1
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Tabata Core',
            'isRestDay': false,
            'estimatedMinutes': 20,
            'exercises': [
              {'name': 'Plank Tabata', 'category': 'hiit', 'sets': 8, 'reps': 1}
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Weekend Torch',
            'isRestDay': false,
            'estimatedMinutes': 25,
            'exercises': [
              {
                'name': 'Mixed Movement HIIT',
                'category': 'hiit',
                'durationSeconds': 1500
              }
            ]
          },
        ]
      },
      {
        'name': 'Pregnancy Pilates',
        'description':
            'Safe and effective core and pelvic floor strength for expecting mothers across all trimesters.',
        'imageUrl':
            'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800',
        'category': 'other',
        'difficulty': 'beginner',
        'durationWeeks': 36,
        'workoutsPerWeek': 2,
        'goals': ['Safe movement', 'Pain relief', 'Preparation for labor'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Trimester Flow',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Pelvic Tilts',
                'category': 'pilates',
                'sets': 3,
                'reps': 12
              },
              {
                'name': 'Gentle Cat-Cow',
                'category': 'yoga',
                'durationSeconds': 300
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Safe Core Foundations',
            'isRestDay': false,
            'estimatedMinutes': 25,
            'exercises': [
              {
                'name': 'Modified Plank',
                'category': 'pilates',
                'durationSeconds': 300
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 4,
            'title': 'Lower Body Relief',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Wall Squats',
                'category': 'pilates',
                'sets': 3,
                'reps': 10
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Active Recovery Walk',
            'isRestDay': true,
            'estimatedMinutes': 20,
            'exercises': []
          },
          {
            'dayNumber': 6,
            'title': 'Pelvic Floor Strengthening',
            'isRestDay': false,
            'estimatedMinutes': 15,
            'exercises': [
              {
                'name': 'Kegel Practice',
                'category': 'other',
                'durationSeconds': 900
              }
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Deep Relaxation',
            'isRestDay': true,
            'estimatedMinutes': 15,
            'exercises': []
          },
        ]
      },
      {
        'name': 'Senior Strength',
        'description':
            'Stay active and independent. 8 weeks of gentle strength training for seniors.',
        'imageUrl':
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
        'category': 'strength',
        'difficulty': 'beginner',
        'durationWeeks': 8,
        'workoutsPerWeek': 2,
        'goals': ['Balance', 'Bone density', 'Joint health'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Silver Strength',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Chair Squats',
                'category': 'strength',
                'sets': 3,
                'reps': 10
              },
              {
                'name': 'Seated Rows with Bands',
                'category': 'strength',
                'sets': 3,
                'reps': 12
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Balance & Stability',
            'isRestDay': false,
            'estimatedMinutes': 20,
            'exercises': [
              {
                'name': 'Single Leg Stand',
                'category': 'other',
                'durationSeconds': 600
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 4,
            'title': 'Gentle Cardio',
            'isRestDay': false,
            'estimatedMinutes': 25,
            'exercises': [
              {
                'name': 'Brisk Walking',
                'category': 'cardio',
                'durationSeconds': 1500
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Mobility & Stretching',
            'isRestDay': false,
            'estimatedMinutes': 20,
            'exercises': [
              {
                'name': 'Joint Rotations',
                'category': 'yoga',
                'durationSeconds': 1200
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Active Seniors Hike',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Nature Walk',
                'category': 'cardio',
                'durationSeconds': 2400
              }
            ]
          },
        ]
      },
      {
        'name': 'Posture Perfect',
        'description':
            'Correct your desk-bound posture with 4 weeks of targeted upper back and neck mobility.',
        'imageUrl':
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
        'category': 'other',
        'difficulty': 'beginner',
        'durationWeeks': 4,
        'workoutsPerWeek': 5,
        'goals': ['Pain reduction', 'Alignment', 'Better habits'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Thoracic Opening',
            'isRestDay': false,
            'estimatedMinutes': 15,
            'exercises': [
              {
                'name': 'Face Pulls',
                'category': 'strength',
                'sets': 3,
                'reps': 15
              }
            ]
          }
        ]
      },
      {
        'name': 'Vertical Jump Pro',
        'description':
            'Scientifically backed 10-week plyometric program to add inches to your vertical leap.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517404212738-198301e9538c?w=800',
        'category': 'strength',
        'difficulty': 'advanced',
        'durationWeeks': 10,
        'workoutsPerWeek': 3,
        'goals': ['Explosive power', 'Landing mechanics', 'Reactive strength'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Peak Power',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {'name': 'Box Jumps', 'category': 'hiit', 'sets': 5, 'reps': 5},
              {'name': 'Depth Jumps', 'category': 'hiit', 'sets': 3, 'reps': 5},
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Strength Base',
            'isRestDay': false,
            'estimatedMinutes': 70,
            'exercises': [
              {
                'name': 'Back Squats for Explosiveness',
                'category': 'strength',
                'sets': 5,
                'reps': 2
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 4,
            'title': 'Plyometric Circuit',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {'name': 'Broad Jumps', 'category': 'hiit', 'sets': 4, 'reps': 6}
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Reactive Strength',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {'name': 'Pogo Jumps', 'category': 'hiit', 'sets': 3, 'reps': 20}
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Maximum Intent Leap',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Max Vertical Jumps',
                'category': 'hiit',
                'sets': 10,
                'reps': 1
              }
            ]
          },
        ]
      },
      {
        'name': 'Fat Burning Fast',
        'description':
            '6 weeks of mixed-modality training optimized for total energy expenditure.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800',
        'category': 'hiit',
        'difficulty': 'intermediate',
        'durationWeeks': 6,
        'workoutsPerWeek': 4,
        'goals': ['Weight management', 'Metabolic health', 'Efficiency'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Metabolic Melt',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Thrusters',
                'category': 'strength',
                'sets': 4,
                'reps': 12
              },
              {
                'name': 'Kettlebell Swings',
                'category': 'strength',
                'sets': 4,
                'reps': 20
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Interval Cardio',
            'isRestDay': false,
            'estimatedMinutes': 35,
            'exercises': [
              {
                'name': 'Sprinting Intervals',
                'category': 'cardio',
                'durationSeconds': 2100
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 4,
            'title': 'Density Set',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'EMOM Workout',
                'category': 'hiit',
                'durationSeconds': 2700
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Strength Endurance',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {
                'name': 'High Volume Push-ups',
                'category': 'strength',
                'sets': 10,
                'reps': 10
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Fat Loss Finale',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Long Duration HIIT',
                'category': 'hiit',
                'durationSeconds': 3600
              }
            ]
          },
        ]
      },
      {
        'name': 'Marathon Prep Phase 2',
        'description':
            'The crucial 8-week sharpening phase for runners heading into their first full marathon.',
        'imageUrl':
            'https://images.unsplash.com/photo-1530549387074-d56a99e142e0?w=800',
        'category': 'cardio',
        'difficulty': 'expert',
        'durationWeeks': 8,
        'workoutsPerWeek': 5,
        'goals': ['Race pace', 'Volume peaking', 'Tapering'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Threshold Run',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Tempo Laps',
                'category': 'cardio',
                'durationSeconds': 3600
              },
              {
                'name': 'Dynamic Stretches',
                'category': 'yoga',
                'durationSeconds': 600
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 3,
            'title': 'Speed Intervals',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {
                'name': '800m Repeats',
                'category': 'cardio',
                'durationSeconds': 3000
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Cross Training',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Cycling Base',
                'category': 'cardio',
                'durationSeconds': 2700
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Recovery Run',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Easy Miles',
                'category': 'cardio',
                'durationSeconds': 1800
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'The Big Long Run',
            'isRestDay': false,
            'estimatedMinutes': 180,
            'exercises': [
              {
                'name': 'Peak Volume Miles',
                'category': 'cardio',
                'durationSeconds': 10800
              }
            ]
          },
        ]
      },
      {
        'name': 'Yoga for Runners',
        'description':
            'Specifically designed sequence for runners to address common imbalances and tight spots.',
        'imageUrl':
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
        'category': 'yoga',
        'difficulty': 'intermediate',
        'durationWeeks': 6,
        'workoutsPerWeek': 3,
        'goals': ['Injury prevention', 'Better stride', 'Breath control'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Glute and IT Band Fix',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {'name': 'Hero Pose', 'category': 'yoga', 'durationSeconds': 600}
            ]
          }
        ]
      },
      {
        'name': 'Calisthenics King',
        'description':
            '12 weeks of skill-based bodyweight training targeting Front Lever, Back Lever, and Planche.',
        'imageUrl':
            'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=800',
        'category': 'strength',
        'difficulty': 'advanced',
        'durationWeeks': 12,
        'workoutsPerWeek': 5,
        'goals': ['Static holds', 'Pulling power', 'Proprioception'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Pushing Mastery',
            'isRestDay': false,
            'estimatedMinutes': 70,
            'exercises': [
              {
                'name': 'Pseudo Planche Pushups',
                'category': 'strength',
                'sets': 4,
                'reps': 8
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Pulling Power',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Front Lever Tucks',
                'category': 'strength',
                'sets': 5,
                'reps': 5
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 4,
            'title': 'Core Strength',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Dragon Flags',
                'category': 'strength',
                'sets': 3,
                'reps': 8
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Skill Practice',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Handstand Hold',
                'category': 'other',
                'durationSeconds': 1800
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Full Body Bar Work',
            'isRestDay': false,
            'estimatedMinutes': 90,
            'exercises': [
              {
                'name': 'Muscle Ups',
                'category': 'strength',
                'sets': 4,
                'reps': 5
              }
            ]
          },
        ]
      },
      {
        'name': 'Iron Core',
        'description':
            '8 weeks of direct core work focusing on carry patterns and anti-rotation movements.',
        'imageUrl':
            'https://images.unsplash.com/photo-1571019623452-8d75c12615ef?w=800',
        'category': 'other',
        'difficulty': 'intermediate',
        'durationWeeks': 8,
        'workoutsPerWeek': 3,
        'goals': ['Functional stability', 'Heavy carries', 'Abdominal density'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'The Anti-Rotation Suite',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Thrusters',
                'category': 'strength',
                'sets': 4,
                'reps': 12
              },
              {
                'name': 'Kettlebell Swings',
                'category': 'strength',
                'sets': 4,
                'reps': 20
              },
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Interval Cardio',
            'isRestDay': false,
            'estimatedMinutes': 35,
            'exercises': [
              {
                'name': 'Sprinting Intervals',
                'category': 'cardio',
                'durationSeconds': 2100
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 4,
            'title': 'Density Set',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'EMOM Workout',
                'category': 'hiit',
                'durationSeconds': 2700
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Strength Endurance',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {
                'name': 'High Volume Push-ups',
                'category': 'strength',
                'sets': 10,
                'reps': 10
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Fat Loss Finale',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Long Duration HIIT',
                'category': 'hiit',
                'durationSeconds': 3600
              }
            ]
          },
        ]
      },
      {
        'name': 'Morning Cardio',
        'description':
            'Jumpstart your metabolism with 4 weeks of consistent, low-impact morning cardio.',
        'imageUrl':
            'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=800',
        'category': 'cardio',
        'difficulty': 'beginner',
        'durationWeeks': 4,
        'workoutsPerWeek': 7,
        'goals': ['Routine building', 'Cardio base', 'Sunlight exposure'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Fasted Walk',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Brisk Walk',
                'category': 'cardio',
                'durationSeconds': 1800
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Morning Yoga',
            'isRestDay': false,
            'estimatedMinutes': 20,
            'exercises': [
              {
                'name': 'Sun Salutations',
                'category': 'yoga',
                'durationSeconds': 1200
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Fasted Jog',
            'isRestDay': false,
            'estimatedMinutes': 25,
            'exercises': [
              {
                'name': 'Easy Jog',
                'category': 'cardio',
                'durationSeconds': 1500
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Mobility Flow',
            'isRestDay': false,
            'estimatedMinutes': 15,
            'exercises': [
              {
                'name': 'Full Body Flow',
                'category': 'yoga',
                'durationSeconds': 900
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Interval Walk',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Speed Intervals Walk',
                'category': 'cardio',
                'durationSeconds': 1800
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Active Recovery',
            'isRestDay': true,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Leisurely Hike',
                'category': 'cardio',
                'durationSeconds': 2700
              }
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Mindfulness Walk',
            'isRestDay': false,
            'estimatedMinutes': 20,
            'exercises': [
              {
                'name': 'Nature Breath Walk',
                'category': 'cardio',
                'durationSeconds': 1200
              }
            ]
          },
        ]
      },
      {
        'name': 'Desk Job Stretch',
        'description':
            'Daily 10-minute micro-workouts to reverse the "C-curve" posture of office workers.',
        'imageUrl':
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
        'category': 'other',
        'difficulty': 'beginner',
        'durationWeeks': 52,
        'workoutsPerWeek': 5,
        'goals': ['Reduced stiffness', 'Mental break', 'Energy levels'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Chair Opening',
            'isRestDay': false,
            'estimatedMinutes': 10,
            'exercises': [
              {
                'name': 'Chest Stretch',
                'category': 'yoga',
                'durationSeconds': 120
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Spine Twist',
            'isRestDay': false,
            'estimatedMinutes': 10,
            'exercises': [
              {
                'name': 'Seated Twist',
                'category': 'yoga',
                'durationSeconds': 600
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Neck Relief',
            'isRestDay': false,
            'estimatedMinutes': 10,
            'exercises': [
              {
                'name': 'Neck Circles',
                'category': 'yoga',
                'durationSeconds': 600
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Hip Release',
            'isRestDay': false,
            'estimatedMinutes': 10,
            'exercises': [
              {
                'name': 'Seated Pigeon',
                'category': 'yoga',
                'durationSeconds': 600
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Wrist Care',
            'isRestDay': false,
            'estimatedMinutes': 10,
            'exercises': [
              {
                'name': 'Forearm Stretch',
                'category': 'other',
                'durationSeconds': 600
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
        ]
      },
      {
        'name': 'Power Yoga',
        'description':
            '10 weeks of physically demanding yoga practice to build both strength and focus.',
        'imageUrl':
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
        'category': 'yoga',
        'difficulty': 'advanced',
        'durationWeeks': 10,
        'workoutsPerWeek': 4,
        'goals': ['Upper body strength', 'Balance', 'Control'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Upper Body Focus Flow',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {
                'name': 'Chaturanga Repeats',
                'category': 'yoga',
                'sets': 5,
                'reps': 5
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Balance Mastery',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Warrior III Reps',
                'category': 'yoga',
                'durationSeconds': 2400
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 4,
            'title': 'Core Ignition Flow',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Boat Pose Pulses',
                'category': 'yoga',
                'sets': 4,
                'reps': 15
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 6,
            'title': 'Full Body Power',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Advanced Vinyasa',
                'category': 'yoga',
                'durationSeconds': 3600
              }
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Sun Salute Challenge',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': '108 Sun Salutations',
                'category': 'yoga',
                'durationSeconds': 1800
              }
            ]
          },
        ]
      },
      {
        'name': 'Bulking Season',
        'description':
            'The definitive hyper-trophy program for packing on serious muscle mass over 12 weeks.',
        'imageUrl':
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
        'category': 'strength',
        'difficulty': 'expert',
        'durationWeeks': 12,
        'workoutsPerWeek': 5,
        'goals': ['Muscle growth', 'High volume tolerance', 'Weight gain'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Leg Hypertrophy',
            'isRestDay': false,
            'estimatedMinutes': 80,
            'exercises': [
              {
                'name': 'Hack Squats',
                'category': 'strength',
                'sets': 4,
                'reps': 12
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Upper Body Push',
            'isRestDay': false,
            'estimatedMinutes': 75,
            'exercises': [
              {
                'name': 'Bench Press',
                'category': 'strength',
                'sets': 4,
                'reps': 10
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 4,
            'title': 'Upper Body Pull',
            'isRestDay': false,
            'estimatedMinutes': 75,
            'exercises': [
              {
                'name': 'Barbell Rows',
                'category': 'strength',
                'sets': 4,
                'reps': 10
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Shoulder & Arm Day',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Lateral Raises',
                'category': 'strength',
                'sets': 5,
                'reps': 15
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Weak Point Training',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {
                'name': 'Mixed Accessory',
                'category': 'strength',
                'durationSeconds': 3000
              }
            ]
          },
        ]
      },
      {
        'name': 'Cutting Phase',
        'description':
            'Maintain muscle while dropping body fat. A 12-week high-frequency, high-intensity program.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800',
        'category': 'other',
        'difficulty': 'intermediate',
        'durationWeeks': 12,
        'workoutsPerWeek': 6,
        'goals': ['Fat loss', 'Muscle retention', 'Vascularity'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Full Body Circuit',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {
                'name': 'Clean and Press',
                'category': 'strength',
                'sets': 4,
                'reps': 10
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Steady State Cardio',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Incline Walk',
                'category': 'cardio',
                'durationSeconds': 2700
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Metabolic HIIT',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Kettlebell Complex',
                'category': 'hiit',
                'durationSeconds': 1800
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Full Body Strength',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {'name': 'Deadlift', 'category': 'strength', 'sets': 3, 'reps': 5}
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Long Duration Cardio',
            'isRestDay': false,
            'estimatedMinutes': 90,
            'exercises': [
              {'name': 'Cycling', 'category': 'cardio', 'durationSeconds': 5400}
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
        ]
      },
      {
        'name': 'Speed Skating Prep',
        'description':
            'Niche focus on lateral power, hip stability, and high-intensity aerobic capacity.',
        'imageUrl':
            'https://images.unsplash.com/photo-1507398941214-57f1cca6cf61?w=800',
        'category': 'other',
        'difficulty': 'advanced',
        'durationWeeks': 8,
        'workoutsPerWeek': 4,
        'goals': ['Lateral power', 'Hip health', 'Lactic threshold'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Lateral Explosiveness',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {
                'name': 'Lateral Jumps',
                'category': 'hiit',
                'sets': 5,
                'reps': 10
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Hip Stability Flow',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Single Leg Balance',
                'category': 'other',
                'durationSeconds': 1800
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Lactic Threshold Ride',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Speed Skating Laps',
                'category': 'cardio',
                'durationSeconds': 3600
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Isometric Hold Suite',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Skater Squat Holds',
                'category': 'strength',
                'sets': 3,
                'reps': 10
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Endurance Laps',
            'isRestDay': false,
            'estimatedMinutes': 90,
            'exercises': [
              {
                'name': 'Steady Pace Skating',
                'category': 'cardio',
                'durationSeconds': 5400
              }
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
        ]
      },
      {
        'name': 'Rock Climbing Ready',
        'description':
            'Better grip, better pull, better reach. 8 weeks to improve your climbing grade.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517404212738-198301e9538c?w=800',
        'category': 'strength',
        'difficulty': 'intermediate',
        'durationWeeks': 8,
        'workoutsPerWeek': 3,
        'goals': ['Grip strength', 'Pulling power', 'Mindset'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Hangboard and Pulls',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Weighted Pulls',
                'category': 'strength',
                'sets': 4,
                'reps': 6
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Finger Strength Prep',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Dead Hangs',
                'category': 'strength',
                'durationSeconds': 1800
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Climbing Specific Core',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Toes to Bar',
                'category': 'strength',
                'sets': 3,
                'reps': 12
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Technique Clinic',
            'isRestDay': false,
            'estimatedMinutes': 90,
            'exercises': [
              {
                'name': 'Static Traverse',
                'category': 'other',
                'durationSeconds': 5400
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Project Climbing',
            'isRestDay': false,
            'estimatedMinutes': 120,
            'exercises': [
              {
                'name': 'Hard Bouldering',
                'category': 'other',
                'durationSeconds': 7200
              }
            ]
          },
        ]
      },
      {
        'name': 'Surfer Stamina',
        'description':
            'Improve your paddle power and pop-up speed with 6 weeks of targeted aquatic conditioning.',
        'imageUrl':
            'https://images.unsplash.com/photo-1530549387074-d56a99e142e0?w=800',
        'category': 'other',
        'difficulty': 'intermediate',
        'durationWeeks': 6,
        'workoutsPerWeek': 4,
        'goals': ['Paddle strength', 'Pop-up speed', 'Balance'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Paddle Endurance',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {
                'name': 'Burpee to Pop-up',
                'category': 'other',
                'sets': 4,
                'reps': 15
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Core Stability Flow',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Superman Holds',
                'category': 'strength',
                'durationSeconds': 1800
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Pop-up Speed Drill',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Explosive Push-ups',
                'category': 'strength',
                'sets': 5,
                'reps': 10
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Balance Mastery',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Bosu Ball Squats',
                'category': 'other',
                'sets': 3,
                'reps': 12
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Ocean Conditioning',
            'isRestDay': false,
            'estimatedMinutes': 90,
            'exercises': [
              {
                'name': 'Paddle Practice',
                'category': 'cardio',
                'durationSeconds': 5400
              }
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
        ]
      },
      {
        'name': 'Dance Cardio',
        'description':
            'Burn calories through rhythm. 4 weeks of high-energy dance routines for all levels.',
        'imageUrl':
            'https://images.unsplash.com/photo-1549719386-74dfcbf7dbed?w=800',
        'category': 'cardio',
        'difficulty': 'beginner',
        'durationWeeks': 4,
        'workoutsPerWeek': 3,
        'goals': ['Weight management', 'Coordination', 'Fun'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Rhythm Intro',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Up-tempo Dance',
                'category': 'cardio',
                'durationSeconds': 1800
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Flow and Grooves',
            'isRestDay': false,
            'estimatedMinutes': 35,
            'exercises': [
              {
                'name': 'Slow Groove',
                'category': 'cardio',
                'durationSeconds': 2100
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 4,
            'title': 'Cardio Party',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'High Energy Dance',
                'category': 'cardio',
                'durationSeconds': 2700
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 6,
            'title': 'Weekend Dance-off',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Full Routine',
                'category': 'cardio',
                'durationSeconds': 3600
              }
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Active Recovery Flow',
            'isRestDay': true,
            'estimatedMinutes': 20,
            'exercises': [
              {
                'name': 'Stretching Groove',
                'category': 'yoga',
                'durationSeconds': 1200
              }
            ]
          },
        ]
      },
      {
        'name': 'Kettlebell HIIT',
        'description':
            'The ultimate metabolic conditioning. 6 weeks of high-octane kettlebell intervals.',
        'imageUrl':
            'https://images.unsplash.com/photo-1526402369013-17865c697f2b?w=800',
        'category': 'hiit',
        'difficulty': 'intermediate',
        'durationWeeks': 6,
        'workoutsPerWeek': 3,
        'goals': ['Fat loss', 'Strength endurance', 'Work capacity'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'The Bell Buster',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Double Swings',
                'category': 'strength',
                'sets': 5,
                'reps': 15
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Snatch Hell',
            'isRestDay': false,
            'estimatedMinutes': 25,
            'exercises': [
              {
                'name': 'KB Snatches',
                'category': 'strength',
                'sets': 8,
                'reps': 10
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 4,
            'title': 'Clean and Jerk Circuit',
            'isRestDay': false,
            'estimatedMinutes': 35,
            'exercises': [
              {
                'name': 'KB Clean & Jerks',
                'category': 'strength',
                'durationSeconds': 2100
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 6,
            'title': 'The Final Flow HIIT',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Full KB Complex',
                'category': 'hiit',
                'durationSeconds': 2400
              }
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Active Mobility',
            'isRestDay': true,
            'estimatedMinutes': 20,
            'exercises': [
              {'name': 'KB Halos', 'category': 'other', 'durationSeconds': 1200}
            ]
          },
        ]
      },
      {
        'name': 'Restorative Yoga',
        'description':
            'Maximum recovery. 4 weeks of deep relaxation and extremely long-held poses.',
        'imageUrl':
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
        'category': 'yoga',
        'difficulty': 'expert',
        'durationWeeks': 4,
        'workoutsPerWeek': 2,
        'goals': ['Nervous system reset', 'Healing', 'Reflection'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'The Big Open',
            'isRestDay': false,
            'estimatedMinutes': 90,
            'exercises': [
              {
                'name': 'Supported Child Pose',
                'category': 'yoga',
                'durationSeconds': 1200
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Hip Release',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Wall Pigeon',
                'category': 'yoga',
                'durationSeconds': 3600
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Spine Health',
            'isRestDay': false,
            'estimatedMinutes': 75,
            'exercises': [
              {
                'name': 'Bolster Twists',
                'category': 'yoga',
                'durationSeconds': 4500
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Heart Opener',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Fish Pose with Blocks',
                'category': 'yoga',
                'durationSeconds': 3600
              }
            ]
          },
          {
            'dayNumber': 5,
            'title': 'Lower Body Calm',
            'isRestDay': false,
            'estimatedMinutes': 80,
            'exercises': [
              {
                'name': 'Legs up the Wall',
                'category': 'yoga',
                'durationSeconds': 4800
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Deep Tissue Release',
            'isRestDay': false,
            'estimatedMinutes': 90,
            'exercises': [
              {
                'name': 'Supported Butterfly',
                'category': 'yoga',
                'durationSeconds': 5400
              }
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Total Stillness',
            'isRestDay': false,
            'estimatedMinutes': 120,
            'exercises': [
              {
                'name': 'Yoga Nidra',
                'category': 'other',
                'durationSeconds': 7200
              }
            ]
          },
        ]
      },
      {
        'name': 'Strong Glutes',
        'description':
            'Direct glute hypertrophy and hip stability over 8 weeks of specialized training.',
        'imageUrl':
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
        'category': 'strength',
        'difficulty': 'beginner',
        'durationWeeks': 8,
        'workoutsPerWeek': 3,
        'goals': ['Aesthetics', 'Hip health', 'Lower body power'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Posterior Chain Blast',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Hip Thrusts',
                'category': 'strength',
                'sets': 4,
                'reps': 15
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Abductor Focus',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Clamshells',
                'category': 'strength',
                'sets': 3,
                'reps': 20
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Glute Strength Base',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {
                'name': 'Romanian Deadlifts',
                'category': 'strength',
                'sets': 3,
                'reps': 12
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Explosive Glutes',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'KB Swings',
                'category': 'strength',
                'sets': 5,
                'reps': 20
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'High Volume Finisher',
            'isRestDay': false,
            'estimatedMinutes': 60,
            'exercises': [
              {
                'name': 'Glute Bridge Holds',
                'category': 'strength',
                'durationSeconds': 3600
              }
            ]
          },
        ]
      },
      {
        'name': 'Shoulder Stability',
        'description':
            'Improve overhead mobility and joint durability. 6 weeks concentrated on the shoulder girdle.',
        'imageUrl':
            'https://images.unsplash.com/photo-1517404212738-198301e9538c?w=800',
        'category': 'strength',
        'difficulty': 'intermediate',
        'durationWeeks': 6,
        'workoutsPerWeek': 3,
        'goals': ['Injury prevention', 'Pressing power', 'Durability'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Refining Rotation',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Face Pulls',
                'category': 'strength',
                'sets': 4,
                'reps': 20
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Scapular Power',
            'isRestDay': false,
            'estimatedMinutes': 25,
            'exercises': [
              {
                'name': 'Scapular Pullups',
                'category': 'strength',
                'sets': 3,
                'reps': 12
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Overhead Stability',
            'isRestDay': false,
            'estimatedMinutes': 35,
            'exercises': [
              {
                'name': 'Overhead KB Hold',
                'category': 'strength',
                'durationSeconds': 2100
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Rear Delt Focus',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Band Pull-aparts',
                'category': 'strength',
                'sets': 4,
                'reps': 25
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Full Girdle Health',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Y-W-T-I Raises',
                'category': 'strength',
                'sets': 3,
                'reps': 15
              }
            ]
          },
        ]
      },
      {
        'name': 'Knee Health Protocol',
        'description':
            'Address knee pain and build a foundation for heavy lifting. 8 weeks of bulletproofing.',
        'imageUrl':
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
        'category': 'other',
        'difficulty': 'beginner',
        'durationWeeks': 8,
        'workoutsPerWeek': 3,
        'goals': ['Pain-free movement', 'Quad strength', 'Tendon health'],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Lower Extremity Rehab',
            'isRestDay': false,
            'estimatedMinutes': 40,
            'exercises': [
              {
                'name': 'Split Squats',
                'category': 'strength',
                'sets': 4,
                'reps': 10
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'VMO Activation',
            'isRestDay': false,
            'estimatedMinutes': 30,
            'exercises': [
              {
                'name': 'Terminal Knee Extension',
                'category': 'strength',
                'sets': 3,
                'reps': 20
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Tendon Loading',
            'isRestDay': false,
            'estimatedMinutes': 45,
            'exercises': [
              {
                'name': 'Spanish Squats',
                'category': 'strength',
                'durationSeconds': 2700
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Deceleration Drill',
            'isRestDay': false,
            'estimatedMinutes': 35,
            'exercises': [
              {
                'name': 'Step-downs',
                'category': 'strength',
                'sets': 4,
                'reps': 12
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 7,
            'title': 'Deep Range Loading',
            'isRestDay': false,
            'estimatedMinutes': 50,
            'exercises': [
              {
                'name': 'Full Range Squats',
                'category': 'strength',
                'sets': 3,
                'reps': 15
              }
            ]
          },
        ]
      },
      {
        'name': 'Ultimate Athlete',
        'description':
            'The final transition. 12 weeks of combining strength, speed, and endurance into a peak athletic performance.',
        'imageUrl':
            'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=800',
        'category': 'other',
        'difficulty': 'expert',
        'durationWeeks': 12,
        'workoutsPerWeek': 6,
        'goals': [
          'Peerless athleticism',
          'Total body synergy',
          'Competition readiness'
        ],
        'schedule': [
          {
            'dayNumber': 1,
            'title': 'Performance Peak',
            'isRestDay': false,
            'estimatedMinutes': 100,
            'exercises': [
              {
                'name': 'Power Cleans',
                'category': 'strength',
                'sets': 5,
                'reps': 3
              }
            ]
          },
          {
            'dayNumber': 2,
            'title': 'Endurance Integration',
            'isRestDay': false,
            'estimatedMinutes': 90,
            'exercises': [
              {
                'name': 'Tempo Run',
                'category': 'cardio',
                'durationSeconds': 5400
              }
            ]
          },
          {
            'dayNumber': 3,
            'title': 'Static Strength Base',
            'isRestDay': false,
            'estimatedMinutes': 110,
            'exercises': [
              {
                'name': 'Deep Squats',
                'category': 'strength',
                'sets': 5,
                'reps': 5
              }
            ]
          },
          {
            'dayNumber': 4,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
          {
            'dayNumber': 5,
            'title': 'Explosive Dynamics',
            'isRestDay': false,
            'estimatedMinutes': 80,
            'exercises': [
              {
                'name': 'Broad Jumps to Sprint',
                'category': 'hiit',
                'sets': 10,
                'reps': 1
              }
            ]
          },
          {
            'dayNumber': 6,
            'title': 'Active Resilience',
            'isRestDay': false,
            'estimatedMinutes': 120,
            'exercises': [
              {
                'name': 'Mixed Movement Flow',
                'category': 'other',
                'durationSeconds': 7200
              }
            ]
          },
          {
            'dayNumber': 7,
            'title': 'Rest Day',
            'isRestDay': true,
            'estimatedMinutes': 0,
            'exercises': []
          },
        ]
      },
    ];

    final batch = _firestore.batch();
    for (var p in programs) {
      final docRef = _firestore.collection('workout_programs').doc();
      batch.set(docRef, p);
    }
    await batch.commit();
    await seedChallenges();
  }

  /// Enroll in a program
  Future<void> enrollInProgram(String userId, String programId) async {
    await _enrolledProgramsCollection(userId).doc(programId).set({
      'enrolledAt': Timestamp.now(),
      'currentDayIndex': 0,
      'completedWorkouts': 0,
    });
  }

  /// Unenroll from a program
  Future<void> unenrollFromProgram(String userId, String programId) async {
    await _enrolledProgramsCollection(userId).doc(programId).delete();
  }

  /// Watch enrolled programs
  Stream<List<String>> watchEnrolledProgramIds(String userId) {
    return _enrolledProgramsCollection(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Get specific enrolled program progress
  Future<Map<String, dynamic>?> getEnrolledProgramProgress(
      String userId, String programId) async {
    final doc = await _enrolledProgramsCollection(userId).doc(programId).get();
    return doc.data();
  }

  /// Update program progress
  Future<void> updateProgramProgress(String userId, String programId,
      int completedWorkouts, int currentDayIndex) async {
    await _enrolledProgramsCollection(userId).doc(programId).update({
      'completedWorkouts': completedWorkouts,
      'currentDayIndex': currentDayIndex,
    });
  }

  // ============================================================================
  // PROGRESS PHOTOS
  // ============================================================================

  /// Upload a progress photo
  Future<ProgressPhoto> uploadProgressPhoto(String userId, File photo,
      {double? weight, String? notes}) async {
    final filename = 'progress_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('users/$userId/progress_photos/$filename');

    await ref.putFile(photo);
    final imageUrl = await ref.getDownloadURL();

    final docRef = await _progressPhotosCollection(userId).add({
      'imageUrl': imageUrl,
      'takenAt': Timestamp.now(),
      'weight': weight,
      'notes': notes,
    });

    return ProgressPhoto(
        id: docRef.id,
        imageUrl: imageUrl,
        takenAt: DateTime.now(),
        weight: weight,
        notes: notes);
  }

  /// Watch progress photos
  Stream<List<ProgressPhoto>> watchProgressPhotos(String userId) {
    return _progressPhotosCollection(userId)
        .orderBy('takenAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProgressPhoto.fromFirestore(doc))
            .toList());
  }

  /// Delete a progress photo
  Future<void> deleteProgressPhoto(String userId, ProgressPhoto photo) async {
    try {
      await _storage.refFromURL(photo.imageUrl).delete();
    } catch (_) {}
    await _progressPhotosCollection(userId).doc(photo.id).delete();
  }

  // ============================================================================
  // BODY MEASUREMENTS
  // ============================================================================

  /// Log body measurements
  Future<String> logMeasurements(
      String userId, BodyMeasurements measurements) async {
    final docRef =
        await _measurementsCollection(userId).add(measurements.toFirestore());
    return docRef.id;
  }

  /// Get latest measurements
  Future<BodyMeasurements?> getLatestMeasurements(String userId) async {
    final snapshot = await _measurementsCollection(userId)
        .orderBy('measuredAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return BodyMeasurements.fromFirestore(snapshot.docs.first);
  }

  /// Watch measurements history
  Stream<List<BodyMeasurements>> watchMeasurements(String userId,
      {int limit = 20}) {
    return _measurementsCollection(userId)
        .orderBy('measuredAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BodyMeasurements.fromFirestore(doc))
            .toList());
  }

  // ============================================================================
  // SAVED WORKOUT VIDEOS
  // ============================================================================

  /// Save a workout video
  Future<String> saveVideo(String userId, WorkoutVideo video) async {
    final docRef =
        await _savedVideosCollection(userId).add(video.toFirestore());
    return docRef.id;
  }

  /// Remove saved video
  Future<void> unsaveVideo(String userId, String videoId) async {
    final snapshot = await _savedVideosCollection(userId)
        .where('videoId', isEqualTo: videoId)
        .limit(1)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Watch saved videos
  Stream<List<WorkoutVideo>> watchSavedVideos(String userId) {
    return _savedVideosCollection(userId)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutVideo.fromFirestore(doc))
            .toList());
  }

  /// Check if video is saved
  Future<bool> isVideoSaved(String userId, String videoId) async {
    final snapshot = await _savedVideosCollection(userId)
        .where('videoId', isEqualTo: videoId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // ============================================================================
  // STREAKS & STATISTICS
  // ============================================================================

  /// Get current workout streak
  Future<int> getCurrentStreak(String userId) async {
    final doc = await _statsDoc(userId).get();
    if (doc.exists && doc.data() != null) {
      return doc.data()!['currentStreak'] ?? 0;
    }
    return 0;
  }

  /// Update streak after completing a workout
  Future<void> _updateStreak(String userId) async {
    final doc = await _statsDoc(userId).get();
    final data = doc.data() ?? {};

    final lastWorkoutDate = (data['lastWorkoutDate'] as Timestamp?)?.toDate();
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));

    int currentStreak = data['currentStreak'] ?? 0;
    int longestStreak = data['longestStreak'] ?? 0;

    if (lastWorkoutDate == null) {
      currentStreak = 1;
    } else {
      final lastWorkoutDay = DateTime(
          lastWorkoutDate.year, lastWorkoutDate.month, lastWorkoutDate.day);
      if (lastWorkoutDay == today) {
        // Already logged today
      } else if (lastWorkoutDay == yesterday) {
        currentStreak += 1;
      } else {
        currentStreak = 1;
      }
    }

    if (currentStreak > longestStreak) longestStreak = currentStreak;

    await _statsDoc(userId).set({
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastWorkoutDate': Timestamp.fromDate(today),
      'totalWorkouts': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  /// Get workout statistics
  Future<Map<String, dynamic>> getStats(String userId) async {
    final doc = await _statsDoc(userId).get();
    return doc.data() ??
        {'currentStreak': 0, 'longestStreak': 0, 'totalWorkouts': 0};
  }

  /// Watch stats
  Stream<Map<String, dynamic>> watchStats(String userId) {
    return _statsDoc(userId).snapshots().map((doc) =>
        doc.data() ??
        {'currentStreak': 0, 'longestStreak': 0, 'totalWorkouts': 0});
  }

  // ============================================================================
  // WEEKLY SUMMARY
  // ============================================================================

  /// Get weekly workout summary
  Future<WeeklyWorkoutSummary> getWeeklySummary(
      String userId, DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final sessions = await getSessionsInRange(userId, weekStart, weekEnd);
    final stats = await getStats(userId);

    int totalCalories = 0;
    Duration totalDuration = Duration.zero;
    final categoryMinutes = <ExerciseCategory, int>{};

    for (final session in sessions) {
      totalCalories += session.totalCaloriesBurned;
      totalDuration += session.totalDuration;
      categoryMinutes[session.category] =
          (categoryMinutes[session.category] ?? 0) +
              session.totalDuration.inMinutes;
    }

    return WeeklyWorkoutSummary(
      weekStart: weekStart,
      workoutsCompleted: sessions.length,
      totalDuration: totalDuration,
      totalCaloriesBurned: totalCalories,
      categoryMinutes: categoryMinutes,
      currentStreak: stats['currentStreak'] ?? 0,
      longestStreak: stats['longestStreak'] ?? 0,
    );
  }

  // ============================================================================
  // CHALLENGES & ACHIEVEMENTS (GAMIFICATION)
  // ============================================================================

  CollectionReference _challengesCollection() =>
      _firestore.collection('workout_challenges');
  CollectionReference _userChallengesCollection(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('joined_challenges');
  CollectionReference _userAchievementsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('achievements');

  /// Watch all available challenges
  Stream<List<WorkoutChallenge>> watchChallenges() {
    return _challengesCollection()
        .orderBy('deadline', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutChallenge.fromFirestore(doc))
            .toList());
  }

  /// Watch joined challenges for a user
  Stream<List<String>> watchJoinedChallengeIds(String userId) {
    return _userChallengesCollection(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Join a challenge
  Future<void> joinChallenge(String userId, String challengeId) async {
    await _userChallengesCollection(userId).doc(challengeId).set({
      'joinedAt': Timestamp.now(),
      'progress': 0.0,
      'isCompleted': false,
    });
  }

  /// Watch user achievements
  Stream<List<WorkoutAchievement>> watchAchievements(String userId) {
    return _userAchievementsCollection(userId)
        .orderBy('earnedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutAchievement.fromFirestore(doc))
            .toList());
  }

  /// Seed initial challenges
  Future<void> seedChallenges() async {
    final challenges = [
      {
        'title': '7-Day Streak',
        'description': 'Complete at least one workout every day for a week.',
        'icon': '🔥',
        'creditReward': 500,
        'requirement': {'type': 'streak', 'value': 7},
        'deadline':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'isGlobal': true,
      },
      {
        'title': 'Iron Lungs',
        'description': 'Log 300 minutes of cardio in 30 days.',
        'icon': '🫁',
        'creditReward': 1000,
        'requirement': {'type': 'cardio_minutes', 'value': 300},
        'deadline':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'isGlobal': true,
      },
      {
        'title': 'Yoga Master',
        'description': 'Complete 10 different yoga programs.',
        'icon': '🧘',
        'creditReward': 1500,
        'requirement': {'type': 'yoga_programs', 'value': 10},
        'deadline': null,
        'isGlobal': true,
      },
      {
        'title': 'Heavy Hitter',
        'description':
            'Log 20 strength sessions with at least 5 exercises each.',
        'icon': '💪',
        'creditReward': 2000,
        'requirement': {'type': 'strength_sessions', 'value': 20},
        'deadline':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 60))),
        'isGlobal': true,
      },
    ];

    final batch = _firestore.batch();
    for (var c in challenges) {
      final docRef = _challengesCollection().doc();
      batch.set(docRef, c);
    }
    await batch.commit();
  }

  /// Internal method to award achievement
  Future<void> awardAchievement(
      String userId, String name, String description, String icon,
      {String? challengeId}) async {
    final docRef = _userAchievementsCollection(userId).doc();
    await docRef.set({
      'name': name,
      'description': description,
      'icon': icon,
      'earnedAt': Timestamp.now(),
      'challengeId': challengeId,
    });
  }
}

// ============================================================================
// RIVERPOD PROVIDERS
// ============================================================================

/// Provider for today's exercises
final todayExercisesProvider =
    StreamProvider.family<List<ExerciseEntry>, String>((ref, userId) {
  return ref
      .watch(workoutServiceProvider)
      .watchExercises(userId, DateTime.now());
});

/// Provider for workout goals
final workoutGoalsProvider =
    StreamProvider.family<WorkoutGoals, String>((ref, userId) {
  return ref.watch(workoutServiceProvider).watchGoals(userId);
});

/// Provider for recent workout sessions
final recentSessionsProvider =
    StreamProvider.family<List<WorkoutSession>, String>((ref, userId) {
  return ref.watch(workoutServiceProvider).watchSessions(userId);
});

/// Provider for saved workout videos
final savedWorkoutVideosProvider =
    StreamProvider.family<List<WorkoutVideo>, String>((ref, userId) {
  return ref.watch(workoutServiceProvider).watchSavedVideos(userId);
});

/// Provider for progress photos
final progressPhotosProvider =
    StreamProvider.family<List<ProgressPhoto>, String>((ref, userId) {
  return ref.watch(workoutServiceProvider).watchProgressPhotos(userId);
});

/// Provider for body measurements
final measurementsProvider =
    StreamProvider.family<List<BodyMeasurements>, String>((ref, userId) {
  return ref.watch(workoutServiceProvider).watchMeasurements(userId);
});

/// Provider for workout stats
final workoutStatsProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, userId) {
  return ref.watch(workoutServiceProvider).watchStats(userId);
});

/// Provider for available workout programs
final availableProgramsProvider = StreamProvider<List<WorkoutProgram>>((ref) {
  return ref.watch(workoutServiceProvider).watchAvailablePrograms();
});

/// Provider for enrolled program IDs
final enrolledProgramIdsProvider =
    StreamProvider.family<List<String>, String>((ref, userId) {
  return ref.watch(workoutServiceProvider).watchEnrolledProgramIds(userId);
});

/// Provider for available challenges
final workoutChallengesProvider = StreamProvider<List<WorkoutChallenge>>((ref) {
  return ref.watch(workoutServiceProvider).watchChallenges();
});

/// Provider for joined challenge IDs
final joinedChallengeIdsProvider =
    StreamProvider.family<List<String>, String>((ref, userId) {
  return ref.watch(workoutServiceProvider).watchJoinedChallengeIds(userId);
});

/// Provider for user achievements
final userAchievementsProvider =
    StreamProvider.family<List<WorkoutAchievement>, String>((ref, userId) {
  return ref.watch(workoutServiceProvider).watchAchievements(userId);
});

/// Provider for active workout session
final activeWorkoutSessionProvider =
    StreamProvider.family<WorkoutSession?, String>((ref, userId) {
  return ref.watch(workoutServiceProvider).watchActiveSession(userId);
});
