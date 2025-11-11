import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../data/models/group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore;

  GroupService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new group
  Future<GroupModel> createGroup(GroupModel group) async {
    final groupRef = _firestore.collection(AppConstants.collectionGroups).doc();
    final memberRef = _firestore
        .collection(AppConstants.collectionGroupMembers)
        .doc('${groupRef.id}_${group.adminId}');

    final now = DateTime.now();
    final groupWithMeta = group.copyWith(
      id: groupRef.id,
      createdAt: now,
      updatedAt: now,
      memberCount: 1,
    );

    final adminMember = GroupMember(
      id: memberRef.id,
      groupId: groupRef.id,
      userId: group.adminId,
      role: 'admin',
      joinedAt: now,
    );

    try {
      await groupRef.set(groupWithMeta.toFirestore());
      await memberRef.set(adminMember.toFirestore());
      return groupWithMeta;
    } catch (e) {
      // Attempt to clean up partially created documents
      try {
        await groupRef.delete();
      } catch (_) {
        // ignore cleanup failures
      }
      rethrow;
    }
  }

  // Get a single group
  Future<GroupModel?> getGroup(String groupId) async {
    final doc = await _firestore
        .collection(AppConstants.collectionGroups)
        .doc(groupId)
        .get();
    if (!doc.exists) return null;
    return GroupModel.fromFirestore(doc);
  }

  // Get groups by category
  Stream<List<GroupModel>> getGroupsByCategory(String category) {
    return _firestore
        .collection(AppConstants.collectionGroups)
        .where('category', isEqualTo: category)
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList());
  }

  // Get all public groups
  Stream<List<GroupModel>> getAllPublicGroups() {
    return _firestore
        .collection(AppConstants.collectionGroups)
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList());
  }

  // Get groups user is a member of
  Stream<List<GroupModel>> getUserGroups(String userId) {
    return _firestore
        .collection(AppConstants.collectionGroupMembers)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final groupIds =
          snapshot.docs.map((doc) => doc.data()['groupId'] as String).toList();
      if (groupIds.isEmpty) return <GroupModel>[];

      final groups = await Future.wait(
        groupIds.map((id) => getGroup(id)),
      );
      return groups.whereType<GroupModel>().toList();
    });
  }

  // Join a group
  Future<void> joinGroup(String groupId, String userId,
      {String role = 'member'}) async {
    // Legacy membership check to avoid duplicate entries
    final legacyMembership = await _firestore
        .collection(AppConstants.collectionGroupMembers)
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (legacyMembership.docs.isNotEmpty) {
      // Backfill deterministic document id for future lookups
      final legacyDoc = legacyMembership.docs.first;
      final deterministicRef = _firestore
          .collection(AppConstants.collectionGroupMembers)
          .doc('${groupId}_$userId');
      await deterministicRef.set({
        ...legacyDoc.data(),
        'role': legacyDoc.data()['role'] ?? role,
        'joinedAt':
            legacyDoc.data()['joinedAt'] ?? Timestamp.fromDate(DateTime.now()),
      });
      return;
    }

    final memberRef = _firestore
        .collection(AppConstants.collectionGroupMembers)
        .doc('${groupId}_$userId');
    final groupRef =
        _firestore.collection(AppConstants.collectionGroups).doc(groupId);

    await _firestore.runTransaction((transaction) async {
      final memberSnapshot = await transaction.get(memberRef);
      if (memberSnapshot.exists) {
        return;
      }

      final groupSnapshot = await transaction.get(groupRef);
      if (!groupSnapshot.exists) {
        throw Exception('Group not found');
      }

      transaction.set(memberRef, {
        'groupId': groupId,
        'userId': userId,
        'role': role,
        'joinedAt': Timestamp.fromDate(DateTime.now()),
      });

      transaction.update(groupRef, {
        'memberCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  // Leave a group
  Future<void> leaveGroup(String groupId, String userId) async {
    final memberRef = _firestore
        .collection(AppConstants.collectionGroupMembers)
        .doc('${groupId}_$userId');
    final groupRef =
        _firestore.collection(AppConstants.collectionGroups).doc(groupId);

    final legacyMembers = await _firestore
        .collection(AppConstants.collectionGroupMembers)
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .limit(5)
        .get();

    await _firestore.runTransaction((transaction) async {
      final memberSnapshot = await transaction.get(memberRef);
      final groupSnapshot = await transaction.get(groupRef);
      if (!groupSnapshot.exists) {
        return;
      }

      bool removed = false;

      if (memberSnapshot.exists) {
        transaction.delete(memberRef);
        removed = true;
      } else if (legacyMembers.docs.isNotEmpty) {
        for (final legacy in legacyMembers.docs) {
          transaction.delete(legacy.reference);
        }
        removed = true;
      }

      if (!removed) return;

      final currentCount =
          (groupSnapshot.data()?['memberCount'] as int? ?? 1).clamp(0, 999999);
      if (currentCount <= 1) {
        transaction.update(groupRef, {
          'memberCount': 0,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        transaction.update(groupRef, {
          'memberCount': FieldValue.increment(-1),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    });
  }

  // Update group
  Future<void> updateGroup(GroupModel group) async {
    if (group.id == null) throw Exception('Group ID is required');
    await _firestore
        .collection(AppConstants.collectionGroups)
        .doc(group.id)
        .update({
      ...group.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete group
  Future<void> deleteGroup(String groupId) async {
    // Delete all members
    final members = await _firestore
        .collection(AppConstants.collectionGroupMembers)
        .where('groupId', isEqualTo: groupId)
        .get();
    for (final doc in members.docs) {
      await doc.reference.delete();
    }

    // Delete group
    await _firestore
        .collection(AppConstants.collectionGroups)
        .doc(groupId)
        .delete();
  }

  // Check if user is a member
  Future<bool> isMember(String groupId, String userId) async {
    final doc = await _firestore
        .collection(AppConstants.collectionGroupMembers)
        .doc('${groupId}_$userId')
        .get();
    if (doc.exists) return true;

    // Backward compatibility check for legacy member documents
    final legacy = await _firestore
        .collection(AppConstants.collectionGroupMembers)
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (legacy.docs.isNotEmpty) {
      final deterministicRef = _firestore
          .collection(AppConstants.collectionGroupMembers)
          .doc('${groupId}_$userId');
      final legacyData = legacy.docs.first.data();
      await deterministicRef.set({
        ...legacyData,
        'joinedAt':
            legacyData['joinedAt'] ?? Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
      return true;
    }
    return false;
  }

  Stream<bool> isMemberStream(String groupId, String userId) {
    final docRef = _firestore
        .collection(AppConstants.collectionGroupMembers)
        .doc('${groupId}_$userId');
    return docRef.snapshots().asyncMap((snapshot) async {
      if (snapshot.exists) return true;
      final legacy = await _firestore
          .collection(AppConstants.collectionGroupMembers)
          .where('groupId', isEqualTo: groupId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (legacy.docs.isNotEmpty) {
        final deterministicRef = _firestore
            .collection(AppConstants.collectionGroupMembers)
            .doc('${groupId}_$userId');
        final legacyData = legacy.docs.first.data();
        await deterministicRef.set({
          ...legacyData,
          'joinedAt':
              legacyData['joinedAt'] ?? Timestamp.fromDate(DateTime.now()),
        }, SetOptions(merge: true));
        return true;
      }
      return false;
    });
  }

  Stream<GroupModel?> watchGroup(String groupId) {
    return _firestore
        .collection(AppConstants.collectionGroups)
        .doc(groupId)
        .snapshots()
        .map((snapshot) =>
            snapshot.exists ? GroupModel.fromFirestore(snapshot) : null);
  }

  Stream<List<GroupMember>> streamGroupMembers(String groupId) {
    return _firestore
        .collection(AppConstants.collectionGroupMembers)
        .where('groupId', isEqualTo: groupId)
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupMember.fromFirestore(doc))
            .toList());
  }

  Future<void> updateMemberRole(
      String groupId, String userId, String role) async {
    final memberRef = _firestore
        .collection(AppConstants.collectionGroupMembers)
        .doc('${groupId}_$userId');
    await memberRef.update({'role': role});
  }
}
