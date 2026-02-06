import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketStatus { open, inProgress, resolved, closed }

enum TicketCategory {
  general,
  billing,
  technical,
  cycleTracking,
  pregnancy,
  wellness,
  other
}

class SupportTicketModel {
  final String id;
  final String userId;
  final String subject;
  final String description;
  final TicketCategory category;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> imageUrls;
  final String? adminReply;
  final String? adminId;
  final DateTime? adminRepliedAt;

  const SupportTicketModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrls = const [],
    this.adminReply,
    this.adminId,
    this.adminRepliedAt,
  });

  factory SupportTicketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportTicketModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      category: TicketCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => TicketCategory.general,
      ),
      status: TicketStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TicketStatus.open,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      adminReply: data['adminReply'],
      adminId: data['adminId'],
      adminRepliedAt: data['adminRepliedAt'] != null
          ? (data['adminRepliedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'subject': subject,
      'description': description,
      'category': category.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'imageUrls': imageUrls,
      'adminReply': adminReply,
      'adminId': adminId,
      'adminRepliedAt':
          adminRepliedAt != null ? Timestamp.fromDate(adminRepliedAt!) : null,
    };
  }

  SupportTicketModel copyWith({
    String? id,
    String? userId,
    String? subject,
    String? description,
    TicketCategory? category,
    TicketStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? imageUrls,
    String? adminReply,
    String? adminId,
    DateTime? adminRepliedAt,
  }) {
    return SupportTicketModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrls: imageUrls ?? this.imageUrls,
      adminReply: adminReply ?? this.adminReply,
      adminId: adminId ?? this.adminId,
      adminRepliedAt: adminRepliedAt ?? this.adminRepliedAt,
    );
  }
}
