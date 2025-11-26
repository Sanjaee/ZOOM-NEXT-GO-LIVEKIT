import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  String? accessToken;

  ApiService({required this.baseUrl});

  void setAccessToken(String? token) {
    accessToken = token;
  }

  Future<Map<String, dynamic>> request({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    final headers = {
      'Content-Type': 'application/json',
    };

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      // Check if response is successful (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Handle wrapped response
        if (responseData.containsKey('data')) {
          return responseData['data'] as Map<String, dynamic>;
        }
        return responseData;
      }

      // Handle error response
      final errorMessage = responseData['message'] ??
          responseData['error']?['message'] ??
          'HTTP ${response.statusCode}: ${response.reasonPhrase ?? "Unknown error"}';
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }
}

