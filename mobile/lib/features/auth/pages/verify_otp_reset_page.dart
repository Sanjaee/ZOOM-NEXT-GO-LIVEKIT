import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/widgets/otp_input_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service_factory.dart';
import '../../../routes/app_routes.dart';

class _OTPInputFieldWrapper extends StatefulWidget {
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final bool enabled;

  const _OTPInputFieldWrapper({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<_OTPInputFieldWrapper> createState() => _OTPInputFieldWrapperState();
}

class _OTPInputFieldWrapperState extends State<_OTPInputFieldWrapper> {
  final GlobalKey<OTPInputFieldState> _otpKey = GlobalKey<OTPInputFieldState>();

  void clear() {
    _otpKey.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    return OTPInputField(
      key: _otpKey,
      length: 6,
      onCompleted: widget.onCompleted,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
    );
  }
}

class VerifyOtpResetPage extends StatefulWidget {
  final String email;

  const VerifyOtpResetPage({
    super.key,
    required this.email,
  });

  @override
  State<VerifyOtpResetPage> createState() => _VerifyOtpResetPageState();
}

class _VerifyOtpResetPageState extends State<VerifyOtpResetPage> {
  final GlobalKey<OTPInputFieldState> _otpFieldKey = GlobalKey<OTPInputFieldState>();
  String _currentOtp = '';
  bool _isLoading = false;
  int _timeLeft = 0;
  bool _canResend = true;
  Timer? _timer;

  final AuthService _authService = AuthService(
    apiService: ApiServiceFactory.getInstance(),
  );

  @override
  void initState() {
    super.initState();
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
      _isLoading = true;
    });

    try {
      // Store OTP in arguments for next page
      if (mounted) {
        Navigator.of(context).pushNamed(
          AppRoutes.verifyResetPassword,
          arguments: {
            'email': widget.email,
            'otp': otp,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
        _otpFieldKey.currentState?.clear();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    _startCountdown();

    try {
      await _authService.requestResetPassword(email: widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode reset telah dikirim ulang'),
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
                'Kode reset telah dikirim ke',
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
                  enabled: !_isLoading,
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
    );
  }
}

