import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../models/user_model.dart';
import '../../repositories/post_repository.dart';
import '../../services/firestore_service.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
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

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: postRepo.commentsStream(widget.post.postId),
              builder: (context, snap) {
                final comments = snap.data ?? [];
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Post body
                    Text(widget.post.authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.post.content),
                    if (widget.post.imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Image.network(widget.post.imageUrl!),
                      ),
                    Row(children: [
                      IconButton(
                        icon: Icon(
                          widget.post.likedBy.contains(uid)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.post.likedBy.contains(uid)
                              ? Colors.red
                              : null,
                        ),
                        onPressed: () =>
                            postRepo.toggleLike(widget.post.postId, uid),
                      ),
                      Text('${widget.post.likesCount}'),
                    ]),
                    const Divider(),
                    // Comments
                    ...comments.map(
                      (c) => ListTile(
                        leading: CircleAvatar(
                          backgroundImage: c.authorPhotoUrl.isNotEmpty
                              ? NetworkImage(c.authorPhotoUrl)
                              : null,
                          child: c.authorPhotoUrl.isEmpty
                              ? Text(c.authorName[0].toUpperCase())
                              : null,
                        ),
                        title: Text(c.authorName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(c.text),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            iconSize: 18,
                            icon: Icon(
                              c.likedBy.contains(uid)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  c.likedBy.contains(uid) ? Colors.red : null,
                            ),
                            onPressed: () => postRepo.toggleCommentLike(
                                widget.post.postId, c.commentId, uid),
                          ),
                          Text('${c.likesCount}',
                              style: const TextStyle(fontSize: 12)),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Comment input
          FutureBuilder<UserModel?>(
            future: firestoreService.getUser(uid),
            builder: (context, snap) {
              final author = snap.data;
              return Padding(
                padding: EdgeInsets.only(
                  left: 12, right: 8, bottom:
                    MediaQuery.of(context).viewInsets.bottom + 8, top: 8),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _submitting
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    onPressed: author == null ? null : () => _submitComment(author),
                  ),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }
}
