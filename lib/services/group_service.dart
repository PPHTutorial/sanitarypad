import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../data/models/group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore;

  GroupService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new group
  Future<GroupModel> createGroup(GroupModel group) async {
    final docRef = _firestore.collection(AppConstants.collectionGroups).doc();
    final groupWithId = group.copyWith(id: docRef.id);
    await docRef.set(groupWithId.toFirestore());
    return groupWithId;
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
  Future<void> joinGroup(String groupId, String userId) async {
    // Check if already a member
    final existing = await _firestore
        .collection(AppConstants.collectionGroupMembers)
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .get();

    if (existing.docs.isNotEmpty) return;

    // Add member
    await _firestore.collection(AppConstants.collectionGroupMembers).add({
      'groupId': groupId,
      'userId': userId,
      'role': 'member',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // Update member count
    final groupRef =
        _firestore.collection(AppConstants.collectionGroups).doc(groupId);
    await groupRef.update({
      'memberCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Leave a group
  Future<void> leaveGroup(String groupId, String userId) async {
    // Remove member
    final memberDocs = await _firestore
        .collection(AppConstants.collectionGroupMembers)
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in memberDocs.docs) {
      await doc.reference.delete();
    }

    // Update member count
    final groupRef =
        _firestore.collection(AppConstants.collectionGroups).doc(groupId);
    await groupRef.update({
      'memberCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
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
    final result = await _firestore
        .collection(AppConstants.collectionGroupMembers)
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }
}
