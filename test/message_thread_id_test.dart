import 'package:flutter_test/flutter_test.dart';
import 'package:univibe/models/message_model.dart';

void main() {
  group('MessageThreadModel.buildThreadId', () {
    test('produces consistent ID regardless of argument order', () {
      final id1 = MessageThreadModel.buildThreadId('alice', 'bob');
      final id2 = MessageThreadModel.buildThreadId('bob', 'alice');
      expect(id1, equals(id2));
    });

    test('different participants produce different IDs', () {
      final id1 = MessageThreadModel.buildThreadId('alice', 'bob');
      final id2 = MessageThreadModel.buildThreadId('alice', 'charlie');
      expect(id1, isNot(equals(id2)));
    });

    test('thread ID contains both UIDs', () {
      const uid1 = 'user_aaa';
      const uid2 = 'user_bbb';
      final id = MessageThreadModel.buildThreadId(uid1, uid2);
      expect(id.contains(uid1), isTrue);
      expect(id.contains(uid2), isTrue);
    });
  });
}
