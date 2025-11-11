import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../data/models/group_message_model.dart';
import 'storage_service.dart';

class GroupMessageService {
  GroupMessageService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _messagesCollection =>
      _firestore.collection(AppConstants.collectionGroupMessages);

  Stream<List<GroupMessage>> streamMessages(
    String groupId, {
    int limit = 200,
  }) {
    return _messagesCollection
        .where('groupId', isEqualTo: groupId)
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupMessage.fromFirestore(doc))
              .toList(),
        );
  }

  Future<GroupMessage> sendMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    String? text,
    List<MessageAttachment> attachments = const [],
    String? replyToMessageId,
    String? replyToSender,
    String? replyPreviewText,
  }) async {
    if ((text == null || text.trim().isEmpty) && attachments.isEmpty) {
      throw Exception('Message cannot be empty');
    }

    final now = DateTime.now();
    final docRef = _messagesCollection.doc();
    final message = GroupMessage(
      id: docRef.id,
      groupId: groupId,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      text: text?.trim(),
      attachments: attachments,
      replyToMessageId: replyToMessageId,
      replyToSender: replyToSender,
      replyPreviewText: replyPreviewText,
      sentAt: now,
    );

    await docRef.set(message.toFirestore());
    return message;
  }

  Future<void> editMessage({
    required String messageId,
    required String newText,
  }) async {
    final docRef = _messagesCollection.doc(messageId);
    await docRef.update({
      'text': newText.trim(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'isDeleted': false,
    });
  }

  Future<void> deleteMessage(GroupMessage message,
      {bool hardDelete = false}) async {
    if (message.id == null) return;
    final docRef = _messagesCollection.doc(message.id);
    if (hardDelete) {
      await docRef.delete();
    } else {
      await docRef.update({
        'text': null,
        'attachments': [],
        'isDeleted': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }

    // Clean up attachments in storage
    if (message.attachments.isNotEmpty) {
      final storage = StorageService();
      for (final attachment in message.attachments) {
        if (attachment.storagePath != null) {
          await storage.deleteFile(attachment.storagePath!);
        }
      }
    }
  }

  Future<void> toggleReaction({
    required String messageId,
    required String reaction,
    required String userId,
  }) async {
    final docRef = _messagesCollection.doc(messageId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final reactions = Map<String, List<dynamic>>.from(
          data['reactions'] as Map<String, dynamic>? ?? {});

      final currentUsers = reactions[reaction] != null
          ? List<String>.from(reactions[reaction] as List<dynamic>)
          : <String>[];

      if (currentUsers.contains(userId)) {
        currentUsers.remove(userId);
      } else {
        currentUsers.add(userId);
      }

      if (currentUsers.isEmpty) {
        reactions.remove(reaction);
      } else {
        reactions[reaction] = currentUsers;
      }

      transaction.update(docRef, {
        'reactions': reactions,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  Future<void> attachFilesToMessage({
    required String messageId,
    required List<MessageAttachment> attachments,
  }) async {
    final docRef = _messagesCollection.doc(messageId);
    await docRef.update({
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
