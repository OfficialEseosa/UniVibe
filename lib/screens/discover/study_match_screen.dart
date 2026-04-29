import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Study Partners',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          FutureBuilder<UserModel?>(
            future: firestoreService.getUser(uid),
            builder: (context, snap) => IconButton(
              icon: const Icon(Icons.refresh_outlined),
              tooltip: 'Refresh matches',
              onPressed: snap.data != null
                  ? () => matchRepo.refreshSuggestions(snap.data!)
                  : null,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
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
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_outline,
                          size: 40, color: Color(0xFF1A73E8)),
                    ),
                    const SizedBox(height: 20),
                    const Text('Find Your Study Partners',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      'We\'ll match you with students who share your courses and availability.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () async {
                        final user = await firestoreService.getUser(uid);
                        if (user != null && context.mounted) {
                          await matchRepo.refreshSuggestions(user);
                        }
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Find Study Partners',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: matches.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _MatchCard(match: matches[i], currentUid: uid),
          );
        },
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final StudyMatchModel match;
  final String currentUid;

  const _MatchCard({required this.match, required this.currentUid});

  Color _scoreColor(double score) {
    if (score >= 70) return const Color(0xFF4CAF50);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFF1A73E8);
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(match.score);
    final overlapDays = (match.availabilityOverlap.keys.toList());

    return Container(
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
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    const Color(0xFF1A73E8).withValues(alpha: 0.15),
                backgroundImage: match.matchPhotoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(match.matchPhotoUrl)
                    : null,
                child: match.matchPhotoUrl.isEmpty
                    ? Text(
                        match.matchName.isNotEmpty
                            ? match.matchName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Color(0xFF1A73E8),
                            fontWeight: FontWeight.w700,
                            fontSize: 20))
                    : null,
              ),
              // Score badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: scoreColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      match.score.toStringAsFixed(0),
                      style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.matchName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),

                // Score bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: match.score / 100,
                          backgroundColor: Colors.grey.shade200,
                          color: scoreColor,
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${match.score.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scoreColor)),
                  ],
                ),
                const SizedBox(height: 6),

                if (match.sharedCourses.isNotEmpty) ...[
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: match.sharedCourses.take(3).map((c) =>
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(c,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1A73E8))),
                      )
                    ).toList(),
                  ),
                ],

                if (overlapDays.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '📅 Available: ${overlapDays.take(3).join(", ")}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Message button
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor:
                  const Color(0xFF1A73E8).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFF1A73E8),
            ),
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            tooltip: 'Message',
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
          ),
        ],
      ),
    );
  }
}
