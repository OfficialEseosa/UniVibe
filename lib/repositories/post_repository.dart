import 'dart:io';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class PostRepository {
  final FirestoreService _firestore;
  final StorageService _storage;

  PostRepository({
    required FirestoreService firestore,
    required StorageService storage,
  })  : _firestore = firestore,
        _storage = storage;

  Stream<List<PostModel>> feedStream({int limit = 30}) =>
      _firestore.feedStream(limit: limit);

  Future<void> createPost({
    required UserModel author,
    required String content,
    String campusTag = 'general',
    File? image,
  }) async {
    String? imageUrl;
    if (image != null) {
      imageUrl = await _storage.uploadPostImage(author.uid, image);
    }

    final post = PostModel(
      postId: '',
      authorUid: author.uid,
      authorName: author.displayName,
      authorPhotoUrl: author.profilePhotoUrl,
      content: content,
      imageUrl: imageUrl,
      campusTag: campusTag,
      createdAt: DateTime.now(),
    );

    await _firestore.createPost(post);
  }

  Future<void> deletePost(PostModel post) async {
    if (post.imageUrl != null) {
      await _storage.deleteFile(post.imageUrl!);
    }
    await _firestore.deletePost(post.postId);
  }

  Future<void> toggleLike(String postId, String uid) =>
      _firestore.toggleLikePost(postId, uid);

  Stream<List<CommentModel>> commentsStream(String postId) =>
      _firestore.commentsStream(postId);

  Future<void> addComment({
    required String postId,
    required UserModel author,
    required String text,
  }) async {
    final comment = CommentModel(
      commentId: '',
      authorUid: author.uid,
      authorName: author.displayName,
      authorPhotoUrl: author.profilePhotoUrl,
      text: text,
      createdAt: DateTime.now(),
    );
    await _firestore.addComment(postId, comment);
  }

  Future<void> toggleCommentLike(
          String postId, String commentId, String uid) =>
      _firestore.toggleLikeComment(postId, commentId, uid);
}
