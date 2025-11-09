import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/pregnancy_model.dart';

/// Pregnancy service
class PregnancyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create pregnancy entry
  Future<String> createPregnancy(Pregnancy pregnancy) async {
    try {
      final docRef = await _firestore
          .collection('pregnancies')
          .add(pregnancy.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update pregnancy entry
  Future<void> updatePregnancy(Pregnancy pregnancy) async {
    if (pregnancy.id == null) {
      throw Exception('Pregnancy ID is required for update');
    }

    try {
      await _firestore
          .collection('pregnancies')
          .doc(pregnancy.id)
          .update(pregnancy.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete pregnancy entry
  Future<void> deletePregnancy(String pregnancyId) async {
    try {
      await _firestore.collection('pregnancies').doc(pregnancyId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's active pregnancy
  Future<Pregnancy?> getActivePregnancy(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('pregnancies')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final pregnancy = Pregnancy.fromFirestore(doc);

      // Check if pregnancy is still active (less than 42 weeks)
      if (pregnancy.currentWeek >= 42) return null;

      return pregnancy;
    } catch (e) {
      return null;
    }
  }

  /// Get user's pregnancy history
  Stream<List<Pregnancy>> getPregnancyHistory(String userId) {
    return _firestore
        .collection('pregnancies')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Pregnancy.fromFirestore(doc)).toList();
    });
  }

  /// Get pregnancy by ID
  Future<Pregnancy?> getPregnancyById(String pregnancyId) async {
    try {
      final doc =
          await _firestore.collection('pregnancies').doc(pregnancyId).get();

      if (!doc.exists) return null;

      return Pregnancy.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Get upcoming milestones
  List<PregnancyMilestone> getUpcomingMilestones(Pregnancy pregnancy) {
    final allMilestones = PregnancyMilestone.getMilestones();
    return allMilestones
        .where((milestone) => milestone.week > pregnancy.currentWeek)
        .toList();
  }

  /// Get completed milestones
  List<PregnancyMilestone> getCompletedMilestones(Pregnancy pregnancy) {
    final allMilestones = PregnancyMilestone.getMilestones();
    return allMilestones
        .where((milestone) => milestone.week <= pregnancy.currentWeek)
        .toList();
  }

  /// Get current milestone
  PregnancyMilestone? getCurrentMilestone(Pregnancy pregnancy) {
    final allMilestones = PregnancyMilestone.getMilestones();
    return allMilestones.firstWhere(
      (milestone) =>
          milestone.week <= pregnancy.currentWeek &&
          (milestone.week + 4) > pregnancy.currentWeek,
      orElse: () => allMilestones.last,
    );
  }
}
