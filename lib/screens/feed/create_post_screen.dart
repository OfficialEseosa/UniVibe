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
    'general', 'academics', 'events', 'sports', 'clubs', 'housing', 'jobs',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          FutureBuilder<UserModel?>(
            future: firestoreService.getUser(uid),
            builder: (context, snap) => TextButton(
              onPressed: snap.data != null && !_loading
                  ? () => _submit(snap.data!)
                  : null,
              child: _loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _campusTag,
              decoration: const InputDecoration(
                labelText: 'Tag',
                border: OutlineInputBorder(),
              ),
              items: _tags
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _campusTag = v ?? 'general'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: "What's happening on campus?",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            if (_image != null) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  Image.file(_image!, height: 180, fit: BoxFit.cover,
                      width: double.infinity),
                  Positioned(
                    top: 4, right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _image = null),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.image_outlined),
              label: const Text('Add Photo'),
              onPressed: _pickImage,
            ),
          ],
        ),
      ),
    );
  }
}
