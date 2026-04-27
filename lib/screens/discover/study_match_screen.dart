import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Partners'),
        centerTitle: true,
        actions: [
          FutureBuilder<UserModel?>(
            future: firestoreService.getUser(uid),
            builder: (context, snap) => IconButton(
              icon: const Icon(Icons.refresh),
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
                  const Text('No matches yet.'),
                  const SizedBox(height: 12),
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
            padding: const EdgeInsets.all(12),
            itemCount: matches.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
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
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: match.matchPhotoUrl.isNotEmpty
            ? NetworkImage(match.matchPhotoUrl)
            : null,
        child: match.matchPhotoUrl.isEmpty
            ? Text(match.matchName.isNotEmpty
                ? match.matchName[0].toUpperCase()
                : '?')
            : null,
      ),
      title: Text(match.matchName),
      subtitle: match.sharedCourses.isNotEmpty
          ? Text('Shared: ${match.sharedCourses.take(3).join(', ')}')
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${match.score.toStringAsFixed(0)} pts',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              )),
          Text('${match.sharedCourses.length} courses',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            currentUid: currentUid,
            recipientUid: match.matchUid,
          ),
        ),
      ),
    );
  }
}
