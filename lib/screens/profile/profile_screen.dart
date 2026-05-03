import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _dayOrder = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const _dayLabels = {
    'mon': 'Mon', 'tue': 'Tue', 'wed': 'Wed', 'thu': 'Thu',
    'fri': 'Fri', 'sat': 'Sat', 'sun': 'Sun',
  };
  static const _slotLabels = {
    '7-9am':    '7–9 AM',
    '9-11am':   '9–11 AM',
    '11am-1pm': '11AM–1PM',
    '1-3pm':    '1–3 PM',
    '3-5pm':    '3–5 PM',
    '5-7pm':    '5–7 PM',
    '7-9pm':    '7–9 PM',
    '9-11pm':   '9–11 PM',
    'morning': 'Morning', 'afternoon': 'Afternoon', 'evening': 'Evening',
  };

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestoreService = context.read<FirestoreService>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: StreamBuilder<UserModel>(
        stream: firestoreService.userStream(uid),
        builder: (context, snap) {
          final user = snap.data;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 230,
                pinned: true,
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                title: const Text('Profile'),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (value) =>
                        _handleMenu(context, value, user, firestoreService),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'visibility',
                        child: Row(children: [
                          Icon(user.isDiscoverable
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          const SizedBox(width: 10),
                          Text(user.isDiscoverable
                              ? 'Hide from Discover'
                              : 'Show on Discover'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(children: [
                          Icon(Icons.logout_rounded),
                          SizedBox(width: 10),
                          Text('Sign out'),
                        ]),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_forever_rounded, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete account',
                              style: TextStyle(color: Colors.red)),
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
                        left: 20,
                        right: 20,
                        bottom: 18,
                        child: Row(
                          children: [
                            _Avatar(user: user),
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
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  _DiscoverChip(user: user),
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
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit Profile'),
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: cs.primary,
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditProfileScreen(user: user),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (user.bio.isNotEmpty) ...[
                      _SectionHeader(
                          icon: Icons.info_outline, label: 'About'),
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
                            style:
                                const TextStyle(fontSize: 14, height: 1.4)),
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
                            .map((course) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    course,
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
                    if (_availabilitySummary(user.availability).isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Text('No study times set yet.',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      )
                    else
                      Column(
                        children: _availabilitySummary(user.availability)
                            .map((line) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: cs.outlineVariant),
                                  ),
                                  child: Text(line,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                ))
                            .toList(),
                      ),
                    if (user.blockedUsers.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _SectionHeader(
                          icon: Icons.block_rounded, label: 'Blocked Users'),
                      const SizedBox(height: 10),
                      ...user.blockedUsers.map(
                        (blockedUid) => _BlockedUserTile(
                          blockedUid: blockedUid,
                          currentUid: uid,
                          firestore: firestoreService,
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleMenu(BuildContext context, String value, UserModel user,
      FirestoreService firestore) async {
    switch (value) {
      case 'visibility':
        final next = user.isDiscoverable
            ? DiscoverStatus.private
            : DiscoverStatus.public;
        await firestore.setDiscoverStatus(user.uid, next);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(next == DiscoverStatus.public
                ? 'You\'re now visible on Discover'
                : 'Hidden from Discover'),
          ));
        }
        break;
      case 'logout':
        await context.read<AuthRepository>().logout();
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete account?'),
            content: const Text(
                'This permanently removes your profile AND all your posts. This cannot be undone.\n\nIf you signed in a while ago you may need to log out and back in for security reasons.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete Everything'),
              ),
            ],
          ),
        );
        if (confirm != true) return;
        try {
          final storage = context.read<StorageService>();
          // Delete all posts + collect image URLs
          final imageUrls = await firestore.deleteAllPostsByUser(user.uid);
          // Delete post images from Storage
          for (final url in imageUrls) {
            try { await storage.deleteFile(url); } catch (_) {}
          }
          // Delete profile photo from Storage
          if (user.profilePhotoUrl.isNotEmpty) {
            try { await storage.deleteFile(user.profilePhotoUrl); } catch (_) {}
          }
          await firestore.deleteUserProfile(user.uid);
          await FirebaseAuth.instance.currentUser?.delete();
        } on FirebaseAuthException catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.code == 'requires-recent-login'
                  ? 'Please log out and back in, then try deleting your account again.'
                  : 'Failed to delete account: ${e.message}'),
            ));
          }
          await FirebaseAuth.instance.signOut();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')));
          }
        }
        break;
    }
  }

  List<String> _availabilitySummary(Map<String, dynamic> availability) {
    final lines = <String>[];
    for (final day in _dayOrder) {
      final rawSlots = availability[day];
      if (rawSlots is! List) continue;
      final labels = rawSlots
          .whereType<String>()
          .map((slot) => _slotLabels[slot] ?? slot)
          .toList();
      if (labels.isEmpty) continue;
      lines.add('${_dayLabels[day] ?? day}: ${labels.join(' • ')}');
    }
    return lines;
  }
}

class _Avatar extends StatelessWidget {
  final UserModel user;
  const _Avatar({required this.user});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';
    return Container(
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
                errorWidget: (_, __, ___) => Container(
                  color: cs.primaryContainer,
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimaryContainer)),
                ),
              )
            : Container(
                color: cs.primaryContainer,
                alignment: Alignment.center,
                child: Text(initial,
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer)),
              ),
      ),
    );
  }
}

class _DiscoverChip extends StatelessWidget {
  final UserModel user;
  const _DiscoverChip({required this.user});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            user.isDiscoverable
                ? Icons.public_rounded
                : Icons.lock_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            user.isDiscoverable ? 'Public profile' : 'Private profile',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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

class _BlockedUserTile extends StatelessWidget {
  final String blockedUid;
  final String currentUid;
  final FirestoreService firestore;
  const _BlockedUserTile({
    required this.blockedUid,
    required this.currentUid,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<UserModel?>(
      future: firestore.getUser(blockedUid),
      builder: (context, snap) {
        final name = snap.data?.displayName ?? blockedUid;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.block_rounded, size: 18, color: cs.error),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              TextButton(
                onPressed: () => firestore.unblockUser(currentUid, blockedUid),
                child: const Text('Unblock'),
              ),
            ],
          ),
        );
      },
    );
  }
}
