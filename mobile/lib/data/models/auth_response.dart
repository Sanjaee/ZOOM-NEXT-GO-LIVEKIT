import 'user_model.dart';

class AuthResponse {
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final bool? requiresVerification;
  final String? verificationToken;
  final String? message;

  AuthResponse({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.requiresVerification,
    this.verificationToken,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      expiresIn: json['expires_in'],
      requiresVerification: json['requires_verification'],
      verificationToken: json['verification_token'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'requires_verification': requiresVerification,
      'verification_token': verificationToken,
      'message': message,
    };
  }
}

