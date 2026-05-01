import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/study_match_model.dart';
import '../../models/user_model.dart';
import '../../repositories/study_match_repository.dart';
import '../../services/firestore_service.dart';
import '../messages/chat_screen.dart';

class StudyMatchScreen extends StatelessWidget {
  const StudyMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final matchRepo = context.read<StudyMatchRepository>();
    final firestoreService = context.read<FirestoreService>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Partners'),
        centerTitle: false,
        actions: [
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
      body: StreamBuilder<List<StudyMatchModel>>(
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
                  Icon(
                    Icons.people_alt_outlined,
                    size: 64,
                    color: cs.primary.withAlpha(120),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No study partners yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap below to discover your top matches.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      final user = await firestoreService.getUser(uid);
                      if (user != null && context.mounted) {
                        await matchRepo.refreshSuggestions(user);
                      }
                    },
                    child: const Text('Find Study Partners'),
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

    return Card(
      elevation: 0,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MatchAvatar(
                  name: match.matchName,
                  photoUrl: match.matchPhotoUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.matchName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _scoreColor(score, cs).withAlpha(35),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${score.toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: _scoreColor(score, cs),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${match.sharedCourses.length} shared courses',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
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
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          course,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    )
                    .toList(),
              )
            else
              Text(
                'No shared courses listed yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      currentUid: currentUid,
                      recipientUid: match.matchUid,
                      recipientName: match.matchName,
                    ),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Message'),
              ),
            ),
          ],
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
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: cs.primaryContainer,
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              )
            : Container(
                color: cs.primaryContainer,
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
      ),
    );
  }
}
