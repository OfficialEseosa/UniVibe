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

  // Availability: day → set of selected slots
  static const _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const _dayLabels = {
    'mon': 'Mon', 'tue': 'Tue', 'wed': 'Wed', 'thu': 'Thu',
    'fri': 'Fri', 'sat': 'Sat', 'sun': 'Sun',
  };
  static const _slots = ['morning', 'afternoon', 'evening'];
  static const _slotLabels = {
    'morning': 'Morning\n8am–12pm',
    'afternoon': 'Afternoon\n12pm–5pm',
    'evening': 'Evening\n5pm–9pm',
  };

  late Map<String, Set<String>> _availability;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.displayName);
    _bioCtrl = TextEditingController(text: widget.user.bio);
    _coursesCtrl = TextEditingController(text: widget.user.courses.join(', '));
    _availability = _parseAvailability(widget.user.availability);
  }

  Map<String, Set<String>> _parseAvailability(Map<String, dynamic> raw) {
    final result = <String, Set<String>>{};
    for (final day in _days) {
      final val = raw[day];
      if (val is List) {
        result[day] = Set<String>.from(val.whereType<String>());
      } else {
        result[day] = {};
      }
    }
    return result;
  }

  Map<String, dynamic> _buildAvailabilityMap() {
    final map = <String, dynamic>{};
    for (final day in _days) {
      final slots = _availability[day] ?? {};
      if (slots.isNotEmpty) map[day] = slots.toList();
    }
    return map;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _coursesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
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
        availability: _buildAvailabilityMap(),
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
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Avatar
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
          const SizedBox(height: 8),
          const Center(
            child: Text('Tap to change photo',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          const SizedBox(height: 24),

          // Display name
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Bio
          TextFormField(
            controller: _bioCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Courses
          TextFormField(
            controller: _coursesCtrl,
            decoration: const InputDecoration(
              labelText: 'Courses (comma-separated)',
              hintText: 'CSC 4360, MATH 2420, BIO 1100',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Availability
          Text('Study Availability',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Select the days and times you are free to study.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ..._days.map((day) => _DayAvailabilityRow(
                day: day,
                label: _dayLabels[day]!,
                slots: _slots,
                slotLabels: _slotLabels,
                selected: _availability[day] ?? {},
                onChanged: (slot, checked) => setState(() {
                  if (checked) {
                    _availability[day] = {...?_availability[day], slot};
                  } else {
                    _availability[day] =
                        (_availability[day] ?? {})..remove(slot);
                  }
                }),
              )),
        ],
      ),
    );
  }
}

class _DayAvailabilityRow extends StatelessWidget {
  final String day;
  final String label;
  final List<String> slots;
  final Map<String, String> slotLabels;
  final Set<String> selected;
  final void Function(String slot, bool checked) onChanged;

  const _DayAvailabilityRow({
    required this.day,
    required this.label,
    required this.slots,
    required this.slotLabels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 6,
              children: slots.map((slot) {
                final isSelected = selected.contains(slot);
                return FilterChip(
                  label: Text(
                    slotLabels[slot]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? cs.onPrimary : null,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: cs.primary,
                  checkmarkColor: cs.onPrimary,
                  onSelected: (v) => onChanged(slot, v),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
