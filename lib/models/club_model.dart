import 'package:cloud_firestore/cloud_firestore.dart';

class ClubModel {
  final String clubId;
  final String name;
  final String description;
  final String adminUid;
  final List<String> members;
  final String? bannerUrl;
  final DateTime createdAt;

  const ClubModel({
    required this.clubId,
    required this.name,
    required this.description,
    required this.adminUid,
    this.members = const [],
    this.bannerUrl,
    required this.createdAt,
  });

  factory ClubModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClubModel(
      clubId: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      adminUid: data['adminUid'] as String,
      members: List<String>.from(data['members'] as List? ?? []),
      bannerUrl: data['bannerUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'adminUid': adminUid,
        'members': members,
        if (bannerUrl != null) 'bannerUrl': bannerUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool isMember(String uid) => members.contains(uid);

  ClubModel copyWith({List<String>? members, String? bannerUrl}) => ClubModel(
        clubId: clubId,
        name: name,
        description: description,
        adminUid: adminUid,
        members: members ?? this.members,
        bannerUrl: bannerUrl ?? this.bannerUrl,
        createdAt: createdAt,
      );
}
