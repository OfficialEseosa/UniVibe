import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../models/user_model.dart';
import '../../repositories/post_repository.dart';
import '../../services/firestore_service.dart';
const _tagColors = {
  'general': Color(0xFF6B7280),
  'academics': Color(0xFF1A73E8),
  'events': Color(0xFF9C27B0),
  'sports': Color(0xFF4CAF50),
  'clubs': Color(0xFFFF9800),
  'housing': Color(0xFF795548),
  'jobs': Color(0xFF009688),
};

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment(UserModel author) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    await context.read<PostRepository>().addComment(
          postId: widget.post.postId,
          author: author,
          text: text,
        );
    _commentCtrl.clear();
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final postRepo = context.read<PostRepository>();
    final firestoreService = context.read<FirestoreService>();
    final isLiked = widget.post.likedBy.contains(uid);
    final tagColor =
        _tagColors[widget.post.campusTag] ?? const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Post',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: postRepo.commentsStream(widget.post.postId),
              builder: (context, snap) {
                final comments = snap.data ?? [];
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Post card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                            child: Row(
                              children: [
                                _AuthorAvatar(
                                    photoUrl: widget.post.authorPhotoUrl,
                                    name: widget.post.authorName),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.post.authorName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14)),
                                      Text(
                                          timeago.format(widget.post.createdAt),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        tagColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('#${widget.post.campusTag}',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: tagColor)),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(widget.post.content,
                                style: const TextStyle(
                                    fontSize: 15, height: 1.5)),
                          ),
                          if (widget.post.imageUrl != null) ...[
                            const SizedBox(height: 10),
                            CachedNetworkImage(
                              imageUrl: widget.post.imageUrl!,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                          ],
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(8, 6, 8, 10),
                            child: Row(children: [
                              IconButton(
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints:
                                    const BoxConstraints(minWidth: 36),
                                icon: Icon(
                                  isLiked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border,
                                  color: isLiked
                                      ? Colors.red
                                      : Colors.grey.shade500,
                                ),
                                onPressed: () => postRepo.toggleLike(
                                    widget.post.postId, uid),
                              ),
                              Text('${widget.post.likesCount}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600)),
                            ]),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Comments header
                    if (comments.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                        child: Text('${comments.length} comment${comments.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                      ...comments.map((c) => _CommentTile(
                            comment: c,
                            currentUid: uid,
                            postId: widget.post.postId,
                          )),
                    ] else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Text('No comments yet. Start the conversation!',
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 13)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Comment input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border:
                  Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            padding: EdgeInsets.only(
              left: 14,
              right: 8,
              top: 10,
              bottom:
                  MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            child: FutureBuilder<UserModel?>(
              future: firestoreService.getUser(uid),
              builder: (context, snap) {
                final author = snap.data;
                return Row(
                  children: [
                    if (author != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _AuthorAvatar(
                            photoUrl: author.profilePhotoUrl,
                            name: author.displayName,
                            radius: 17),
                      ),
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.send,
                        onSubmitted: author != null
                            ? (_) => _submitComment(author)
                            : null,
                        decoration: InputDecoration(
                          hintText: 'Write a comment…',
                          hintStyle:
                              TextStyle(color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : Icon(Icons.send_rounded,
                              color: Theme.of(context).colorScheme.primary),
                      onPressed:
                          author == null ? null : () => _submitComment(author),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final String currentUid;
  final String postId;

  const _CommentTile({
    required this.comment,
    required this.currentUid,
    required this.postId,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = comment.likedBy.contains(currentUid);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorAvatar(
              photoUrl: comment.authorPhotoUrl,
              name: comment.authorName,
              radius: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(comment.authorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(timeago.format(comment.createdAt),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.text,
                    style: const TextStyle(fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28),
                icon: Icon(
                  isLiked ? Icons.favorite_rounded : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey.shade400,
                ),
                onPressed: () => context.read<PostRepository>().toggleCommentLike(
                    postId, comment.commentId, currentUid),
              ),
              Text('${comment.likesCount}',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final String photoUrl;
  final String name;
  final double radius;
  const _AuthorAvatar(
      {required this.photoUrl, required this.name, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(photoUrl),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          const Color(0xFF1A73E8).withValues(alpha: 0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Color(0xFF1A73E8), fontWeight: FontWeight.w700),
      ),
    );
  }
}
