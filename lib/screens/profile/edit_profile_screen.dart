import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _coursesCtrl;
  File? _newPhoto;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.displayName);
    _bioCtrl = TextEditingController(text: widget.user.bio);
    _coursesCtrl = TextEditingController(
        text: widget.user.courses.join(', '));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _coursesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _newPhoto = File(picked.path));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final storage = context.read<StorageService>();
      final firestore = context.read<FirestoreService>();

      String photoUrl = widget.user.profilePhotoUrl;
      if (_newPhoto != null) {
        photoUrl = await storage.uploadProfilePhoto(widget.user.uid, _newPhoto!);
      }

      final courses = _coursesCtrl.text
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();

      final updated = widget.user.copyWith(
        displayName: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        profilePhotoUrl: photoUrl,
        courses: courses,
      );

      await firestore.updateUserProfile(updated);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: CircleAvatar(
                radius: 48,
                backgroundImage: _newPhoto != null
                    ? FileImage(_newPhoto!)
                    : (widget.user.profilePhotoUrl.isNotEmpty
                        ? NetworkImage(widget.user.profilePhotoUrl)
                            as ImageProvider
                        : null),
                child: _newPhoto == null && widget.user.profilePhotoUrl.isEmpty
                    ? const Icon(Icons.camera_alt, size: 32)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _coursesCtrl,
            decoration: const InputDecoration(
              labelText: 'Courses (comma-separated)',
              hintText: 'CSC 4360, MATH 2420, BIO 1100',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
