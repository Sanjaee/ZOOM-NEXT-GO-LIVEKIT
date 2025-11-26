class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  // Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    if (value.length > 128) {
      return 'Password maksimal 128 karakter';
    }
    return null;
  }

  // Username validation
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username wajib diisi';
    }
    if (value.length < 3) {
      return 'Username minimal 3 karakter';
    }
    if (value.length > 50) {
      return 'Username maksimal 50 karakter';
    }
    return null;
  }

  // Confirm password validation
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    if (value != originalPassword) {
      return 'Password tidak cocok';
    }
    return null;
  }

  // OTP validation
  static String? otp(String? value, {int length = 6}) {
    if (value == null || value.isEmpty) {
      return 'Kode OTP wajib diisi';
    }
    if (value.length != length) {
      return 'Kode OTP harus $length digit';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Kode OTP harus berupa angka';
    }
    return null;
  }

  // Required field validation
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }
}

