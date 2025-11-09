import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/cycle_model.dart';
import '../core/constants/app_constants.dart';
import 'storage_service.dart';
import 'auth_service.dart';

/// Cycle tracking service
class CycleService {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new cycle entry
  Future<CycleModel> createCycle({
    required DateTime startDate,
    DateTime? endDate,
    required int cycleLength,
    required int periodLength,
    required String flowIntensity,
    List<String> symptoms = const [],
    String? mood,
    String? notes,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final cycleId =
        _firestore.collection(AppConstants.collectionCycles).doc().id;

    final cycle = CycleModel(
      cycleId: cycleId,
      userId: user.uid,
      startDate: startDate,
      endDate: endDate,
      cycleLength: cycleLength,
      periodLength: periodLength,
      flowIntensity: flowIntensity,
      symptoms: symptoms,
      mood: mood,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storageService.saveDocument(
      collection: AppConstants.collectionCycles,
      documentId: cycleId,
      data: cycle.toFirestore(),
    );

    return cycle;
  }

  /// Update cycle
  Future<void> updateCycle(CycleModel cycle) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final updatedCycle = cycle.copyWith(
      updatedAt: DateTime.now(),
    );

    await _storageService.updateDocument(
      collection: AppConstants.collectionCycles,
      documentId: cycle.cycleId,
      data: updatedCycle.toFirestore(),
    );
  }

  /// Get cycles for user
  Future<List<CycleModel>> getCycles({
    int? limit,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final query = await _storageService.queryDocuments(
      collection: AppConstants.collectionCycles,
      whereField: 'userId',
      whereValue: user.uid,
      orderBy: 'startDate',
      descending: true,
      limit: limit,
    );

    return query.docs.map((doc) => CycleModel.fromFirestore(doc)).toList();
  }

  /// Get cycle by ID
  Future<CycleModel?> getCycleById(String cycleId) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final doc = await _storageService.getDocument(
      collection: AppConstants.collectionCycles,
      documentId: cycleId,
    );

    if (doc == null) return null;

    final cycleDoc = await _firestore
        .collection(AppConstants.collectionCycles)
        .doc(cycleId)
        .get();

    if (!cycleDoc.exists) return null;

    return CycleModel.fromFirestore(cycleDoc);
  }

  /// Delete cycle
  Future<void> deleteCycle(String cycleId) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _storageService.deleteDocument(
      collection: AppConstants.collectionCycles,
      documentId: cycleId,
    );
  }

  /// Calculate cycle statistics
  Future<Map<String, dynamic>> getCycleStatistics() async {
    final cycles = await getCycles();

    if (cycles.isEmpty) {
      return {
        'averageCycleLength': 0,
        'averagePeriodLength': 0,
        'regularity': 'insufficient_data',
        'totalCycles': 0,
      };
    }

    // Calculate averages
    final totalCycleLength = cycles.fold<int>(
      0,
      (sum, cycle) => sum + cycle.cycleLength,
    );
    final averageCycleLength = (totalCycleLength / cycles.length).round();

    final totalPeriodLength = cycles.fold<int>(
      0,
      (sum, cycle) => sum + cycle.periodLength,
    );
    final averagePeriodLength = (totalPeriodLength / cycles.length).round();

    // Calculate regularity
    String regularity = 'regular';
    if (cycles.length >= 3) {
      final cycleLengths = cycles.map((c) => c.cycleLength).toList();
      final minLength = cycleLengths.reduce((a, b) => a < b ? a : b);
      final maxLength = cycleLengths.reduce((a, b) => a > b ? a : b);
      final variation = maxLength - minLength;

      if (variation <= 7) {
        regularity = 'very_regular';
      } else if (variation <= 14) {
        regularity = 'regular';
      } else {
        regularity = 'irregular';
      }
    } else {
      regularity = 'insufficient_data';
    }

    return {
      'averageCycleLength': averageCycleLength,
      'averagePeriodLength': averagePeriodLength,
      'regularity': regularity,
      'totalCycles': cycles.length,
    };
  }
}
