import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/message_model.dart';
import '../models/event_model.dart';
import '../models/club_model.dart';
import '../models/study_match_model.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<void> updateUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).update(user.toFirestore());
    // Keep post author photos in sync so the feed always shows the latest photo.
    if (user.profilePhotoUrl.isNotEmpty) {
      await _updateAuthorPhotoOnPosts(user.uid, user.profilePhotoUrl);
    }
  }

  Future<void> _updateAuthorPhotoOnPosts(String uid, String photoUrl) async {
    final snap = await _db
        .collection('posts')
        .where('authorUid', isEqualTo: uid)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'authorPhotoUrl': photoUrl});
    }
    await batch.commit();
  }

  /// Delete all posts (+ sub-collections) authored by [uid].
  /// Images are NOT deleted from Storage here — call deleteUserContent instead.
  Future<List<String>> deleteAllPostsByUser(String uid) async {
    final snap = await _db
        .collection('posts')
        .where('authorUid', isEqualTo: uid)
        .get();
    final imageUrls = <String>[];
    final batch = _db.batch();
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['imageUrl'] is String) imageUrls.add(data['imageUrl'] as String);
      // Delete comments sub-collection docs
      final comments = await doc.reference.collection('comments').get();
      for (final c in comments.docs) {
        batch.delete(c.reference);
      }
      batch.delete(doc.reference);
    }
    await batch.commit();
    return imageUrls;
  }

  Stream<UserModel> userStream(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map(UserModel.fromFirestore);

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  Future<void> updateFcmToken(String uid, String token) =>
      _db.collection('users').doc(uid).update({'fcmToken': token});

  /// Streams every user. Discover/search filters happen client-side
  /// (legacy users without `discoverStatus` are treated as public).
  Stream<List<UserModel>> allUsersStream() => _db
      .collection('users')
      .orderBy('displayName')
      .snapshots()
      .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());

  Future<void> blockUser(String currentUid, String targetUid) =>
      _db.collection('users').doc(currentUid).update({
        'blockedUsers': FieldValue.arrayUnion([targetUid]),
      });

  Future<void> unblockUser(String currentUid, String targetUid) =>
      _db.collection('users').doc(currentUid).update({
        'blockedUsers': FieldValue.arrayRemove([targetUid]),
      });

  Future<void> setDiscoverStatus(String uid, String status) =>
      _db.collection('users').doc(uid).update({'discoverStatus': status});

  /// Hard-delete the user's profile document. Caller is responsible for
  /// also deleting the FirebaseAuth account (which requires a recent login).
  Future<void> deleteUserProfile(String uid) =>
      _db.collection('users').doc(uid).delete();

  // ── Posts ──────────────────────────────────────────────────────────────────

  Stream<List<PostModel>> feedStream({int limit = 30}) => _db
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) => snap.docs.map(PostModel.fromFirestore).toList());

  Future<DocumentReference> createPost(PostModel post) =>
      _db.collection('posts').add(post.toFirestore());

  Future<void> deletePost(String postId) =>
      _db.collection('posts').doc(postId).delete();

  Future<void> toggleLikePost(String postId, String uid) =>
      _db.runTransaction((tx) async {
        final ref = _db.collection('posts').doc(postId);
        final snap = await tx.get(ref);
        final likedBy = List<String>.from(snap['likedBy'] as List? ?? []);
        if (likedBy.contains(uid)) {
          likedBy.remove(uid);
        } else {
          likedBy.add(uid);
        }
        tx.update(ref, {'likedBy': likedBy, 'likesCount': likedBy.length});
      });

  // ── Comments ───────────────────────────────────────────────────────────────

  Stream<List<CommentModel>> commentsStream(String postId) => _db
      .collection('posts')
      .doc(postId)
      .collection('comments')
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs.map(CommentModel.fromFirestore).toList());

  Future<void> addComment(String postId, CommentModel comment) =>
      _db
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add(comment.toFirestore());

  Future<void> toggleLikeComment(
      String postId, String commentId, String uid) =>
      _db.runTransaction((tx) async {
        final ref = _db
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId);
        final snap = await tx.get(ref);
        final likedBy = List<String>.from(snap['likedBy'] as List? ?? []);
        if (likedBy.contains(uid)) {
          likedBy.remove(uid);
        } else {
          likedBy.add(uid);
        }
        tx.update(ref, {'likedBy': likedBy, 'likesCount': likedBy.length});
      });

  // ── Messages ───────────────────────────────────────────────────────────────

  Stream<List<MessageThreadModel>> threadsStream(String uid) => _db
      .collection('messages')
      .where('participants', arrayContains: uid)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(MessageThreadModel.fromFirestore).toList());

  Stream<List<MessageModel>> messagesStream(String threadId) => _db
      .collection('messages')
      .doc(threadId)
      .collection('messages')
      .orderBy('timestamp')
      .snapshots()
      .map((snap) => snap.docs.map(MessageModel.fromFirestore).toList());

  Future<void> sendMessage(
      String threadId, MessageModel message, List<String> participants) =>
      _db.runTransaction((tx) async {
        final threadRef = _db.collection('messages').doc(threadId);
        final msgRef = threadRef.collection('messages').doc();

        final threadSnap = await tx.get(threadRef);
        final unreadCount =
            Map<String, int>.from((threadSnap.data()?['unreadCount'] as Map?)
                    ?.map((k, v) => MapEntry(k as String, (v as num).toInt())) ??
                {});

        for (final uid in participants) {
          if (uid != message.senderUid) {
            unreadCount[uid] = (unreadCount[uid] ?? 0) + 1;
          }
        }

        tx.set(
          threadRef,
          {
            'participants': participants,
            'lastMessage': message.text,
            'lastMessageAt': Timestamp.fromDate(message.timestamp),
            'unreadCount': unreadCount,
          },
          SetOptions(merge: true),
        );
        tx.set(msgRef, message.toFirestore());
      });

  Future<void> markThreadRead(String threadId, String uid) =>
      _db.collection('messages').doc(threadId).update({
        'unreadCount.$uid': 0,
      });

  // ── Events ─────────────────────────────────────────────────────────────────

  Stream<List<EventModel>> upcomingEventsStream({int limit = 30}) => _db
      .collection('events')
      .where('startTime', isGreaterThan: Timestamp.now())
      .orderBy('startTime')
      .limit(limit)
      .snapshots()
      .map((snap) => snap.docs.map(EventModel.fromFirestore).toList());

  Future<DocumentReference> createEvent(EventModel event) =>
      _db.collection('events').add(event.toFirestore());

  Future<void> toggleRsvp(String eventId, String uid) =>
      _db.runTransaction((tx) async {
        final ref = _db.collection('events').doc(eventId);
        final snap = await tx.get(ref);
        final rsvpedBy = List<String>.from(snap['rsvpedBy'] as List? ?? []);
        if (rsvpedBy.contains(uid)) {
          rsvpedBy.remove(uid);
        } else {
          rsvpedBy.add(uid);
        }
        tx.update(ref, {'rsvpedBy': rsvpedBy, 'rsvpCount': rsvpedBy.length});
      });

  // ── Clubs ──────────────────────────────────────────────────────────────────

  Stream<List<ClubModel>> clubsStream() => _db
      .collection('clubs')
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map(ClubModel.fromFirestore).toList());

  Stream<List<ClubModel>> myClubsStream(String uid) => _db
      .collection('clubs')
      .where('members', arrayContains: uid)
      .snapshots()
      .map((snap) => snap.docs.map(ClubModel.fromFirestore).toList());

  Future<void> joinClub(String clubId, String uid) =>
      _db.collection('clubs').doc(clubId).update({
        'members': FieldValue.arrayUnion([uid]),
      });

  Future<void> leaveClub(String clubId, String uid) =>
      _db.collection('clubs').doc(clubId).update({
        'members': FieldValue.arrayRemove([uid]),
      });

  Future<DocumentReference> createClub(ClubModel club) =>
      _db.collection('clubs').add(club.toFirestore());

  // ── Study Matches ──────────────────────────────────────────────────────────

  Stream<List<StudyMatchModel>> studyMatchesStream(String uid) => _db
      .collection('studyMatches')
      .doc(uid)
      .collection('suggestions')
      .orderBy('score', descending: true)
      .limit(10)
      .snapshots()
      .map((snap) => snap.docs.map(StudyMatchModel.fromFirestore).toList());

  Future<void> saveStudyMatch(String uid, StudyMatchModel match) =>
      _db
          .collection('studyMatches')
          .doc(uid)
          .collection('suggestions')
          .doc(match.matchUid)
          .set(match.toFirestore());
}
