import 'package:cloud_firestore/cloud_firestore.dart';

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
      };

  UserModel copyWith({
    String? displayName,
    String? bio,
    String? profilePhotoUrl,
    List<String>? courses,
    Map<String, dynamic>? availability,
    String? fcmToken,
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
      );
}
