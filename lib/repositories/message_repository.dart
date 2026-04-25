import '../models/message_model.dart';
import '../services/firestore_service.dart';

class MessageRepository {
  final FirestoreService _firestore;

  MessageRepository({required FirestoreService firestore})
      : _firestore = firestore;

  Stream<List<MessageThreadModel>> threadsStream(String uid) =>
      _firestore.threadsStream(uid);

  Stream<List<MessageModel>> messagesStream(String threadId) =>
      _firestore.messagesStream(threadId);

  Future<void> sendMessage({
    required String senderUid,
    required String recipientUid,
    required String text,
  }) async {
    final threadId = MessageThreadModel.buildThreadId(senderUid, recipientUid);
    final message = MessageModel(
      msgId: '',
      senderUid: senderUid,
      text: text,
      timestamp: DateTime.now(),
      readBy: [senderUid],
    );
    await _firestore.sendMessage(
        threadId, message, [senderUid, recipientUid]);
  }

  Future<void> markRead(String senderUid, String recipientUid) {
    final threadId =
        MessageThreadModel.buildThreadId(senderUid, recipientUid);
    return _firestore.markThreadRead(threadId, senderUid);
  }
}
