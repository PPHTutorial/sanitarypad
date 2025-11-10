import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Fertility tracking entry
class FertilityEntry extends Equatable {
  final String? id;
  final String userId;
  final DateTime date;
  final double? basalBodyTemperature; // BBT in Celsius
  final String? cervicalMucus; // dry, sticky, creamy, watery, egg-white
  final String? cervicalPosition; // low, medium, high
  final bool? lhTestPositive; // LH test result
  final bool? intercourse;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FertilityEntry({
    this.id,
    required this.userId,
    required this.date,
    this.basalBodyTemperature,
    this.cervicalMucus,
    this.cervicalPosition,
    this.lhTestPositive,
    this.intercourse,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory FertilityEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FertilityEntry(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      basalBodyTemperature: (data['basalBodyTemperature'] as num?)?.toDouble(),
      cervicalMucus: data['cervicalMucus'] as String?,
      cervicalPosition: data['cervicalPosition'] as String?,
      lhTestPositive: data['lhTestPositive'] as bool?,
      intercourse: data['intercourse'] as bool?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'basalBodyTemperature': basalBodyTemperature,
      'cervicalMucus': cervicalMucus,
      'cervicalPosition': cervicalPosition,
      'lhTestPositive': lhTestPositive,
      'intercourse': intercourse,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create copy with updated fields
  FertilityEntry copyWith({
    DateTime? date,
    double? basalBodyTemperature,
    String? cervicalMucus,
    String? cervicalPosition,
    bool? lhTestPositive,
    bool? intercourse,
    String? notes,
    DateTime? updatedAt,
  }) {
    return FertilityEntry(
      id: id,
      userId: userId,
      date: date ?? this.date,
      basalBodyTemperature: basalBodyTemperature ?? this.basalBodyTemperature,
      cervicalMucus: cervicalMucus ?? this.cervicalMucus,
      cervicalPosition: cervicalPosition ?? this.cervicalPosition,
      lhTestPositive: lhTestPositive ?? this.lhTestPositive,
      intercourse: intercourse ?? this.intercourse,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        basalBodyTemperature,
        cervicalMucus,
        cervicalPosition,
        lhTestPositive,
        intercourse,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// Fertility prediction
class FertilityPrediction {
  final DateTime predictedOvulation;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final double confidence; // 0.0 to 1.0
  final List<String> methods; // Methods used for prediction

  const FertilityPrediction({
    required this.predictedOvulation,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.confidence,
    required this.methods,
  });

  /// Calculate fertile window (5 days before ovulation, 1 day after)
  static FertilityPrediction calculateFertileWindow(
    DateTime predictedOvulation,
    List<String> methods,
  ) {
    return FertilityPrediction(
      predictedOvulation: predictedOvulation,
      fertileWindowStart: predictedOvulation.subtract(const Duration(days: 5)),
      fertileWindowEnd: predictedOvulation.add(const Duration(days: 1)),
      confidence: _calculateConfidence(methods),
      methods: methods,
    );
  }

  static double _calculateConfidence(List<String> methods) {
    // More methods = higher confidence
    if (methods.length >= 3) return 0.9;
    if (methods.length == 2) return 0.7;
    return 0.5;
  }

  /// Check if date is in fertile window
  bool isInFertileWindow(DateTime date) {
    return date.isAfter(fertileWindowStart) &&
        date.isBefore(fertileWindowEnd.add(const Duration(days: 1)));
  }
}

/// Hormone cycle insights
class HormoneCycle extends Equatable {
  final String? id;
  final String userId;
  final DateTime date;
  final double? estrogenLevel; // Relative level 0-100
  final double? progesteroneLevel; // Relative level 0-100
  final double? lhLevel; // Luteinizing hormone level
  final double? fshLevel; // Follicle-stimulating hormone level
  final String? cyclePhase; // follicular, ovulation, luteal, menstrual
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const HormoneCycle({
    this.id,
    required this.userId,
    required this.date,
    this.estrogenLevel,
    this.progesteroneLevel,
    this.lhLevel,
    this.fshLevel,
    this.cyclePhase,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory HormoneCycle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HormoneCycle(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      estrogenLevel: (data['estrogenLevel'] as num?)?.toDouble(),
      progesteroneLevel: (data['progesteroneLevel'] as num?)?.toDouble(),
      lhLevel: (data['lhLevel'] as num?)?.toDouble(),
      fshLevel: (data['fshLevel'] as num?)?.toDouble(),
      cyclePhase: data['cyclePhase'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'estrogenLevel': estrogenLevel,
      'progesteroneLevel': progesteroneLevel,
      'lhLevel': lhLevel,
      'fshLevel': fshLevel,
      'cyclePhase': cyclePhase,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        estrogenLevel,
        progesteroneLevel,
        lhLevel,
        fshLevel,
        cyclePhase,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// Fertility symptom entry
class FertilitySymptom extends Equatable {
  final String? id;
  final String userId;
  final DateTime date;
  final List<String>
      symptoms; // bloating, cramps, mood_swings, tender_breasts, etc.
  final int? painLevel; // 1-10
  final String? location; // lower_abdomen, back, breasts, etc.
  final String? notes;
  final DateTime createdAt;

  const FertilitySymptom({
    this.id,
    required this.userId,
    required this.date,
    this.symptoms = const [],
    this.painLevel,
    this.location,
    this.notes,
    required this.createdAt,
  });

  factory FertilitySymptom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FertilitySymptom(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      symptoms: (data['symptoms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      painLevel: data['painLevel'] as int?,
      location: data['location'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'symptoms': symptoms,
      'painLevel': painLevel,
      'location': location,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props =>
      [id, userId, date, symptoms, painLevel, location, notes, createdAt];
}

/// Mood & energy tracker entry
class MoodEnergyEntry extends Equatable {
  final String? id;
  final String userId;
  final DateTime date;
  final String? mood; // happy, sad, anxious, irritable, calm, etc.
  final int? energyLevel; // 1-10
  final int? stressLevel; // 1-10
  final int? libidoLevel; // 1-10
  final String? notes;
  final DateTime createdAt;

  const MoodEnergyEntry({
    this.id,
    required this.userId,
    required this.date,
    this.mood,
    this.energyLevel,
    this.stressLevel,
    this.libidoLevel,
    this.notes,
    required this.createdAt,
  });

  factory MoodEnergyEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoodEnergyEntry(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      mood: data['mood'] as String?,
      energyLevel: data['energyLevel'] as int?,
      stressLevel: data['stressLevel'] as int?,
      libidoLevel: data['libidoLevel'] as int?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'mood': mood,
      'energyLevel': energyLevel,
      'stressLevel': stressLevel,
      'libidoLevel': libidoLevel,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        mood,
        energyLevel,
        stressLevel,
        libidoLevel,
        notes,
        createdAt
      ];
}

/// Medication/supplement reminder for fertility
class FertilityMedication extends Equatable {
  final String? id;
  final String userId;
  final String medicationName;
  final String? dosage;
  final String frequency; // daily, twice_daily, weekly, etc.
  final DateTime startDate;
  final DateTime? endDate;
  final List<int> timesOfDay; // Hours of day (0-23)
  final String? purpose; // fertility_support, hormone_balance, etc.
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FertilityMedication({
    this.id,
    required this.userId,
    required this.medicationName,
    this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.timesOfDay = const [],
    this.purpose,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory FertilityMedication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FertilityMedication(
      id: doc.id,
      userId: data['userId'] as String,
      medicationName: data['medicationName'] as String,
      dosage: data['dosage'] as String?,
      frequency: data['frequency'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      timesOfDay: (data['timesOfDay'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      purpose: data['purpose'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'timesOfDay': timesOfDay,
      'purpose': purpose,
      'isActive': isActive,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        medicationName,
        dosage,
        frequency,
        startDate,
        endDate,
        timesOfDay,
        purpose,
        isActive,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// Intercourse/fertility activity entry
class IntercourseEntry extends Equatable {
  final String? id;
  final String userId;
  final DateTime date;
  final DateTime? time;
  final bool usedProtection;
  final String? notes;
  final DateTime createdAt;

  const IntercourseEntry({
    this.id,
    required this.userId,
    required this.date,
    this.time,
    this.usedProtection = false,
    this.notes,
    required this.createdAt,
  });

  factory IntercourseEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IntercourseEntry(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] != null ? (data['time'] as Timestamp).toDate() : null,
      usedProtection: data['usedProtection'] as bool? ?? false,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'time': time != null ? Timestamp.fromDate(time!) : null,
      'usedProtection': usedProtection,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props =>
      [id, userId, date, time, usedProtection, notes, createdAt];
}

/// Pregnancy test entry
class PregnancyTestEntry extends Equatable {
  final String? id;
  final String userId;
  final DateTime date;
  final DateTime? time;
  final String result; // positive, negative, invalid
  final String? testBrand;
  final int? daysPastOvulation;
  final String? notes;
  final List<String>? photoUrls;
  final DateTime createdAt;

  const PregnancyTestEntry({
    this.id,
    required this.userId,
    required this.date,
    this.time,
    required this.result,
    this.testBrand,
    this.daysPastOvulation,
    this.notes,
    this.photoUrls,
    required this.createdAt,
  });

  factory PregnancyTestEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PregnancyTestEntry(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] != null ? (data['time'] as Timestamp).toDate() : null,
      result: data['result'] as String,
      testBrand: data['testBrand'] as String?,
      daysPastOvulation: data['daysPastOvulation'] as int?,
      notes: data['notes'] as String?,
      photoUrls: (data['photoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'time': time != null ? Timestamp.fromDate(time!) : null,
      'result': result,
      'testBrand': testBrand,
      'daysPastOvulation': daysPastOvulation,
      'notes': notes,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        time,
        result,
        testBrand,
        daysPastOvulation,
        notes,
        photoUrls,
        createdAt,
      ];
}

/// Health & lifestyle recommendation
class HealthRecommendation extends Equatable {
  final String? id;
  final String userId;
  final String category; // diet, exercise, sleep, stress, supplements, etc.
  final String title;
  final String description;
  final String? priority; // high, medium, low
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const HealthRecommendation({
    this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.description,
    this.priority,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory HealthRecommendation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HealthRecommendation(
      id: doc.id,
      userId: data['userId'] as String,
      category: data['category'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      priority: data['priority'] as String?,
      isCompleted: data['isCompleted'] as bool? ?? false,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'category': category,
      'title': title,
      'description': description,
      'priority': priority,
      'isCompleted': isCompleted,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        category,
        title,
        description,
        priority,
        isCompleted,
        completedAt,
        createdAt,
        updatedAt,
      ];
}

/// Ovulation test reminder
class OvulationTestReminder extends Equatable {
  final String? id;
  final String userId;
  final DateTime scheduledDate;
  final DateTime? completedAt;
  final String? result; // positive, negative, not_taken
  final bool isCompleted;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const OvulationTestReminder({
    this.id,
    required this.userId,
    required this.scheduledDate,
    this.completedAt,
    this.result,
    this.isCompleted = false,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory OvulationTestReminder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OvulationTestReminder(
      id: doc.id,
      userId: data['userId'] as String,
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      result: data['result'] as String?,
      isCompleted: data['isCompleted'] as bool? ?? false,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'result': result,
      'isCompleted': isCompleted,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        scheduledDate,
        completedAt,
        result,
        isCompleted,
        notes,
        createdAt,
        updatedAt,
      ];
}
