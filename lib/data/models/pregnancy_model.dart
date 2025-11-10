import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Pregnancy model
class Pregnancy extends Equatable {
  final String? id;
  final String userId;
  final DateTime lastMenstrualPeriod; // LMP
  final DateTime? dueDate;
  final int currentWeek;
  final int currentDay;
  final double? weight; // in kg
  final List<String> symptoms;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Pregnancy({
    this.id,
    required this.userId,
    required this.lastMenstrualPeriod,
    this.dueDate,
    required this.currentWeek,
    required this.currentDay,
    this.weight,
    this.symptoms = const [],
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  /// Calculate due date from LMP (40 weeks)
  static DateTime calculateDueDate(DateTime lmp) {
    return lmp.add(const Duration(days: 280)); // 40 weeks
  }

  /// Calculate current week and day from LMP
  static Map<String, int> calculateCurrentWeek(DateTime lmp) {
    final now = DateTime.now();
    final difference = now.difference(lmp).inDays;
    final weeks = (difference / 7).floor();
    final days = difference % 7;
    return {'week': weeks, 'day': days};
  }

  /// Create from Firestore document
  factory Pregnancy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final lmp = (data['lastMenstrualPeriod'] as Timestamp).toDate();
    final weekDay = calculateCurrentWeek(lmp);

    return Pregnancy(
      id: doc.id,
      userId: data['userId'] as String,
      lastMenstrualPeriod: lmp,
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : calculateDueDate(lmp),
      currentWeek: weekDay['week']!,
      currentDay: weekDay['day']!,
      weight: (data['weight'] as num?)?.toDouble(),
      symptoms: (data['symptoms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
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
      'lastMenstrualPeriod': Timestamp.fromDate(lastMenstrualPeriod),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'currentWeek': currentWeek,
      'currentDay': currentDay,
      'weight': weight,
      'symptoms': symptoms,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create copy with updated fields
  Pregnancy copyWith({
    DateTime? lastMenstrualPeriod,
    DateTime? dueDate,
    double? weight,
    List<String>? symptoms,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Pregnancy(
      id: id,
      userId: userId,
      lastMenstrualPeriod: lastMenstrualPeriod ?? this.lastMenstrualPeriod,
      dueDate: dueDate ?? this.dueDate,
      currentWeek: lastMenstrualPeriod != null
          ? calculateCurrentWeek(lastMenstrualPeriod)['week']!
          : currentWeek,
      currentDay: lastMenstrualPeriod != null
          ? calculateCurrentWeek(lastMenstrualPeriod)['day']!
          : currentDay,
      weight: weight ?? this.weight,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get trimester (1, 2, or 3)
  int get trimester {
    if (currentWeek < 13) return 1;
    if (currentWeek < 27) return 2;
    return 3;
  }

  /// Get pregnancy progress percentage
  double get progressPercentage {
    return (currentWeek / 40 * 100).clamp(0.0, 100.0);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        lastMenstrualPeriod,
        dueDate,
        currentWeek,
        currentDay,
        weight,
        symptoms,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// Pregnancy milestone
class PregnancyMilestone {
  final int week;
  final String title;
  final String description;
  final String? imageUrl;

  const PregnancyMilestone({
    required this.week,
    required this.title,
    required this.description,
    this.imageUrl,
  });

  static List<PregnancyMilestone> getMilestones() {
    return [
      const PregnancyMilestone(
        week: 4,
        title: 'Positive Test',
        description: 'You can now take a pregnancy test!',
      ),
      const PregnancyMilestone(
        week: 8,
        title: 'First Ultrasound',
        description: 'Baby\'s heartbeat can be detected',
      ),
      const PregnancyMilestone(
        week: 12,
        title: 'End of First Trimester',
        description: 'Risk of miscarriage decreases significantly',
      ),
      const PregnancyMilestone(
        week: 16,
        title: 'Gender Reveal',
        description: 'You can find out your baby\'s gender',
      ),
      const PregnancyMilestone(
        week: 20,
        title: 'Halfway There!',
        description: 'You\'re halfway through your pregnancy',
      ),
      const PregnancyMilestone(
        week: 24,
        title: 'Viability',
        description: 'Baby has a chance of survival if born early',
      ),
      const PregnancyMilestone(
        week: 28,
        title: 'Third Trimester',
        description: 'Welcome to the final trimester!',
      ),
      const PregnancyMilestone(
        week: 32,
        title: 'Baby Positioning',
        description: 'Baby may start moving into birth position',
      ),
      const PregnancyMilestone(
        week: 36,
        title: 'Full Term',
        description: 'Baby is considered full term',
      ),
      const PregnancyMilestone(
        week: 40,
        title: 'Due Date',
        description: 'Your baby is due!',
      ),
    ];
  }
}

/// Kick counter entry
class KickEntry extends Equatable {
  final String? id;
  final String userId;
  final String pregnancyId;
  final DateTime date;
  final DateTime time;
  final int kickCount;
  final Duration? duration; // Time taken to count kicks
  final String? notes;
  final DateTime createdAt;

  const KickEntry({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.date,
    required this.time,
    required this.kickCount,
    this.duration,
    this.notes,
    required this.createdAt,
  });

  factory KickEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KickEntry(
      id: doc.id,
      userId: data['userId'] as String,
      pregnancyId: data['pregnancyId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      time: (data['time'] as Timestamp).toDate(),
      kickCount: data['kickCount'] as int,
      duration: data['duration'] != null
          ? Duration(seconds: data['duration'] as int)
          : null,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pregnancyId': pregnancyId,
      'date': Timestamp.fromDate(date),
      'time': Timestamp.fromDate(time),
      'kickCount': kickCount,
      'duration': duration?.inSeconds,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        pregnancyId,
        date,
        time,
        kickCount,
        duration,
        notes,
        createdAt
      ];
}

/// Contraction timer entry
class ContractionEntry extends Equatable {
  final String? id;
  final String userId;
  final String pregnancyId;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final Duration? interval; // Time since last contraction
  final int? intensity; // 1-10 scale
  final String? notes;
  final DateTime createdAt;

  const ContractionEntry({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.startTime,
    this.endTime,
    this.duration,
    this.interval,
    this.intensity,
    this.notes,
    required this.createdAt,
  });

  factory ContractionEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContractionEntry(
      id: doc.id,
      userId: data['userId'] as String,
      pregnancyId: data['pregnancyId'] as String,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      duration: data['duration'] != null
          ? Duration(seconds: data['duration'] as int)
          : null,
      interval: data['interval'] != null
          ? Duration(seconds: data['interval'] as int)
          : null,
      intensity: data['intensity'] as int?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pregnancyId': pregnancyId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'duration': duration?.inSeconds,
      'interval': interval?.inSeconds,
      'intensity': intensity,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        pregnancyId,
        startTime,
        endTime,
        duration,
        interval,
        intensity,
        notes,
        createdAt
      ];
}

/// Pregnancy appointment
class PregnancyAppointment extends Equatable {
  final String? id;
  final String userId;
  final String pregnancyId;
  final String title;
  final String? description;
  final DateTime scheduledDate;
  final String? location;
  final String? doctorName;
  final String? appointmentType; // ultrasound, checkup, test, etc.
  final bool isCompleted;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PregnancyAppointment({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.title,
    this.description,
    required this.scheduledDate,
    this.location,
    this.doctorName,
    this.appointmentType,
    this.isCompleted = false,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory PregnancyAppointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PregnancyAppointment(
      id: doc.id,
      userId: data['userId'] as String,
      pregnancyId: data['pregnancyId'] as String,
      title: data['title'] as String,
      description: data['description'] as String?,
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      location: data['location'] as String?,
      doctorName: data['doctorName'] as String?,
      appointmentType: data['appointmentType'] as String?,
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
      'pregnancyId': pregnancyId,
      'title': title,
      'description': description,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'location': location,
      'doctorName': doctorName,
      'appointmentType': appointmentType,
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
        pregnancyId,
        title,
        description,
        scheduledDate,
        location,
        doctorName,
        appointmentType,
        isCompleted,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// Pregnancy medication reminder
class PregnancyMedication extends Equatable {
  final String? id;
  final String userId;
  final String pregnancyId;
  final String medicationName;
  final String? dosage;
  final String frequency; // daily, twice daily, weekly, etc.
  final DateTime startDate;
  final DateTime? endDate;
  final List<int> timesOfDay; // Hours of day (0-23)
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PregnancyMedication({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.medicationName,
    this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.timesOfDay = const [],
    this.isActive = true,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory PregnancyMedication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PregnancyMedication(
      id: doc.id,
      userId: data['userId'] as String,
      pregnancyId: data['pregnancyId'] as String,
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
      'pregnancyId': pregnancyId,
      'medicationName': medicationName,
      'dosage': dosage,
      'frequency': frequency,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'timesOfDay': timesOfDay,
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
        pregnancyId,
        medicationName,
        dosage,
        frequency,
        startDate,
        endDate,
        timesOfDay,
        isActive,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// Pregnancy journal entry
class PregnancyJournalEntry extends Equatable {
  final String? id;
  final String userId;
  final String pregnancyId;
  final DateTime date;
  final String? mood; // happy, anxious, excited, tired, etc.
  final List<String> symptoms;
  final String? journalText;
  final List<String>? photoUrls;
  final int? sleepHours;
  final String? sleepQuality; // good, fair, poor
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PregnancyJournalEntry({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.date,
    this.mood,
    this.symptoms = const [],
    this.journalText,
    this.photoUrls,
    this.sleepHours,
    this.sleepQuality,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory PregnancyJournalEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PregnancyJournalEntry(
      id: doc.id,
      userId: data['userId'] as String,
      pregnancyId: data['pregnancyId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      mood: data['mood'] as String?,
      symptoms: (data['symptoms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      journalText: data['journalText'] as String?,
      photoUrls: (data['photoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      sleepHours: data['sleepHours'] as int?,
      sleepQuality: data['sleepQuality'] as String?,
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
      'pregnancyId': pregnancyId,
      'date': Timestamp.fromDate(date),
      'mood': mood,
      'symptoms': symptoms,
      'journalText': journalText,
      'photoUrls': photoUrls,
      'sleepHours': sleepHours,
      'sleepQuality': sleepQuality,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        pregnancyId,
        date,
        mood,
        symptoms,
        journalText,
        photoUrls,
        sleepHours,
        sleepQuality,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// Weight entry for pregnancy
class PregnancyWeightEntry extends Equatable {
  final String? id;
  final String userId;
  final String pregnancyId;
  final DateTime date;
  final double weight; // in kg
  final String? notes;
  final DateTime createdAt;

  const PregnancyWeightEntry({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.date,
    required this.weight,
    this.notes,
    required this.createdAt,
  });

  factory PregnancyWeightEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PregnancyWeightEntry(
      id: doc.id,
      userId: data['userId'] as String,
      pregnancyId: data['pregnancyId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      weight: (data['weight'] as num).toDouble(),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pregnancyId': pregnancyId,
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props =>
      [id, userId, pregnancyId, date, weight, notes, createdAt];
}

/// Baby name suggestion
class BabyName extends Equatable {
  final String name;
  final String gender; // boy, girl, unisex
  final String? meaning;
  final String? origin;
  final int? popularity; // 1-100

  const BabyName({
    required this.name,
    required this.gender,
    this.meaning,
    this.origin,
    this.popularity,
  });

  @override
  List<Object?> get props => [name, gender, meaning, origin, popularity];
}

/// Hospital checklist item
class HospitalChecklistItem extends Equatable {
  final String? id;
  final String userId;
  final String pregnancyId;
  final String category; // documents, personal_items, baby_items, etc.
  final String item;
  final bool isChecked;
  final int? priority; // 1-5
  final DateTime createdAt;
  final DateTime? updatedAt;

  const HospitalChecklistItem({
    this.id,
    required this.userId,
    required this.pregnancyId,
    required this.category,
    required this.item,
    this.isChecked = false,
    this.priority,
    required this.createdAt,
    this.updatedAt,
  });

  factory HospitalChecklistItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HospitalChecklistItem(
      id: doc.id,
      userId: data['userId'] as String,
      pregnancyId: data['pregnancyId'] as String,
      category: data['category'] as String,
      item: data['item'] as String,
      isChecked: data['isChecked'] as bool? ?? false,
      priority: data['priority'] as int?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pregnancyId': pregnancyId,
      'category': category,
      'item': item,
      'isChecked': isChecked,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        pregnancyId,
        category,
        item,
        isChecked,
        priority,
        createdAt,
        updatedAt
      ];
}
