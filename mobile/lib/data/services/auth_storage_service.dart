import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _tokenExpiryKey = 'token_expiry';

  // Save access token
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  // Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Save refresh token
  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Save user data
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, json.encode(user.toJson()));
  }

  // Get user data
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userDataKey);
    if (userData != null && userData.isNotEmpty) {
      try {
        return User.fromJson(json.decode(userData));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Save token expiry time
  Future<void> saveTokenExpiry(int expiresIn) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
    await prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String());
  }

  // Check if token is expired
  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryString = prefs.getString(_tokenExpiryKey);
    if (expiryString == null) return true;
    
    try {
      final expiryTime = DateTime.parse(expiryString);
      // Consider expired if less than 5 minutes remaining
      return DateTime.now().isAfter(expiryTime.subtract(const Duration(minutes: 5)));
    } catch (e) {
      return true;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;
    
    // Optionally check token expiry
    final isExpired = await isTokenExpired();
    return !isExpired;
  }

  // Clear all tokens and user data (logout)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_tokenExpiryKey);
  }

  // Legacy method - now calls clearAll
  Future<void> clearTokens() async {
    await clearAll();
  }

  // Save tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  // Save complete session (tokens + user + expiry)
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    User? user,
    int? expiresIn,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
    if (user != null) {
      await saveUser(user);
    }
    if (expiresIn != null) {
      await saveTokenExpiry(expiresIn);
    }
  }
}

