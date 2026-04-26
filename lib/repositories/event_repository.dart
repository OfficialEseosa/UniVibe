import 'dart:io';
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class EventRepository {
  final FirestoreService _firestore;
  final StorageService _storage;

  EventRepository({
    required FirestoreService firestore,
    required StorageService storage,
  })  : _firestore = firestore,
        _storage = storage;

  Stream<List<EventModel>> upcomingEventsStream({int limit = 30}) =>
      _firestore.upcomingEventsStream(limit: limit);

  Future<void> createEvent({
    required String title,
    required String description,
    required String clubId,
    required DateTime startTime,
    required String location,
    File? banner,
  }) async {
    final event = EventModel(
      eventId: '',
      title: title,
      description: description,
      clubId: clubId,
      startTime: startTime,
      location: location,
      createdAt: DateTime.now(),
    );

    final ref = await _firestore.createEvent(event);

    if (banner != null) {
      final url = await _storage.uploadEventBanner(ref.id, banner);
      await ref.update({'imageUrl': url});
    }
  }

  Future<void> toggleRsvp(String eventId, String uid) =>
      _firestore.toggleRsvp(eventId, uid);
}
