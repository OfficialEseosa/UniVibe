import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../messages/chat_screen.dart';

/// Read-only profile view for OTHER users — reachable from Discover,
/// study matches, or the messages screen. Provides "Message" + "Block" CTAs.
class PublicProfileScreen extends StatelessWidget {
  final String uid;
  const PublicProfileScreen({super.key, required this.uid});

  static const _dayOrder = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const _dayLabels = {
    'mon': 'Mon', 'tue': 'Tue', 'wed': 'Wed', 'thu': 'Thu',
    'fri': 'Fri', 'sat': 'Sat', 'sun': 'Sun',
  };
  static const _slotLabels = {
    'morning': 'Morning',
    'afternoon': 'Afternoon',
    'evening': 'Evening',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final firestore = context.read<FirestoreService>();
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final isMe = currentUid == uid;

    return Scaffold(
      body: StreamBuilder<UserModel>(
        stream: firestore.userStream(uid),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snap.data!;
          final initial =
              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                actions: [
                  if (!isMe)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      onSelected: (value) =>
                          _handleMenu(context, value, firestore, currentUid),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'block',
                          child: Row(children: [
                            Icon(Icons.block_rounded),
                            SizedBox(width: 10),
                            Text('Block user'),
                          ]),
                        ),
                      ],
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [cs.primary, const Color(0xFF7B61FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 24,
                        right: 24,
                        child: Row(
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: user.profilePhotoUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: user.profilePhotoUrl,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: cs.primaryContainer,
                                        alignment: Alignment.center,
                                        child: Text(
                                          initial,
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w700,
                                            color: cs.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (!isMe)
                      FilledButton.icon(
                        icon: const Icon(Icons.chat_bubble_rounded),
                        label: const Text('Send Message'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: cs.primary,
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              currentUid: currentUid,
                              recipientUid: user.uid,
                              recipientName: user.displayName,
                              recipientPhotoUrl: user.profilePhotoUrl,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    if (user.bio.isNotEmpty) ...[
                      _SectionHeader(icon: Icons.info_outline, label: 'About'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Text(user.bio,
                            style: const TextStyle(fontSize: 14, height: 1.4)),
                      ),
                      const SizedBox(height: 22),
                    ],

                    if (user.courses.isNotEmpty) ...[
                      _SectionHeader(
                          icon: Icons.menu_book_rounded, label: 'Courses'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.courses
                            .map((c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    c,
                                    style: TextStyle(
                                      color: cs.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 22),
                    ],

                    _SectionHeader(
                        icon: Icons.schedule_rounded, label: 'Availability'),
                    const SizedBox(height: 10),
                    _AvailabilityList(availability: user.availability),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleMenu(BuildContext context, String value,
      FirestoreService firestore, String currentUid) async {
    if (value == 'block') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Block user?'),
          content: const Text(
              'You won\'t see this user in Discover or study matches, and they won\'t be able to start new conversations with you.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Block'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await firestore.blockUser(currentUid, uid);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('User blocked')));
          Navigator.of(context).pop();
        }
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.primary, size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _AvailabilityList extends StatelessWidget {
  final Map<String, dynamic> availability;
  const _AvailabilityList({required this.availability});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lines = <MapEntry<String, List<String>>>[];
    for (final day in PublicProfileScreen._dayOrder) {
      final raw = availability[day];
      if (raw is! List) continue;
      final slots = raw
          .whereType<String>()
          .map((s) => PublicProfileScreen._slotLabels[s] ?? s)
          .toList();
      if (slots.isEmpty) continue;
      lines.add(MapEntry(PublicProfileScreen._dayLabels[day] ?? day, slots));
    }

    if (lines.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Text('No study times set yet.',
            style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }
    return Column(
      children: lines
          .map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(e.key,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value.join(' • '),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
