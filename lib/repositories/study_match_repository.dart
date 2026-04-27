import '../models/study_match_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/study_match_service.dart';

class StudyMatchRepository {
  final FirestoreService _firestore;
  final StudyMatchService _matchService;

  StudyMatchRepository({
    required FirestoreService firestore,
    required StudyMatchService matchService,
  })  : _firestore = firestore,
        _matchService = matchService;

  Stream<List<StudyMatchModel>> suggestionsStream(String uid) =>
      _firestore.studyMatchesStream(uid);

  Future<void> refreshSuggestions(UserModel user) =>
      _matchService.refreshMatches(user);
}
