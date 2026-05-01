import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
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
    final cs = Theme.of(context).colorScheme;

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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  children: [
                    // ── Full post card ────────────────────────────────────
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 21,
                                  backgroundColor: cs.primaryContainer,
                                  backgroundImage:
                                      widget.post.authorPhotoUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              widget.post.authorPhotoUrl)
                                          : null,
                                  child: widget.post.authorPhotoUrl.isEmpty
                                      ? Text(
                                          _avatarInitial(
                                              widget.post.authorName),
                                          style: TextStyle(
                                            color: cs.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.post.authorName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        timeago.format(widget.post.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _tagColor(widget.post.campusTag)
                                        .withValues(alpha: 0.14),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _formatTag(widget.post.campusTag),
                                    style: TextStyle(
                                      color: _tagColor(
                                          widget.post.campusTag),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.post.content,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            if (widget.post.imageUrl != null &&
                                widget.post.imageUrl!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: CachedNetworkImage(
                                  imageUrl: widget.post.imageUrl!,
                                  width: double.infinity,
                                  height: 240,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    height: 240,
                                    color: cs.surfaceContainerHighest,
                                    alignment: Alignment.center,
                                    child:
                                        const CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    height: 240,
                                    color: cs.surfaceContainerHighest,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                InkWell(
                                  borderRadius:
                                      BorderRadius.circular(999),
                                  onTap: () => postRepo.toggleLike(
                                      widget.post.postId, uid),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          widget.post.likedBy
                                                  .contains(uid)
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: widget.post.likedBy
                                                  .contains(uid)
                                              ? Colors.red
                                              : cs.onSurfaceVariant,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${widget.post.likesCount}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Comments heading ──────────────────────────────────
                    Text(
                      'Comments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),

                    // ── Comment list ──────────────────────────────────────
                    if (comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'No comments yet. Be the first!',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      )
                    else
                      ...comments.map((c) {
                        final commentLiked = c.likedBy.contains(uid);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          cs.primaryContainer,
                                      backgroundImage: c
                                              .authorPhotoUrl.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              c.authorPhotoUrl)
                                          : null,
                                      child: c.authorPhotoUrl.isEmpty
                                          ? Text(
                                              c.authorName.isNotEmpty
                                                  ? c.authorName[0]
                                                      .toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                color: cs.primary,
                                                fontWeight:
                                                    FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.authorName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            timeago.format(c.createdAt),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color:
                                                      cs.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      onTap: () => postRepo
                                          .toggleCommentLike(
                                              widget.post.postId,
                                              c.commentId,
                                              uid),
                                      child: Padding(
                                        padding: const EdgeInsets
                                            .symmetric(
                                          horizontal: 4,
                                          vertical: 6,
                                        ),
                                        child: Row(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                            Icon(
                                              commentLiked
                                                  ? Icons.favorite
                                                  : Icons
                                                      .favorite_border,
                                              color: commentLiked
                                                  ? Colors.red
                                                  : cs.onSurfaceVariant,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${c.likesCount}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  c.text,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
            ),
          ),

          // ── Comment input bar ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: FutureBuilder<UserModel?>(
              future: firestoreService.getUser(uid),
              builder: (context, snap) {
                final author = snap.data;
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    8,
                    8,
                    MediaQuery.of(context).viewInsets.bottom + 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentCtrl,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (text) =>
                              author == null ? null : _submitComment(author),
                          decoration: InputDecoration(
                            hintText: 'Add a comment…',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.send_rounded,
                                  size: 20,
                                  color: author == null
                                      ? cs.onSurfaceVariant
                                      : cs.primary,
                                ),
                          onPressed: author == null
                              ? null
                              : () => _submitComment(author),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _avatarInitial(String name) {
    if (name.trim().isEmpty) return '?';
    return name.trim()[0].toUpperCase();
  }

  String _formatTag(String rawTag) {
    if (rawTag.isEmpty) return 'General';
    final normalized = rawTag.trim().toLowerCase();
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  Color _tagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'academics':
        return const Color(0xFF1565C0);
      case 'events':
        return const Color(0xFF2E7D32);
      case 'sports':
        return const Color(0xFFEF6C00);
      case 'clubs':
        return const Color(0xFF6A1B9A);
      case 'housing':
        return const Color(0xFF00838F);
      case 'jobs':
        return const Color(0xFF8D6E63);
      default:
        return const Color(0xFF1A73E8);
    }
  }
}
