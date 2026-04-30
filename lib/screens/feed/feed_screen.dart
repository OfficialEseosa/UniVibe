import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post_model.dart';
import '../../repositories/post_repository.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final repo = context.read<PostRepository>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UniVibe'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 2,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Post'),
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: repo.feedStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final posts = snap.data ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: cs.primaryContainer,
                      child: Icon(
                        Icons.forum_outlined,
                        color: cs.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No posts yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Be the first to share what is happening on campus.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _PostCard(post: posts[i], currentUid: uid),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUid;

  const _PostCard({required this.post, required this.currentUid});
  @override
  Widget build(BuildContext context) {
    final repo = context.read<PostRepository>();
    final cs = Theme.of(context).colorScheme;
    final liked = post.likedBy.contains(currentUid);
    final tagColor = _tagColor(post.campusTag);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(post: post),
          ),
        ),
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
                    backgroundImage: post.authorPhotoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(post.authorPhotoUrl)
                        : null,
                    child: post.authorPhotoUrl.isEmpty
                        ? Text(
                            _avatarInitial(post.authorName),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeago.format(post.createdAt),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _formatTag(post.campusTag),
                      style: TextStyle(
                        color: tagColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 220,
                      color: cs.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 220,
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
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => repo.toggleLike(post.postId, currentUid),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            color: liked ? Colors.red : cs.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.likesCount}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(post.postId)
                        .collection('comments')
                        .snapshots(),
                    builder: (context, snap) {
                      final commentsCount = snap.data?.docs.length ?? 0;
                      return Row(
                        children: [
                          Icon(
                            Icons.mode_comment_outlined,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$commentsCount',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
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
