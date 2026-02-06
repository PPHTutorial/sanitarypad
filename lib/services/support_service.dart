import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sanitarypad/data/models/support_ticket_model.dart';
import 'package:sanitarypad/services/storage_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supportServiceProvider = Provider((ref) => SupportService());

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  final _uuid = const Uuid();

  static const String ticketCollection = 'support_tickets';

  /// Create a new support ticket
  Future<void> createTicket({
    required String userId,
    required String subject,
    required String description,
    required TicketCategory category,
    List<File> images = const [],
  }) async {
    try {
      final ticketId = _uuid.v4();
      final List<String> imageUrls = [];

      // Upload images if any
      for (int i = 0; i < images.length; i++) {
        final filename = 'image_$i.jpg';
        final storagePath = 'support_tickets/$userId/$ticketId/$filename';
        final result = await _storageService.uploadFile(
          path: storagePath,
          file: images[i],
        );
        imageUrls.add(result.downloadUrl);
      }

      final ticket = SupportTicketModel(
        id: ticketId,
        userId: userId,
        subject: subject,
        description: description,
        category: category,
        status: TicketStatus.open,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrls: imageUrls,
      );

      await _firestore
          .collection(ticketCollection)
          .doc(ticketId)
          .set(ticket.toFirestore());
    } catch (e) {
      throw Exception('Failed to create ticket: ${e.toString()}');
    }
  }

  /// Get user's support tickets
  Stream<List<SupportTicketModel>> getUserTickets(String userId) {
    return _firestore
        .collection(ticketCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportTicketModel.fromFirestore(doc))
            .toList());
  }

  /// Get all tickets (Admin only)
  Stream<List<SupportTicketModel>> getAllTickets({bool showResolved = false}) {
    Query query = _firestore
        .collection(ticketCollection)
        .orderBy('createdAt', descending: true);

    // Note: For large datasets, filtering by inequality on one field and sorting by another
    // requires a composite index. For now we fetch all sorted by date and filter status if needed
    // or rely on the client or simple queries.
    // If we wanted to filter by status 'open' AND sort by createdAt, we'd need an index.

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => SupportTicketModel.fromFirestore(doc))
        .where(
            (ticket) => showResolved || ticket.status != TicketStatus.resolved)
        .toList());
  }

  /// Reply to a ticket
  Future<void> replyToTicket({
    required String ticketId,
    required String reply,
    required String adminId,
  }) async {
    await _firestore.collection(ticketCollection).doc(ticketId).update({
      'adminReply': reply,
      'adminId': adminId,
      'adminRepliedAt': FieldValue.serverTimestamp(),
      'status': TicketStatus.inProgress.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Close a ticket
  Future<void> closeTicket(String ticketId) async {
    await _firestore.collection(ticketCollection).doc(ticketId).update({
      'status': TicketStatus.resolved.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get FAQs
  List<Map<String, String>> getFAQs() {
    return [
      {
        'question': 'How do I log my period?',
        'answer':
            'Go to the Home screen and tap the "Log Period" button. Choose your start and end dates, flow intensity, and any symptoms you are experiencing.',
      },
      {
        'question': 'What are credits used for?',
        'answer':
            'Credits are used to access premium features like AI analysis, exporting health reports, or searching for specialists. You can earn credits by watching ads or subscribing to a premium plan.',
      },
      {
        'question': 'How can I track my pregnancy?',
        'answer':
            'Navigate to the Pregnancy tab from the Home screen. You can log your baby\'s kicks, your weight, contractions, and maintain a pregnancy journal.',
      },
      {
        'question': 'Is my data secure?',
        'answer':
            'Yes, your data is encrypted and stored securely on our cloud servers. We prioritize your privacy and do not share your sensitive health information with third parties.',
      },
      {
        'question': 'How do I upgrade my subscription?',
        '                  ' 'answer':
            'Go to your Profile tab and tap the "Upgrade" button in the subscription card to view our premium plans and their benefits.',
      },
      {
        'question': 'Can I export my health data?',
        'answer':
            'Yes, you can generate a PDF health report by going to Profile > Health Reports. This feature requires a small amount of credits or a premium subscription.',
      },
    ];
  }
}
