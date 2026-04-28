import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:univibe/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('toFirestore and fromFirestore round-trip', () async {
      final fakeDb = FakeFirebaseFirestore();
      final user = UserModel(
        uid: 'test-uid',
        displayName: 'Raphael Omorose',
        email: 'r.omorose@student.gsu.edu',
        bio: 'Backend lead',
        courses: ['CSC 4360', 'CSC 4710'],
        availability: {'mon': ['9am', '11am'], 'wed': true},
        createdAt: DateTime(2026, 4, 14),
      );

      await fakeDb.collection('users').doc(user.uid).set(user.toFirestore());
      final snap = await fakeDb.collection('users').doc(user.uid).get();
      final restored = UserModel.fromFirestore(snap);

      expect(restored.uid, equals(user.uid));
      expect(restored.displayName, equals(user.displayName));
      expect(restored.email, equals(user.email));
      expect(restored.bio, equals(user.bio));
      expect(restored.courses, equals(user.courses));
    });

    test('copyWith preserves unchanged fields', () {
      final user = UserModel(
        uid: 'u1',
        displayName: 'Alice',
        email: 'alice@test.edu',
        bio: 'Old bio',
        courses: ['CSC1'],
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = user.copyWith(bio: 'New bio');
      expect(updated.bio, equals('New bio'));
      expect(updated.displayName, equals('Alice'));
      expect(updated.courses, equals(['CSC1']));
      expect(updated.uid, equals('u1'));
    });
  });
}
