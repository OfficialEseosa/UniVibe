import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage;
  static const _uuid = Uuid();

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadProfilePhoto(String uid, File file) async {
    final ext = _extOf(file.path);
    final ref = _storage.ref('profiles/$uid/avatar$ext');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: _mimeFor(ext)),
    );
    return task.ref.getDownloadURL();
  }

  Future<String> uploadPostImage(String authorUid, File file) async {
    final ext = _extOf(file.path);
    final name = _uuid.v4();
    final ref = _storage.ref('posts/$authorUid/$name$ext');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: _mimeFor(ext)),
    );
    return task.ref.getDownloadURL();
  }

  Future<String> uploadEventBanner(String eventId, File file) async {
    final ext = _extOf(file.path);
    final ref = _storage.ref('events/$eventId/banner$ext');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: _mimeFor(ext)),
    );
    return task.ref.getDownloadURL();
  }

  Future<String> uploadClubBanner(String clubId, File file) async {
    final ext = _extOf(file.path);
    final ref = _storage.ref('clubs/$clubId/banner$ext');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: _mimeFor(ext)),
    );
    return task.ref.getDownloadURL();
  }

  Future<void> deleteFile(String downloadUrl) async {
    final ref = _storage.refFromURL(downloadUrl);
    await ref.delete();
  }

  String _extOf(String path) {
    final idx = path.lastIndexOf('.');
    return idx == -1 ? '' : path.substring(idx);
  }

  String _mimeFor(String ext) {
    switch (ext.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
