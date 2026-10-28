import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final bool isDisabled;
  final String? profileImage;
  final DateTime? createdAt;

  const AdminUserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isDisabled,
    this.profileImage,
    this.createdAt,
  });

  factory AdminUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUserModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      isDisabled: data['isDisabled'] ?? false,
      profileImage: data['profileImage'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'fullName': fullName,
        'email': email,
        'role': role,
        'isDisabled': isDisabled,
        'profileImage': profileImage,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      };

  AdminUserModel copyWith({
    String? fullName,
    String? email,
    String? role,
    bool? isDisabled,
    String? profileImage,
  }) {
    return AdminUserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      isDisabled: isDisabled ?? this.isDisabled,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt,
    );
  }
}
