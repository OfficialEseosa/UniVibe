import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/study_match_model.dart';
import '../../models/user_model.dart';
import '../../repositories/study_match_repository.dart';
import '../../services/firestore_service.dart';
import '../messages/chat_screen.dart';
import '../profile/public_profile_screen.dart';

/// Two-tab Discover experience:
///   - **Browse** lists every user with `discoverStatus == 'public'` (legacy
///     users with no field default to public). Excludes blocked users.
///   - **Smart Matches** keeps the original ML-style suggestions list.
class StudyMatchScreen extends StatefulWidget {
  const StudyMatchScreen({super.key});

  @override
  State<StudyMatchScreen> createState() => _StudyMatchScreenState();
}

class _StudyMatchScreenState extends State<StudyMatchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestoreService = context.read<FirestoreService>();
    final matchRepo = context.read<StudyMatchRepository>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabs,
          labelColor: cs.primary,
          indicatorColor: cs.primary,
          tabs: const [
            Tab(icon: Icon(Icons.explore_rounded), text: 'Browse'),
            Tab(icon: Icon(Icons.auto_awesome_rounded), text: 'Smart Matches'),
          ],
        ),
        actions: [
          if (_tabs.index == 1)
            FutureBuilder<UserModel?>(
              future: firestoreService.getUser(uid),
              builder: (context, snap) => IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh matches',
                onPressed: snap.data != null
                    ? () => matchRepo.refreshSuggestions(snap.data!)
                    : null,
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildBrowse(context, uid, firestoreService),
          _buildSmartMatches(context, uid, firestoreService, matchRepo),
        ],
      ),
    );
  }

  Widget _buildBrowse(
      BuildContext context, String currentUid, FirestoreService firestore) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<UserModel>(
      stream: firestore.userStream(currentUid),
      builder: (context, meSnap) {
        final me = meSnap.data;
        final blocked = me?.blockedUsers.toSet() ?? <String>{};

        return StreamBuilder<List<UserModel>>(
          stream: firestore.allUsersStream(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snap.data!;
            final users = all.where((u) {
              if (u.uid == currentUid) return false;
              if (!u.isDiscoverable) return false;
              if (blocked.contains(u.uid)) return false;
              if (_query.isEmpty) return true;
              final q = _query.toLowerCase();
              return u.displayName.toLowerCase().contains(q) ||
                  u.courses.any((c) => c.toLowerCase().contains(q)) ||
                  u.bio.toLowerCase().contains(q);
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name, course, or bio…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      isDense: true,
                    ),
                  ),
                ),
                if (users.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.travel_explore_rounded,
                                size: 64, color: cs.primary.withValues(alpha: 0.45)),
                            const SizedBox(height: 12),
                            Text('No one to show yet',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              _query.isEmpty
                                  ? 'When classmates join UniVibe with a public profile, they\'ll show up here.'
                                  : 'No public profiles match "$_query".',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) =>
                          _UserBrowseTile(user: users[i], currentUid: currentUid),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSmartMatches(
    BuildContext context,
    String uid,
    FirestoreService firestoreService,
    StudyMatchRepository matchRepo,
  ) {
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<List<StudyMatchModel>>(
      stream: matchRepo.suggestionsStream(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final matches = snap.data ?? [];
        if (matches.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 64, color: cs.primary.withValues(alpha: 0.45)),
                const SizedBox(height: 14),
                Text('No study partners yet',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Tap below to discover your top matches.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.bolt_rounded),
                  label: const Text('Find Study Partners'),
                  onPressed: () async {
                    final user = await firestoreService.getUser(uid);
                    if (user != null && context.mounted) {
                      await matchRepo.refreshSuggestions(user);
                    }
                  },
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          itemCount: matches.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, i) =>
              _MatchTile(match: matches[i], currentUid: uid),
        );
      },
    );
  }
}

class _UserBrowseTile extends StatelessWidget {
  final UserModel user;
  final String currentUid;
  const _UserBrowseTile({required this.user, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial =
        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(uid: user.uid),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [cs.primary, const Color(0xFF7B61FF)],
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: user.profilePhotoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.profilePhotoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: cs.primaryContainer,
                            alignment: Alignment.center,
                            child: Text(initial,
                                style: TextStyle(
                                    color: cs.onPrimaryContainer,
                                    fontWeight: FontWeight.w700)),
                          ),
                        )
                      : Container(
                          color: cs.primaryContainer,
                          alignment: Alignment.center,
                          child: Text(initial,
                              style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22)),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (user.courses.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: user.courses
                            .take(3)
                            .map((c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(c,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onPrimaryContainer)),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final StudyMatchModel match;
  final String currentUid;

  const _MatchTile({required this.match, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = match.score.clamp(0, 100).toDouble();
    final scoreFraction = score / 100;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(uid: match.matchUid),
        ),
      ),
      child: Card(
        elevation: 0,
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MatchAvatar(
                      name: match.matchName, photoUrl: match.matchPhotoUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.matchName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _scoreColor(score, cs).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${score.toStringAsFixed(0)}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: _scoreColor(score, cs),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${match.sharedCourses.length} shared courses',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: scoreFraction,
                  color: _scoreColor(score, cs),
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 12),
              if (match.sharedCourses.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: match.sharedCourses
                      .take(4)
                      .map(
                        (course) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            course,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PublicProfileScreen(uid: match.matchUid),
                      ),
                    ),
                    icon: const Icon(Icons.person_outline_rounded),
                    label: const Text('View'),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          currentUid: currentUid,
                          recipientUid: match.matchUid,
                          recipientName: match.matchName,
                          recipientPhotoUrl: match.matchPhotoUrl,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Message'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor(double score, ColorScheme cs) {
    if (score >= 80) return const Color(0xFF2E7D32);
    if (score >= 60) return const Color(0xFF1565C0);
    if (score >= 40) return const Color(0xFFEF6C00);
    return cs.error;
  }
}

class _MatchAvatar extends StatelessWidget {
  final String name;
  final String photoUrl;
  const _MatchAvatar({required this.name, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return SizedBox(
      width: 54,
      height: 54,
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: cs.surfaceContainerHighest,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.primary),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: cs.primaryContainer,
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer,
                      )),
                ),
              )
            : Container(
                color: cs.primaryContainer,
                alignment: Alignment.center,
                child: Text(initial,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer,
                    )),
              ),
      ),
    );
  }
}
