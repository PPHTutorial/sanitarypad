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
  final String? imagePath;
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
    this.imagePath,
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
      imagePath: data['imagePath'] as String?,
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
      'imagePath': imagePath,
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
        imagePath,
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

/// Skin type analysis result
class SkinType extends Equatable {
  final String? id;
  final String userId;
  final String primaryType; // oily, dry, combination, normal, sensitive
  final Map<String, double> typeScores; // Scores for each type
  final String? concerns; // acne, aging, dark spots, etc.
  final String? analysisNotes;
  final DateTime analyzedAt;
  final DateTime? updatedAt;

  const SkinType({
    this.id,
    required this.userId,
    required this.primaryType,
    required this.typeScores,
    this.concerns,
    this.analysisNotes,
    required this.analyzedAt,
    this.updatedAt,
  });

  factory SkinType.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SkinType(
      id: doc.id,
      userId: data['userId'] as String,
      primaryType: data['primaryType'] as String,
      typeScores: Map<String, double>.from(
        (data['typeScores'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
      concerns: data['concerns'] as String?,
      analysisNotes: data['analysisNotes'] as String?,
      analyzedAt: (data['analyzedAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'primaryType': primaryType,
      'typeScores': typeScores,
      'concerns': concerns,
      'analysisNotes': analysisNotes,
      'analyzedAt': Timestamp.fromDate(analyzedAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        primaryType,
        typeScores,
        concerns,
        analysisNotes,
        analyzedAt,
        updatedAt,
      ];
}

/// Daily skin journal entry
class SkinJournalEntry extends Equatable {
  final String? id;
  final String userId;
  final DateTime date;
  final String? skinCondition; // excellent, good, fair, poor
  final int? hydrationLevel; // 1-10
  final int? oilinessLevel; // 1-10
  final List<String> concerns; // acne, dryness, redness, etc.
  final String? notes;
  final List<String>? photoUrls;
  final String? weatherCondition;
  final int? sleepHours;
  final String? stressLevel; // low, medium, high
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SkinJournalEntry({
    this.id,
    required this.userId,
    required this.date,
    this.skinCondition,
    this.hydrationLevel,
    this.oilinessLevel,
    this.concerns = const [],
    this.notes,
    this.photoUrls,
    this.weatherCondition,
    this.sleepHours,
    this.stressLevel,
    required this.createdAt,
    this.updatedAt,
  });

  factory SkinJournalEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SkinJournalEntry(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      skinCondition: data['skinCondition'] as String?,
      hydrationLevel: data['hydrationLevel'] as int?,
      oilinessLevel: data['oilinessLevel'] as int?,
      concerns: (data['concerns'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      notes: data['notes'] as String?,
      photoUrls: (data['photoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      weatherCondition: data['weatherCondition'] as String?,
      sleepHours: data['sleepHours'] as int?,
      stressLevel: data['stressLevel'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'skinCondition': skinCondition,
      'hydrationLevel': hydrationLevel,
      'oilinessLevel': oilinessLevel,
      'concerns': concerns,
      'notes': notes,
      'photoUrls': photoUrls,
      'weatherCondition': weatherCondition,
      'sleepHours': sleepHours,
      'stressLevel': stressLevel,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        skinCondition,
        hydrationLevel,
        oilinessLevel,
        concerns,
        notes,
        photoUrls,
        weatherCondition,
        sleepHours,
        stressLevel,
        createdAt,
        updatedAt,
      ];
}

extension SkinJournalEntryExtension on SkinJournalEntry {
  SkinJournalEntry copyWith({
    DateTime? date,
    String? skinCondition,
    int? hydrationLevel,
    int? oilinessLevel,
    List<String>? concerns,
    String? notes,
    List<String>? photoUrls,
    String? weatherCondition,
    int? sleepHours,
    String? stressLevel,
    DateTime? updatedAt,
  }) {
    return SkinJournalEntry(
      id: id,
      userId: userId,
      date: date ?? this.date,
      skinCondition: skinCondition ?? this.skinCondition,
      hydrationLevel: hydrationLevel ?? this.hydrationLevel,
      oilinessLevel: oilinessLevel ?? this.oilinessLevel,
      concerns: concerns ?? this.concerns,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      sleepHours: sleepHours ?? this.sleepHours,
      stressLevel: stressLevel ?? this.stressLevel,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Personalized routine template
class RoutineTemplate extends Equatable {
  final String? id;
  final String userId;
  final String name;
  final String skinType; // Target skin type
  final List<String> concerns; // Target concerns
  final String routineType; // morning, evening, weekly
  final List<String> productIds; // Product IDs in order
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RoutineTemplate({
    this.id,
    required this.userId,
    required this.name,
    required this.skinType,
    this.concerns = const [],
    required this.routineType,
    this.productIds = const [],
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory RoutineTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoutineTemplate(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      skinType: data['skinType'] as String,
      concerns: (data['concerns'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      routineType: data['routineType'] as String,
      productIds: (data['productIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      notes: data['notes'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'skinType': skinType,
      'concerns': concerns,
      'routineType': routineType,
      'productIds': productIds,
      'notes': notes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        skinType,
        concerns,
        routineType,
        productIds,
        notes,
        isActive,
        createdAt,
        updatedAt,
      ];
}

extension RoutineTemplateExtension on RoutineTemplate {
  RoutineTemplate copyWith({
    String? name,
    String? skinType,
    List<String>? concerns,
    String? routineType,
    List<String>? productIds,
    String? notes,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return RoutineTemplate(
      id: id,
      userId: userId,
      name: name ?? this.name,
      skinType: skinType ?? this.skinType,
      concerns: concerns ?? this.concerns,
      routineType: routineType ?? this.routineType,
      productIds: productIds ?? this.productIds,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Product ingredient
class Ingredient extends Equatable {
  final String? id;
  final String name;
  final String? scientificName;
  final String category; // humectant, emollient, active, preservative, etc.
  final String? description;
  final String? benefits;
  final String? concerns; // potential irritants, allergies, etc.
  final String? comedogenicRating; // 0-5
  final String? irritationRating; // low, medium, high
  final List<String>? goodFor; // skin types/concerns
  final List<String>? avoidWith; // ingredients to avoid mixing
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Ingredient({
    this.id,
    required this.name,
    this.scientificName,
    required this.category,
    this.description,
    this.benefits,
    this.concerns,
    this.comedogenicRating,
    this.irritationRating,
    this.goodFor,
    this.avoidWith,
    required this.createdAt,
    this.updatedAt,
  });

  factory Ingredient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ingredient(
      id: doc.id,
      name: data['name'] as String,
      scientificName: data['scientificName'] as String?,
      category: data['category'] as String,
      description: data['description'] as String?,
      benefits: data['benefits'] as String?,
      concerns: data['concerns'] as String?,
      comedogenicRating: data['comedogenicRating'] as String?,
      irritationRating: data['irritationRating'] as String?,
      goodFor:
          (data['goodFor'] as List<dynamic>?)?.map((e) => e as String).toList(),
      avoidWith: (data['avoidWith'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'nameLower': name.toLowerCase(),
      'scientificName': scientificName,
      'scientificNameLower': scientificName?.toLowerCase(),
      'category': category,
      'description': description,
      'benefits': benefits,
      'concerns': concerns,
      'comedogenicRating': comedogenicRating,
      'irritationRating': irritationRating,
      'goodFor': goodFor,
      'avoidWith': avoidWith,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        scientificName,
        category,
        description,
        benefits,
        concerns,
        comedogenicRating,
        irritationRating,
        goodFor,
        avoidWith,
        createdAt,
        updatedAt,
      ];
}

/// Acne/pimple tracking entry
class AcneEntry extends Equatable {
  final String? id;
  final String userId;
  final DateTime date;
  final String location; // forehead, cheek, chin, nose, etc.
  final String type; // whitehead, blackhead, papule, pustule, nodule, cyst
  final int severity; // 1-5
  final String? notes;
  final List<String>? photoUrls;
  final String? treatmentUsed;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AcneEntry({
    this.id,
    required this.userId,
    required this.date,
    required this.location,
    required this.type,
    required this.severity,
    this.notes,
    this.photoUrls,
    this.treatmentUsed,
    required this.createdAt,
    this.updatedAt,
  });

  factory AcneEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AcneEntry(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] as String,
      type: data['type'] as String,
      severity: data['severity'] as int,
      notes: data['notes'] as String?,
      photoUrls: (data['photoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      treatmentUsed: data['treatmentUsed'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'location': location,
      'type': type,
      'severity': severity,
      'notes': notes,
      'photoUrls': photoUrls,
      'treatmentUsed': treatmentUsed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        location,
        type,
        severity,
        notes,
        photoUrls,
        treatmentUsed,
        createdAt,
        updatedAt,
      ];
}

extension AcneEntryExtension on AcneEntry {
  AcneEntry copyWith({
    DateTime? date,
    String? location,
    String? type,
    int? severity,
    String? notes,
    List<String>? photoUrls,
    String? treatmentUsed,
    DateTime? updatedAt,
  }) {
    return AcneEntry(
      id: id,
      userId: userId,
      date: date ?? this.date,
      location: location ?? this.location,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      treatmentUsed: treatmentUsed ?? this.treatmentUsed,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// UV Index entry
class UVIndexEntry extends Equatable {
  final String? id;
  final String userId;
  final DateTime date;
  final int uvIndex; // 0-11+
  final String? location;
  final String? weatherCondition;
  final String? protectionUsed; // sunscreen, hat, umbrella, etc.
  final DateTime createdAt;

  const UVIndexEntry({
    this.id,
    required this.userId,
    required this.date,
    required this.uvIndex,
    this.location,
    this.weatherCondition,
    this.protectionUsed,
    required this.createdAt,
  });

  factory UVIndexEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UVIndexEntry(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      uvIndex: data['uvIndex'] as int,
      location: data['location'] as String?,
      weatherCondition: data['weatherCondition'] as String?,
      protectionUsed: data['protectionUsed'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'uvIndex': uvIndex,
      'location': location,
      'weatherCondition': weatherCondition,
      'protectionUsed': protectionUsed,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        uvIndex,
        location,
        weatherCondition,
        protectionUsed,
        createdAt
      ];
}

extension UVIndexEntryExtension on UVIndexEntry {
  UVIndexEntry copyWith({
    DateTime? date,
    int? uvIndex,
    String? location,
    String? weatherCondition,
    String? protectionUsed,
  }) {
    return UVIndexEntry(
      id: id,
      userId: userId,
      date: date ?? this.date,
      uvIndex: uvIndex ?? this.uvIndex,
      location: location ?? this.location,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      protectionUsed: protectionUsed ?? this.protectionUsed,
      createdAt: createdAt,
    );
  }
}

/// Skin goal
class SkinGoal extends Equatable {
  final String? id;
  final String userId;
  final String goal; // clear skin, reduce acne, anti-aging, hydration, etc.
  final String? description;
  final DateTime targetDate;
  final String status; // active, achieved, paused
  final List<String>? actionSteps;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SkinGoal({
    this.id,
    required this.userId,
    required this.goal,
    this.description,
    required this.targetDate,
    this.status = 'active',
    this.actionSteps,
    required this.createdAt,
    this.updatedAt,
  });

  factory SkinGoal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SkinGoal(
      id: doc.id,
      userId: data['userId'] as String,
      goal: data['goal'] as String,
      description: data['description'] as String?,
      targetDate: (data['targetDate'] as Timestamp).toDate(),
      status: data['status'] as String? ?? 'active',
      actionSteps: (data['actionSteps'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'goal': goal,
      'description': description,
      'targetDate': Timestamp.fromDate(targetDate),
      'status': status,
      'actionSteps': actionSteps,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        goal,
        description,
        targetDate,
        status,
        actionSteps,
        createdAt,
        updatedAt,
      ];
}

extension SkinGoalExtension on SkinGoal {
  SkinGoal copyWith({
    String? goal,
    String? description,
    DateTime? targetDate,
    String? status,
    List<String>? actionSteps,
    DateTime? updatedAt,
  }) {
    return SkinGoal(
      id: id,
      userId: userId,
      goal: goal ?? this.goal,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      actionSteps: actionSteps ?? this.actionSteps,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
