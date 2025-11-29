import 'package:flutter/material.dart';
import 'app.dart';
import 'data/services/auth_storage_service.dart';
import 'data/services/api_service_factory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API service with saved token (if exists)
  await _initializeAuth();
  
  runApp(const MyApp());
}

/// Initialize authentication state from stored session
Future<void> _initializeAuth() async {
  try {
    final authStorage = AuthStorageService();
    final token = await authStorage.getAccessToken();
    
    if (token != null && token.isNotEmpty) {
      // Check if token is not expired
      final isExpired = await authStorage.isTokenExpired();
      if (!isExpired) {
        // Set token to API service for authenticated requests
        ApiServiceFactory.getInstance().setAccessToken(token);
        debugPrint('[Auth] Session restored from device storage');
      } else {
        // Token expired, clear session
        await authStorage.clearAll();
        debugPrint('[Auth] Session expired, cleared from device');
      }
    }
  } catch (e) {
    debugPrint('[Auth] Error initializing auth: $e');
  }
}
