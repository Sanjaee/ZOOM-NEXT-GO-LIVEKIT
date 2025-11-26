import '../services/api_service.dart';
import '../../core/constants/api_config.dart';

/// Factory untuk membuat instance ApiService dengan baseUrl dari config
/// Gunakan ini untuk membuat ApiService di seluruh aplikasi
class ApiServiceFactory {
  static ApiService? _instance;

  /// Mendapatkan singleton instance ApiService
  static ApiService getInstance() {
    _instance ??= ApiService(baseUrl: ApiConfig.baseUrl);
    return _instance!;
  }

  /// Membuat instance baru ApiService (jika diperlukan instance berbeda)
  static ApiService createInstance() {
    return ApiService(baseUrl: ApiConfig.baseUrl);
  }

  /// Reset instance (untuk testing atau perubahan baseUrl)
  static void resetInstance() {
    _instance = null;
  }
}

