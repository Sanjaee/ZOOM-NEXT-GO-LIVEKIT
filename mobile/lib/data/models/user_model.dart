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
  final String? role;

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
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      // Support both 'username' and fallback to 'name'
      username: json['username'] ?? json['name'],
      phone: json['phone'],
      // Support both 'full_name' (snake_case) and 'name' (camelCase from Google OAuth)
      fullName: json['full_name'] ?? json['fullName'] ?? json['name'] ?? '',
      // Support both 'user_type' and 'userType'
      userType: json['user_type'] ?? json['userType'] ?? json['role'] ?? 'member',
      // Support both 'profile_photo' and 'image' (from Google OAuth)
      profilePhoto: json['profile_photo'] ?? json['profilePhoto'] ?? json['image'],
      dateOfBirth: json['date_of_birth'] ?? json['dateOfBirth'],
      gender: json['gender'],
      // Support both 'is_active' and 'isActive'
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      // Support both 'is_verified' and 'isVerified'
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      lastLogin: json['last_login'] ?? json['lastLogin'],
      // Support both 'login_type' and 'loginType'
      loginType: json['login_type'] ?? json['loginType'] ?? 'credential',
      createdAt: json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String(),
      role: json['role'],
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
      'role': role,
    };
  }
}

