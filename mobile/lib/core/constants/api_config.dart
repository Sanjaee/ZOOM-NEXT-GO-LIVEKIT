class ApiConfig {
  // Base URL untuk API - Ubah di sini saja untuk semua request
  
  // Development (local)
  // static const String baseUrl = 'http://192.168.194.248:5000';
  
  // Production
  static const String baseUrl = 'https://zoom.zacloth.com';
  
  // LiveKit WebSocket URL (via nginx proxy)
  static const String livekitUrl = 'wss://zoom.zacloth.com/rtc';
  
  // Timeout untuk request (dalam detik)
  static const int requestTimeout = 30;
  
  // Retry count untuk failed request
  static const int retryCount = 3;
}

