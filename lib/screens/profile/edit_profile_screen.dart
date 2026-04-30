import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          // Avatar section
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primaryContainer,
                    ),
                    child: _newPhoto != null
                        ? ClipOval(
                            child: Image.file(
                              _newPhoto!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : (widget.user.profilePhotoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.user.profilePhotoUrl,
                                imageBuilder: (context, imageProvider) =>
                                    ClipOval(
                                  child: Image(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cs.primary,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Text(
                                    widget.user.displayName[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  widget.user.displayName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                              )),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: cs.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Tap to change photo',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 24),

          // Display name
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Display Name',
            ),
          ),
          const SizedBox(height: 16),

          // Bio
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio',
              hintText: 'Tell others about yourself',
            ),
          ),
          const SizedBox(height: 16),

          // Courses
          TextField(
            controller: _coursesCtrl,
            decoration: const InputDecoration(
              labelText: 'Courses',
              hintText: 'CSC 4360, MATH 2420, BIO 1100',
            ),
          ),
          const SizedBox(height: 28),

          // Availability header
          Text(
            'Study Availability',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select the days and times you are free to study.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),

          // Availability grid
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: slots.map((slot) {
                final isSelected = selected.contains(slot);
                return FilterChip(
                  label: Text(
                    slotLabels[slot]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      color: isSelected ? cs.onPrimary : cs.onSurface,
                      fontWeight: isSelected ? FontWeight.w500 : null,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: cs.primary,
                  backgroundColor: cs.surfaceContainerHighest,
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
