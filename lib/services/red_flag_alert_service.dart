import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../data/models/red_flag_alert_model.dart';
import '../data/models/cycle_model.dart';
import '../data/models/wellness_model.dart';

/// Red flag alert service
class RedFlagAlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check for red flag alerts based on user data
  Future<List<RedFlagAlert>> checkForAlerts({
    required String userId,
    required List<CycleModel> cycles,
    required List<WellnessModel> wellnessEntries,
  }) async {
    final alerts = <RedFlagAlert>[];

    // Check PCOS indicators
    final pcosIndicators = RedFlagAlertTypes.checkPCOSIndicators(
      cycles: cycles,
      wellnessEntries: wellnessEntries,
    );
    if (pcosIndicators.isNotEmpty) {
      final severity = _determineSeverity(pcosIndicators);
      alerts.add(RedFlagAlert(
        userId: userId,
        alertType: RedFlagAlertTypes.pcos,
        severity: severity,
        title: 'Possible PCOS Indicators Detected',
        description:
            'Your cycle patterns suggest possible PCOS. Please consult with a healthcare provider.',
        indicators: pcosIndicators,
        detectedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));
    }

    // Check anemia indicators
    final anemiaIndicators = RedFlagAlertTypes.checkAnemiaIndicators(
      cycles: cycles,
      wellnessEntries: wellnessEntries,
    );
    if (anemiaIndicators.isNotEmpty) {
      final severity = _determineSeverity(anemiaIndicators);
      alerts.add(RedFlagAlert(
        userId: userId,
        alertType: RedFlagAlertTypes.anemia,
        severity: severity,
        title: 'Possible Anemia Indicators',
        description:
            'Your symptoms may indicate anemia. Consider discussing with a healthcare provider.',
        indicators: anemiaIndicators,
        detectedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));
    }

    // Check infection indicators
    final infectionIndicators = RedFlagAlertTypes.checkInfectionIndicators(
      cycles: cycles,
      wellnessEntries: wellnessEntries,
    );
    if (infectionIndicators.isNotEmpty) {
      alerts.add(RedFlagAlert(
        userId: userId,
        alertType: RedFlagAlertTypes.infection,
        severity: 'high',
        title: 'Possible Infection Indicators',
        description:
            'Your symptoms may indicate an infection. Please consult with a healthcare provider promptly.',
        indicators: infectionIndicators,
        detectedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));
    }

    // Check severe symptoms
    final currentCycle = cycles.isNotEmpty ? cycles.first : null;
    final recentWellness = wellnessEntries.take(7).toList();
    final severeIndicators = RedFlagAlertTypes.checkSevereSymptoms(
      currentCycle: currentCycle,
      recentWellness: recentWellness,
    );
    if (severeIndicators.isNotEmpty) {
      alerts.add(RedFlagAlert(
        userId: userId,
        alertType: RedFlagAlertTypes.severeSymptom,
        severity: 'critical',
        title: 'Severe Symptoms Detected',
        description:
            'You have reported severe symptoms. Please seek medical attention if symptoms persist or worsen.',
        indicators: severeIndicators,
        detectedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));
    }

    // Save alerts to Firestore
    for (final alert in alerts) {
      await createAlert(alert);
    }

    return alerts;
  }

  /// Create alert
  Future<String> createAlert(RedFlagAlert alert) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.collectionRedFlagAlerts)
          .add(alert.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's alerts
  Stream<List<RedFlagAlert>> getUserAlerts(String userId) {
    return _firestore
        .collection(AppConstants.collectionRedFlagAlerts)
        .where('userId', isEqualTo: userId)
        .orderBy('detectedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RedFlagAlert.fromFirestore(doc))
          .toList();
    });
  }

  /// Get unacknowledged alerts
  Stream<List<RedFlagAlert>> getUnacknowledgedAlerts(String userId) {
    return _firestore
        .collection(AppConstants.collectionRedFlagAlerts)
        .where('userId', isEqualTo: userId)
        .where('acknowledged', isEqualTo: false)
        .orderBy('detectedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RedFlagAlert.fromFirestore(doc))
          .toList();
    });
  }

  /// Acknowledge alert
  Future<void> acknowledgeAlert(String alertId, {String? actionTaken}) async {
    try {
      await _firestore
          .collection(AppConstants.collectionRedFlagAlerts)
          .doc(alertId)
          .update({
        'acknowledged': true,
        'acknowledgedAt': Timestamp.fromDate(DateTime.now()),
        if (actionTaken != null) 'actionTaken': actionTaken,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Delete alert
  Future<void> deleteAlert(String alertId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionRedFlagAlerts)
          .doc(alertId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  String _determineSeverity(Map<String, dynamic> indicators) {
    final criticalCount =
        indicators.values.where((v) => v is bool && v == true).length;

    if (criticalCount >= 3) return 'critical';
    if (criticalCount >= 2) return 'high';
    if (criticalCount >= 1) return 'medium';
    return 'low';
  }
}
