import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('UniVibe',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Color(0xFF1A73E8))),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ),
        icon: const Icon(Icons.edit_outlined),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dynamic_feed_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No posts yet.',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Be the first to post something!',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _PostCard(post: posts[i], currentUid: uid),
          );
        },
      ),
    );
  }
}

// Campus tag colors
const _tagColors = {
  'general': Color(0xFF6B7280),
  'academics': Color(0xFF1A73E8),
  'events': Color(0xFF9C27B0),
  'sports': Color(0xFF4CAF50),
  'clubs': Color(0xFFFF9800),
  'housing': Color(0xFF795548),
  'jobs': Color(0xFF009688),
};

class _PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUid;

  const _PostCard({required this.post, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PostRepository>();
    final isLiked = post.likedBy.contains(currentUid);
    final tagColor = _tagColors[post.campusTag] ?? const Color(0xFF6B7280);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
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
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  _Avatar(photoUrl: post.authorPhotoUrl, name: post.authorName, radius: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.authorName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(timeago.format(post.createdAt),
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#${post.campusTag}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tagColor),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(post.content,
                  style: const TextStyle(fontSize: 14, height: 1.5)),
            ),

            // Image
            if (post.imageUrl != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(0)),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                      height: 200, color: Colors.grey.shade100),
                  errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: Colors.grey.shade100,
                      child:
                          const Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ],

            // Action row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36),
                    icon: Icon(
                      isLiked ? Icons.favorite_rounded : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey.shade500,
                    ),
                    onPressed: () =>
                        repo.toggleLike(post.postId, currentUid),
                  ),
                  Text('${post.likesCount}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(width: 12),
                  Icon(Icons.chat_bubble_outline,
                      size: 18, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text('Comment',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String photoUrl;
  final String name;
  final double radius;
  const _Avatar(
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
      backgroundColor: const Color(0xFF1A73E8).withValues(alpha: 0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Color(0xFF1A73E8), fontWeight: FontWeight.w700),
      ),
    );
  }
}
