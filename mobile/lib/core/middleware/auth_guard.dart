import 'package:flutter/material.dart';
import '../../data/services/auth_storage_service.dart';
import '../../routes/app_routes.dart';

class AuthGuard {
  static final AuthStorageService _authStorage = AuthStorageService();

  // Check if route requires authentication
  static bool requiresAuth(String routeName) {
    return routeName == AppRoutes.home || routeName == AppRoutes.profile;
  }

  // Check if route is auth page (login, register, etc)
  static bool isAuthRoute(String routeName) {
    return routeName == AppRoutes.login ||
        routeName == AppRoutes.register ||
        routeName == AppRoutes.verifyOtp ||
        routeName == AppRoutes.resetPassword ||
        routeName == AppRoutes.verifyOtpReset ||
        routeName == AppRoutes.verifyResetPassword;
  }

  // Guard auth routes - redirect to home if already logged in
  static Future<String?> guardAuthRoute(
    String routeName,
    BuildContext context,
  ) async {
    final isLoggedIn = await _authStorage.isLoggedIn();

    if (isLoggedIn && isAuthRoute(routeName)) {
      // User is logged in but trying to access auth page - redirect to home
      return AppRoutes.home;
    }

    return null; // Allow access
  }

  // Guard protected routes - redirect to login if not logged in
  static Future<String?> guardProtectedRoute(
    String routeName,
    BuildContext context,
  ) async {
    if (!requiresAuth(routeName)) {
      return null; // Route doesn't require auth
    }

    final isLoggedIn = await _authStorage.isLoggedIn();

    if (!isLoggedIn) {
      // User not logged in but trying to access protected route - redirect to login
      return AppRoutes.login;
    }

    return null; // Allow access
  }
}

