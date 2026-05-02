import 'package:cloud_firestore/cloud_firestore.dart';

/// Discovery visibility for a profile.
/// 'public' → appears in Discover and search results.
/// 'private' → hidden from Discover (still reachable via direct link / messages).
class DiscoverStatus {
  static const public = 'public';
  static const private = 'private';
}

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String bio;
  final String profilePhotoUrl;
  final List<String> courses;
  final Map<String, dynamic> availability;
  final String? fcmToken;
  final DateTime createdAt;

  /// Whether the user wants to appear on the Discover screen.
  /// Legacy users (created before this field existed) are treated as public.
  final String discoverStatus;

  /// UIDs this user has blocked. Blocked users are filtered from
  /// Discover, study matches, and inbound messages.
  final List<String> blockedUsers;

  /// True once the user has completed the onboarding wizard.
  /// New accounts default to false so we can show the wizard right after register.
  final bool onboardingComplete;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.bio = '',
    this.profilePhotoUrl = '',
    this.courses = const [],
    this.availability = const {},
    this.fcmToken,
    required this.createdAt,
    this.discoverStatus = DiscoverStatus.public,
    this.blockedUsers = const [],
    this.onboardingComplete = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] as String,
      email: data['email'] as String,
      bio: data['bio'] as String? ?? '',
      profilePhotoUrl: data['profilePhotoUrl'] as String? ?? '',
      courses: List<String>.from(data['courses'] as List? ?? []),
      availability: Map<String, dynamic>.from(
          data['availability'] as Map? ?? {}),
      fcmToken: data['fcmToken'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      // Legacy users without this field default to public so they still appear.
      discoverStatus:
          data['discoverStatus'] as String? ?? DiscoverStatus.public,
      blockedUsers: List<String>.from(data['blockedUsers'] as List? ?? []),
      onboardingComplete: data['onboardingComplete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'email': email,
        'bio': bio,
        'profilePhotoUrl': profilePhotoUrl,
        'courses': courses,
        'availability': availability,
        if (fcmToken != null) 'fcmToken': fcmToken,
        'createdAt': Timestamp.fromDate(createdAt),
        'discoverStatus': discoverStatus,
        'blockedUsers': blockedUsers,
        'onboardingComplete': onboardingComplete,
      };

  UserModel copyWith({
    String? displayName,
    String? bio,
    String? profilePhotoUrl,
    List<String>? courses,
    Map<String, dynamic>? availability,
    String? fcmToken,
    String? discoverStatus,
    List<String>? blockedUsers,
    bool? onboardingComplete,
  }) =>
      UserModel(
        uid: uid,
        displayName: displayName ?? this.displayName,
        email: email,
        bio: bio ?? this.bio,
        profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
        courses: courses ?? this.courses,
        availability: availability ?? this.availability,
        fcmToken: fcmToken ?? this.fcmToken,
        createdAt: createdAt,
        discoverStatus: discoverStatus ?? this.discoverStatus,
        blockedUsers: blockedUsers ?? this.blockedUsers,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      );

  bool get isDiscoverable => discoverStatus == DiscoverStatus.public;
}
