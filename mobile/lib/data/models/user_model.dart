class User {
  final String id;
  final String email;
  final String? username;
  final String? phone;
  final String fullName;
  final String userType;
  final String? profilePhoto;
  final String? dateOfBirth;
  final String? gender;
  final bool isActive;
  final bool isVerified;
  final String? lastLogin;
  final String loginType;
  final String createdAt;

  User({
    required this.id,
    required this.email,
    this.username,
    this.phone,
    required this.fullName,
    required this.userType,
    this.profilePhoto,
    this.dateOfBirth,
    this.gender,
    required this.isActive,
    required this.isVerified,
    this.lastLogin,
    required this.loginType,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'],
      phone: json['phone'],
      fullName: json['full_name'] ?? '',
      userType: json['user_type'] ?? 'member',
      profilePhoto: json['profile_photo'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      lastLogin: json['last_login'],
      loginType: json['login_type'] ?? 'credential',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'phone': phone,
      'full_name': fullName,
      'user_type': userType,
      'profile_photo': profilePhoto,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'is_active': isActive,
      'is_verified': isVerified,
      'last_login': lastLogin,
      'login_type': loginType,
      'created_at': createdAt,
    };
  }
}

