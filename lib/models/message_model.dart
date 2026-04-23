import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String msgId;
  final String senderUid;
  final String text;
  final DateTime timestamp;
  final List<String> readBy;

  const MessageModel({
    required this.msgId,
    required this.senderUid,
    required this.text,
    required this.timestamp,
    this.readBy = const [],
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      msgId: doc.id,
      senderUid: data['senderUid'] as String,
      text: data['text'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      readBy: List<String>.from(data['readBy'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderUid': senderUid,
        'text': text,
        'timestamp': Timestamp.fromDate(timestamp),
        'readBy': readBy,
      };
}

class MessageThreadModel {
  final String threadId;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageAt;
  final Map<String, int> unreadCount;

  const MessageThreadModel({
    required this.threadId,
    required this.participants,
    this.lastMessage = '',
    required this.lastMessageAt,
    this.unreadCount = const {},
  });

  factory MessageThreadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageThreadModel(
      threadId: doc.id,
      participants: List<String>.from(data['participants'] as List),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp).toDate(),
      unreadCount: Map<String, int>.from(
          (data['unreadCount'] as Map?)?.map(
                (k, v) => MapEntry(k as String, (v as num).toInt()),
              ) ??
              {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'participants': participants,
        'lastMessage': lastMessage,
        'lastMessageAt': Timestamp.fromDate(lastMessageAt),
        'unreadCount': unreadCount,
      };

  static String buildThreadId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
