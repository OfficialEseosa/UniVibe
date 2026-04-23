import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String eventId;
  final String title;
  final String description;
  final String clubId;
  final DateTime startTime;
  final String location;
  final int rsvpCount;
  final List<String> rsvpedBy;
  final String? imageUrl;
  final DateTime createdAt;

  const EventModel({
    required this.eventId,
    required this.title,
    required this.description,
    required this.clubId,
    required this.startTime,
    required this.location,
    this.rsvpCount = 0,
    this.rsvpedBy = const [],
    this.imageUrl,
    required this.createdAt,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      eventId: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      clubId: data['clubId'] as String? ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      location: data['location'] as String,
      rsvpCount: data['rsvpCount'] as int? ?? 0,
      rsvpedBy: List<String>.from(data['rsvpedBy'] as List? ?? []),
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'clubId': clubId,
        'startTime': Timestamp.fromDate(startTime),
        'location': location,
        'rsvpCount': rsvpCount,
        'rsvpedBy': rsvpedBy,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  EventModel copyWith({
    int? rsvpCount,
    List<String>? rsvpedBy,
  }) =>
      EventModel(
        eventId: eventId,
        title: title,
        description: description,
        clubId: clubId,
        startTime: startTime,
        location: location,
        rsvpCount: rsvpCount ?? this.rsvpCount,
        rsvpedBy: rsvpedBy ?? this.rsvpedBy,
        imageUrl: imageUrl,
        createdAt: createdAt,
      );
}
