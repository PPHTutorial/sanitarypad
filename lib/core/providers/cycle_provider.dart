import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cycle_model.dart';
import '../../core/constants/app_constants.dart';
import '../../services/storage_service.dart';
import '../../services/cycle_service.dart';
import 'auth_provider.dart';

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Cycle service provider
final cycleServiceProvider = Provider<CycleService>((ref) {
  return CycleService();
});

/// Cycles stream provider for current user
final cyclesStreamProvider = StreamProvider<List<CycleModel>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield [];
    return;
  }

  final storageService = ref.watch(storageServiceProvider);

  yield* storageService
      .getCollectionStream(
    collection: AppConstants.collectionCycles,
    orderBy: 'startDate',
    descending: true,
  )
      .map((snapshot) {
    return snapshot.docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data != null && data['userId'] == user.userId;
        })
        .map((doc) => CycleModel.fromFirestore(doc))
        .toList();
  });
});

/// Current active cycle provider
final activeCycleProvider = Provider<CycleModel?>((ref) {
  final cyclesAsync = ref.watch(cyclesStreamProvider);
  final cycles = cyclesAsync.value ?? [];

  if (cycles.isEmpty) return null;

  // Find the most recent cycle that hasn't ended or ended recently
  final now = DateTime.now();
  for (final cycle in cycles) {
    if (cycle.endDate == null ||
        cycle.endDate!.isAfter(now.subtract(const Duration(days: 7)))) {
      return cycle;
    }
  }

  return cycles.first;
});

/// Cycle predictions provider
final cyclePredictionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final cyclesAsync = ref.watch(cyclesStreamProvider);
  final cycles = cyclesAsync.value ?? [];

  if (user == null || cycles.isEmpty) {
    return [];
  }

  // Simple prediction algorithm
  if (cycles.length < 2) {
    return [];
  }

  // Calculate average cycle length
  int totalLength = 0;
  for (final cycle in cycles.take(6)) {
    totalLength += cycle.cycleLength;
  }
  final avgCycleLength = (totalLength / cycles.length).round();

  // Calculate average period length
  int totalPeriodLength = 0;
  for (final cycle in cycles.take(6)) {
    totalPeriodLength += cycle.periodLength;
  }
  final avgPeriodLength = (totalPeriodLength / cycles.length).round();

  // Get last cycle
  final lastCycle = cycles.first;
  final nextPeriodStart =
      lastCycle.startDate.add(Duration(days: avgCycleLength));
  final nextPeriodEnd = nextPeriodStart.add(Duration(days: avgPeriodLength));
  final ovulationDate = nextPeriodStart.subtract(const Duration(days: 14));
  final fertileStart = ovulationDate.subtract(const Duration(days: 5));
  final fertileEnd = ovulationDate.add(const Duration(days: 1));

  return [
    {
      'predictedStartDate': nextPeriodStart,
      'predictedEndDate': nextPeriodEnd,
      'ovulationDate': ovulationDate,
      'fertileWindow': <String, DateTime>{
        'start': fertileStart,
        'end': fertileEnd,
      },
      'confidence': cycles.length >= 3 ? 0.8 : 0.6,
    },
  ];
});
