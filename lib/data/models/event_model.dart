import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String? id;
  final String title;
  final String description;
  final String category; // 'pregnancy', 'fertility', 'skincare', 'general'
  final String? imageUrl;
  final String createdBy;
  final DateTime startDate;
  final DateTime endDate;
  final String? location;
  final String? onlineLink;
  final bool isOnline;
  final int maxAttendees;
  final int attendeeCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final Map<String, dynamic>? metadata;

  EventModel({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    required this.createdBy,
    required this.startDate,
    required this.endDate,
    this.location,
    this.onlineLink,
    this.isOnline = false,
    this.maxAttendees = 0,
    this.attendeeCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.metadata,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'general',
      imageUrl: data['imageUrl'],
      createdBy: data['createdBy'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      location: data['location'],
      onlineLink: data['onlineLink'],
      isOnline: data['isOnline'] ?? false,
      maxAttendees: data['maxAttendees'] ?? 0,
      attendeeCount: data['attendeeCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      tags: List<String>.from(data['tags'] ?? []),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'onlineLink': onlineLink,
      'isOnline': isOnline,
      'maxAttendees': maxAttendees,
      'attendeeCount': attendeeCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'metadata': metadata,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
    String? createdBy,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? onlineLink,
    bool? isOnline,
    int? maxAttendees,
    int? attendeeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdBy: createdBy ?? this.createdBy,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      onlineLink: onlineLink ?? this.onlineLink,
      isOnline: isOnline ?? this.isOnline,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }
}

class EventAttendee {
  final String? id;
  final String eventId;
  final String userId;
  final DateTime registeredAt;
  final String? status; // 'registered', 'attended', 'cancelled'
  final Map<String, dynamic>? metadata;

  EventAttendee({
    this.id,
    required this.eventId,
    required this.userId,
    required this.registeredAt,
    this.status = 'registered',
    this.metadata,
  });

  factory EventAttendee.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventAttendee(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'registered',
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'userId': userId,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'status': status,
      'metadata': metadata,
    };
  }
}
