import 'package:cloud_firestore/cloud_firestore.dart';

class StudyMatchModel {
  final String matchUid;
  final String matchName;
  final String matchPhotoUrl;
  final double score;
  final List<String> sharedCourses;
  final Map<String, dynamic> availabilityOverlap;
  final DateTime lastUpdated;

  const StudyMatchModel({
    required this.matchUid,
    required this.matchName,
    this.matchPhotoUrl = '',
    required this.score,
    required this.sharedCourses,
    this.availabilityOverlap = const {},
    required this.lastUpdated,
  });

  factory StudyMatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudyMatchModel(
      matchUid: doc.id,
      matchName: data['matchName'] as String? ?? '',
      matchPhotoUrl: data['matchPhotoUrl'] as String? ?? '',
      score: (data['score'] as num).toDouble(),
      sharedCourses: List<String>.from(data['sharedCourses'] as List? ?? []),
      availabilityOverlap: Map<String, dynamic>.from(
          data['availabilityOverlap'] as Map? ?? {}),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'matchName': matchName,
        'matchPhotoUrl': matchPhotoUrl,
        'score': score,
        'sharedCourses': sharedCourses,
        'availabilityOverlap': availabilityOverlap,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };
}
