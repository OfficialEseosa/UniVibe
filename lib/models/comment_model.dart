import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String commentId;
  final String authorUid;
  final String authorName;
  final String authorPhotoUrl;
  final String text;
  final int likesCount;
  final List<String> likedBy;
  final DateTime createdAt;

  const CommentModel({
    required this.commentId,
    required this.authorUid,
    required this.authorName,
    this.authorPhotoUrl = '',
    required this.text,
    this.likesCount = 0,
    this.likedBy = const [],
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      commentId: doc.id,
      authorUid: data['authorUid'] as String,
      authorName: data['authorName'] as String? ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String? ?? '',
      text: data['text'] as String,
      likesCount: data['likesCount'] as int? ?? 0,
      likedBy: List<String>.from(data['likedBy'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorUid': authorUid,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'text': text,
        'likesCount': likesCount,
        'likedBy': likedBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
