import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/pad_model.dart';
import '../core/constants/app_constants.dart';
import 'storage_service.dart';
import 'auth_service.dart';

/// Pad management service
class PadService {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Log pad change
  Future<PadModel> logPadChange({
    required DateTime changeTime,
    required String padType,
    required String flowIntensity,
    int? duration,
    String? cycleId,
    String? notes,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get last pad change to calculate duration
    final lastPad = await getLastPadChange();
    final calculatedDuration = duration ??
        (lastPad != null
            ? changeTime.difference(lastPad.changeTime).inHours
            : 0);

    final padId = _firestore.collection(AppConstants.collectionPads).doc().id;

    final pad = PadModel(
      padId: padId,
      userId: user.uid,
      changeTime: changeTime,
      cycleId: cycleId,
      padType: padType,
      flowIntensity: flowIntensity,
      duration: calculatedDuration,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _storageService.saveDocument(
      collection: AppConstants.collectionPads,
      documentId: padId,
      data: pad.toFirestore(),
    );

    // Update inventory if needed
    await _decrementInventory(padType);

    return pad;
  }

  /// Get pad changes
  Future<List<PadModel>> getPadChanges({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    Query query = _firestore
        .collection(AppConstants.collectionPads)
        .where('userId', isEqualTo: user.uid);

    if (startDate != null) {
      query = query.where('changeTime', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('changeTime', isLessThanOrEqualTo: endDate);
    }

    query = query.orderBy('changeTime', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => PadModel.fromFirestore(doc)).toList();
  }

  /// Get last pad change
  Future<PadModel?> getLastPadChange() async {
    final pads = await getPadChanges(limit: 1);
    return pads.isNotEmpty ? pads.first : null;
  }

  /// Get pad inventory
  Future<List<PadInventoryModel>> getInventory() async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final query = await _storageService.queryDocuments(
      collection: AppConstants.collectionPadInventory,
      whereField: 'userId',
      whereValue: user.uid,
    );

    return query.docs
        .map((doc) => PadInventoryModel.fromFirestore(doc))
        .toList();
  }

  /// Update inventory
  Future<void> updateInventory({
    required String padType,
    required int quantity,
    String? brand,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Check if inventory exists
    final inventory = await getInventory();
    final existing = inventory.firstWhere(
      (item) => item.padType == padType,
      orElse: () => PadInventoryModel(
        inventoryId: '',
        userId: user.uid,
        padType: padType,
        quantity: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (existing.inventoryId.isEmpty) {
      // Create new inventory
      final inventoryId =
          _firestore.collection(AppConstants.collectionPadInventory).doc().id;

      final newInventory = PadInventoryModel(
        inventoryId: inventoryId,
        userId: user.uid,
        padType: padType,
        quantity: quantity,
        brand: brand,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _storageService.saveDocument(
        collection: AppConstants.collectionPadInventory,
        documentId: inventoryId,
        data: newInventory.toFirestore(),
      );
    } else {
      // Update existing inventory
      final updatedInventory = PadInventoryModel(
        inventoryId: existing.inventoryId,
        userId: user.uid,
        padType: padType,
        quantity: quantity,
        brand: brand ?? existing.brand,
        lastRefillDate: quantity > existing.quantity
            ? DateTime.now()
            : existing.lastRefillDate,
        lowStockThreshold: existing.lowStockThreshold,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );

      await _storageService.updateDocument(
        collection: AppConstants.collectionPadInventory,
        documentId: existing.inventoryId,
        data: updatedInventory.toFirestore(),
      );
    }
  }

  /// Decrement inventory when pad is used
  Future<void> _decrementInventory(String padType) async {
    final inventory = await getInventory();
    final item = inventory.firstWhere(
      (i) => i.padType == padType,
      orElse: () => PadInventoryModel(
        inventoryId: '',
        userId: _authService.currentUser!.uid,
        padType: padType,
        quantity: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (item.inventoryId.isNotEmpty && item.quantity > 0) {
      await updateInventory(
        padType: padType,
        quantity: item.quantity - 1,
        brand: item.brand,
      );
    }
  }

  /// Get pad statistics
  Future<Map<String, dynamic>> getPadStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pads = await getPadChanges(
      startDate: startDate,
      endDate: endDate,
    );

    if (pads.isEmpty) {
      return {
        'totalChanges': 0,
        'averageDuration': 0,
        'mostUsedType': null,
        'averagePerDay': 0,
      };
    }

    // Calculate statistics
    final totalChanges = pads.length;
    final totalDuration = pads.fold<int>(
      0,
      (sum, pad) => sum + pad.duration,
    );
    final averageDuration = totalDuration / totalChanges;

    // Most used pad type
    final typeCounts = <String, int>{};
    for (final pad in pads) {
      typeCounts[pad.padType] = (typeCounts[pad.padType] ?? 0) + 1;
    }
    final mostUsedType =
        typeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    // Average per day
    final days = startDate != null && endDate != null
        ? endDate.difference(startDate).inDays + 1
        : 30;
    final averagePerDay = totalChanges / days;

    return {
      'totalChanges': totalChanges,
      'averageDuration': averageDuration.round(),
      'mostUsedType': mostUsedType,
      'averagePerDay': averagePerDay.toStringAsFixed(1),
    };
  }

  /// Get recommended pad type based on flow
  String getRecommendedPadType(String flowIntensity) {
    switch (flowIntensity) {
      case AppConstants.flowLight:
        return AppConstants.padTypeLight;
      case AppConstants.flowMedium:
        return AppConstants.padTypeRegular;
      case AppConstants.flowHeavy:
        return AppConstants.padTypeSuper;
      default:
        return AppConstants.padTypeRegular;
    }
  }
}
