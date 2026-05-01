import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../repositories/post_repository.dart';
import '../../services/firestore_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentCtrl = TextEditingController();
  File? _image;
  String _campusTag = 'general';
  bool _loading = false;

  static const _tags = [
    'general',
    'academics',
    'events',
    'sports',
    'clubs',
    'housing',
    'jobs',
  ];

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit(UserModel author) async {
    if (_contentCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await context.read<PostRepository>().createPost(
            author: author,
            content: _contentCtrl.text.trim(),
            campusTag: _campusTag,
            image: _image,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestoreService = context.read<FirestoreService>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<UserModel?>(
        future: firestoreService.getUser(uid),
        builder: (context, snap) {
          final author = snap.data;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Author info ────────────────────────────────────────
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: cs.primaryContainer,
                        backgroundImage: author?.profilePhotoUrl != null &&
                                author!.profilePhotoUrl.isNotEmpty
                            ? NetworkImage(author.profilePhotoUrl)
                            : null,
                        child: author?.profilePhotoUrl == null ||
                                author!.profilePhotoUrl.isEmpty
                            ? Text(
                                author?.displayName.isNotEmpty == true
                                    ? author!.displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              author?.displayName ?? 'User',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Posting to campus',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Tag selector ────────────────────────────────────────
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _campusTag,
                      isExpanded: true,
                      underline: const SizedBox(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      borderRadius: BorderRadius.circular(12),
                      items: _tags
                          .map((tag) => DropdownMenuItem(
                                value: tag,
                                child: Row(
                                  children: [
                                    _getTagIcon(tag, cs.primary),
                                    const SizedBox(width: 10),
                                    Text(
                                      _formatTag(tag),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _campusTag = v ?? 'general'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Content input ────────────────────────────────────────
                  Text(
                    'What\'s happening on campus?',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentCtrl,
                    maxLines: 6,
                    minLines: 4,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Share your thoughts, ask questions, or post updates...',
                    ),
                  ),

                  // ── Image preview ────────────────────────────────────────
                  if (_image != null) ...[
                    const SizedBox(height: 16),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _image!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _image = null),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Image picker button ─────────────────────────────────
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: cs.outlineVariant),
                          bottom: BorderSide(color: cs.outlineVariant),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.image_outlined,
                              color: cs.primary, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Add photo',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Post button ──────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed:
                          (_loading || author == null || _contentCtrl.text.trim().isEmpty)
                              ? null
                              : () => _submit(author),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Post'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTag(String tag) {
    if (tag.isEmpty) return 'General';
    final normalized = tag.trim().toLowerCase();
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  Widget _getTagIcon(String tag, Color color) {
    IconData icon;
    switch (tag.toLowerCase()) {
      case 'academics':
        icon = Icons.school_outlined;
        break;
      case 'events':
        icon = Icons.event_outlined;
        break;
      case 'sports':
        icon = Icons.sports_outlined;
        break;
      case 'clubs':
        icon = Icons.groups_outlined;
        break;
      case 'housing':
        icon = Icons.home_outlined;
        break;
      case 'jobs':
        icon = Icons.work_outline;
        break;
      default:
        icon = Icons.public_outlined;
    }
    return Icon(icon, color: color, size: 20);
  }
}
