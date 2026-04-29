import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../services/firestore_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthRepository>().logout(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: StreamBuilder<UserModel>(
        stream: firestoreService.userStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData) {
            return const Center(child: Text('Profile not found.'));
          }
          final user = snap.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor:
                                const Color(0xFF1A73E8).withValues(alpha: 0.15),
                            backgroundImage: user.profilePhotoUrl.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    user.profilePhotoUrl)
                                : null,
                            child: user.profilePhotoUrl.isEmpty
                                ? Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A73E8)))
                                : null,
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        EditProfileScreen(user: user)),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A73E8),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.edit,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(user.displayName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(user.email,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500)),
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(user.bio,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.4)),
                      ],
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => EditProfileScreen(user: user)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Courses
                if (user.courses.isNotEmpty)
                  _Section(
                    title: 'Courses',
                    icon: Icons.school_outlined,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.courses
                          .map((c) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A73E8)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(c,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A73E8))),
                              ))
                          .toList(),
                    ),
                  ),

                if (user.availability.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Section(
                    title: 'Study Availability',
                    icon: Icons.schedule_outlined,
                    child: _AvailabilityGrid(availability: user.availability),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AvailabilityGrid extends StatelessWidget {
  final Map<String, dynamic> availability;
  const _AvailabilityGrid({required this.availability});

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
    final activeDays = _dayLabels.entries
        .where((e) {
          final v = availability[e.key];
          return v is List && v.isNotEmpty;
        })
        .toList();

    if (activeDays.isEmpty) {
      return Text('No availability set.',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13));
    }

    return Column(
      children: activeDays.map((e) {
        final slots =
            List<String>.from(availability[e.key] as List? ?? []);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 36,
                child: Text(_dayLabels[e.key]!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: slots.map((s) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_slotLabels[s] ?? s,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A73E8))),
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
