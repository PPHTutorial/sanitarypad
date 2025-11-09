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
