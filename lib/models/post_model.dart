import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String authorUid;
  final String authorName;
  final String authorPhotoUrl;
  final String content;
  final String? imageUrl;
  final int likesCount;
  final List<String> likedBy;
  final String campusTag;
  final DateTime createdAt;

  const PostModel({
    required this.postId,
    required this.authorUid,
    required this.authorName,
    this.authorPhotoUrl = '',
    required this.content,
    this.imageUrl,
    this.likesCount = 0,
    this.likedBy = const [],
    this.campusTag = 'general',
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      postId: doc.id,
      authorUid: data['authorUid'] as String,
      authorName: data['authorName'] as String? ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String? ?? '',
      content: data['content'] as String,
      imageUrl: data['imageUrl'] as String?,
      likesCount: data['likesCount'] as int? ?? 0,
      likedBy: List<String>.from(data['likedBy'] as List? ?? []),
      campusTag: data['campusTag'] as String? ?? 'general',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'authorUid': authorUid,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'content': content,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'likesCount': likesCount,
        'likedBy': likedBy,
        'campusTag': campusTag,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  PostModel copyWith({
    int? likesCount,
    List<String>? likedBy,
    String? imageUrl,
  }) =>
      PostModel(
        postId: postId,
        authorUid: authorUid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        content: content,
        imageUrl: imageUrl ?? this.imageUrl,
        likesCount: likesCount ?? this.likesCount,
        likedBy: likedBy ?? this.likedBy,
        campusTag: campusTag,
        createdAt: createdAt,
      );
}
