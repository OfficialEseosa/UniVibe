import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

/// Three-step onboarding wizard shown immediately after registration.
/// Collects bio + photo, courses, and weekly availability so the user
/// lands in a fully populated profile.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _bioCtrl = TextEditingController();
  final _coursesCtrl = TextEditingController();
  File? _photo;
  int _step = 0;
  bool _saving = false;
  String? _error;

  static const _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const _dayLabels = {
    'mon': 'Mon', 'tue': 'Tue', 'wed': 'Wed', 'thu': 'Thu',
    'fri': 'Fri', 'sat': 'Sat', 'sun': 'Sun',
  };
  static const _slots = ['morning', 'afternoon', 'evening'];
  static const _slotLabels = {
    'morning': 'Morning',
    'afternoon': 'Afternoon',
    'evening': 'Evening',
  };

  final Map<String, Set<String>> _availability = {
    for (final d in _days) d: <String>{},
  };

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bioCtrl.dispose();
    _coursesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      _pageCtrl.animateToPage(
        _step,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
    _pageCtrl.animateToPage(
      _step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final firestore = context.read<FirestoreService>();
      final storage = context.read<StorageService>();

      final current = await firestore.getUser(uid);
      if (current == null) throw Exception('Profile not found');

      String photoUrl = current.profilePhotoUrl;
      if (_photo != null) {
        photoUrl = await storage.uploadProfilePhoto(uid, _photo!);
      }

      final courses = _coursesCtrl.text
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();

      final availability = <String, dynamic>{};
      for (final day in _days) {
        final slots = _availability[day] ?? {};
        if (slots.isNotEmpty) availability[day] = slots.toList();
      }

      final updated = current.copyWith(
        bio: _bioCtrl.text.trim(),
        profilePhotoUrl: photoUrl,
        courses: courses,
        availability: availability,
        onboardingComplete: true,
      );
      await firestore.updateUserProfile(updated);
      // _AuthGate listens to userStream and will swap to MainShell on its own.
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _skip() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final firestore = context.read<FirestoreService>();
      final current = await firestore.getUser(uid);
      if (current != null) {
        await firestore.updateUserProfile(
          current.copyWith(onboardingComplete: true),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header strip with progress + skip
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: List.generate(3, (i) {
                        final active = i <= _step;
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.only(right: 6),
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? cs.primary
                                  : cs.primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _skip,
                    child: const Text('Skip for now'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildBioStep(cs),
                  _buildCoursesStep(cs),
                  _buildAvailabilityStep(cs),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: cs.error),
                  textAlign: TextAlign.center,
                ),
              ),
            // Footer nav
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _back,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving ? null : _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(_step == 2 ? 'Finish' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioStep(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.waving_hand_rounded,
                color: Colors.white, size: 56),
          ),
          const SizedBox(height: 22),
          const Text(
            'Tell us a bit about you',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a photo and a quick bio so classmates know who they\'re studying with.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 22),
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primaryContainer,
                      image: _photo != null
                          ? DecorationImage(
                              image: FileImage(_photo!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _photo == null
                        ? Icon(Icons.person_rounded,
                            size: 64, color: cs.onPrimaryContainer)
                        : null,
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _bioCtrl,
            maxLines: 4,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Bio',
              hintText: 'CS major, big into hackathons and bubble tea ☕',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesStep(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF7B61FF), cs.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: Colors.white, size: 56),
          ),
          const SizedBox(height: 22),
          const Text(
            'What courses are you taking?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'We use this to find study partners with overlapping classes.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _coursesCtrl,
            decoration: const InputDecoration(
              labelText: 'Your courses',
              hintText: 'CSC 4360, MATH 2420, BIO 1100',
              prefixIcon: Icon(Icons.school_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: cs.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Separate course codes with commas. You can update these any time.',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityStep(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 110,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF00B894), cs.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.schedule_rounded,
                color: Colors.white, size: 52),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'When are you free to study?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Pick the slots that usually work. Tap again to deselect.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 18),
          ..._days.map((day) {
            final selected = _availability[day]!;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 38,
                    child: Text(
                      _dayLabels[day]!,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _slots.map((slot) {
                        final isSel = selected.contains(slot);
                        return FilterChip(
                          label: Text(_slotLabels[slot]!,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isSel ? cs.onPrimary : cs.onSurface,
                                fontWeight:
                                    isSel ? FontWeight.w600 : null,
                              )),
                          selected: isSel,
                          showCheckmark: false,
                          selectedColor: cs.primary,
                          backgroundColor: cs.surfaceContainerHighest,
                          side: BorderSide(
                            color: isSel ? cs.primary : cs.outlineVariant,
                          ),
                          onSelected: (v) => setState(() {
                            if (v) {
                              selected.add(slot);
                            } else {
                              selected.remove(slot);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
