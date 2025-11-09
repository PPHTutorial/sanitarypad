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
