class ApiConfig {
  // Base URL untuk API - Ubah di sini saja untuk semua request
  // Development
  static const String baseUrl = 'http://192.168.194.248:5000';
  
  // Production (uncomment dan sesuaikan jika perlu)
  // static const String baseUrl = 'https://api.yourapp.com';
  
  // Staging (uncomment dan sesuaikan jika perlu)
  // static const String baseUrl = 'https://staging-api.yourapp.com';
  
  // Timeout untuk request (dalam detik)
  static const int requestTimeout = 30;
  
  // Retry count untuk failed request
  static const int retryCount = 3;
}

