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
