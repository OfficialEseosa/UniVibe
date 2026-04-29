import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../repositories/post_repository.dart';
import '../../services/firestore_service.dart';

const _tags = [
  'general', 'academics', 'events', 'sports', 'clubs', 'housing', 'jobs',
];

const _tagIcons = {
  'general': Icons.public,
  'academics': Icons.school_outlined,
  'events': Icons.event_outlined,
  'sports': Icons.sports,
  'clubs': Icons.groups_outlined,
  'housing': Icons.home_outlined,
  'jobs': Icons.work_outline,
};

const _tagColors = {
  'general': Color(0xFF6B7280),
  'academics': Color(0xFF1A73E8),
  'events': Color(0xFF9C27B0),
  'sports': Color(0xFF4CAF50),
  'clubs': Color(0xFFFF9800),
  'housing': Color(0xFF795548),
  'jobs': Color(0xFF009688),
};

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

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
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
    final tagColor = _tagColors[_campusTag] ?? const Color(0xFF6B7280);

    return FutureBuilder<UserModel?>(
      future: firestoreService.getUser(uid),
      builder: (context, snap) {
        final author = snap.data;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('New Post',
                style: TextStyle(fontWeight: FontWeight.w700)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton(
                  onPressed: author != null && !_loading
                      ? () => _submit(author)
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(72, 36),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Post',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: Colors.grey.shade100),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Author row
              if (author != null)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          const Color(0xFF1A73E8).withValues(alpha: 0.15),
                      child: Text(
                        author.displayName.isNotEmpty
                            ? author.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Color(0xFF1A73E8),
                            fontWeight: FontWeight.w700,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(author.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const SizedBox(height: 2),
                        // Tag selector pill
                        GestureDetector(
                          onTap: () => _showTagPicker(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: tagColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_tagIcons[_campusTag],
                                    size: 12, color: tagColor),
                                const SizedBox(width: 4),
                                Text('#$_campusTag',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: tagColor)),
                                const SizedBox(width: 3),
                                Icon(Icons.arrow_drop_down,
                                    size: 14, color: tagColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // Text input
              TextField(
                controller: _contentCtrl,
                maxLines: null,
                minLines: 6,
                style: const TextStyle(fontSize: 16, height: 1.5),
                decoration: InputDecoration(
                  hintText: "What's happening on campus?",
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontSize: 16),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),

              // Image preview
              if (_image != null) ...[
                const SizedBox(height: 12),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_image!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _image = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 4),

              // Action bar
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.image_outlined,
                        color: Theme.of(context).colorScheme.primary),
                    tooltip: 'Add Photo',
                    onPressed: _pickImage,
                  ),
                  Text('Add photo',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTagPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose a tag',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final color = _tagColors[tag]!;
                final selected = tag == _campusTag;
                return GestureDetector(
                  onTap: () {
                    setState(() => _campusTag = tag);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? color
                          : color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_tagIcons[tag],
                            size: 14,
                            color: selected ? Colors.white : color),
                        const SizedBox(width: 6),
                        Text('#$tag',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    selected ? Colors.white : color)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
