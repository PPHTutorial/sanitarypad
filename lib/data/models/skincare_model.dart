import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Skincare product model
class SkincareProduct extends Equatable {
  final String? id;
  final String userId;
  final String name;
  final String category; // cleanser, moisturizer, serum, sunscreen, etc.
  final String? brand;
  final String? imageUrl;
  final DateTime? purchaseDate;
  final DateTime? expirationDate;
  final double? price;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SkincareProduct({
    this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.brand,
    this.imageUrl,
    this.purchaseDate,
    this.expirationDate,
    this.price,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory SkincareProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SkincareProduct(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      category: data['category'] as String,
      brand: data['brand'] as String?,
      imageUrl: data['imageUrl'] as String?,
      purchaseDate: data['purchaseDate'] != null
          ? (data['purchaseDate'] as Timestamp).toDate()
          : null,
      expirationDate: data['expirationDate'] != null
          ? (data['expirationDate'] as Timestamp).toDate()
          : null,
      price: (data['price'] as num?)?.toDouble(),
      notes: data['notes'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'category': category,
      'brand': brand,
      'imageUrl': imageUrl,
      'purchaseDate':
          purchaseDate != null ? Timestamp.fromDate(purchaseDate!) : null,
      'expirationDate':
          expirationDate != null ? Timestamp.fromDate(expirationDate!) : null,
      'price': price,
      'notes': notes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Check if product is expired or expiring soon
  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final daysUntilExpiry = expirationDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  bool get isExpired {
    if (expirationDate == null) return false;
    return expirationDate!.isBefore(DateTime.now());
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        category,
        brand,
        imageUrl,
        purchaseDate,
        expirationDate,
        price,
        notes,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Skincare routine entry
class SkincareEntry extends Equatable {
  final String? id;
  final String userId;
  final DateTime date;
  final String timeOfDay; // morning, evening, both
  final List<String> productsUsed; // Product IDs
  final String? skinCondition; // dry, oily, combination, normal, sensitive
  final String? notes;
  final List<String>? photoUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SkincareEntry({
    this.id,
    required this.userId,
    required this.date,
    required this.timeOfDay,
    this.productsUsed = const [],
    this.skinCondition,
    this.notes,
    this.photoUrls,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory SkincareEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SkincareEntry(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      timeOfDay: data['timeOfDay'] as String,
      productsUsed: (data['productsUsed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      skinCondition: data['skinCondition'] as String?,
      notes: data['notes'] as String?,
      photoUrls: (data['photoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['date'] as Timestamp)
              .toDate(), // Fallback to date if createdAt missing
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'timeOfDay': timeOfDay,
      'productsUsed': productsUsed,
      'skinCondition': skinCondition,
      'notes': notes,
      'photoUrls': photoUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        timeOfDay,
        productsUsed,
        skinCondition,
        notes,
        photoUrls,
        createdAt,
        updatedAt,
      ];
}
