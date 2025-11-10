import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String? id;
  final String name;
  final String description;
  final String category; // 'pregnancy', 'fertility', 'skincare', 'general'
  final String? imageUrl;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final int memberCount;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  GroupModel({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    this.imageUrl,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = true,
    this.memberCount = 0,
    this.tags = const [],
    this.metadata,
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'general',
      imageUrl: data['imageUrl'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isPublic: data['isPublic'] ?? true,
      memberCount: data['memberCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPublic': isPublic,
      'memberCount': memberCount,
      'tags': tags,
      'metadata': metadata,
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? imageUrl,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
    int? memberCount,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
      memberCount: memberCount ?? this.memberCount,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }
}

class GroupMember {
  final String? id;
  final String groupId;
  final String userId;
  final String role; // 'admin', 'moderator', 'member'
  final DateTime joinedAt;
  final Map<String, dynamic>? metadata;

  GroupMember({
    this.id,
    required this.groupId,
    required this.userId,
    this.role = 'member',
    required this.joinedAt,
    this.metadata,
  });

  factory GroupMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMember(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      userId: data['userId'] ?? '',
      role: data['role'] ?? 'member',
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'userId': userId,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'metadata': metadata,
    };
  }
}
