import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Cycle model
class CycleModel extends Equatable {
  final String cycleId;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final int cycleLength;
  final int periodLength;
  final String flowIntensity;
  final List<String> symptoms;
  final String? mood;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CycleModel({
    required this.cycleId,
    required this.userId,
    required this.startDate,
    this.endDate,
    required this.cycleLength,
    required this.periodLength,
    required this.flowIntensity,
    required this.symptoms,
    this.mood,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory CycleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CycleModel(
      cycleId: doc.id,
      userId: data['userId'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      cycleLength: data['cycleLength'] as int,
      periodLength: data['periodLength'] as int,
      flowIntensity: data['flowIntensity'] as String,
      symptoms: List<String>.from(data['symptoms'] as List? ?? []),
      mood: data['mood'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'cycleLength': cycleLength,
      'periodLength': periodLength,
      'flowIntensity': flowIntensity,
      'symptoms': symptoms,
      'mood': mood,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create copy with updated fields
  CycleModel copyWith({
    String? cycleId,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? cycleLength,
    int? periodLength,
    String? flowIntensity,
    List<String>? symptoms,
    String? mood,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CycleModel(
      cycleId: cycleId ?? this.cycleId,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      cycleLength: cycleLength ?? this.cycleLength,
      periodLength: periodLength ?? this.periodLength,
      flowIntensity: flowIntensity ?? this.flowIntensity,
      symptoms: symptoms ?? this.symptoms,
      mood: mood ?? this.mood,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if cycle is active (period is ongoing)
  bool get isActive {
    if (endDate == null) return true;
    return endDate!.isAfter(DateTime.now());
  }

  /// Get cycle day (day of current cycle)
  int getCycleDay(DateTime date) {
    return date.difference(startDate).inDays + 1;
  }

  @override
  List<Object?> get props => [
        cycleId,
        userId,
        startDate,
        endDate,
        cycleLength,
        periodLength,
        flowIntensity,
        symptoms,
        mood,
        notes,
        createdAt,
        updatedAt,
      ];
}
