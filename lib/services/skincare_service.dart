import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../data/models/skincare_model.dart';

/// Skincare service
class SkincareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== Product Management ==========

  /// Create skincare product
  Future<String> createProduct(SkincareProduct product) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.collectionSkincareProducts)
          .add(product.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update skincare product
  Future<void> updateProduct(SkincareProduct product) async {
    if (product.id == null) {
      throw Exception('Product ID is required for update');
    }

    try {
      await _firestore
          .collection(AppConstants.collectionSkincareProducts)
          .doc(product.id)
          .update(product.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete skincare product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionSkincareProducts)
          .doc(productId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's products
  Stream<List<SkincareProduct>> getUserProducts(String userId) {
    return _firestore
        .collection(AppConstants.collectionSkincareProducts)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SkincareProduct.fromFirestore(doc))
          .toList();
    });
  }

  /// Get products by category
  Stream<List<SkincareProduct>> getProductsByCategory(
    String userId,
    String category,
  ) {
    return _firestore
        .collection(AppConstants.collectionSkincareProducts)
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SkincareProduct.fromFirestore(doc))
          .toList();
    });
  }

  /// Get expiring products
  Stream<List<SkincareProduct>> getExpiringProducts(String userId) {
    return _firestore
        .collection(AppConstants.collectionSkincareProducts)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SkincareProduct.fromFirestore(doc))
          .where((product) => product.isExpiringSoon || product.isExpired)
          .toList();
    });
  }

  // ========== Routine Entry Management ==========

  /// Create skincare entry
  Future<String> createEntry(SkincareEntry entry) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.collectionSkincareEntries)
          .add(entry.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update skincare entry
  Future<void> updateEntry(SkincareEntry entry) async {
    if (entry.id == null) {
      throw Exception('Entry ID is required for update');
    }

    try {
      await _firestore
          .collection(AppConstants.collectionSkincareEntries)
          .doc(entry.id)
          .update(entry.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete skincare entry
  Future<void> deleteEntry(String entryId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionSkincareEntries)
          .doc(entryId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Get skincare entries for date range
  Stream<List<SkincareEntry>> getEntries(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection(AppConstants.collectionSkincareEntries)
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SkincareEntry.fromFirestore(doc))
          .toList();
    });
  }

  /// Get entry for specific date
  Future<SkincareEntry?> getEntryForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(AppConstants.collectionSkincareEntries)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return SkincareEntry.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }
}

extension SkincareProductExtension on SkincareProduct {
  SkincareProduct copyWith({
    String? name,
    String? category,
    String? brand,
    String? imageUrl,
    DateTime? purchaseDate,
    DateTime? expirationDate,
    double? price,
    String? notes,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return SkincareProduct(
      id: id,
      userId: userId,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expirationDate: expirationDate ?? this.expirationDate,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ===== Enhanced feature helpers =====

class SkincareEnhancedService {
  SkincareEnhancedService(this._firestore);

  final FirebaseFirestore _firestore;

  // Skin type
  Future<void> saveSkinType(SkinType skinType) async {
    await _firestore
        .collection(AppConstants.collectionSkinTypes)
        .doc(skinType.userId)
        .set(skinType.toFirestore());
  }

  Future<SkinType?> getSkinType(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.collectionSkinTypes)
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return SkinType.fromFirestore(doc);
  }

  // Skin journal
  Stream<List<SkinJournalEntry>> getSkinJournalEntries(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore
        .collection(AppConstants.collectionSkinJournalEntries)
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
              .map((doc) => SkinJournalEntry.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> logSkinJournal(SkinJournalEntry entry) async {
    await _firestore
        .collection(AppConstants.collectionSkinJournalEntries)
        .add(entry.toFirestore());
  }

  // Routine templates
  Stream<List<RoutineTemplate>> getRoutineTemplates(String userId) {
    return _firestore
        .collection(AppConstants.collectionRoutineTemplates)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RoutineTemplate.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> saveRoutineTemplate(RoutineTemplate template) async {
    await _firestore
        .collection(AppConstants.collectionRoutineTemplates)
        .add(template.toFirestore());
  }

  // Ingredients
  Stream<List<Ingredient>> getIngredients({String? searchTerm}) {
    Query query = _firestore
        .collection(AppConstants.collectionIngredients)
        .orderBy('name');

    if (searchTerm != null && searchTerm.trim().isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThanOrEqualTo: '$searchTerm\uf8ff');
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Ingredient.fromFirestore(doc))
              .toList(),
        );
  }

  // Acne tracker
  Stream<List<AcneEntry>> getAcneEntries(String userId) {
    return _firestore
        .collection(AppConstants.collectionAcneEntries)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => AcneEntry.fromFirestore(doc)).toList(),
        );
  }

  Future<void> logAcneEntry(AcneEntry entry) async {
    await _firestore
        .collection(AppConstants.collectionAcneEntries)
        .add(entry.toFirestore());
  }

  // UV index
  Future<void> logUVIndex(UVIndexEntry entry) async {
    await _firestore
        .collection(AppConstants.collectionUVIndexEntries)
        .add(entry.toFirestore());
  }

  Stream<List<UVIndexEntry>> getUVIndexEntries(String userId) {
    return _firestore
        .collection(AppConstants.collectionUVIndexEntries)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UVIndexEntry.fromFirestore(doc))
              .toList(),
        );
  }

  // Skin goals
  Stream<List<SkinGoal>> getSkinGoals(String userId) {
    return _firestore
        .collection(AppConstants.collectionSkinGoals)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => SkinGoal.fromFirestore(doc)).toList(),
        );
  }

  Future<void> createSkinGoal(SkinGoal goal) async {
    await _firestore
        .collection(AppConstants.collectionSkinGoals)
        .add(goal.toFirestore());
  }

  Future<void> updateSkinGoal(SkinGoal goal) async {
    if (goal.id == null) throw Exception('Goal ID required');
    await _firestore
        .collection(AppConstants.collectionSkinGoals)
        .doc(goal.id)
        .update(goal.toFirestore());
  }
}

extension SkincareEntryExtension on SkincareEntry {
  SkincareEntry copyWith({
    DateTime? date,
    String? timeOfDay,
    List<String>? productsUsed,
    String? skinCondition,
    String? notes,
    List<String>? photoUrls,
    DateTime? updatedAt,
  }) {
    return SkincareEntry(
      id: id,
      userId: userId,
      date: date ?? this.date,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      productsUsed: productsUsed ?? this.productsUsed,
      skinCondition: skinCondition ?? this.skinCondition,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
