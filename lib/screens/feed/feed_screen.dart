import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
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
      appBar: AppBar(title: const Text('UniVibe'), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ),
        child: const Icon(Icons.add),
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
            return const Center(child: Text('No posts yet. Be the first!'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
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

class _PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUid;

  const _PostCard({required this.post, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PostRepository>();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(post: post),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: post.authorPhotoUrl.isNotEmpty
                    ? NetworkImage(post.authorPhotoUrl)
                    : null,
                child: post.authorPhotoUrl.isEmpty
                    ? Text(post.authorName[0].toUpperCase())
                    : null,
              ),
              title: Text(post.authorName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(post.campusTag),
            ),
            if (post.imageUrl != null)
              Image.network(post.imageUrl!,
                  width: double.infinity, height: 200, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(post.content),
            ),
            OverflowBar(
              children: [
                IconButton(
                  icon: Icon(
                    post.likedBy.contains(currentUid)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: post.likedBy.contains(currentUid) ? Colors.red : null,
                  ),
                  onPressed: () => repo.toggleLike(post.postId, currentUid),
                ),
                Text('${post.likesCount}'),
                const SizedBox(width: 8),
                const Icon(Icons.comment_outlined, size: 20),
                const SizedBox(width: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
