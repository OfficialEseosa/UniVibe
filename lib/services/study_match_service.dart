import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/study_match_model.dart';

/// Rule-based study-partner suggestion engine.
///
/// Scoring weights (total 100 pts):
///   - Shared courses     : 60 pts  (10 pts per shared course, cap 6)
///   - Availability overlap: 30 pts  (5 pts per overlapping day, cap 6)
///   - Bio keyword match  : 10 pts  (5 pts per keyword, cap 2)
class StudyMatchService {
  final FirebaseFirestore _db;

  static const _sharedCoursePts = 10.0;
  static const _maxCourseScore = 60.0;
  static const _availabilityDayPts = 5.0;
  static const _maxAvailabilityScore = 30.0;
  static const _bioKeywordPts = 5.0;
  static const _maxBioScore = 10.0;

  StudyMatchService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<List<StudyMatchModel>> computeMatches(UserModel currentUser) async {
    final snap = await _db.collection('users').get();

    final candidates = snap.docs
        .map(UserModel.fromFirestore)
        .where((u) => u.uid != currentUser.uid)
        .toList();

    final matches = candidates
        .map((candidate) => _score(currentUser, candidate))
        .where((m) => m.score > 0)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return matches.take(10).toList();
  }

  StudyMatchModel publicScore(UserModel current, UserModel candidate) =>
      _score(current, candidate);

  StudyMatchModel _score(UserModel current, UserModel candidate) {
    // Shared courses
    final shared = current.courses
        .where((c) => candidate.courses.contains(c))
        .toList();
    final courseScore =
        (shared.length * _sharedCoursePts).clamp(0, _maxCourseScore);

    // Availability overlap
    final overlap = _availabilityOverlap(
        current.availability, candidate.availability);
    final availScore =
        (overlap.length * _availabilityDayPts).clamp(0, _maxAvailabilityScore);

    // Bio keyword match
    final bioScore = _bioScore(current.bio, candidate.bio);

    final total = courseScore + availScore + bioScore;

    return StudyMatchModel(
      matchUid: candidate.uid,
      matchName: candidate.displayName,
      matchPhotoUrl: candidate.profilePhotoUrl,
      score: total,
      sharedCourses: shared,
      availabilityOverlap: {for (final d in overlap) d: true},
      lastUpdated: DateTime.now(),
    );
  }

  List<String> _availabilityOverlap(
      Map<String, dynamic> a, Map<String, dynamic> b) {
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return days.where((day) {
      final aSlots = a[day];
      final bSlots = b[day];
      if (aSlots == null || bSlots == null) return false;
      if (aSlots is List && bSlots is List) {
        return aSlots.any((s) => bSlots.contains(s));
      }
      return aSlots == true && bSlots == true;
    }).toList();
  }

  double _bioScore(String bio1, String bio2) {
    if (bio1.isEmpty || bio2.isEmpty) return 0;
    final academicKeywords = [
      'study', 'research', 'engineering', 'cs', 'biology',
      'math', 'science', 'programming', 'design', 'art',
      'music', 'chemistry', 'physics', 'nursing', 'business',
    ];
    final words1 = bio1.toLowerCase().split(RegExp(r'\W+'));
    final words2 = bio2.toLowerCase().split(RegExp(r'\W+'));
    final shared = academicKeywords
        .where((kw) => words1.contains(kw) && words2.contains(kw))
        .length;
    return (shared * _bioKeywordPts).clamp(0, _maxBioScore);
  }

  Future<void> refreshMatches(UserModel currentUser) async {
    final matches = await computeMatches(currentUser);
    final batch = _db.batch();
    for (final match in matches) {
      final ref = _db
          .collection('studyMatches')
          .doc(currentUser.uid)
          .collection('suggestions')
          .doc(match.matchUid);
      batch.set(ref, match.toFirestore());
    }
    await batch.commit();
  }
}
