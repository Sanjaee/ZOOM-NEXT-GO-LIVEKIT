import 'user_model.dart';

class AuthResponse {
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final String? expiresAt; // For Google OAuth format: "expires": "2025-12-06T02:18:28.529Z"
  final bool? requiresVerification;
  final String? verificationToken;
  final String? message;
  final bool? isVerified;
  final String? loginType;

  AuthResponse({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.expiresAt,
    this.requiresVerification,
    this.verificationToken,
    this.message,
    this.isVerified,
    this.loginType,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Parse expires - could be int (seconds) or string (ISO date)
    int? expiresInValue;
    String? expiresAtValue;
    
    if (json['expires_in'] != null) {
      expiresInValue = json['expires_in'] as int?;
    } else if (json['expiresIn'] != null) {
      expiresInValue = json['expiresIn'] as int?;
    } else if (json['expires'] != null) {
      // Google OAuth format: expires is ISO date string
      expiresAtValue = json['expires'] as String?;
      // Calculate expiresIn from the date
      if (expiresAtValue != null) {
        try {
          final expiryDate = DateTime.parse(expiresAtValue);
          expiresInValue = expiryDate.difference(DateTime.now()).inSeconds;
        } catch (e) {
          // Ignore parsing errors
        }
      }
    }
    
    return AuthResponse(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      // Support both 'access_token' (snake_case) and 'accessToken' (camelCase)
      accessToken: json['access_token'] ?? json['accessToken'],
      // Support both 'refresh_token' (snake_case) and 'refreshToken' (camelCase)
      refreshToken: json['refresh_token'] ?? json['refreshToken'],
      expiresIn: expiresInValue,
      expiresAt: expiresAtValue,
      // Support both formats
      requiresVerification: json['requires_verification'] ?? json['requiresVerification'],
      verificationToken: json['verification_token'] ?? json['verificationToken'],
      message: json['message'],
      isVerified: json['is_verified'] ?? json['isVerified'],
      loginType: json['login_type'] ?? json['loginType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'expires': expiresAt,
      'requires_verification': requiresVerification,
      'verification_token': verificationToken,
      'message': message,
      'is_verified': isVerified,
      'login_type': loginType,
    };
  }
}

