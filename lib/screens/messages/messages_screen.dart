import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../repositories/message_repository.dart';
import '../../services/firestore_service.dart';
import 'chat_screen.dart';
import 'new_conversation_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final repo = context.read<MessageRepository>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('New'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NewConversationScreen(currentUid: uid),
          ),
        ),
      ),
      body: StreamBuilder<UserModel>(
        stream: context.read<FirestoreService>().userStream(uid),
        builder: (context, meSnap) {
          final blocked = meSnap.data?.blockedUsers.toSet() ?? <String>{};
          return StreamBuilder<List<MessageThreadModel>>(
        stream: repo.threadsStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allThreads = snap.data ?? [];
          // Hide threads where the only other participant is blocked.
          final threads = allThreads.where((t) {
            final other = t.participants.firstWhere(
              (p) => p != uid,
              orElse: () => uid,
            );
            return !blocked.contains(other);
          }).toList();
          if (threads.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: cs.primaryContainer,
                      child: Icon(
                        Icons.chat_outlined,
                        color: cs.primary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No conversations yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start chatting with a study partner to begin conversations.',
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
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            itemCount: threads.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 68,
              endIndent: 16,
              color: cs.outlineVariant,
            ),
            itemBuilder: (context, i) {
              final thread = threads[i];
              final recipientUid = thread.participants
                  .firstWhere((p) => p != uid, orElse: () => uid);
              final unread = thread.unreadCount[uid] ?? 0;

              return _ThreadTile(
                thread: thread,
                currentUid: uid,
                recipientUid: recipientUid,
                unread: unread,
              );
            },
          );
        },
      );
        },
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final MessageThreadModel thread;
  final String currentUid;
  final String recipientUid;
  final int unread;

  const _ThreadTile({
    required this.thread,
    required this.currentUid,
    required this.recipientUid,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<UserModel?>(
      future: firestore.getUser(recipientUid),
      builder: (context, snap) {
        final recipient = snap.data;
        final name = recipient?.displayName ?? recipientUid;
        final photoUrl = recipient?.profilePhotoUrl ?? '';

        return Material(
          color: unread > 0 ? cs.primaryContainer.withValues(alpha: 0.3) : null,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  currentUid: currentUid,
                  recipientUid: recipientUid,
                  recipientName: name,
                  recipientPhotoUrl: photoUrl,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: photoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(photoUrl)
                        : null,
                    child: photoUrl.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Message info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: unread > 0
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(thread.lastMessageAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                thread.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: unread > 0
                                          ? cs.onSurface
                                          : cs.onSurfaceVariant,
                                      fontWeight: unread > 0
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                    ),
                              ),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius:
                                      BorderRadius.circular(999),
                                ),
                                child: Text(
                                  unread > 99 ? '99+' : '$unread',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: cs.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (date == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
