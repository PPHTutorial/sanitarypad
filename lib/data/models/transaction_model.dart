import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  credit, // User earned/received credits (Ads, Subscription, Daily Reset)
  debit // User spent credits (Actions, Creating Groups/Events)
}

class TransactionModel {
  final String? id;
  final String userId;
  final double amount;
  final String action; // e.g., 'aiChat', 'ad_reward', 'daily_reset_bonus'
  final TransactionType type;
  final DateTime timestamp;
  final String description;
  final Map<String, dynamic>? metadata;

  TransactionModel({
    this.id,
    required this.userId,
    required this.amount,
    required this.action,
    required this.type,
    required this.timestamp,
    required this.description,
    this.metadata,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      action: data['action'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => TransactionType.debit,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] ?? '',
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'action': action,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
      'metadata': metadata,
    };
  }
}
