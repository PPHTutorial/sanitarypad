import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../data/models/baby_model.dart';

class BabyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _babiesCollection =>
      _firestore.collection(AppConstants.collectionBabies);
  CollectionReference get _growthCollection =>
      _firestore.collection(AppConstants.collectionBabyGrowth);
  CollectionReference get _milestonesCollection =>
      _firestore.collection(AppConstants.collectionBabyMilestones);
  CollectionReference get _galleryCollection =>
      _firestore.collection(AppConstants.collectionBabyGallery);

  // --- Baby Profile Operations ---

  /// Create a new baby profile
  Future<String> createBaby(Baby baby) async {
    final docRef = await _babiesCollection.add(baby.toFirestore());
    return docRef.id;
  }

  /// Update an existing baby profile
  Future<void> updateBaby(Baby baby) async {
    if (baby.id == null) throw Exception('Baby ID is required for update');
    await _babiesCollection.doc(baby.id).update(baby.toFirestore());
  }

  /// Delete a baby profile and related data
  Future<void> deleteBaby(String babyId) async {
    // Note: In production, you might want to use a Cloud Function or Batch
    // to delete all sub-data (growth, milestones, gallery) as well.
    await _babiesCollection.doc(babyId).delete();
  }

  /// Watch babies for a specific user
  Stream<List<Baby>> watchBabies(String userId) {
    return _babiesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('birthDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Baby.fromFirestore(doc)).toList());
  }

  /// Get a single baby by ID
  Future<Baby?> getBaby(String babyId) async {
    final doc = await _babiesCollection.doc(babyId).get();
    if (!doc.exists) return null;
    return Baby.fromFirestore(doc);
  }

  // --- Growth Tracking Operations ---

  /// Log a new growth entry
  Future<void> logGrowth(GrowthEntry entry) async {
    await _growthCollection.add(entry.toFirestore());
  }

  /// Watch growth entries for a specific baby
  Stream<List<GrowthEntry>> watchGrowthEntries(String babyId) {
    return _growthCollection
        .where('babyId', isEqualTo: babyId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GrowthEntry.fromFirestore(doc))
            .toList());
  }

  // --- Milestone Operations ---

  /// Log a developmental milestone
  Future<void> logMilestone(BabyDevelopmentMilestone milestone) async {
    await _milestonesCollection.add(milestone.toFirestore());
  }

  /// Watch milestones for a specific baby
  Stream<List<BabyDevelopmentMilestone>> watchMilestones(String babyId) {
    return _milestonesCollection
        .where('babyId', isEqualTo: babyId)
        .orderBy('achievedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BabyDevelopmentMilestone.fromFirestore(doc))
            .toList());
  }

  // --- Gallery Operations ---

  /// Add an item to the baby's gallery
  Future<void> addGalleryItem(BabyGalleryItem item) async {
    await _galleryCollection.add(item.toFirestore());
  }

  /// Watch gallery items for a specific baby
  Stream<List<BabyGalleryItem>> watchGalleryItems(String babyId,
      {String? type}) {
    Query query = _galleryCollection
        .where('babyId', isEqualTo: babyId)
        .orderBy('date', descending: true);

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => BabyGalleryItem.fromFirestore(doc))
        .toList());
  }
}

final babyServiceProvider = Provider<BabyService>((ref) {
  return BabyService();
});
