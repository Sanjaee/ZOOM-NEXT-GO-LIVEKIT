import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message_model.dart';
import '../../core/constants/api_config.dart';
import 'auth_storage_service.dart';

class ChatService {
  final String baseUrl;
  final AuthStorageService _authStorage = AuthStorageService();
  
  WebSocketChannel? _channel;
  StreamController<ChatMessageModel>? _messageController;
  bool _isConnected = false;
  String? _currentRoomId;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  ChatService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get the current user ID from JWT token
  Future<String?> getCurrentUserId() async {
    final token = await _authStorage.getAccessToken();
    if (token == null) return null;
    
    try {
      // JWT token structure: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      // Decode payload (base64)
      String normalizedPayload = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalizedPayload));
      final payload = json.decode(payloadString);
      
      // Return userId from token (this is the database ID)
      return payload['userId'] ?? payload['user_id'] ?? payload['sub'];
    } catch (e) {
      debugPrint('[ChatService] Error decoding token: $e');
      return null;
    }
  }

  /// Get messages for a room
  Future<List<ChatMessageModel>> getMessages(String roomId, {int limit = 50, int offset = 0}) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/rooms/$roomId/messages?limit=$limit&offset=$offset'),
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      final messagesData = data['data'] ?? data;
      
      if (messagesData is List) {
        return messagesData.map((m) => ChatMessageModel.fromJson(m)).toList();
      }
      return [];
    }
    
    throw Exception('Failed to load messages: ${response.body}');
  }

  /// Send a message to a room
  Future<ChatMessageModel> sendMessage(String roomId, String message) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/rooms/$roomId/messages'),
      headers: headers,
      body: json.encode({'message': message}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      final messageData = data['data'] ?? data;
      return ChatMessageModel.fromJson(messageData);
    }
    
    throw Exception('Failed to send message: ${response.body}');
  }

  /// Connect to WebSocket for real-time messages
  Future<Stream<ChatMessageModel>> connectWebSocket(String roomId) async {
    // Clean up existing connection if any
    await disconnectWebSocket();
    
    _currentRoomId = roomId;
    _messageController = StreamController<ChatMessageModel>.broadcast();
    
    final token = await _authStorage.getAccessToken();
    if (token == null) {
      throw Exception('No access token available');
    }

    // Determine WebSocket URL based on base URL
    String wsUrl;
    if (baseUrl.startsWith('https://')) {
      wsUrl = baseUrl.replaceFirst('https://', 'wss://');
    } else if (baseUrl.startsWith('http://')) {
      wsUrl = baseUrl.replaceFirst('http://', 'ws://');
    } else {
      wsUrl = 'wss://$baseUrl';
    }
    
    final fullWsUrl = '$wsUrl/api/v1/rooms/$roomId/chat/ws?token=${Uri.encodeComponent(token)}';
    
    debugPrint('[ChatService] Connecting to WebSocket: ${fullWsUrl.replaceAll(RegExp(r'token=[^&]*'), 'token=***')}');
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(fullWsUrl));
      _isConnected = true;
      
      // Listen for messages
      _channel!.stream.listen(
        (data) {
          try {
            final message = json.decode(data);
            debugPrint('[ChatService] Received WebSocket message: ${message['type']}');
            
            if (message['type'] == 'message' && message['payload'] != null) {
              final chatMessage = ChatMessageModel.fromJson(message['payload']);
              _messageController?.add(chatMessage);
            }
          } catch (e) {
            debugPrint('[ChatService] Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          debugPrint('[ChatService] WebSocket error: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('[ChatService] WebSocket connection closed');
          _isConnected = false;
          _scheduleReconnect();
        },
      );
      
      // Start ping timer to keep connection alive
      _startPingTimer();
      
      debugPrint('[ChatService] WebSocket connected successfully');
      
    } catch (e) {
      debugPrint('[ChatService] Failed to connect WebSocket: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
    
    return _messageController!.stream;
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(json.encode({'type': 'ping'}));
        } catch (e) {
          debugPrint('[ChatService] Error sending ping: $e');
        }
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_currentRoomId != null) {
      _reconnectTimer = Timer(const Duration(seconds: 3), () {
        if (_currentRoomId != null && !_isConnected) {
          debugPrint('[ChatService] Attempting to reconnect...');
          connectWebSocket(_currentRoomId!);
        }
      });
    }
  }

  /// Disconnect WebSocket
  Future<void> disconnectWebSocket() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _currentRoomId = null;
    _isConnected = false;
    
    try {
      await _channel?.sink.close();
    } catch (e) {
      debugPrint('[ChatService] Error closing WebSocket: $e');
    }
    _channel = null;
    
    await _messageController?.close();
    _messageController = null;
  }

  /// Check if WebSocket is connected
  bool get isConnected => _isConnected;
}

