import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/message_model.dart';
import '../../repositories/message_repository.dart';
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
              final recipientUid =
                  thread.participants.firstWhere((p) => p != uid,
                      orElse: () => uid);
              final unread = thread.unreadCount[uid] ?? 0;

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(recipientUid),
                subtitle: Text(
                  thread.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: unread > 0
                    ? CircleAvatar(
                        radius: 10,
                        child: Text('$unread',
                            style: const TextStyle(fontSize: 10)),
                      )
                    : null,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      currentUid: uid,
                      recipientUid: recipientUid,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
