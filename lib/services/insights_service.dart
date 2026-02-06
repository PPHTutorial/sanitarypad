import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cycle_model.dart';
import '../data/models/wellness_model.dart';
import '../data/models/skincare_model.dart';
import '../data/models/pad_model.dart';
import 'cycle_service.dart';
import 'wellness_service.dart';
import 'fertility_service.dart';
import 'skincare_service.dart';
import 'pad_service.dart';
import 'auth_service.dart';
import 'pregnancy_service.dart';

final insightsServiceProvider = Provider<InsightsService>((ref) {
  return InsightsService();
});

/// Comprehensive insights service
class InsightsService {
  final CycleService _cycleService = CycleService();
  final WellnessService _wellnessService = WellnessService();
  final FertilityService _fertilityService = FertilityService();
  final SkincareService _skincareService = SkincareService();
  final PadService _padService = PadService();
  final AuthService _authService = AuthService();
  final PregnancyService _pregnancyService = PregnancyService();

  /// Get comprehensive insights
  Future<Map<String, dynamic>> getComprehensiveInsights() async {
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));
    final last90Days = now.subtract(const Duration(days: 90));

    // Get userId from auth
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final userId = user.uid;

    // Fetch all data
    final cycles = await _cycleService.getCycles();
    final wellnessEntries = await _wellnessService.getWellnessEntries();
    final pads = await _padService.getPadChanges();

    // Get skincare data (Streams)
    final skincareEntriesStream = _skincareService.getEntries(
      userId,
      last30Days,
      now,
    );
    final skincareEntries = await skincareEntriesStream.first;

    final skincareProductsStream = _skincareService.getUserProducts(userId);
    final skincareProducts = await skincareProductsStream.first;

    return {
      'cycles': _calculateCycleInsights(cycles),
      'wellness': _calculateWellnessInsights(wellnessEntries),
      'fertility': await _calculateFertilityInsights(cycles, last90Days),
      'skincare': _calculateSkincareInsights(skincareEntries, skincareProducts),
      'pads': _calculatePadInsights(pads),
      'pregnancy': await _calculatePregnancyInsights(userId),
      'overallHealth': await _calculateOverallHealthScore(
        cycles,
        wellnessEntries,
        last30Days,
      ),
    };
  }

  /// Calculate cycle insights
  Map<String, dynamic> _calculateCycleInsights(List<CycleModel> cycles) {
    if (cycles.isEmpty) {
      return {
        'hasData': false,
        'averageCycleLength': 0,
        'averagePeriodLength': 0,
        'regularity': 'insufficient_data',
        'totalCycles': 0,
        'mostCommonSymptoms': [],
      };
    }

    final cycleLengths = cycles.map((c) => c.cycleLength).toList();
    final periodLengths = cycles.map((c) => c.periodLength).toList();

    final avgCycleLength =
        (cycleLengths.reduce((a, b) => a + b) / cycles.length).round();
    final avgPeriodLength =
        (periodLengths.reduce((a, b) => a + b) / cycles.length).round();

    // Calculate regularity
    String regularity = 'regular';
    if (cycles.length >= 3) {
      final minLength = cycleLengths.reduce((a, b) => a < b ? a : b);
      final maxLength = cycleLengths.reduce((a, b) => a > b ? a : b);
      final variation = maxLength - minLength;

      if (variation <= 7) {
        regularity = 'very_regular';
      } else if (variation <= 14) {
        regularity = 'regular';
      } else {
        regularity = 'irregular';
      }
    } else {
      regularity = 'insufficient_data';
    }

    // Most common symptoms
    final symptomCounts = <String, int>{};
    for (final cycle in cycles) {
      for (final symptom in cycle.symptoms) {
        symptomCounts[symptom] = (symptomCounts[symptom] ?? 0) + 1;
      }
    }
    final mostCommonSymptoms = symptomCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'hasData': true,
      'averageCycleLength': avgCycleLength,
      'averagePeriodLength': avgPeriodLength,
      'regularity': regularity,
      'totalCycles': cycles.length,
      'mostCommonSymptoms': mostCommonSymptoms
          .take(5)
          .map((e) => {
                'symptom': e.key,
                'count': e.value,
                'frequency': (e.value / cycles.length * 100).round(),
              })
          .toList(),
    };
  }

  /// Calculate wellness insights
  Map<String, dynamic> _calculateWellnessInsights(List<WellnessModel> entries) {
    if (entries.isEmpty) {
      return {
        'hasData': false,
        'averageHydration': 0.0,
        'averageSleep': 0.0,
        'averageEnergy': 0.0,
        'averageMood': 0.0,
        'exerciseFrequency': 0.0,
        'mostCommonMoods': [],
        'wellnessScore': 0.0,
      };
    }

    final avgHydration =
        entries.map((e) => e.hydration.waterGlasses).reduce((a, b) => a + b) /
            entries.length;

    final avgSleep = entries.map((e) => e.sleep.hours).reduce((a, b) => a + b) /
        entries.length;

    final avgEnergy =
        entries.map((e) => e.mood.energyLevel).reduce((a, b) => a + b) /
            entries.length;

    final avgMood =
        entries.map((e) => e.mood.energyLevel).reduce((a, b) => a + b) /
            entries.length;

    final exerciseCount = entries.where((e) => e.exercise != null).length;
    final exerciseFrequency = (exerciseCount / entries.length * 100);

    // Most common moods/emotions
    final moodCounts = <String, int>{};
    for (final entry in entries) {
      for (final emotion in entry.mood.emotions) {
        moodCounts[emotion] = (moodCounts[emotion] ?? 0) + 1;
      }
    }
    final mostCommonMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate wellness score
    double totalScore = 0.0;
    for (final entry in entries) {
      double entryScore = 0.0;
      entryScore += (entry.hydration.progress * 25).clamp(0, 25);
      entryScore += (entry.sleep.hours / 8 * 25).clamp(0, 25);
      entryScore += (entry.mood.energyLevel / 5 * 25).clamp(0, 25);
      if (entry.exercise != null) {
        entryScore += 25;
      }
      totalScore += entryScore;
    }
    final wellnessScore = (totalScore / entries.length).clamp(0, 100);

    return {
      'hasData': true,
      'averageHydration': avgHydration.roundToDouble(),
      'averageSleep': avgSleep,
      'averageEnergy': avgEnergy,
      'averageMood': avgMood,
      'exerciseFrequency': exerciseFrequency.roundToDouble(),
      'mostCommonMoods': mostCommonMoods
          .take(5)
          .map((e) => {
                'emotion': e.key,
                'count': e.value,
                'frequency': (e.value / entries.length * 100).round(),
              })
          .toList(),
      'wellnessScore': wellnessScore.roundToDouble(),
      'totalEntries': entries.length,
    };
  }

  /// Calculate fertility insights
  Future<Map<String, dynamic>> _calculateFertilityInsights(
    List<CycleModel> cycles,
    DateTime startDate,
  ) async {
    if (cycles.isEmpty) {
      return {
        'hasData': false,
        'averageBBT': 0.0,
        'ovulationPrediction': null,
        'fertileWindow': null,
      };
    }

    final userId = cycles.first.userId;
    final endDate = DateTime.now();

    // Get fertility entries
    final fertilityEntriesStream = _fertilityService.getFertilityEntries(
      userId,
      startDate,
      endDate,
    );
    final fertilityEntries = await fertilityEntriesStream.first;

    if (fertilityEntries.isEmpty) {
      return {
        'hasData': false,
        'averageBBT': 0.0,
        'ovulationPrediction': null,
        'fertileWindow': null,
      };
    }

    // Calculate average BBT
    final bbtEntries =
        fertilityEntries.where((e) => e.basalBodyTemperature != null).toList();
    double avgBBT = 0.0;
    if (bbtEntries.isNotEmpty) {
      avgBBT = bbtEntries
              .map((e) => e.basalBodyTemperature!)
              .reduce((a, b) => a + b) /
          bbtEntries.length;
    }

    // Get ovulation prediction
    final prediction = await _fertilityService.predictOvulation(
      userId,
      cycles,
      fertilityEntries,
    );

    return {
      'hasData': true,
      'averageBBT': avgBBT,
      'totalEntries': fertilityEntries.length,
      'ovulationPrediction': prediction.predictedOvulation,
      'fertileWindow': {
        'start': prediction.fertileWindowStart,
        'end': prediction.fertileWindowEnd,
      },
      'confidence': prediction.confidence,
      'methods': prediction.methods,
    };
  }

  /// Calculate skincare insights
  Map<String, dynamic> _calculateSkincareInsights(
    List<SkincareEntry> entries,
    List<SkincareProduct> products,
  ) {
    if (entries.isEmpty && products.isEmpty) {
      return {
        'hasData': false,
        'totalRoutines': 0,
        'totalProducts': 0,
        'averageRoutinesPerWeek': 0.0,
        'mostUsedProducts': [],
        'expiringProducts': 0,
      };
    }

    // Calculate routines per week
    final now = DateTime.now();
    final last7Days = now.subtract(const Duration(days: 7));
    final recentEntries =
        entries.where((e) => e.date.isAfter(last7Days)).length;
    final routinesPerWeek = recentEntries.toDouble();

    // Most used products
    final productUsage = <String, int>{};
    for (final entry in entries) {
      for (final productId in entry.productsUsed) {
        productUsage[productId] = (productUsage[productId] ?? 0) + 1;
      }
    }

    final mostUsedProducts = productUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Expiring products
    final expiringProducts =
        products.where((p) => p.isExpiringSoon || p.isExpired).length;

    return {
      'hasData': true,
      'totalRoutines': entries.length,
      'totalProducts': products.length,
      'averageRoutinesPerWeek': routinesPerWeek,
      'mostUsedProducts': mostUsedProducts.take(5).map((e) {
        final product = products.firstWhere(
          (p) => p.id == e.key,
          orElse: () => SkincareProduct(
            userId: '',
            name: 'Unknown',
            category: 'unknown',
            createdAt: DateTime.now(),
          ),
        );
        return {
          'name': product.name,
          'count': e.value,
          'frequency':
              entries.isNotEmpty ? (e.value / entries.length * 100).round() : 0,
        };
      }).toList(),
      'expiringProducts': expiringProducts,
    };
  }

  /// Calculate pad usage insights
  Map<String, dynamic> _calculatePadInsights(List<PadModel> pads) {
    if (pads.isEmpty) {
      return {
        'hasData': false,
        'totalChanges': 0,
        'averageChangesPerDay': 0.0,
        'mostUsedType': null,
        'inventoryStatus': null,
      };
    }

    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));
    final recentPads =
        pads.where((p) => p.changeTime.isAfter(last30Days)).toList();

    final avgChangesPerDay =
        recentPads.isNotEmpty ? (recentPads.length / 30).roundToDouble() : 0.0;

    // Most used pad type
    final typeCounts = <String, int>{};
    for (final pad in recentPads) {
      typeCounts[pad.padType] = (typeCounts[pad.padType] ?? 0) + 1;
    }
    final mostUsedType = typeCounts.entries.isNotEmpty
        ? typeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : null;

    return {
      'hasData': true,
      'totalChanges': pads.length,
      'recentChanges': recentPads.length,
      'averageChangesPerDay': avgChangesPerDay,
      'mostUsedType': mostUsedType,
    };
  }

  /// Calculate overall health score
  Future<double> _calculateOverallHealthScore(
    List<CycleModel> cycles,
    List<WellnessModel> wellnessEntries,
    DateTime startDate,
  ) async {
    double totalScore = 0.0;
    int factors = 0;

    // Cycle regularity (0-25 points)
    if (cycles.length >= 3) {
      final cycleLengths = cycles.map((c) => c.cycleLength).toList();
      final minLength = cycleLengths.reduce((a, b) => a < b ? a : b);
      final maxLength = cycleLengths.reduce((a, b) => a > b ? a : b);
      final variation = maxLength - minLength;
      double cycleScore = 25.0;
      if (variation > 14) {
        cycleScore = 15.0; // Irregular
      } else if (variation > 7) {
        cycleScore = 20.0; // Regular
      }
      totalScore += cycleScore;
      factors++;
    }

    // Wellness score (0-50 points)
    if (wellnessEntries.isNotEmpty) {
      final wellnessScore = await _wellnessService.calculateWellnessScore(
        startDate: startDate,
        endDate: DateTime.now(),
      );
      totalScore += (wellnessScore / 2); // Convert 0-100 to 0-50
      factors++;
    }

    // Hydration (0-15 points)
    if (wellnessEntries.isNotEmpty) {
      final avgHydration = wellnessEntries
              .map((e) => e.hydration.waterGlasses)
              .reduce((a, b) => a + b) /
          wellnessEntries.length;
      final hydrationScore = (avgHydration / 8 * 15).clamp(0, 15);
      totalScore += hydrationScore;
      factors++;
    }

    // Sleep (0-10 points)
    if (wellnessEntries.isNotEmpty) {
      final avgSleep =
          wellnessEntries.map((e) => e.sleep.hours).reduce((a, b) => a + b) /
              wellnessEntries.length;
      final sleepScore = (avgSleep / 8 * 10).clamp(0, 10);
      totalScore += sleepScore;
      factors++;
    }

    if (factors == 0) return 0.0;

    return (totalScore / factors * 4).clamp(0, 100); // Scale to 0-100
  }

  /// Calculate pregnancy insights
  Future<Map<String, dynamic>> _calculatePregnancyInsights(
      String userId) async {
    final pregnancy = await _pregnancyService.getActivePregnancy(userId);
    if (pregnancy == null) {
      return {'hasData': false};
    }

    final pregnancyId = pregnancy.id!;

    // Get kicks data
    final kicksStream = _pregnancyService.getKickEntries(userId, pregnancyId);
    final kicks = await kicksStream.first;

    // Get weight data
    final weightsStream =
        _pregnancyService.getWeightEntries(userId, pregnancyId);
    final weights = await weightsStream.first;

    // Calculate avg kicks per session
    double avgKicks = 0;
    if (kicks.isNotEmpty) {
      avgKicks =
          kicks.map((k) => k.kickCount).reduce((a, b) => a + b) / kicks.length;
    }

    // Weight gain
    double weightGain = 0;
    if (weights.length >= 2) {
      weightGain = weights.first.weight - weights.last.weight;
    }

    return {
      'hasData': true,
      'currentWeek': pregnancy.currentWeek,
      'dueDate': pregnancy.dueDate,
      'averageKicks': avgKicks,
      'totalWeightGain': weightGain,
      'totalKicksLogged': kicks.length,
      'totalWeightsLogged': weights.length,
      'lastWeight': weights.isNotEmpty ? weights.first.weight : null,
    };
  }
}
