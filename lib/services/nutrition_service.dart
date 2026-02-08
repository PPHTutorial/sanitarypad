import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nutrition_models.dart';

/// Provider for NutritionService
final nutritionServiceProvider = Provider<NutritionService>((ref) {
  return NutritionService();
});

/// Nutrition Service - handles all nutrition-related Firestore operations
class NutritionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Helper to get nutrition collection for a user
  CollectionReference<Map<String, dynamic>> _mealsCollection(String userId) {
    return _firestore.collection('users/$userId/nutrition_meals');
  }

  CollectionReference<Map<String, dynamic>> _waterCollection(String userId) {
    return _firestore.collection('users/$userId/nutrition_water');
  }

  CollectionReference<Map<String, dynamic>> _recipesCollection(String userId) {
    return _firestore.collection('users/$userId/nutrition_recipes');
  }

  DocumentReference<Map<String, dynamic>> _goalsDoc(String userId) {
    return _firestore.doc('users/$userId/nutrition_goals/goals');
  }

  // ============================================================================
  // MEAL LOGGING
  // ============================================================================

  /// Log a new meal entry
  Future<String> logMeal(String userId, MealEntry meal) async {
    final docRef = await _mealsCollection(userId).add(meal.toFirestore());
    return docRef.id;
  }

  /// Update an existing meal entry
  Future<void> updateMeal(String userId, MealEntry meal) async {
    await _mealsCollection(userId).doc(meal.id).update(meal.toFirestore());
  }

  /// Delete a meal entry
  Future<void> deleteMeal(String userId, String mealId) async {
    await _mealsCollection(userId).doc(mealId).delete();
  }

  /// Restore a deleted meal entry
  Future<void> restoreMeal(String userId, MealEntry meal) async {
    await _mealsCollection(userId).doc(meal.id).set(meal.toFirestore());
  }

  /// Watch meals for a specific date
  Stream<List<MealEntry>> watchMeals(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _mealsCollection(userId)
        .where('loggedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('loggedAt', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('loggedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MealEntry.fromFirestore(doc)).toList());
  }

  /// Get meals for a date range (for insights)
  Future<List<MealEntry>> getMealsInRange(
      String userId, DateTime start, DateTime end) async {
    final snapshot = await _mealsCollection(userId)
        .where('loggedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('loggedAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('loggedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => MealEntry.fromFirestore(doc)).toList();
  }

  // ============================================================================
  // WATER TRACKING
  // ============================================================================

  /// Log water intake
  Future<void> logWater(String userId, int amountMl) async {
    await _waterCollection(userId).add({
      'amountMl': amountMl,
      'loggedAt': Timestamp.now(),
    });
  }

  /// Watch daily water intake
  Stream<int> watchDailyWater(String userId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _waterCollection(userId)
        .where('loggedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('loggedAt', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        total += (doc.data()['amountMl'] as int?) ?? 0;
      }
      return total;
    });
  }

  /// Get water intake for a specific date
  Future<int> getWaterForDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _waterCollection(userId)
        .where('loggedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('loggedAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    int total = 0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['amountMl'] as int?) ?? 0;
    }
    return total;
  }

  // ============================================================================
  // NUTRITION GOALS
  // ============================================================================

  /// Get user's nutrition goals
  Future<NutritionGoals> getGoals(String userId) async {
    final doc = await _goalsDoc(userId).get();

    if (doc.exists && doc.data() != null) {
      return NutritionGoals.fromFirestore(doc.data()!);
    }
    return NutritionGoals.defaultGoals();
  }

  /// Watch user's nutrition goals
  Stream<NutritionGoals> watchGoals(String userId) {
    return _goalsDoc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return NutritionGoals.fromFirestore(doc.data()!);
      }
      return NutritionGoals.defaultGoals();
    });
  }

  /// Update nutrition goals
  Future<void> setGoals(String userId, NutritionGoals goals) async {
    await _goalsDoc(userId).set(goals.toFirestore());
  }

  // ============================================================================
  // RECIPES
  // ============================================================================

  /// Save a recipe
  Future<String> saveRecipe(String userId, Recipe recipe) async {
    final docRef = await _recipesCollection(userId).add(recipe.toFirestore());
    return docRef.id;
  }

  /// Delete a saved recipe
  Future<void> deleteRecipe(String userId, String recipeId) async {
    await _recipesCollection(userId).doc(recipeId).delete();
  }

  /// Watch saved recipes
  Stream<List<Recipe>> watchSavedRecipes(String userId) {
    return _recipesCollection(userId)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList());
  }

  /// Check if a recipe is saved
  Future<bool> isRecipeSaved(String userId, String youtubeVideoId) async {
    final snapshot = await _recipesCollection(userId)
        .where('youtubeVideoId', isEqualTo: youtubeVideoId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // ============================================================================
  // DAILY SUMMARY
  // ============================================================================

  /// Get daily nutrition summary
  Future<DailyNutritionSummary> getDailySummary(
      String userId, DateTime date) async {
    final meals = await getMealsInRange(
      userId,
      DateTime(date.year, date.month, date.day),
      DateTime(date.year, date.month, date.day).add(const Duration(days: 1)),
    );
    final water = await getWaterForDate(userId, date);
    return DailyNutritionSummary.fromMeals(date, meals, water);
  }

  /// Watch daily nutrition summary (live updates)
  Stream<DailyNutritionSummary> watchDailySummary(
      String userId, DateTime date) {
    return watchMeals(userId, date).asyncMap((meals) async {
      final water = await getWaterForDate(userId, date);
      return DailyNutritionSummary.fromMeals(date, meals, water);
    });
  }

  // ============================================================================
  // WEEKLY/MONTHLY INSIGHTS
  // ============================================================================

  /// Get weekly averages
  Future<Map<String, double>> getWeeklyAverages(
      String userId, DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final meals = await getMealsInRange(userId, weekStart, weekEnd);

    if (meals.isEmpty) {
      return {'avgCalories': 0, 'avgProtein': 0, 'avgCarbs': 0, 'avgFat': 0};
    }

    final dailyTotals = <DateTime, Map<String, double>>{};

    for (final meal in meals) {
      final dateKey =
          DateTime(meal.loggedAt.year, meal.loggedAt.month, meal.loggedAt.day);
      dailyTotals.putIfAbsent(dateKey,
          () => {'calories': 0.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0});
      dailyTotals[dateKey]!['calories'] =
          dailyTotals[dateKey]!['calories']! + meal.calories;
      dailyTotals[dateKey]!['protein'] =
          dailyTotals[dateKey]!['protein']! + meal.protein;
      dailyTotals[dateKey]!['carbs'] =
          dailyTotals[dateKey]!['carbs']! + meal.carbs;
      dailyTotals[dateKey]!['fat'] = dailyTotals[dateKey]!['fat']! + meal.fat;
    }

    final daysWithData = dailyTotals.length;
    double totalCalories = 0, totalProtein = 0, totalCarbs = 0, totalFat = 0;

    for (final daily in dailyTotals.values) {
      totalCalories += daily['calories']!;
      totalProtein += daily['protein']!;
      totalCarbs += daily['carbs']!;
      totalFat += daily['fat']!;
    }

    return {
      'avgCalories': totalCalories / daysWithData,
      'avgProtein': totalProtein / daysWithData,
      'avgCarbs': totalCarbs / daysWithData,
      'avgFat': totalFat / daysWithData,
      'daysTracked': daysWithData.toDouble(),
    };
  }

  /// Get calorie trend for the past N days
  Future<List<Map<String, dynamic>>> getCalorieTrend(
      String userId, int days) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final end =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

    final meals = await getMealsInRange(userId, start, end);

    final dailyCalories = <DateTime, int>{};
    for (int i = 0; i < days; i++) {
      final day = start.add(Duration(days: i));
      dailyCalories[DateTime(day.year, day.month, day.day)] = 0;
    }

    for (final meal in meals) {
      final dateKey =
          DateTime(meal.loggedAt.year, meal.loggedAt.month, meal.loggedAt.day);
      dailyCalories[dateKey] = (dailyCalories[dateKey] ?? 0) + meal.calories;
    }

    return dailyCalories.entries
        .map((e) => {'date': e.key, 'calories': e.value})
        .toList()
      ..sort(
          (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }
}

// ============================================================================
// RIVERPOD PROVIDERS
// ============================================================================

/// Provider for today's meals
final todayMealsProvider =
    StreamProvider.family<List<MealEntry>, String>((ref, userId) {
  return ref.watch(nutritionServiceProvider).watchMeals(userId, DateTime.now());
});

/// Provider for today's water intake
final todayWaterProvider = StreamProvider.family<int, String>((ref, userId) {
  return ref
      .watch(nutritionServiceProvider)
      .watchDailyWater(userId, DateTime.now());
});

/// Provider for nutrition goals
final nutritionGoalsProvider =
    StreamProvider.family<NutritionGoals, String>((ref, userId) {
  return ref.watch(nutritionServiceProvider).watchGoals(userId);
});

/// Provider for saved recipes
final savedRecipesProvider =
    StreamProvider.family<List<Recipe>, String>((ref, userId) {
  return ref.watch(nutritionServiceProvider).watchSavedRecipes(userId);
});

/// Provider for today's nutrition summary
final todayNutritionSummaryProvider =
    StreamProvider.family<DailyNutritionSummary, String>((ref, userId) {
  return ref
      .watch(nutritionServiceProvider)
      .watchDailySummary(userId, DateTime.now());
});
