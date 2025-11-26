import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/widgets/otp_input_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service_factory.dart';
import '../../../data/services/auth_storage_service.dart';
import '../../../routes/app_routes.dart';

class VerifyOtpPage extends StatefulWidget {
  final String email;

  const VerifyOtpPage({
    super.key,
    required this.email,
  });

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<OTPInputFieldState> _otpFieldKey = GlobalKey<OTPInputFieldState>();
  String _currentOtp = '';
  
  bool _isLoading = false;
  bool _isVerifying = false;
  int _timeLeft = 0;
  bool _canResend = true;
  Timer? _timer;

  final AuthService _authService = AuthService(
    apiService: ApiServiceFactory.getInstance(),
  );
  final AuthStorageService _authStorage = AuthStorageService();

  @override
  void initState() {
    super.initState();
    // Start with 0 countdown - user can resend immediately
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _timeLeft = 30;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _verifyOtp(String otp) async {
    setState(() {
      _isVerifying = true;
      _isLoading = true;
    });

    try {
      final response = await _authService.verifyOTP(
        email: widget.email,
        otpCode: otp,
      );

      if (response.accessToken != null && response.refreshToken != null) {
        // Store tokens
        await _authStorage.saveTokens(
          accessToken: response.accessToken!,
          refreshToken: response.refreshToken!,
        );
        
        // Update API service with access token
        ApiServiceFactory.getInstance().setAccessToken(response.accessToken);
        
        // Navigate to home
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
        // Clear OTP on error
        _otpFieldKey.currentState?.clear();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    _startCountdown();

    try {
      await _authService.resendOTP(email: widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode OTP telah dikirim ulang'),
            backgroundColor: AppColors.success,
          ),
        );
        _otpFieldKey.currentState?.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.email_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Verifikasi OTP',
                  style: AppTextStyles.h1(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kode verifikasi telah dikirim ke',
                  style: AppTextStyles.bodyMedium(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                OTPInputField(
                  key: _otpFieldKey,
                  length: 6,
                  onCompleted: _verifyOtp,
                  onChanged: (otp) {
                    setState(() {
                      _currentOtp = otp;
                    });
                  },
                  enabled: !_isLoading && !_isVerifying,
                ),
                const SizedBox(height: 16),
                if (_isVerifying)
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Memverifikasi kode...',
                          style: AppTextStyles.bodySmall(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                if (!_canResend)
                  Center(
                    child: Text(
                      'Kirim ulang kode dalam ${_timeLeft}s',
                      style: AppTextStyles.bodySmall(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Tidak menerima email?',
                          style: AppTextStyles.bodySmall(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _resendOtp,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            minimumSize: const Size(120, 48),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Kirim Ulang Kode',
                            style: AppTextStyles.bodyLarge(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

