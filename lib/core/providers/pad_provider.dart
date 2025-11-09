import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pad_model.dart';
import '../../core/constants/app_constants.dart';
import '../../services/pad_service.dart';
import 'auth_provider.dart';
import 'cycle_provider.dart';

/// Pad service provider
final padServiceProvider = Provider<PadService>((ref) {
  return PadService();
});

/// Pad changes stream provider
final padChangesStreamProvider = StreamProvider<List<PadModel>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield [];
    return;
  }

  final storageService = ref.watch(storageServiceProvider);

  yield* storageService
      .getCollectionStream(
    collection: AppConstants.collectionPads,
    orderBy: 'changeTime',
    descending: true,
  )
      .map((snapshot) {
    return snapshot.docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data != null && data['userId'] == user.userId;
        })
        .map((doc) => PadModel.fromFirestore(doc))
        .toList();
  });
});

/// Pad inventory stream provider
final padInventoryStreamProvider =
    StreamProvider<List<PadInventoryModel>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield [];
    return;
  }

  final storageService = ref.watch(storageServiceProvider);

  yield* storageService
      .getCollectionStream(
    collection: AppConstants.collectionPadInventory,
  )
      .map((snapshot) {
    return snapshot.docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data != null && data['userId'] == user.userId;
        })
        .map((doc) => PadInventoryModel.fromFirestore(doc))
        .toList();
  });
});

/// Low stock items provider
final lowStockItemsProvider = Provider<List<PadInventoryModel>>((ref) {
  final inventoryAsync = ref.watch(padInventoryStreamProvider);
  final inventory = inventoryAsync.value ?? [];
  return inventory.where((item) => item.isLowStock).toList();
});

/// Last pad change provider
final lastPadChangeProvider = Provider<PadModel?>((ref) {
  final padsAsync = ref.watch(padChangesStreamProvider);
  final pads = padsAsync.value ?? [];
  return pads.isNotEmpty ? pads.first : null;
});
