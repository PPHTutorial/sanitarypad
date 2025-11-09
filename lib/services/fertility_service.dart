import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/fertility_model.dart';
import '../data/models/cycle_model.dart';

/// Fertility service
class FertilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create fertility entry
  Future<String> createFertilityEntry(FertilityEntry entry) async {
    try {
      final docRef = await _firestore
          .collection('fertilityEntries')
          .add(entry.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update fertility entry
  Future<void> updateFertilityEntry(FertilityEntry entry) async {
    if (entry.id == null) {
      throw Exception('Fertility entry ID is required for update');
    }

    try {
      await _firestore
          .collection('fertilityEntries')
          .doc(entry.id)
          .update(entry.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete fertility entry
  Future<void> deleteFertilityEntry(String entryId) async {
    try {
      await _firestore.collection('fertilityEntries').doc(entryId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Get fertility entries for date range
  Stream<List<FertilityEntry>> getFertilityEntries(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection('fertilityEntries')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FertilityEntry.fromFirestore(doc))
          .toList();
    });
  }

  /// Get fertility entry for specific date
  Future<FertilityEntry?> getFertilityEntryForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('fertilityEntries')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return FertilityEntry.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  /// Predict ovulation using multiple methods
  Future<FertilityPrediction> predictOvulation(
    String userId,
    List<CycleModel> cycles,
    List<FertilityEntry> fertilityEntries,
  ) async {
    final methods = <String>[];
    DateTime? predictedOvulation;

    // Method 1: Calendar method (based on cycle length)
    if (cycles.isNotEmpty) {
      final cycleLengths = cycles.map((c) => c.cycleLength).toList();
      if (cycleLengths.isNotEmpty) {
        final avgCycleLength =
            cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
        final lastPeriod = cycles.first.startDate;
        predictedOvulation =
            lastPeriod.add(Duration(days: (avgCycleLength - 14).round()));
        methods.add('calendar');
      }
    }

    // Method 2: BBT method (temperature rise)
    final bbtEntries =
        fertilityEntries.where((e) => e.basalBodyTemperature != null).toList();
    if (bbtEntries.length >= 3) {
      final bbtOvulation = _detectBBTOvulation(bbtEntries);
      if (bbtOvulation != null) {
        predictedOvulation = bbtOvulation;
        methods.add('bbt');
      }
    }

    // Method 3: Cervical mucus method (egg-white consistency)
    final cmEntries =
        fertilityEntries.where((e) => e.cervicalMucus == 'egg-white').toList();
    if (cmEntries.isNotEmpty) {
      final cmOvulation = cmEntries.first.date;
      if (predictedOvulation == null ||
          (cmOvulation.difference(predictedOvulation).inDays.abs() <= 3)) {
        predictedOvulation = cmOvulation;
        methods.add('cervical_mucus');
      }
    }

    // Method 4: LH test method
    final lhEntries =
        fertilityEntries.where((e) => e.lhTestPositive == true).toList();
    if (lhEntries.isNotEmpty) {
      final lhOvulation = lhEntries.first.date;
      if (predictedOvulation == null ||
          (lhOvulation.difference(predictedOvulation).inDays.abs() <= 2)) {
        predictedOvulation = lhOvulation;
        methods.add('lh_test');
      }
    }

    // Default: If no methods work, use calendar method with 14 days from last period
    if (predictedOvulation == null && cycles.isNotEmpty) {
      final lastPeriod = cycles.first.startDate;
      predictedOvulation = lastPeriod.add(const Duration(days: 14));
      methods.add('calendar_default');
    }

    // If still null, use current date + 14 days
    predictedOvulation ??= DateTime.now().add(const Duration(days: 14));

    return FertilityPrediction.calculateFertileWindow(
      predictedOvulation,
      methods,
    );
  }

  /// Detect ovulation from BBT pattern (temperature rise)
  DateTime? _detectBBTOvulation(List<FertilityEntry> entries) {
    if (entries.length < 3) return null;

    // Sort by date
    entries.sort((a, b) => a.date.compareTo(b.date));

    // Look for temperature rise (0.3-0.5°C increase)
    for (int i = 1; i < entries.length; i++) {
      final prevTemp = entries[i - 1].basalBodyTemperature;
      final currTemp = entries[i].basalBodyTemperature;

      if (prevTemp != null && currTemp != null) {
        final tempRise = currTemp - prevTemp;
        if (tempRise >= 0.3 && tempRise <= 0.5) {
          // Ovulation typically occurs 1-2 days before temperature rise
          return entries[i].date.subtract(const Duration(days: 1));
        }
      }
    }

    return null;
  }

  /// Get BBT chart data
  List<Map<String, dynamic>> getBBTChartData(List<FertilityEntry> entries) {
    return entries
        .where((e) => e.basalBodyTemperature != null)
        .map((e) => {
              'date': e.date,
              'temperature': e.basalBodyTemperature,
            })
        .toList();
  }

  /// Get fertility score for a date
  double getFertilityScore(DateTime date, FertilityPrediction prediction) {
    if (prediction.isInFertileWindow(date)) {
      // Peak fertility on ovulation day
      if (date.day == prediction.predictedOvulation.day &&
          date.month == prediction.predictedOvulation.month &&
          date.year == prediction.predictedOvulation.year) {
        return 1.0;
      }
      // High fertility in fertile window
      return 0.8;
    }
    return 0.2; // Low fertility outside window
  }
}
