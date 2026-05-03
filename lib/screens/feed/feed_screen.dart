import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../repositories/post_repository.dart';
import '../../services/firestore_service.dart';
import '../profile/public_profile_screen.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final repo = context.read<PostRepository>();
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        toolbarHeight: 56,
        title: const Text('UniVibe'),
        actions: [
          StreamBuilder<UserModel>(
            stream: firestore.userStream(uid),
            builder: (context, snap) {
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const CreatePostScreen()),
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Post',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
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
            return _EmptyFeed(onPost: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreatePostScreen()),
            ));
          }
          return ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _PostCard(
              post: posts[i],
              currentUid: uid,
              animationDelay: Duration(milliseconds: i * 55),
            ),
          );
        },
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyFeed extends StatelessWidget {
  final VoidCallback onPost;
  const _EmptyFeed({required this.onPost});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, const Color(0xFF7B61FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.forum_rounded,
                  color: Colors.white, size: 52),
            ),
            const SizedBox(height: 22),
            const Text('Campus is quiet…',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Be the first to share what\'s happening on campus!',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onPost,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Create a Post'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Post card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUid;
  final Duration animationDelay;

  const _PostCard({
    required this.post,
    required this.currentUid,
    this.animationDelay = Duration.zero,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _likeAnimating = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.animationDelay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: _buildCard(context)),
    );
  }

  Widget _buildCard(BuildContext context) {
    final repo = context.read<PostRepository>();
    final firestore = context.read<FirestoreService>();
    final post = widget.post;
    final cs = Theme.of(context).colorScheme;
    final liked = post.likedBy.contains(widget.currentUid);
    final isAuthor = post.authorUid == widget.currentUid;
    final tagColor = _tagColor(post.campusTag);

    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PostDetailScreen(post: post))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _openProfile(context, post.authorUid),
                    child: _AuthorAvatar(
                      uid: post.authorUid,
                      cachedUrl: post.authorPhotoUrl,
                      name: post.authorName,
                      firestore: firestore,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              _openProfile(context, post.authorUid),
                          child: Text(
                            post.authorName,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              timeago.format(post.createdAt),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(width: 5),
                            Icon(Icons.public_rounded,
                                size: 12, color: cs.onSurfaceVariant),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _formatTag(post.campusTag),
                      style: TextStyle(
                        color: tagColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isAuthor)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded,
                          color: cs.onSurfaceVariant),
                      onSelected: (v) async {
                        if (v == 'delete') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete post?'),
                              content: const Text(
                                  'This cannot be undone.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel')),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(true),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: cs.error),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true && context.mounted) {
                            repo.deletePost(post);
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline_rounded,
                                color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete post',
                                style: TextStyle(color: Colors.red)),
                          ]),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Text(
                post.content,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),

            // ── Image ────────────────────────────────────────────────────────
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 260,
                    color: const Color(0xFFF0F2F5),
                    child: const Center(
                        child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 100,
                    color: const Color(0xFFF0F2F5),
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),

            // ── Counts ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  if (post.likesCount > 0) ...[
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite,
                          color: Colors.white, size: 12),
                    ),
                    const SizedBox(width: 5),
                    Text('${post.likesCount}',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13)),
                  ],
                  const Spacer(),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(post.postId)
                        .collection('comments')
                        .snapshots(),
                    builder: (context, snap) {
                      final c = snap.data?.docs.length ?? 0;
                      if (c == 0) return const SizedBox.shrink();
                      return Text(
                        '$c comment${c == 1 ? '' : 's'}',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Divider ──────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Divider(height: 1, color: Color(0xFFE4E6EB)),
            ),

            // ── Actions ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Row(
                children: [
                  _ActionBtn(
                    icon: liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    label: 'Like',
                    color: liked ? Colors.red : const Color(0xFF65676B),
                    animating: _likeAnimating,
                    onTap: () async {
                      setState(() => _likeAnimating = true);
                      await repo.toggleLike(
                          post.postId, widget.currentUid);
                      if (mounted) {
                        setState(() => _likeAnimating = false);
                      }
                    },
                  ),
                  _ActionBtn(
                    icon: Icons.mode_comment_outlined,
                    label: 'Comment',
                    color: const Color(0xFF65676B),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(
                          post: post,
                          autoFocusComment: true,
                        ),
                      ),
                    ),
                  ),
                  _ActionBtn(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: const Color(0xFF65676B),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProfile(BuildContext context, String uid) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid == myUid) return; // don't navigate to own profile from feed
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicProfileScreen(uid: uid)),
    );
  }

  String _formatTag(String rawTag) {
    if (rawTag.trim().isEmpty) return 'General';
    final n = rawTag.trim().toLowerCase();
    return n[0].toUpperCase() + n.substring(1);
  }

  Color _tagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'academics': return const Color(0xFF1565C0);
      case 'events':    return const Color(0xFF2E7D32);
      case 'sports':    return const Color(0xFFEF6C00);
      case 'clubs':     return const Color(0xFF6A1B9A);
      case 'housing':   return const Color(0xFF00838F);
      case 'jobs':      return const Color(0xFF8D6E63);
      default:          return const Color(0xFF1A73E8);
    }
  }
}

// ── Author avatar (always fetches live photo) ─────────────────────────────────

class _AuthorAvatar extends StatelessWidget {
  final String uid;
  final String cachedUrl;
  final String name;
  final FirestoreService firestore;

  const _AuthorAvatar({
    required this.uid,
    required this.cachedUrl,
    required this.name,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return FutureBuilder<UserModel?>(
      future: firestore.getUser(uid),
      builder: (context, snap) {
        final photoUrl = snap.data?.profilePhotoUrl ?? cachedUrl;
        return CircleAvatar(
          radius: 22,
          backgroundColor: cs.primaryContainer,
          backgroundImage: photoUrl.isNotEmpty
              ? CachedNetworkImageProvider(photoUrl)
              : null,
          child: photoUrl.isEmpty
              ? Text(initial,
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ))
              : null,
        );
      },
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool animating;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.animating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: animating ? 1.4 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.elasticOut,
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
