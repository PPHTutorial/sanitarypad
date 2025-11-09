import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Symptom model
class SymptomModel extends Equatable {
  final String symptomId;
  final String userId;
  final DateTime date;
  final String? cycleId;
  final String type;
  final int severity; // 1-5
  final String? location;
  final int? duration; // minutes
  final String? notes;
  final DateTime createdAt;

  const SymptomModel({
    required this.symptomId,
    required this.userId,
    required this.date,
    this.cycleId,
    required this.type,
    required this.severity,
    this.location,
    this.duration,
    this.notes,
    required this.createdAt,
  });

  factory SymptomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SymptomModel(
      symptomId: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      cycleId: data['cycleId'] as String?,
      type: data['type'] as String,
      severity: data['severity'] as int,
      location: data['location'] as String?,
      duration: data['duration'] as int?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'cycleId': cycleId,
      'type': type,
      'severity': severity,
      'location': location,
      'duration': duration,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SymptomModel copyWith({
    String? symptomId,
    String? userId,
    DateTime? date,
    String? cycleId,
    String? type,
    int? severity,
    String? location,
    int? duration,
    String? notes,
    DateTime? createdAt,
  }) {
    return SymptomModel(
      symptomId: symptomId ?? this.symptomId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      cycleId: cycleId ?? this.cycleId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      location: location ?? this.location,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        symptomId,
        userId,
        date,
        cycleId,
        type,
        severity,
        location,
        duration,
        notes,
        createdAt,
      ];
}

