import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

/// Wellness content model
class WellnessContent {
  final String? id;
  final String? userId; // Author ID
  final String title;
  final String content;
  final String type;
  final String? category;
  final String? imageUrl;
  final List<String>? tags;
  final bool isPremium;
  final bool isPaid;
  final bool isAIGenerated;
  final double? price;
  final int? readTime; // in minutes
  final DateTime createdAt;
  final DateTime? updatedAt;

  WellnessContent({
    this.id,
    this.userId,
    required this.title,
    required this.content,
    required this.type,
    this.category,
    this.imageUrl,
    this.tags,
    this.isPremium = false,
    this.isPaid = false,
    this.isAIGenerated = false,
    this.price,
    this.readTime,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'type': type,
      'category': category,
      'imageUrl': imageUrl,
      'tags': tags,
      'isPremium': isPremium,
      'isPaid': isPaid,
      'isAIGenerated': isAIGenerated,
      'price': price,
      'readTime': readTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory WellnessContent.fromMap(Map<String, dynamic> map, String id) {
    return WellnessContent(
      id: id,
      userId: map['userId'] as String?,
      title: map['title'] as String,
      content: map['content'] as String,
      type: map['type'] as String,
      category: map['category'] as String?,
      imageUrl: map['imageUrl'] as String?,
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isPremium: map['isPremium'] as bool? ?? false,
      isPaid: map['isPaid'] as bool? ?? false,
      isAIGenerated: map['isAIGenerated'] as bool? ?? false,
      price: (map['price'] as num?)?.toDouble(),
      readTime: map['readTime'] as int?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}

/// Wellness content service
class WellnessContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get wellness content by type
  Stream<List<WellnessContent>> getContentByType(
    String type, {
    bool? isPremium,
    String? category,
  }) {
    Query query = _firestore
        .collection(AppConstants.collectionWellnessContent)
        .where('type', isEqualTo: type);

    if (isPremium != null) {
      query = query.where('isPremium', isEqualTo: isPremium);
    }

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return WellnessContent.fromMap(data, doc.id);
      }).toList();
    });
  }

  /// Get all wellness content
  Stream<List<WellnessContent>> getAllContent({
    bool? isPremium,
    String? category,
  }) {
    Query query = _firestore.collection(AppConstants.collectionWellnessContent);

    if (isPremium != null) {
      query = query.where('isPremium', isEqualTo: isPremium);
    }

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return WellnessContent.fromMap(data, doc.id);
      }).toList();
    });
  }

  /// Get content by ID
  Future<WellnessContent?> getContentById(String contentId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionWellnessContent)
          .doc(contentId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return WellnessContent.fromMap(data, doc.id);
    } catch (e) {
      return null;
    }
  }

  /// Get featured content
  Stream<List<WellnessContent>> getFeaturedContent({int limit = 5}) {
    return _firestore
        .collection(AppConstants.collectionWellnessContent)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WellnessContent.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get content categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionWellnessContent)
          .get();

      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          categories.add(data['category'] as String);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  /// Create wellness content
  Future<void> createContent(WellnessContent content) async {
    try {
      await _firestore
          .collection(AppConstants.collectionWellnessContent)
          .add(content.toMap());
    } catch (e) {
      throw Exception('Failed to create content: ${e.toString()}');
    }
  }

  /// Update wellness content
  Future<void> updateContent(WellnessContent content) async {
    if (content.id == null) {
      throw Exception('Content ID is required for update');
    }
    try {
      await _firestore
          .collection(AppConstants.collectionWellnessContent)
          .doc(content.id)
          .update(content.toMap());
    } catch (e) {
      throw Exception('Failed to update content: ${e.toString()}');
    }
  }

  /// Delete wellness content
  Future<void> deleteContent(String? contentId) async {
    if (contentId == null) {
      throw Exception('Content ID is required for deletion');
    }
    try {
      await _firestore
          .collection(AppConstants.collectionWellnessContent)
          .doc(contentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete content: ${e.toString()}');
    }
  }
}
