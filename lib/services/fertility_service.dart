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
  /// Always predicts FUTURE ovulation dates
  Future<FertilityPrediction> predictOvulation(
    String userId,
    List<CycleModel> cycles,
    List<FertilityEntry> fertilityEntries,
  ) async {
    final methods = <String>[];
    DateTime? predictedOvulation;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Method 1: Calendar method (based on cycle length) - Calculate NEXT ovulation
    if (cycles.isNotEmpty) {
      final cycleLengths = cycles.map((c) => c.cycleLength).toList();
      if (cycleLengths.isNotEmpty) {
        final avgCycleLength =
            cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
        final lastPeriod = cycles.first.startDate;

        // Calculate next period start date
        DateTime nextPeriodStart = lastPeriod;
        while (nextPeriodStart.isBefore(today) ||
            nextPeriodStart.isAtSameMomentAs(today)) {
          nextPeriodStart =
              nextPeriodStart.add(Duration(days: avgCycleLength.round()));
        }

        // Ovulation is typically 14 days before next period
        predictedOvulation = nextPeriodStart.subtract(const Duration(days: 14));
        methods.add('calendar');
      }
    }

    // Method 2: BBT method (temperature rise) - Only use recent/future entries
    final recentBbtEntries = fertilityEntries
        .where((e) =>
            e.basalBodyTemperature != null &&
            e.date.isAfter(today.subtract(const Duration(days: 60))))
        .toList();
    if (recentBbtEntries.length >= 3) {
      final bbtOvulation = _detectBBTOvulation(recentBbtEntries);
      if (bbtOvulation != null && bbtOvulation.isAfter(today)) {
        // Only use if it's in the future
        if (predictedOvulation == null ||
            (bbtOvulation.difference(predictedOvulation).inDays.abs() <= 3)) {
          predictedOvulation = bbtOvulation;
          methods.add('bbt');
        }
      }
    }

    // Method 3: Cervical mucus method (egg-white consistency) - Only use recent/future entries
    final recentCmEntries = fertilityEntries
        .where((e) =>
            e.cervicalMucus == 'egg-white' &&
            e.date.isAfter(today.subtract(const Duration(days: 30))))
        .toList();
    if (recentCmEntries.isNotEmpty) {
      // Find the most recent or next egg-white entry
      recentCmEntries.sort((a, b) => a.date.compareTo(b.date));
      final cmOvulation = recentCmEntries.firstWhere(
        (e) => e.date.isAfter(today),
        orElse: () => recentCmEntries.last,
      );

      // If it's in the past, calculate next occurrence based on cycle
      DateTime cmPrediction = cmOvulation.date;
      if (cmPrediction.isBefore(today) && cycles.isNotEmpty) {
        final cycleLengths = cycles.map((c) => c.cycleLength).toList();
        final avgCycleLength =
            cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
        while (cmPrediction.isBefore(today)) {
          cmPrediction =
              cmPrediction.add(Duration(days: avgCycleLength.round()));
        }
      }

      if (cmPrediction.isAfter(today) || cmPrediction.isAtSameMomentAs(today)) {
        if (predictedOvulation == null ||
            (cmPrediction.difference(predictedOvulation).inDays.abs() <= 3)) {
          predictedOvulation = cmPrediction;
          methods.add('cervical_mucus');
        }
      }
    }

    // Method 4: LH test method - Only use recent/future entries
    final recentLhEntries = fertilityEntries
        .where((e) =>
            e.lhTestPositive == true &&
            e.date.isAfter(today.subtract(const Duration(days: 30))))
        .toList();
    if (recentLhEntries.isNotEmpty) {
      recentLhEntries.sort((a, b) => a.date.compareTo(b.date));
      final lhOvulation = recentLhEntries.firstWhere(
        (e) => e.date.isAfter(today),
        orElse: () => recentLhEntries.last,
      );

      // If it's in the past, calculate next occurrence based on cycle
      DateTime lhPrediction = lhOvulation.date;
      if (lhPrediction.isBefore(today) && cycles.isNotEmpty) {
        final cycleLengths = cycles.map((c) => c.cycleLength).toList();
        final avgCycleLength =
            cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
        while (lhPrediction.isBefore(today)) {
          lhPrediction =
              lhPrediction.add(Duration(days: avgCycleLength.round()));
        }
      }

      if (lhPrediction.isAfter(today) || lhPrediction.isAtSameMomentAs(today)) {
        if (predictedOvulation == null ||
            (lhPrediction.difference(predictedOvulation).inDays.abs() <= 2)) {
          predictedOvulation = lhPrediction;
          methods.add('lh_test');
        }
      }
    }

    // Default: If no methods work, use calendar method with 14 days from next period
    if (predictedOvulation == null && cycles.isNotEmpty) {
      final cycleLengths = cycles.map((c) => c.cycleLength).toList();
      final avgCycleLength =
          cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
      final lastPeriod = cycles.first.startDate;

      // Calculate next period start
      DateTime nextPeriodStart = lastPeriod;
      while (nextPeriodStart.isBefore(today) ||
          nextPeriodStart.isAtSameMomentAs(today)) {
        nextPeriodStart =
            nextPeriodStart.add(Duration(days: avgCycleLength.round()));
      }

      predictedOvulation = nextPeriodStart.subtract(const Duration(days: 14));
      methods.add('calendar_default');
    }

    // If still null, use current date + 14 days (minimum prediction)
    predictedOvulation ??= today.add(const Duration(days: 14));

    // Ensure prediction is always in the future (guaranteed non-null at this point)
    final finalPrediction = predictedOvulation;
    if (finalPrediction.isBefore(today)) {
      // If somehow still in past, add one cycle length
      DateTime adjustedPrediction = finalPrediction;
      if (cycles.isNotEmpty) {
        final cycleLengths = cycles.map((c) => c.cycleLength).toList();
        final avgCycleLength =
            cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
        while (adjustedPrediction.isBefore(today)) {
          adjustedPrediction =
              adjustedPrediction.add(Duration(days: avgCycleLength.round()));
        }
      } else {
        adjustedPrediction = today.add(const Duration(days: 14));
      }
      return FertilityPrediction.calculateFertileWindow(
        adjustedPrediction,
        methods,
      );
    }

    return FertilityPrediction.calculateFertileWindow(
      finalPrediction,
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
