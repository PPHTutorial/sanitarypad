import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../data/models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore;

  EventService([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new event
  Future<EventModel> createEvent(EventModel event) async {
    final docRef = _firestore.collection(AppConstants.collectionEvents).doc();
    final eventWithId = event.copyWith(id: docRef.id);
    await docRef.set(eventWithId.toFirestore());
    return eventWithId;
  }

  // Get a single event
  Future<EventModel?> getEvent(String eventId) async {
    final doc = await _firestore
        .collection(AppConstants.collectionEvents)
        .doc(eventId)
        .get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc);
  }

  // Get events by category
  Stream<List<EventModel>> getEventsByCategory(String category) {
    return _firestore
        .collection(AppConstants.collectionEvents)
        .where('category', isEqualTo: category)
        .where('startDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  // Get upcoming events
  Stream<List<EventModel>> getUpcomingEvents() {
    return _firestore
        .collection(AppConstants.collectionEvents)
        .where('startDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
        .orderBy('startDate', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  // Get events user is attending
  Stream<List<EventModel>> getUserEvents(String userId) {
    return _firestore
        .collection(AppConstants.collectionEventAttendees)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'registered')
        .snapshots()
        .asyncMap((snapshot) async {
      final eventIds =
          snapshot.docs.map((doc) => doc.data()['eventId'] as String).toList();
      if (eventIds.isEmpty) return <EventModel>[];

      final events = await Future.wait(
        eventIds.map((id) => getEvent(id)),
      );
      return events.whereType<EventModel>().toList();
    });
  }

  // Register for an event
  Future<void> registerForEvent(String eventId, String userId) async {
    // Check if already registered
    final existing = await _firestore
        .collection(AppConstants.collectionEventAttendees)
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .get();

    if (existing.docs.isNotEmpty) return;

    // Check if event is full
    final event = await getEvent(eventId);
    if (event != null &&
        event.maxAttendees > 0 &&
        event.attendeeCount >= event.maxAttendees) {
      throw Exception('Event is full');
    }

    // Add attendee
    await _firestore.collection(AppConstants.collectionEventAttendees).add({
      'eventId': eventId,
      'userId': userId,
      'status': 'registered',
      'registeredAt': FieldValue.serverTimestamp(),
    });

    // Update attendee count
    final eventRef =
        _firestore.collection(AppConstants.collectionEvents).doc(eventId);
    await eventRef.update({
      'attendeeCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Cancel event registration
  Future<void> cancelRegistration(String eventId, String userId) async {
    // Remove attendee
    final attendeeDocs = await _firestore
        .collection(AppConstants.collectionEventAttendees)
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in attendeeDocs.docs) {
      await doc.reference.update({'status': 'cancelled'});
    }

    // Update attendee count
    final eventRef =
        _firestore.collection(AppConstants.collectionEvents).doc(eventId);
    await eventRef.update({
      'attendeeCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update event
  Future<void> updateEvent(EventModel event) async {
    if (event.id == null) throw Exception('Event ID is required');
    await _firestore
        .collection(AppConstants.collectionEvents)
        .doc(event.id)
        .update({
      ...event.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete event (restricted to creator)
  Future<void> deleteEvent(String eventId, String userId) async {
    final event = await getEvent(eventId);
    if (event == null) throw Exception('Event not found');

    if (event.createdBy != userId) {
      throw Exception('Only the creator can delete this event');
    }

    // Delete all attendees
    final attendees = await _firestore
        .collection(AppConstants.collectionEventAttendees)
        .where('eventId', isEqualTo: eventId)
        .get();
    for (final doc in attendees.docs) {
      await doc.reference.delete();
    }

    // Delete event
    await _firestore
        .collection(AppConstants.collectionEvents)
        .doc(eventId)
        .delete();
  }

  // Check if user is registered
  Future<bool> isRegistered(String eventId, String userId) async {
    final result = await _firestore
        .collection(AppConstants.collectionEventAttendees)
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'registered')
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }

  // Get events linked to a specific group
  Stream<List<EventModel>> getEventsForGroup(String groupId) {
    return _firestore
        .collection(AppConstants.collectionEvents)
        .where('groupId', isEqualTo: groupId)
        .where('startDate',
            isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(
              const Duration(hours: 2),
            )))
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }
}
