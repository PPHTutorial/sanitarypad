import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../data/models/pregnancy_model.dart';

/// Pregnancy service
class PregnancyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create pregnancy entry
  Future<String> createPregnancy(Pregnancy pregnancy) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.collectionPregnancies)
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
          .collection(AppConstants.collectionPregnancies)
          .doc(pregnancy.id)
          .update(pregnancy.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete pregnancy entry
  Future<void> deletePregnancy(String pregnancyId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionPregnancies)
          .doc(pregnancyId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's active pregnancy
  Future<Pregnancy?> getActivePregnancy(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionPregnancies)
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
        .collection(AppConstants.collectionPregnancies)
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
      final doc = await _firestore
          .collection(AppConstants.collectionPregnancies)
          .doc(pregnancyId)
          .get();

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

  // ----- Enhanced feature helpers -----

  Stream<List<KickEntry>> getKickEntries(String userId, String pregnancyId) {
    return _firestore
        .collection(AppConstants.collectionKickEntries)
        .where('userId', isEqualTo: userId)
        .where('pregnancyId', isEqualTo: pregnancyId)
        .orderBy('loggedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => KickEntry.fromFirestore(doc)).toList());
  }

  Future<void> logKickEntry(KickEntry entry) async {
    await _firestore
        .collection(AppConstants.collectionKickEntries)
        .add(entry.toFirestore());
  }

  Stream<List<ContractionEntry>> getContractionEntries(
    String userId,
    String pregnancyId,
  ) {
    return _firestore
        .collection(AppConstants.collectionContractionEntries)
        .where('userId', isEqualTo: userId)
        .where('pregnancyId', isEqualTo: pregnancyId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContractionEntry.fromFirestore(doc))
            .toList());
  }

  Future<void> logContraction(ContractionEntry entry) async {
    await _firestore
        .collection(AppConstants.collectionContractionEntries)
        .add(entry.toFirestore());
  }

  Stream<List<PregnancyAppointment>> getAppointments(
    String userId,
    String pregnancyId,
  ) {
    return _firestore
        .collection(AppConstants.collectionPregnancyAppointments)
        .where('userId', isEqualTo: userId)
        .where('pregnancyId', isEqualTo: pregnancyId)
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PregnancyAppointment.fromFirestore(doc))
            .toList());
  }

  Future<void> saveAppointment(PregnancyAppointment appointment) async {
    if (appointment.id == null) {
      await _firestore
          .collection(AppConstants.collectionPregnancyAppointments)
          .add(appointment.toFirestore());
    } else {
      await _firestore
          .collection(AppConstants.collectionPregnancyAppointments)
          .doc(appointment.id)
          .update(appointment.toFirestore());
    }
  }

  Future<void> deleteAppointment(String id) async {
    await _firestore
        .collection(AppConstants.collectionPregnancyAppointments)
        .doc(id)
        .delete();
  }

  Stream<List<PregnancyMedication>> getMedications(
    String userId,
    String pregnancyId,
  ) {
    return _firestore
        .collection(AppConstants.collectionPregnancyMedications)
        .where('userId', isEqualTo: userId)
        .where('pregnancyId', isEqualTo: pregnancyId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PregnancyMedication.fromFirestore(doc))
            .toList());
  }

  Future<void> saveMedication(PregnancyMedication medication) async {
    if (medication.id == null) {
      await _firestore
          .collection(AppConstants.collectionPregnancyMedications)
          .add(medication.toFirestore());
    } else {
      await _firestore
          .collection(AppConstants.collectionPregnancyMedications)
          .doc(medication.id)
          .update(medication.toFirestore());
    }
  }

  Stream<List<PregnancyJournalEntry>> getJournalEntries(
    String userId,
    String pregnancyId,
  ) {
    return _firestore
        .collection(AppConstants.collectionPregnancyJournalEntries)
        .where('userId', isEqualTo: userId)
        .where('pregnancyId', isEqualTo: pregnancyId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PregnancyJournalEntry.fromFirestore(doc))
            .toList());
  }

  Future<void> saveJournalEntry(PregnancyJournalEntry entry) async {
    if (entry.id == null) {
      await _firestore
          .collection(AppConstants.collectionPregnancyJournalEntries)
          .add(entry.toFirestore());
    } else {
      await _firestore
          .collection(AppConstants.collectionPregnancyJournalEntries)
          .doc(entry.id)
          .update(entry.toFirestore());
    }
  }

  Stream<List<PregnancyWeightEntry>> getWeightEntries(
    String userId,
    String pregnancyId,
  ) {
    return _firestore
        .collection(AppConstants.collectionPregnancyWeightEntries)
        .where('userId', isEqualTo: userId)
        .where('pregnancyId', isEqualTo: pregnancyId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PregnancyWeightEntry.fromFirestore(doc))
            .toList());
  }

  Future<void> logWeightEntry(PregnancyWeightEntry entry) async {
    await _firestore
        .collection(AppConstants.collectionPregnancyWeightEntries)
        .add(entry.toFirestore());
  }

  Stream<List<HospitalChecklistItem>> getHospitalChecklist(
    String userId,
    String pregnancyId,
  ) {
    return _firestore
        .collection(AppConstants.collectionHospitalChecklistItems)
        .where('userId', isEqualTo: userId)
        .where('pregnancyId', isEqualTo: pregnancyId)
        .orderBy('category')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HospitalChecklistItem.fromFirestore(doc))
            .toList());
  }

  Future<void> saveHospitalChecklistItem(HospitalChecklistItem item) async {
    if (item.id == null) {
      await _firestore
          .collection(AppConstants.collectionHospitalChecklistItems)
          .add(item.toFirestore());
    } else {
      await _firestore
          .collection(AppConstants.collectionHospitalChecklistItems)
          .doc(item.id)
          .update(item.toFirestore());
    }
  }

  Future<void> deleteHospitalChecklistItem(String id) async {
    await _firestore
        .collection(AppConstants.collectionHospitalChecklistItems)
        .doc(id)
        .delete();
  }
}
