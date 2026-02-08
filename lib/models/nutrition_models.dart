import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Meal type enumeration
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
}

extension MealTypeExtension on MealType {
  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  IconData get icon {
    switch (this) {
      case MealType.breakfast:
        return FontAwesomeIcons.jar;
      case MealType.lunch:
        return FontAwesomeIcons.bowlRice;
      case MealType.dinner:
        return FontAwesomeIcons.bowlFood;
      case MealType.snack:
        return FontAwesomeIcons.pizzaSlice;
    }
  }
}

/// Represents a single meal entry logged by the user
class MealEntry extends Equatable {
  final String id;
  final MealType type;
  final String name;
  final String? description;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;
  final String? imageUrl;
  final DateTime loggedAt;
  final DateTime createdAt;

  const MealEntry({
    required this.id,
    required this.type,
    required this.name,
    this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.imageUrl,
    required this.loggedAt,
    required this.createdAt,
  });

  factory MealEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealEntry(
      id: doc.id,
      type: MealType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MealType.snack,
      ),
      name: data['name'] ?? '',
      description: data['description'],
      calories: data['calories'] ?? 0,
      protein: (data['protein'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      fiber: data['fiber']?.toDouble(),
      sugar: data['sugar']?.toDouble(),
      sodium: data['sodium']?.toDouble(),
      imageUrl: data['imageUrl'],
      loggedAt: (data['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'name': name,
      'description': description,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'imageUrl': imageUrl,
      'loggedAt': Timestamp.fromDate(loggedAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  MealEntry copyWith({
    String? id,
    MealType? type,
    String? name,
    String? description,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    double? sodium,
    String? imageUrl,
    DateTime? loggedAt,
    DateTime? createdAt,
  }) {
    return MealEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      imageUrl: imageUrl ?? this.imageUrl,
      loggedAt: loggedAt ?? this.loggedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, type, name, calories, protein, carbs, fat, loggedAt];
}

/// User's daily nutrition goals
class NutritionGoals extends Equatable {
  final int dailyCalories;
  final double proteinGrams;
  final double carbGrams;
  final double fatGrams;
  final int waterMl;
  final double? fiberGrams;
  final double? sugarGrams;
  final double? sodiumMg;

  const NutritionGoals({
    required this.dailyCalories,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    required this.waterMl,
    this.fiberGrams,
    this.sugarGrams,
    this.sodiumMg,
  });

  factory NutritionGoals.defaultGoals() {
    return const NutritionGoals(
      dailyCalories: 2000,
      proteinGrams: 50,
      carbGrams: 250,
      fatGrams: 65,
      waterMl: 2500,
      fiberGrams: 25,
      sugarGrams: 50,
      sodiumMg: 2300,
    );
  }

  factory NutritionGoals.fromFirestore(Map<String, dynamic> data) {
    return NutritionGoals(
      dailyCalories: data['dailyCalories'] ?? 2000,
      proteinGrams: (data['proteinGrams'] ?? 50).toDouble(),
      carbGrams: (data['carbGrams'] ?? 250).toDouble(),
      fatGrams: (data['fatGrams'] ?? 65).toDouble(),
      waterMl: data['waterMl'] ?? 2500,
      fiberGrams: data['fiberGrams']?.toDouble(),
      sugarGrams: data['sugarGrams']?.toDouble(),
      sodiumMg: data['sodiumMg']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dailyCalories': dailyCalories,
      'proteinGrams': proteinGrams,
      'carbGrams': carbGrams,
      'fatGrams': fatGrams,
      'waterMl': waterMl,
      'fiberGrams': fiberGrams,
      'sugarGrams': sugarGrams,
      'sodiumMg': sodiumMg,
    };
  }

  NutritionGoals copyWith({
    int? dailyCalories,
    double? proteinGrams,
    double? carbGrams,
    double? fatGrams,
    int? waterMl,
    double? fiberGrams,
    double? sugarGrams,
    double? sodiumMg,
  }) {
    return NutritionGoals(
      dailyCalories: dailyCalories ?? this.dailyCalories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbGrams: carbGrams ?? this.carbGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      waterMl: waterMl ?? this.waterMl,
      fiberGrams: fiberGrams ?? this.fiberGrams,
      sugarGrams: sugarGrams ?? this.sugarGrams,
      sodiumMg: sodiumMg ?? this.sodiumMg,
    );
  }

  @override
  List<Object?> get props =>
      [dailyCalories, proteinGrams, carbGrams, fatGrams, waterMl];
}

/// Water intake log entry
class WaterLog extends Equatable {
  final String id;
  final int amountMl;
  final DateTime loggedAt;

  const WaterLog({
    required this.id,
    required this.amountMl,
    required this.loggedAt,
  });

  factory WaterLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WaterLog(
      id: doc.id,
      amountMl: data['amountMl'] ?? 0,
      loggedAt: (data['loggedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amountMl': amountMl,
      'loggedAt': Timestamp.fromDate(loggedAt),
    };
  }

  @override
  List<Object?> get props => [id, amountMl, loggedAt];
}

/// Recipe from YouTube with nutrition info
class Recipe extends Equatable {
  final String id;
  final String youtubeVideoId;
  final String title;
  final String? description;
  final String thumbnailUrl;
  final Duration duration;
  final int? estimatedCalories;
  final List<String> ingredients;
  final List<String> tags;
  final String? channelName;
  final DateTime savedAt;

  const Recipe({
    required this.id,
    required this.youtubeVideoId,
    required this.title,
    this.description,
    required this.thumbnailUrl,
    required this.duration,
    this.estimatedCalories,
    required this.ingredients,
    required this.tags,
    this.channelName,
    required this.savedAt,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      youtubeVideoId: data['youtubeVideoId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      duration: Duration(seconds: data['durationSeconds'] ?? 0),
      estimatedCalories: data['estimatedCalories'],
      ingredients: List<String>.from(data['ingredients'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      channelName: data['channelName'],
      savedAt: (data['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'youtubeVideoId': youtubeVideoId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': duration.inSeconds,
      'estimatedCalories': estimatedCalories,
      'ingredients': ingredients,
      'tags': tags,
      'channelName': channelName,
      'savedAt': Timestamp.fromDate(savedAt),
    };
  }

  @override
  List<Object?> get props => [id, youtubeVideoId, title];
}

/// Daily nutrition summary calculated from meal entries
class DailyNutritionSummary {
  final DateTime date;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int totalWaterMl;
  final int mealCount;
  final Map<MealType, int> mealTypeCalories;

  const DailyNutritionSummary({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalWaterMl,
    required this.mealCount,
    required this.mealTypeCalories,
  });

  factory DailyNutritionSummary.empty(DateTime date) {
    return DailyNutritionSummary(
      date: date,
      totalCalories: 0,
      totalProtein: 0,
      totalCarbs: 0,
      totalFat: 0,
      totalWaterMl: 0,
      mealCount: 0,
      mealTypeCalories: {},
    );
  }

  factory DailyNutritionSummary.fromMeals(
      DateTime date, List<MealEntry> meals, int waterMl) {
    final mealTypeCalories = <MealType, int>{};
    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final meal in meals) {
      totalCalories += meal.calories;
      totalProtein += meal.protein;
      totalCarbs += meal.carbs;
      totalFat += meal.fat;
      mealTypeCalories[meal.type] =
          (mealTypeCalories[meal.type] ?? 0) + meal.calories;
    }

    return DailyNutritionSummary(
      date: date,
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      totalWaterMl: waterMl,
      mealCount: meals.length,
      mealTypeCalories: mealTypeCalories,
    );
  }

  double getPercentage(NutritionGoals goals) {
    if (goals.dailyCalories == 0) return 0;
    return (totalCalories / goals.dailyCalories * 100).clamp(0, 200);
  }

  double getWaterPercentage(NutritionGoals goals) {
    if (goals.waterMl == 0) return 0;
    return (totalWaterMl / goals.waterMl * 100).clamp(0, 200);
  }
}

/// YouTube video metadata for recipe/nutrition content
class VideoMetadata extends Equatable {
  final String videoId;
  final String title;
  final String? description;
  final String thumbnailUrl;
  final Duration duration;
  final String? channelName;
  final String? channelId;
  final int? viewCount;
  final DateTime? publishedAt;

  const VideoMetadata({
    required this.videoId,
    required this.title,
    this.description,
    required this.thumbnailUrl,
    required this.duration,
    this.channelName,
    this.channelId,
    this.viewCount,
    this.publishedAt, int? likes,
  });

  factory VideoMetadata.fromYtDlp(Map<String, dynamic> data) {
    return VideoMetadata(
      videoId: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      thumbnailUrl: data['thumbnail'] ?? data['thumbnails']?[0]?['url'] ?? '',
      duration: Duration(seconds: data['duration'] ?? 0),
      channelName: data['uploader'] ?? data['channel'],
      channelId: data['uploader_id'] ?? data['channel_id'],
      viewCount: data['view_count'],
      publishedAt: data['upload_date'] != null
          ? DateTime.tryParse(data['upload_date'])
          : null,
    );
  }

  @override
  List<Object?> get props => [videoId, title];
}
