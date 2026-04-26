import 'dart:io';
import '../models/club_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ClubRepository {
  final FirestoreService _firestore;
  final StorageService _storage;

  ClubRepository({
    required FirestoreService firestore,
    required StorageService storage,
  })  : _firestore = firestore,
        _storage = storage;

  Stream<List<ClubModel>> allClubsStream() => _firestore.clubsStream();

  Stream<List<ClubModel>> myClubsStream(String uid) =>
      _firestore.myClubsStream(uid);

  Future<void> joinClub(String clubId, String uid) =>
      _firestore.joinClub(clubId, uid);

  Future<void> leaveClub(String clubId, String uid) =>
      _firestore.leaveClub(clubId, uid);

  Future<void> createClub({
    required String name,
    required String description,
    required String adminUid,
    File? banner,
  }) async {
    final club = ClubModel(
      clubId: '',
      name: name,
      description: description,
      adminUid: adminUid,
      members: [adminUid],
      createdAt: DateTime.now(),
    );

    final ref = await _firestore.createClub(club);

    if (banner != null) {
      final url = await _storage.uploadClubBanner(ref.id, banner);
      await ref.update({'bannerUrl': url});
    }
  }
}
