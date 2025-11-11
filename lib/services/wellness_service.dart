import '../data/models/wellness_model.dart';
import '../core/constants/app_constants.dart';
import 'storage_service.dart';
import 'auth_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Wellness tracking service
class WellnessService {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create wellness entry
  Future<WellnessModel> createWellnessEntry({
    required DateTime date,
    required WellnessHydration hydration,
    required WellnessSleep sleep,
    required WellnessAppetite appetite,
    required WellnessMood mood,
    WellnessExercise? exercise,
    String? journal,
    List<String>? photoUrls,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final entryId =
        _firestore.collection(AppConstants.collectionWellnessEntries).doc().id;

    final entry = WellnessModel(
      entryId: entryId,
      userId: user.uid,
      date: date,
      hydration: hydration,
      sleep: sleep,
      appetite: appetite,
      mood: mood,
      exercise: exercise,
      journal: journal,
      photoUrls: photoUrls,
      createdAt: DateTime.now(),
    );

    await _storageService.saveDocument(
      collection: AppConstants.collectionWellnessEntries,
      documentId: entryId,
      data: entry.toFirestore(),
    );

    return entry;
  }

  /// Get wellness entries
  Future<List<WellnessModel>> getWellnessEntries({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final query = await _storageService.queryDocuments(
      collection: AppConstants.collectionWellnessEntries,
      whereField: 'userId',
      whereValue: user.uid,
      orderBy: 'date',
      descending: true,
      limit: limit,
    );

    return query.docs.map((doc) => WellnessModel.fromFirestore(doc)).toList();
  }

  /// Stream wellness entries for real-time updates
  Stream<List<WellnessModel>> watchWellnessEntries(
    String userId, {
    int? limit,
  }) {
    Query collection = _firestore
        .collection(AppConstants.collectionWellnessEntries)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true);

    if (limit != null && limit > 0) {
      collection = collection.limit(limit);
    }

    return collection.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => WellnessModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get wellness entry for specific date
  Future<WellnessModel?> getWellnessEntryForDate(DateTime date) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = await _storageService.queryDocuments(
      collection: AppConstants.collectionWellnessEntries,
      whereField: 'userId',
      whereValue: user.uid,
    );

    final entries = query.docs
        .map((doc) => WellnessModel.fromFirestore(doc))
        .where((entry) {
      final entryDate = entry.date;
      return entryDate
              .isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          entryDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
    }).toList();

    return entries.isNotEmpty ? entries.first : null;
  }

  /// Update wellness entry
  Future<void> updateWellnessEntry(WellnessModel entry) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _storageService.updateDocument(
      collection: AppConstants.collectionWellnessEntries,
      documentId: entry.entryId,
      data: entry.toFirestore(),
    );
  }

  /// Delete wellness entry
  Future<void> deleteWellnessEntry(String entryId) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _storageService.deleteDocument(
      collection: AppConstants.collectionWellnessEntries,
      documentId: entryId,
    );
  }

  /// Calculate wellness score
  Future<double> calculateWellnessScore({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final entries = await getWellnessEntries(
      startDate: startDate,
      endDate: endDate,
    );

    if (entries.isEmpty) return 0.0;

    double totalScore = 0.0;
    for (final entry in entries) {
      double entryScore = 0.0;

      // Hydration score (0-25 points)
      entryScore += (entry.hydration.progress * 25).clamp(0, 25);

      // Sleep score (0-25 points)
      final sleepScore = (entry.sleep.hours / 8 * 25).clamp(0, 25);
      entryScore += sleepScore;

      // Mood score (0-25 points)
      entryScore += (entry.mood.energyLevel / 5 * 25).clamp(0, 25);

      // Exercise bonus (0-25 points)
      if (entry.exercise != null) {
        entryScore += 25;
      }

      totalScore += entryScore;
    }

    return (totalScore / entries.length).clamp(0, 100);
  }
}
