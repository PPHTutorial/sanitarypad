import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Baby model to track newborn details
class Baby extends Equatable {
  final String? id;
  final String userId;
  final String? pregnancyId;
  final String name;
  final String gender;
  final DateTime birthDate;
  final String birthType; // 'single', 'twins', 'triplets', etc.
  final double? weightAtBirth; // in kg
  final double? heightAtBirth; // in cm
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Baby({
    this.id,
    required this.userId,
    this.pregnancyId,
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.birthType,
    this.weightAtBirth,
    this.heightAtBirth,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Baby.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Baby(
      id: doc.id,
      userId: data['userId'] as String,
      pregnancyId: data['pregnancyId'] as String?,
      name: data['name'] as String,
      gender: data['gender'] as String,
      birthDate: (data['birthDate'] as Timestamp).toDate(),
      birthType: data['birthType'] as String? ?? 'single',
      weightAtBirth: (data['weightAtBirth'] as num?)?.toDouble(),
      heightAtBirth: (data['heightAtBirth'] as num?)?.toDouble(),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'pregnancyId': pregnancyId,
      'name': name,
      'gender': gender,
      'birthDate': Timestamp.fromDate(birthDate),
      'birthType': birthType,
      'weightAtBirth': weightAtBirth,
      'heightAtBirth': heightAtBirth,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Baby copyWith({
    String? name,
    String? gender,
    DateTime? birthDate,
    String? birthType,
    double? weightAtBirth,
    double? heightAtBirth,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Baby(
      id: id,
      userId: userId,
      pregnancyId: pregnancyId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      birthType: birthType ?? this.birthType,
      weightAtBirth: weightAtBirth ?? this.weightAtBirth,
      heightAtBirth: heightAtBirth ?? this.heightAtBirth,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        pregnancyId,
        name,
        gender,
        birthDate,
        birthType,
        weightAtBirth,
        heightAtBirth,
        notes,
        createdAt,
        updatedAt,
      ];
}

/// Growth entry to track baby's growth over time
class GrowthEntry extends Equatable {
  final String? id;
  final String babyId;
  final DateTime date;
  final double weight; // in kg
  final double height; // in cm
  final double? headCircumference; // in cm
  final String? notes;
  final DateTime createdAt;

  const GrowthEntry({
    this.id,
    required this.babyId,
    required this.date,
    required this.weight,
    required this.height,
    this.headCircumference,
    this.notes,
    required this.createdAt,
  });

  factory GrowthEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GrowthEntry(
      id: doc.id,
      babyId: data['babyId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      weight: (data['weight'] as num).toDouble(),
      height: (data['height'] as num).toDouble(),
      headCircumference: (data['headCircumference'] as num?)?.toDouble(),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'babyId': babyId,
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'height': height,
      'headCircumference': headCircumference,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props =>
      [id, babyId, date, weight, height, headCircumference, notes, createdAt];
}

/// Baby milestone to track developmental achievements
class BabyDevelopmentMilestone extends Equatable {
  final String? id;
  final String babyId;
  final String title;
  final String description;
  final DateTime achievedDate;
  final String category; // 'physical', 'cognitive', 'social', 'language'
  final String? imageUrl;
  final String? notes;
  final DateTime createdAt;

  const BabyDevelopmentMilestone({
    this.id,
    required this.babyId,
    required this.title,
    required this.description,
    required this.achievedDate,
    required this.category,
    this.imageUrl,
    this.notes,
    required this.createdAt,
  });

  factory BabyDevelopmentMilestone.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BabyDevelopmentMilestone(
      id: doc.id,
      babyId: data['babyId'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      achievedDate: (data['achievedDate'] as Timestamp).toDate(),
      category: data['category'] as String,
      imageUrl: data['imageUrl'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'babyId': babyId,
      'title': title,
      'description': description,
      'achievedDate': Timestamp.fromDate(achievedDate),
      'category': category,
      'imageUrl': imageUrl,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        babyId,
        title,
        description,
        achievedDate,
        category,
        imageUrl,
        notes,
        createdAt
      ];
}

/// Baby gallery item for photos and scan reports
class BabyGalleryItem extends Equatable {
  final String? id;
  final String babyId;
  final String? title;
  final String imageUrl;
  final String type; // 'photo', 'scan_report'
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  const BabyGalleryItem({
    this.id,
    required this.babyId,
    this.title,
    required this.imageUrl,
    required this.type,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  factory BabyGalleryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BabyGalleryItem(
      id: doc.id,
      babyId: data['babyId'] as String,
      title: data['title'] as String?,
      imageUrl: data['imageUrl'] as String,
      type: data['type'] as String,
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'babyId': babyId,
      'title': title,
      'imageUrl': imageUrl,
      'type': type,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props =>
      [id, babyId, title, imageUrl, type, date, notes, createdAt];
}
