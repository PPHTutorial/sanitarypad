import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Emergency contact model
class EmergencyContact extends Equatable {
  final String? id;
  final String userId;
  final String name;
  final String phoneNumber;
  final String? email;
  final String relationship; // family, friend, doctor, partner, other
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const EmergencyContact({
    this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.relationship,
    this.isPrimary = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory EmergencyContact.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmergencyContact(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      phoneNumber: data['phoneNumber'] as String,
      email: data['email'] as String?,
      relationship: data['relationship'] as String,
      isPrimary: data['isPrimary'] as bool? ?? false,
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
      'phoneNumber': phoneNumber,
      'email': email,
      'relationship': relationship,
      'isPrimary': isPrimary,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create copy with updated fields
  EmergencyContact copyWith({
    String? name,
    String? phoneNumber,
    String? email,
    String? relationship,
    bool? isPrimary,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id,
      userId: userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        phoneNumber,
        email,
        relationship,
        isPrimary,
        createdAt,
        updatedAt,
      ];
}
