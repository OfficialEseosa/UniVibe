import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
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
      appBar: AppBar(title: const Text('Messages'), centerTitle: true),
      body: StreamBuilder<List<MessageThreadModel>>(
        stream: repo.threadsStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final threads = snap.data ?? [];
          if (threads.isEmpty) {
            return const Center(child: Text('No conversations yet.'));
          }
          return ListView.builder(
            itemCount: threads.length,
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
        final name = recipient?.displayName ?? recipientUid;
        final photoUrl = recipient?.profilePhotoUrl ?? '';

        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            child: photoUrl.isEmpty
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                : null,
          ),
          title: Text(name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            thread.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: unread > 0
              ? CircleAvatar(
                  radius: 10,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    '$unread',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                )
              : null,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                currentUid: currentUid,
                recipientUid: recipientUid,
                recipientName: name,
              ),
            ),
          ),
        );
      },
    );
  }
}
