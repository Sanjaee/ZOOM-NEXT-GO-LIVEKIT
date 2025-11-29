import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/room_model.dart';
import '../../core/constants/api_config.dart';
import 'auth_storage_service.dart';

class RoomService {
  final String baseUrl;
  final AuthStorageService _authStorage = AuthStorageService();

  RoomService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get all rooms
  Future<List<RoomModel>> getRooms() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/rooms'),
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      final roomsData = data['data'] ?? data;
      
      if (roomsData is List) {
        return roomsData.map((r) => RoomModel.fromJson(r)).toList();
      }
      return [];
    }
    
    throw Exception('Failed to load rooms: ${response.body}');
  }

  /// Get my rooms (created by me)
  Future<List<RoomModel>> getMyRooms() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/rooms/my'),
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      final roomsData = data['data'] ?? data;
      
      if (roomsData is List) {
        return roomsData.map((r) => RoomModel.fromJson(r)).toList();
      }
      return [];
    }
    
    throw Exception('Failed to load my rooms: ${response.body}');
  }

  /// Create a new room
  Future<RoomModel> createRoom({
    required String name,
    String? description,
    int maxParticipants = 10,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/rooms'),
      headers: headers,
      body: json.encode({
        'name': name,
        'description': description,
        'max_participants': maxParticipants,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      final roomData = data['data'] ?? data;
      return RoomModel.fromJson(roomData);
    }
    
    throw Exception('Failed to create room: ${response.body}');
  }

  /// Join a room - returns LiveKit token and URL
  Future<JoinRoomResponse> joinRoom(String roomId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/rooms/$roomId/join'),
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      final joinData = data['data'] ?? data;
      return JoinRoomResponse.fromJson(joinData);
    }
    
    throw Exception('Failed to join room: ${response.body}');
  }

  /// Leave a room
  Future<void> leaveRoom(String roomId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/rooms/$roomId/leave'),
      headers: headers,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to leave room: ${response.body}');
    }
  }

  /// Delete a room
  Future<void> deleteRoom(String roomId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/rooms/$roomId'),
      headers: headers,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete room: ${response.body}');
    }
  }

  /// Get room by ID
  Future<RoomModel> getRoom(String roomId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/rooms/$roomId'),
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      final roomData = data['data'] ?? data;
      return RoomModel.fromJson(roomData);
    }
    
    throw Exception('Failed to get room: ${response.body}');
  }
}

