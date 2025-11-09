import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Wellness entry model
class WellnessModel extends Equatable {
  final String entryId;
  final String userId;
  final DateTime date;
  final WellnessHydration hydration;
  final WellnessSleep sleep;
  final WellnessAppetite appetite;
  final WellnessMood mood;
  final WellnessExercise? exercise;
  final String? journal;
  final DateTime createdAt;

  const WellnessModel({
    required this.entryId,
    required this.userId,
    required this.date,
    required this.hydration,
    required this.sleep,
    required this.appetite,
    required this.mood,
    this.exercise,
    this.journal,
    required this.createdAt,
  });

  factory WellnessModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WellnessModel(
      entryId: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      hydration: WellnessHydration.fromMap(
        data['hydration'] as Map<String, dynamic>,
      ),
      sleep: WellnessSleep.fromMap(
        data['sleep'] as Map<String, dynamic>,
      ),
      appetite: WellnessAppetite.fromMap(
        data['appetite'] as Map<String, dynamic>,
      ),
      mood: WellnessMood.fromMap(
        data['mood'] as Map<String, dynamic>,
      ),
      exercise: data['exercise'] != null
          ? WellnessExercise.fromMap(
              data['exercise'] as Map<String, dynamic>,
            )
          : null,
      journal: data['journal'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'hydration': hydration.toMap(),
      'sleep': sleep.toMap(),
      'appetite': appetite.toMap(),
      'mood': mood.toMap(),
      'exercise': exercise?.toMap(),
      'journal': journal,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        entryId,
        userId,
        date,
        hydration,
        sleep,
        appetite,
        mood,
        exercise,
        journal,
        createdAt,
      ];
}

/// Hydration data
class WellnessHydration extends Equatable {
  final int waterGlasses;
  final int goal;

  const WellnessHydration({
    required this.waterGlasses,
    this.goal = 8,
  });

  factory WellnessHydration.fromMap(Map<String, dynamic> map) {
    return WellnessHydration(
      waterGlasses: map['waterGlasses'] as int? ?? 0,
      goal: map['goal'] as int? ?? 8,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'waterGlasses': waterGlasses,
      'goal': goal,
    };
  }

  double get progress => waterGlasses / goal;

  @override
  List<Object?> get props => [waterGlasses, goal];
}

/// Sleep data
class WellnessSleep extends Equatable {
  final double hours;
  final int quality; // 1-5
  final DateTime? bedtime;
  final DateTime? wakeTime;

  const WellnessSleep({
    required this.hours,
    required this.quality,
    this.bedtime,
    this.wakeTime,
  });

  factory WellnessSleep.fromMap(Map<String, dynamic> map) {
    return WellnessSleep(
      hours: (map['hours'] as num?)?.toDouble() ?? 0.0,
      quality: map['quality'] as int? ?? 3,
      bedtime: map['bedtime'] != null
          ? (map['bedtime'] as Timestamp).toDate()
          : null,
      wakeTime: map['wakeTime'] != null
          ? (map['wakeTime'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hours': hours,
      'quality': quality,
      'bedtime': bedtime != null ? Timestamp.fromDate(bedtime!) : null,
      'wakeTime': wakeTime != null ? Timestamp.fromDate(wakeTime!) : null,
    };
  }

  @override
  List<Object?> get props => [hours, quality, bedtime, wakeTime];
}

/// Appetite data
class WellnessAppetite extends Equatable {
  final String level; // 'low', 'normal', 'high'
  final String? notes;

  const WellnessAppetite({
    required this.level,
    this.notes,
  });

  factory WellnessAppetite.fromMap(Map<String, dynamic> map) {
    return WellnessAppetite(
      level: map['level'] as String? ?? 'normal',
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [level, notes];
}

/// Mood data
class WellnessMood extends Equatable {
  final String emoji;
  final String? description;
  final int energyLevel; // 1-5

  const WellnessMood({
    required this.emoji,
    this.description,
    required this.energyLevel,
  });

  factory WellnessMood.fromMap(Map<String, dynamic> map) {
    return WellnessMood(
      emoji: map['emoji'] as String? ?? '😊',
      description: map['description'] as String?,
      energyLevel: map['energyLevel'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emoji': emoji,
      'description': description,
      'energyLevel': energyLevel,
    };
  }

  @override
  List<Object?> get props => [emoji, description, energyLevel];
}

/// Exercise data
class WellnessExercise extends Equatable {
  final String type;
  final int duration; // minutes
  final String intensity; // 'light', 'moderate', 'vigorous'

  const WellnessExercise({
    required this.type,
    required this.duration,
    required this.intensity,
  });

  factory WellnessExercise.fromMap(Map<String, dynamic> map) {
    return WellnessExercise(
      type: map['type'] as String,
      duration: map['duration'] as int,
      intensity: map['intensity'] as String? ?? 'moderate',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'duration': duration,
      'intensity': intensity,
    };
  }

  @override
  List<Object?> get props => [type, duration, intensity];
}

