import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../data/models/ai_chat_model.dart';

class AIChatService {
  final FirebaseFirestore _firestore;

  AIChatService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get chat messages for a conversation
  Stream<List<AIChatMessage>> getChatMessages(String userId, String category) {
    return _firestore
        .collection(AppConstants.collectionAIChatMessages)
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AIChatMessage.fromFirestore(doc))
            .toList());
  }

  /// Save a chat message
  Future<AIChatMessage> saveMessage(AIChatMessage message) async {
    final docRef =
        _firestore.collection(AppConstants.collectionAIChatMessages).doc();
    final messageWithId = message.copyWith(id: docRef.id);
    await docRef.set(messageWithId.toFirestore());
    return messageWithId;
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    await _firestore
        .collection(AppConstants.collectionAIChatMessages)
        .doc(messageId)
        .delete();
  }

  /// Clear all messages for a category
  Future<void> clearChatHistory(String userId, String category) async {
    final messages = await _firestore
        .collection(AppConstants.collectionAIChatMessages)
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .get();

    for (final doc in messages.docs) {
      await doc.reference.delete();
    }
  }

  /// Get conversations list
  Stream<List<AIConversation>> getConversations(
      String userId, String category) {
    return _firestore
        .collection(AppConstants.collectionAIConversations)
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AIConversation.fromFirestore(doc))
            .toList());
  }

  /// Create or update conversation
  Future<AIConversation> saveConversation(AIConversation conversation) async {
    final docRef = conversation.id != null
        ? _firestore
            .collection(AppConstants.collectionAIConversations)
            .doc(conversation.id)
        : _firestore.collection(AppConstants.collectionAIConversations).doc();

    final conversationWithId = conversation.copyWith(
      id: docRef.id,
      updatedAt: DateTime.now(),
    );
    await docRef.set(conversationWithId.toFirestore());
    return conversationWithId;
  }
}

extension AIConversationCopyWith on AIConversation {
  AIConversation copyWith({
    String? id,
    String? userId,
    String? category,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? messageIds,
  }) {
    return AIConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageIds: messageIds ?? this.messageIds,
    );
  }
}
