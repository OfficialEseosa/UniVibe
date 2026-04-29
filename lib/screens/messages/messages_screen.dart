import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../repositories/message_repository.dart';
import '../../services/firestore_service.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final repo = context.read<MessageRepository>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Messages',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: StreamBuilder<List<MessageThreadModel>>(
        stream: repo.threadsStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final threads = snap.data ?? [];
          if (threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No conversations yet.',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Connect with a study partner to start chatting!',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: threads.length,
            separatorBuilder: (context, index) =>
                Divider(indent: 76, height: 1, color: Colors.grey.shade100),
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

    return FutureBuilder<UserModel?>(
      future: firestore.getUser(recipientUid),
      builder: (context, snap) {
        final recipient = snap.data;
        final name = recipient?.displayName ?? '…';
        final photoUrl = recipient?.profilePhotoUrl ?? '';

        return ListTile(
          tileColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    const Color(0xFF1A73E8).withValues(alpha: 0.15),
                backgroundImage: photoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(photoUrl)
                    : null,
                child: photoUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: Color(0xFF1A73E8),
                            fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              if (unread > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight:
                  unread > 0 ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            thread.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: unread > 0
                  ? Colors.grey.shade700
                  : Colors.grey.shade500,
              fontWeight:
                  unread > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          trailing: Text(
            timeago.format(thread.lastMessageAt, allowFromNow: true),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
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
        );
      },
    );
  }
}
