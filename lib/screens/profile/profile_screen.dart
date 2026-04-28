import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthRepository>().logout(),
          ),
        ],
      ),
      body: StreamBuilder<UserModel>(
        stream: firestoreService.userStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData) return const Center(child: Text('Profile not found.'));
          final user = snap.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundImage: user.profilePhotoUrl.isNotEmpty
                      ? NetworkImage(user.profilePhotoUrl)
                      : null,
                  child: user.profilePhotoUrl.isEmpty
                      ? Text(user.displayName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 36))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(user.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold)),
                Text(user.email,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                if (user.bio.isNotEmpty)
                  Text(user.bio, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => EditProfileScreen(user: user)),
                  ),
                  child: const Text('Edit Profile'),
                ),
                const SizedBox(height: 24),
                if (user.courses.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Courses',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: user.courses
                        .map((c) => Chip(label: Text(c)))
                        .toList(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
