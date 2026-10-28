class UserProfileModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String? profileImageUrl;

  UserProfileModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profileImageUrl,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserProfileModel(
      uid: docId,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImageUrl: map['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    };
  }
}
