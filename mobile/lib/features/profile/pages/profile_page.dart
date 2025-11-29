import 'package:flutter/material.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_storage_service.dart';
import '../../../data/services/api_service_factory.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authStorage = AuthStorageService();
      final user = await authStorage.getUser();
      
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Profile] Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Clear access token from API service first
      ApiServiceFactory.getInstance().setAccessToken(null);
      
      // Clear all session data from storage
      final authStorage = AuthStorageService();
      await authStorage.clearAll();
      
      // Wait a bit to ensure tokens are cleared
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Navigate to login and remove ALL previous routes
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false, // Remove all previous routes - cannot go back
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(
        title: 'Profile',
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header
                    Center(
                      child: Column(
                        children: [
                          // Profile Photo - show network image if available
                          _user?.profilePhoto != null && _user!.profilePhoto!.isNotEmpty
                              ? CircleAvatar(
                                  radius: 50,
                                  backgroundImage: NetworkImage(_user!.profilePhoto!),
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  onBackgroundImageError: (_, __) {},
                                )
                              : CircleAvatar(
                                  radius: 50,
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  child: Text(
                                    (_user?.fullName.isNotEmpty == true 
                                        ? _user!.fullName[0] 
                                        : '?').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 16),
                          Text(
                            _user?.fullName ?? 'N/A',
                            style: AppTextStyles.h3(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _user?.email ?? 'N/A',
                            style: AppTextStyles.bodyMedium(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                          // Show login type badge
                          if (_user?.loginType != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _user?.loginType == 'google' 
                                    ? Colors.blue.withOpacity(0.1) 
                                    : AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _user?.loginType == 'google' 
                                        ? Icons.g_mobiledata 
                                        : Icons.email_outlined,
                                    size: 16,
                                    color: _user?.loginType == 'google' 
                                        ? Colors.blue 
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _user?.loginType == 'google' ? 'Google' : 'Email',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _user?.loginType == 'google' 
                                          ? Colors.blue 
                                          : AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Profile Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem(
                            context,
                            'Username',
                            _user?.username ?? 'Tidak ada',
                            Icons.person_outline,
                          ),
                          const Divider(height: 32),
                          _buildDetailItem(
                            context,
                            'Email',
                            _user?.email ?? 'N/A',
                            Icons.email_outlined,
                          ),
                          const Divider(height: 32),
                          _buildDetailItem(
                            context,
                            'Tipe User',
                            _user?.userType ?? 'N/A',
                            Icons.badge_outlined,
                          ),
                          const Divider(height: 32),
                          _buildDetailItem(
                            context,
                            'Status',
                            _user?.isVerified == true ? 'Terverifikasi' : 'Belum Terverifikasi',
                            _user?.isVerified == true ? Icons.verified : Icons.verified_user_outlined,
                            color: _user?.isVerified == true ? AppColors.success : AppColors.warning,
                          ),
                          const Divider(height: 32),
                          _buildDetailItem(
                            context,
                            'Login Via',
                            _user?.loginType == 'google' ? 'Google Account' : 'Email & Password',
                            _user?.loginType == 'google' ? Icons.g_mobiledata : Icons.lock_outline,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Logout Button
                    PrimaryButton(
                      text: 'Logout',
                      onPressed: _handleLogout,
                      backgroundColor: AppColors.error,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final itemColor = color ?? AppColors.primary;

    return Row(
      children: [
        Icon(
          icon,
          color: itemColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall(
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyMedium(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

