import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'chat_screen.dart';

/// User picker for starting a brand-new direct message conversation.
/// Shows every user except the current user and anyone the current user
/// has blocked. Includes a quick search by name/email.
class NewConversationScreen extends StatefulWidget {
  final String currentUid;
  const NewConversationScreen({super.key, required this.currentUid});

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
        centerTitle: false,
      ),
      body: StreamBuilder<UserModel>(
        stream: firestore.userStream(widget.currentUid),
        builder: (context, meSnap) {
          final blocked = meSnap.data?.blockedUsers.toSet() ?? <String>{};
          return StreamBuilder<List<UserModel>>(
            stream: firestore.allUsersStream(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final users = snap.data!.where((u) {
                if (u.uid == widget.currentUid) return false;
                if (blocked.contains(u.uid)) return false;
                if (_query.isEmpty) return true;
                final q = _query.toLowerCase();
                return u.displayName.toLowerCase().contains(q) ||
                    u.email.toLowerCase().contains(q);
              }).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: TextField(
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                        hintText: 'Search people…',
                        prefixIcon: Icon(Icons.search_rounded),
                        contentPadding: EdgeInsets.symmetric(
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
                              Icon(Icons.person_search_rounded,
                                  size: 56,
                                  color: cs.primary.withValues(alpha: 0.45)),
                              const SizedBox(height: 12),
                              Text(
                                _query.isEmpty
                                    ? 'No one to message yet'
                                    : 'No matches for "$_query"',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 72,
                          color: cs.outlineVariant,
                        ),
                        itemBuilder: (context, i) {
                          final u = users[i];
                          final initial = u.displayName.isNotEmpty
                              ? u.displayName[0].toUpperCase()
                              : '?';
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: cs.primaryContainer,
                              backgroundImage: u.profilePhotoUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      u.profilePhotoUrl)
                                  : null,
                              child: u.profilePhotoUrl.isEmpty
                                  ? Text(initial,
                                      style: TextStyle(
                                          color: cs.onPrimaryContainer,
                                          fontWeight: FontWeight.w700))
                                  : null,
                            ),
                            title: Text(u.displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              u.bio.isNotEmpty ? u.bio : u.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                            trailing: Icon(Icons.chat_bubble_outline_rounded,
                                color: cs.primary, size: 20),
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    currentUid: widget.currentUid,
                                    recipientUid: u.uid,
                                    recipientName: u.displayName,
                                    recipientPhotoUrl: u.profilePhotoUrl,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
