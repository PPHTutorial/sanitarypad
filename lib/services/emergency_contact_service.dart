import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_constants.dart';
import '../data/models/emergency_contact_model.dart';

/// Emergency contact service
class EmergencyContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create emergency contact
  Future<String> createContact(EmergencyContact contact) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.collectionSupportContacts)
          .add(contact.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update emergency contact
  Future<void> updateContact(EmergencyContact contact) async {
    if (contact.id == null) {
      throw Exception('Contact ID is required for update');
    }

    try {
      await _firestore
          .collection(AppConstants.collectionSupportContacts)
          .doc(contact.id)
          .update(contact.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Delete emergency contact
  Future<void> deleteContact(String contactId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionSupportContacts)
          .doc(contactId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's emergency contacts
  Stream<List<EmergencyContact>> getUserContacts(String userId) {
    return _firestore
        .collection(AppConstants.collectionSupportContacts)
        .where('userId', isEqualTo: userId)
        .orderBy('isPrimary', descending: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EmergencyContact.fromFirestore(doc))
          .toList();
    });
  }

  /// Get primary emergency contact
  Future<EmergencyContact?> getPrimaryContact(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionSupportContacts)
          .where('userId', isEqualTo: userId)
          .where('isPrimary', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return EmergencyContact.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  /// Set primary contact (unset others)
  Future<void> setPrimaryContact(String userId, String contactId) async {
    try {
      // Unset all primary contacts
      final snapshot = await _firestore
          .collection(AppConstants.collectionSupportContacts)
          .where('userId', isEqualTo: userId)
          .where('isPrimary', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isPrimary': false});
      }
      await batch.commit();

      // Set new primary
      await _firestore
          .collection(AppConstants.collectionSupportContacts)
          .doc(contactId)
          .update({'isPrimary': true});
    } catch (e) {
      rethrow;
    }
  }

  /// Call emergency contact
  Future<void> callContact(EmergencyContact contact) async {
    final uri = Uri.parse('tel:${contact.phoneNumber}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch phone call');
    }
  }

  /// Send SMS to emergency contact
  Future<void> sendSMSToContact(
      EmergencyContact contact, String message) async {
    final uri = Uri.parse(
        'sms:${contact.phoneNumber}?body=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch SMS');
    }
  }

  /// Send email to emergency contact
  Future<void> sendEmailToContact(
    EmergencyContact contact,
    String subject,
    String body,
  ) async {
    if (contact.email == null) {
      throw Exception('Contact does not have an email address');
    }

    final uri = Uri.parse(
      'mailto:${contact.email}?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Could not launch email');
    }
  }
}
