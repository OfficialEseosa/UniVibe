import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:univibe/models/user_model.dart';
import 'package:univibe/services/study_match_service.dart';

void main() {
  group('StudyMatchService scoring', () {
    late StudyMatchService service;

    setUp(() => service = StudyMatchService(db: FakeFirebaseFirestore()));

    UserModel makeUser({
      required String uid,
      List<String> courses = const [],
      Map<String, dynamic> availability = const {},
      String bio = '',
    }) =>
        UserModel(
          uid: uid,
          displayName: 'User $uid',
          email: '$uid@test.edu',
          courses: courses,
          availability: availability,
          bio: bio,
          createdAt: DateTime(2026, 1, 1),
        );

    test('identical courses give max course score', () {
      final a = makeUser(uid: 'a', courses: ['CSC1', 'CSC2', 'CSC3', 'CSC4', 'CSC5', 'CSC6', 'CSC7']);
      final b = makeUser(uid: 'b', courses: ['CSC1', 'CSC2', 'CSC3', 'CSC4', 'CSC5', 'CSC6', 'CSC7']);
      final match = service.publicScore(a, b);
      // 6 courses × 10 = 60 (capped at 60)
      expect(match.score, greaterThanOrEqualTo(60));
    });

    test('no shared courses gives zero course score', () {
      final a = makeUser(uid: 'a', courses: ['CSC1', 'CSC2']);
      final b = makeUser(uid: 'b', courses: ['ENG1', 'ENG2']);
      final match = service.publicScore(a, b);
      expect(match.sharedCourses, isEmpty);
      expect(match.score, lessThan(60));
    });

    test('availability overlap increases score', () {
      final avail = {'mon': ['9am-11am'], 'wed': ['2pm-4pm']};
      final a = makeUser(uid: 'a', courses: ['CSC1'], availability: avail);
      final b = makeUser(uid: 'b', courses: ['CSC1'], availability: avail);
      final noOverlap = makeUser(uid: 'c', courses: ['CSC1']);

      final withOverlap = service.publicScore(a, b);
      final without = service.publicScore(a, noOverlap);
      expect(withOverlap.score, greaterThan(without.score));
    });

    test('bio keyword match increases score', () {
      final a = makeUser(uid: 'a', bio: 'I love math and programming');
      final b = makeUser(uid: 'b', bio: 'math and programming enthusiast');
      final c = makeUser(uid: 'c', bio: 'I enjoy hiking');

      final withMatch = service.publicScore(a, b);
      final without = service.publicScore(a, c);
      expect(withMatch.score, greaterThan(without.score));
    });

    test('score is symmetric', () {
      final a = makeUser(uid: 'a', courses: ['CSC1', 'CSC2'],
          bio: 'programming');
      final b = makeUser(uid: 'b', courses: ['CSC1', 'CSC3'],
          bio: 'programming');
      final ab = service.publicScore(a, b).score;
      final ba = service.publicScore(b, a).score;
      expect(ab, equals(ba));
    });

    test('sharedCourses lists correctly populated', () {
      final a = makeUser(uid: 'a', courses: ['CSC1', 'CSC2', 'MATH1']);
      final b = makeUser(uid: 'b', courses: ['CSC1', 'MATH1', 'ENG1']);
      final match = service.publicScore(a, b);
      expect(match.sharedCourses, containsAll(['CSC1', 'MATH1']));
      expect(match.sharedCourses, isNot(contains('ENG1')));
    });
  });
}
