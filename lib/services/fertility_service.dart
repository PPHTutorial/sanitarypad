import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../data/models/fertility_model.dart';
import '../data/models/cycle_model.dart';

/// Fertility service
class FertilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create fertility entry
  Future<String> createFertilityEntry(FertilityEntry entry) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.collectionFertilityEntries)
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
          .collection(AppConstants.collectionFertilityEntries)
          .doc(entry.id)
          .update(entry.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete fertility entry
  Future<void> deleteFertilityEntry(String entryId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionFertilityEntries)
          .doc(entryId)
          .delete();
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
        .collection(AppConstants.collectionFertilityEntries)
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
          .collection(AppConstants.collectionFertilityEntries)
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

  // ===== Enhanced Feature Methods =====

  /// Hormone cycle entries
  Stream<List<HormoneCycle>> getHormoneCycles(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore
        .collection(AppConstants.collectionHormoneCycles)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => HormoneCycle.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> logHormoneCycle(HormoneCycle cycle) async {
    try {
      await _firestore
          .collection(AppConstants.collectionHormoneCycles)
          .add(cycle.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Fertility symptoms
  Stream<List<FertilitySymptom>> getFertilitySymptoms(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore
        .collection(AppConstants.collectionFertilitySymptoms)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => FertilitySymptom.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> logFertilitySymptom(FertilitySymptom symptom) async {
    await _firestore
        .collection(AppConstants.collectionFertilitySymptoms)
        .add(symptom.toFirestore());
  }

  /// Mood & Energy
  Stream<List<MoodEnergyEntry>> getMoodEnergyEntries(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore
        .collection(AppConstants.collectionMoodEnergyEntries)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => MoodEnergyEntry.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> logMoodEnergy(MoodEnergyEntry entry) async {
    await _firestore
        .collection(AppConstants.collectionMoodEnergyEntries)
        .add(entry.toFirestore());
  }

  /// Fertility medications
  Stream<List<FertilityMedication>> getActiveMedications(String userId) {
    return _firestore
        .collection(AppConstants.collectionFertilityMedications)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FertilityMedication.fromFirestore(doc))
            .toList());
  }

  Future<void> addFertilityMedication(FertilityMedication medication) async {
    await _firestore
        .collection(AppConstants.collectionFertilityMedications)
        .add(medication.toFirestore());
  }

  Future<void> updateFertilityMedication(FertilityMedication medication) async {
    if (medication.id == null) {
      throw Exception('Medication ID required for update');
    }

    await _firestore
        .collection(AppConstants.collectionFertilityMedications)
        .doc(medication.id)
        .update(medication.toFirestore());
  }

  /// Intercourse tracking
  Stream<List<IntercourseEntry>> getIntercourseEntries(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore
        .collection(AppConstants.collectionIntercourseEntries)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => IntercourseEntry.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> logIntercourse(IntercourseEntry entry) async {
    await _firestore
        .collection(AppConstants.collectionIntercourseEntries)
        .add(entry.toFirestore());
  }

  /// Pregnancy tests
  Stream<List<PregnancyTestEntry>> getPregnancyTests(String userId) {
    return _firestore
        .collection(AppConstants.collectionPregnancyTestEntries)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PregnancyTestEntry.fromFirestore(doc))
            .toList());
  }

  Future<void> logPregnancyTest(PregnancyTestEntry entry) async {
    await _firestore
        .collection(AppConstants.collectionPregnancyTestEntries)
        .add(entry.toFirestore());
  }

  /// Health recommendations
  Stream<List<HealthRecommendation>> getHealthRecommendations(String userId) {
    return _firestore
        .collection(AppConstants.collectionHealthRecommendations)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealthRecommendation.fromFirestore(doc))
            .toList());
  }

  Future<void> addHealthRecommendation(
      HealthRecommendation recommendation) async {
    await _firestore
        .collection(AppConstants.collectionHealthRecommendations)
        .add(recommendation.toFirestore());
  }

  Future<void> updateHealthRecommendation(
    String id, {
    bool? isCompleted,
    DateTime? completedAt,
  }) async {
    final data = <String, dynamic>{};
    if (isCompleted != null) data['isCompleted'] = isCompleted;
    if (completedAt != null) {
      data['completedAt'] = Timestamp.fromDate(completedAt);
    }
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());

    await _firestore
        .collection(AppConstants.collectionHealthRecommendations)
        .doc(id)
        .update(data);
  }

  /// Ovulation test reminders
  Stream<List<OvulationTestReminder>> getUpcomingOvulationTests(
    String userId,
  ) {
    final now = DateTime.now();
    return _firestore
        .collection(AppConstants.collectionOvulationTestReminders)
        .where('userId', isEqualTo: userId)
        .where('scheduledDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(now.year, now.month, now.day),
            ))
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OvulationTestReminder.fromFirestore(doc))
            .toList());
  }

  Future<void> scheduleOvulationTest(OvulationTestReminder reminder) async {
    await _firestore
        .collection(AppConstants.collectionOvulationTestReminders)
        .add(reminder.toFirestore());
  }

  Future<void> updateOvulationTest(
    OvulationTestReminder reminder,
  ) async {
    if (reminder.id == null) {
      throw Exception('Reminder ID is required');
    }
    await _firestore
        .collection(AppConstants.collectionOvulationTestReminders)
        .doc(reminder.id)
        .update(reminder.toFirestore());
  }

  /// Pregnancy probability calculation (basic weighted algorithm)
  double calculatePregnancyProbability({
    required FertilityPrediction prediction,
    required DateTime currentDate,
    required List<IntercourseEntry> intercourseEntries,
    required List<FertilityEntry> fertilityEntries,
  }) {
    double probability = 0.1; // base probability

    // Increase probability if intercourse occurred within fertile window
    final relevantIntercourse = intercourseEntries.where((entry) =>
        prediction.isInFertileWindow(entry.date) &&
        !entry.usedProtection &&
        entry.date.isAfter(currentDate.subtract(const Duration(days: 14))));
    if (relevantIntercourse.isNotEmpty) {
      probability += 0.25;
    }

    // Consider BBT data quality
    final recentBbtEntries =
        fertilityEntries.where((e) => e.basalBodyTemperature != null).toList();
    if (recentBbtEntries.length >= 5) {
      probability += 0.15;
    }

    // Consider LH positivity
    final recentLh = fertilityEntries.any((e) =>
        e.lhTestPositive == true &&
        prediction.isInFertileWindow(e.date) &&
        e.date.isAfter(currentDate.subtract(const Duration(days: 30))));
    if (recentLh) {
      probability += 0.2;
    }

    // Factor in cervical mucus quality
    final fertileCm = fertilityEntries.any((e) =>
        e.cervicalMucus == 'egg-white' && prediction.isInFertileWindow(e.date));
    if (fertileCm) {
      probability += 0.2;
    }

    return probability.clamp(0.1, 0.95);
  }

  /// Build calendar events for ovulation calendar
  Map<DateTime, List<String>> buildCalendarEvents({
    required List<FertilityEntry> entries,
    required FertilityPrediction prediction,
    List<FertilitySymptom> symptoms = const [],
    List<IntercourseEntry> intercourseEntries = const [],
    List<PregnancyTestEntry> pregnancyTests = const [],
  }) {
    final events = <DateTime, List<String>>{};

    void addEvent(DateTime date, String event) {
      final key = DateTime(date.year, date.month, date.day);
      events.putIfAbsent(key, () => []).add(event);
    }

    // Fertility entries
    for (final entry in entries) {
      if (entry.lhTestPositive == true) {
        addEvent(entry.date, 'LH Surge');
      }
      if (entry.cervicalMucus == 'egg-white') {
        addEvent(entry.date, 'Fertile CM');
      }
      if (entry.basalBodyTemperature != null) {
        addEvent(entry.date, 'BBT: ${entry.basalBodyTemperature}℃');
      }
    }

    // Symptoms
    for (final symptom in symptoms) {
      addEvent(symptom.date, 'Symptoms');
    }

    // Intercourse
    for (final intercourse in intercourseEntries) {
      addEvent(intercourse.date, 'Intimacy');
    }

    // Pregnancy tests
    for (final test in pregnancyTests) {
      addEvent(test.date, 'Pregnancy Test (${test.result})');
    }

    // Fertile window
    for (int i = 0;
        i <=
            prediction.fertileWindowEnd
                .difference(prediction.fertileWindowStart)
                .inDays;
        i++) {
      final date = prediction.fertileWindowStart.add(Duration(days: i));
      addEvent(date, 'Fertile Window');
    }

    addEvent(prediction.predictedOvulation, 'Predicted Ovulation');

    return events;
  }
}
