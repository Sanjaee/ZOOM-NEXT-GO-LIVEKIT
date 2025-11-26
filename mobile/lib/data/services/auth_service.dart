import '../models/auth_response.dart';
import 'api_service.dart';

class AuthService {
  final ApiService apiService;

  AuthService({required this.apiService});

  // Register
  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
    String? username,
    String? phone,
    String userType = 'member',
    String? gender,
    String? dateOfBirth,
  }) async {
    final data = await apiService.request(
      endpoint: '/api/v1/auth/register',
      method: 'POST',
      body: {
        'full_name': fullName,
        'email': email,
        'password': password,
        if (username != null) 'username': username,
        if (phone != null) 'phone': phone,
        'user_type': userType,
        if (gender != null) 'gender': gender,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      },
    );

    return AuthResponse.fromJson(data);
  }

  // Login
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final data = await apiService.request(
      endpoint: '/api/v1/auth/login',
      method: 'POST',
      body: {
        'email': email,
        'password': password,
      },
    );

    return AuthResponse.fromJson(data);
  }

  // Verify OTP
  Future<AuthResponse> verifyOTP({
    required String email,
    required String otpCode,
  }) async {
    final data = await apiService.request(
      endpoint: '/api/v1/auth/verify-otp',
      method: 'POST',
      body: {
        'email': email,
        'otp_code': otpCode,
      },
    );

    return AuthResponse.fromJson(data);
  }

  // Resend OTP
  Future<void> resendOTP({
    required String email,
  }) async {
    await apiService.request(
      endpoint: '/api/v1/auth/resend-otp',
      method: 'POST',
      body: {
        'email': email,
      },
    );
  }

  // Request Reset Password
  Future<void> requestResetPassword({
    required String email,
  }) async {
    await apiService.request(
      endpoint: '/api/v1/auth/forgot-password',
      method: 'POST',
      body: {
        'email': email,
      },
    );
  }

  // Verify Reset Password
  Future<void> verifyResetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    await apiService.request(
      endpoint: '/api/v1/auth/verify-reset-password',
      method: 'POST',
      body: {
        'email': email,
        'otp_code': otpCode,
        'new_password': newPassword,
      },
    );
  }

  // Verify Email
  Future<AuthResponse> verifyEmail({
    required String token,
  }) async {
    final data = await apiService.request(
      endpoint: '/api/v1/auth/verify-email',
      method: 'POST',
      body: {
        'token': token,
      },
    );

    return AuthResponse.fromJson(data);
  }
}

