import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'cycle_model.dart';
import 'wellness_model.dart';

/// Red flag alert model for concerning health indicators
class RedFlagAlert extends Equatable {
  final String? id;
  final String userId;
  final String
      alertType; // 'pcos', 'anemia', 'infection', 'irregular_cycle', 'severe_symptom'
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String title;
  final String description;
  final Map<String, dynamic>
      indicators; // Symptoms/indicators that triggered the alert
  final DateTime detectedAt;
  final bool acknowledged;
  final DateTime? acknowledgedAt;
  final String? actionTaken;
  final DateTime createdAt;

  const RedFlagAlert({
    this.id,
    required this.userId,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.description,
    required this.indicators,
    required this.detectedAt,
    this.acknowledged = false,
    this.acknowledgedAt,
    this.actionTaken,
    required this.createdAt,
  });

  factory RedFlagAlert.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RedFlagAlert(
      id: doc.id,
      userId: data['userId'] as String,
      alertType: data['alertType'] as String,
      severity: data['severity'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      indicators: data['indicators'] as Map<String, dynamic>,
      detectedAt: (data['detectedAt'] as Timestamp).toDate(),
      acknowledged: data['acknowledged'] as bool? ?? false,
      acknowledgedAt: data['acknowledgedAt'] != null
          ? (data['acknowledgedAt'] as Timestamp).toDate()
          : null,
      actionTaken: data['actionTaken'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'alertType': alertType,
      'severity': severity,
      'title': title,
      'description': description,
      'indicators': indicators,
      'detectedAt': Timestamp.fromDate(detectedAt),
      'acknowledged': acknowledged,
      'acknowledgedAt':
          acknowledgedAt != null ? Timestamp.fromDate(acknowledgedAt!) : null,
      'actionTaken': actionTaken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RedFlagAlert copyWith({
    String? alertType,
    String? severity,
    String? title,
    String? description,
    Map<String, dynamic>? indicators,
    DateTime? detectedAt,
    bool? acknowledged,
    DateTime? acknowledgedAt,
    String? actionTaken,
  }) {
    return RedFlagAlert(
      id: id,
      userId: userId,
      alertType: alertType ?? this.alertType,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      indicators: indicators ?? this.indicators,
      detectedAt: detectedAt ?? this.detectedAt,
      acknowledged: acknowledged ?? this.acknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      actionTaken: actionTaken ?? this.actionTaken,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        alertType,
        severity,
        title,
        description,
        indicators,
        detectedAt,
        acknowledged,
        acknowledgedAt,
        actionTaken,
        createdAt,
      ];
}

/// Red flag alert types and their indicators
class RedFlagAlertTypes {
  static const String pcos = 'pcos';
  static const String anemia = 'anemia';
  static const String infection = 'infection';
  static const String irregularCycle = 'irregular_cycle';
  static const String severeSymptom = 'severe_symptom';

  /// PCOS indicators
  static Map<String, dynamic> checkPCOSIndicators({
    required List<CycleModel> cycles,
    required List<WellnessModel> wellnessEntries,
  }) {
    final indicators = <String, dynamic>{};

    // Irregular cycles (variation > 7 days)
    if (cycles.length >= 3) {
      final cycleLengths = cycles.map((c) => c.cycleLength).toList();
      final avg = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
      final variations = cycleLengths.map((l) => (l - avg).abs()).toList();
      final maxVariation = variations.reduce((a, b) => a > b ? a : b);

      if (maxVariation > 7) {
        indicators['irregular_cycles'] = true;
        indicators['cycle_variation'] = maxVariation;
      }
    }

    // Missing periods
    final now = DateTime.now();
    final lastPeriod = cycles.isNotEmpty ? cycles.first.startDate : null;
    if (lastPeriod != null) {
      final daysSinceLastPeriod = now.difference(lastPeriod).inDays;
      if (daysSinceLastPeriod > 45) {
        indicators['missed_period'] = true;
        indicators['days_since_period'] = daysSinceLastPeriod;
      }
    }

    return indicators;
  }

  /// Anemia indicators
  static Map<String, dynamic> checkAnemiaIndicators({
    required List<CycleModel> cycles,
    required List<WellnessModel> wellnessEntries,
  }) {
    final indicators = <String, dynamic>{};

    // Heavy bleeding
    final heavyPeriods = cycles.where((c) => c.flowIntensity == 'heavy').length;
    if (heavyPeriods >= 2) {
      indicators['heavy_periods'] = true;
      indicators['heavy_period_count'] = heavyPeriods;
    }

    // Long periods
    final longPeriods = cycles.where((c) => c.periodLength > 7).length;
    if (longPeriods >= 2) {
      indicators['long_periods'] = true;
    }

    // Fatigue/low energy
    final lowEnergyDays =
        wellnessEntries.where((e) => e.mood.energyLevel <= 2).length;
    if (lowEnergyDays >= 5) {
      indicators['persistent_fatigue'] = true;
      indicators['low_energy_days'] = lowEnergyDays;
    }

    return indicators;
  }

  /// Infection indicators
  static Map<String, dynamic> checkInfectionIndicators({
    required List<CycleModel> cycles,
    required List<WellnessModel> wellnessEntries,
  }) {
    final indicators = <String, dynamic>{};

    // Unusual discharge symptoms
    final unusualSymptoms = cycles
        .where((c) =>
            c.symptoms.contains('unusual_discharge') ||
            c.symptoms.contains('itching') ||
            c.symptoms.contains('burning'))
        .length;
    if (unusualSymptoms >= 2) {
      indicators['unusual_symptoms'] = true;
      indicators['symptom_count'] = unusualSymptoms;
    }

    return indicators;
  }

  /// Check for severe symptoms
  static Map<String, dynamic> checkSevereSymptoms({
    required CycleModel? currentCycle,
    required List<WellnessModel> recentWellness,
  }) {
    final indicators = <String, dynamic>{};

    if (currentCycle != null) {
      // Severe pain
      if (currentCycle.symptoms.contains('severe_cramps') ||
          currentCycle.symptoms.contains('severe_pain')) {
        indicators['severe_pain'] = true;
      }

      // Excessive bleeding
      if (currentCycle.flowIntensity == 'heavy' &&
          currentCycle.periodLength > 7) {
        indicators['excessive_bleeding'] = true;
      }
    }

    // Mental health concerns
    final concerningMoods =
        recentWellness.where((e) => e.mood.hasConcerningIndicators).length;
    if (concerningMoods >= 3) {
      indicators['mental_health_concerns'] = true;
      indicators['concerning_days'] = concerningMoods;
    }

    return indicators;
  }
}
