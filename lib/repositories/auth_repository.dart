import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';

class AuthRepository {
  final AuthService _authService;
  final FcmService _fcmService;

  AuthRepository({required AuthService authService, required FcmService fcmService})
      : _authService = authService,
        _fcmService = fcmService;

  User? get currentUser => _authService.currentUser;
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final user = await _authService.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
    await _fcmService.initialize(user.uid);
    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final user = await _authService.signIn(email: email, password: password);
    await _fcmService.initialize(user.uid);
    return user;
  }

  Future<void> logout() => _authService.signOut();

  Future<void> resetPassword(String email) =>
      _authService.sendPasswordReset(email);

  Future<UserModel?> getProfile() => _authService.fetchCurrentUserProfile();
}
