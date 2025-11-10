import 'package:cloud_firestore/cloud_firestore.dart';

class AIChatMessage {
  final String? id;
  final String userId;
  final String category; // 'pregnancy', 'fertility', 'skincare', 'general'
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>?
      metadata; // For context data (pregnancy week, cycle day, etc.)

  AIChatMessage({
    this.id,
    required this.userId,
    required this.category,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  factory AIChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIChatMessage(
      id: doc.id,
      userId: data['userId'] ?? '',
      category: data['category'] ?? 'general',
      role: data['role'] ?? 'user',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'category': category,
      'role': role,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  AIChatMessage copyWith({
    String? id,
    String? userId,
    String? category,
    String? role,
    String? content,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return AIChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
}

class AIConversation {
  final String? id;
  final String userId;
  final String category;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> messageIds;

  AIConversation({
    this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageIds = const [],
  });

  factory AIConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIConversation(
      id: doc.id,
      userId: data['userId'] ?? '',
      category: data['category'] ?? 'general',
      title: data['title'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      messageIds: List<String>.from(data['messageIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'category': category,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'messageIds': messageIds,
    };
  }
}
