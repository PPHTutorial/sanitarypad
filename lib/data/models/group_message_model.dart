import 'package:cloud_firestore/cloud_firestore.dart';

class MessageAttachment {
  final String url;
  final String? storagePath;
  final String type; // image, file, audio, video
  final String? name;
  final int? size;
  final String? mimeType;
  final String? thumbnailUrl;

  const MessageAttachment({
    required this.url,
    this.storagePath,
    required this.type,
    this.name,
    this.size,
    this.mimeType,
    this.thumbnailUrl,
  });

  factory MessageAttachment.fromMap(Map<String, dynamic> map) {
    return MessageAttachment(
      url: map['url'] as String,
      storagePath: map['storagePath'] as String?,
      type: map['type'] as String? ?? 'file',
      name: map['name'] as String?,
      size: map['size'] as int?,
      mimeType: map['mimeType'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      if (storagePath != null) 'storagePath': storagePath,
      'type': type,
      if (name != null) 'name': name,
      if (size != null) 'size': size,
      if (mimeType != null) 'mimeType': mimeType,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    };
  }
}

class GroupMessage {
  final String? id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String? text;
  final List<MessageAttachment> attachments;
  final Map<String, List<String>> reactions;
  final String? replyToMessageId;
  final String? replyToSender;
  final String? replyPreviewText;
  final DateTime sentAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  const GroupMessage({
    this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    this.text,
    this.attachments = const [],
    this.reactions = const {},
    this.replyToMessageId,
    this.replyToSender,
    this.replyPreviewText,
    required this.sentAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  bool get hasAttachments => attachments.isNotEmpty;

  bool get canDisplayText =>
      !isDeleted &&
      ((text != null && text!.trim().isNotEmpty) || hasAttachments);

  factory GroupMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMessage(
      id: doc.id,
      groupId: data['groupId'] as String,
      senderId: data['senderId'] as String,
      senderName: data['senderName'] as String? ?? 'Unknown',
      senderAvatarUrl: data['senderAvatarUrl'] as String?,
      text: data['text'] as String?,
      attachments: (data['attachments'] as List<dynamic>? ?? [])
          .map(
              (item) => MessageAttachment.fromMap(item as Map<String, dynamic>))
          .toList(),
      reactions: (data['reactions'] as Map<String, dynamic>? ?? {}).map(
          (key, value) =>
              MapEntry(key, List<String>.from(value as List<dynamic>))),
      replyToMessageId: data['replyToMessageId'] as String?,
      replyToSender: data['replyToSender'] as String?,
      replyPreviewText: data['replyPreviewText'] as String?,
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'text': text,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'reactions': reactions,
      'replyToMessageId': replyToMessageId,
      'replyToSender': replyToSender,
      'replyPreviewText': replyPreviewText,
      'sentAt': Timestamp.fromDate(sentAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'isDeleted': isDeleted,
    };
  }

  GroupMessage copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    String? text,
    List<MessageAttachment>? attachments,
    Map<String, List<String>>? reactions,
    String? replyToMessageId,
    String? replyToSender,
    String? replyPreviewText,
    DateTime? sentAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return GroupMessage(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      text: text ?? this.text,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToSender: replyToSender ?? this.replyToSender,
      replyPreviewText: replyPreviewText ?? this.replyPreviewText,
      sentAt: sentAt ?? this.sentAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
