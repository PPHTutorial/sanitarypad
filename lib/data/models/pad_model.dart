import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Pad change model
class PadModel extends Equatable {
  final String padId;
  final String userId;
  final DateTime changeTime;
  final String? cycleId;
  final String padType;
  final String flowIntensity;
  final int duration; // hours since last change
  final String? notes;
  final DateTime createdAt;

  const PadModel({
    required this.padId,
    required this.userId,
    required this.changeTime,
    this.cycleId,
    required this.padType,
    required this.flowIntensity,
    required this.duration,
    this.notes,
    required this.createdAt,
  });

  factory PadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PadModel(
      padId: doc.id,
      userId: data['userId'] as String,
      changeTime: (data['changeTime'] as Timestamp).toDate(),
      cycleId: data['cycleId'] as String?,
      padType: data['padType'] as String,
      flowIntensity: data['flowIntensity'] as String,
      duration: data['duration'] as int,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'changeTime': Timestamp.fromDate(changeTime),
      'cycleId': cycleId,
      'padType': padType,
      'flowIntensity': flowIntensity,
      'duration': duration,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        padId,
        userId,
        changeTime,
        cycleId,
        padType,
        flowIntensity,
        duration,
        notes,
        createdAt,
      ];
}

/// Pad inventory model
class PadInventoryModel extends Equatable {
  final String inventoryId;
  final String userId;
  final String padType;
  final int quantity;
  final String? brand;
  final DateTime? lastRefillDate;
  final int lowStockThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PadInventoryModel({
    required this.inventoryId,
    required this.userId,
    required this.padType,
    required this.quantity,
    this.brand,
    this.lastRefillDate,
    this.lowStockThreshold = 10,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PadInventoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PadInventoryModel(
      inventoryId: doc.id,
      userId: data['userId'] as String,
      padType: data['padType'] as String,
      quantity: data['quantity'] as int,
      brand: data['brand'] as String?,
      lastRefillDate: data['lastRefillDate'] != null
          ? (data['lastRefillDate'] as Timestamp).toDate()
          : null,
      lowStockThreshold: data['lowStockThreshold'] as int? ?? 10,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'padType': padType,
      'quantity': quantity,
      'brand': brand,
      'lastRefillDate': lastRefillDate != null
          ? Timestamp.fromDate(lastRefillDate!)
          : null,
      'lowStockThreshold': lowStockThreshold,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isLowStock => quantity <= lowStockThreshold;

  @override
  List<Object?> get props => [
        inventoryId,
        userId,
        padType,
        quantity,
        brand,
        lastRefillDate,
        lowStockThreshold,
        createdAt,
        updatedAt,
      ];
}

