class RoomModel {
  final String id;
  final String name;
  final String? description;
  final String hostId;
  final String? hostName;
  final int maxParticipants;
  final int currentParticipants;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RoomModel({
    required this.id,
    required this.name,
    this.description,
    required this.hostId,
    this.hostName,
    this.maxParticipants = 10,
    this.currentParticipants = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? json['ID'] ?? '',
      name: json['name'] ?? json['Name'] ?? '',
      description: json['description'] ?? json['Description'],
      hostId: json['host_id'] ?? json['HostID'] ?? json['host_user_id'] ?? '',
      hostName: json['host_name'] ?? json['HostName'] ?? json['host']?['full_name'],
      maxParticipants: json['max_participants'] ?? json['MaxParticipants'] ?? 10,
      currentParticipants: json['current_participants'] ?? json['CurrentParticipants'] ?? 0,
      isActive: json['is_active'] ?? json['IsActive'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : (json['CreatedAt'] != null ? DateTime.parse(json['CreatedAt']) : DateTime.now()),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : (json['UpdatedAt'] != null ? DateTime.parse(json['UpdatedAt']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'host_id': hostId,
      'max_participants': maxParticipants,
    };
  }
}

class JoinRoomResponse {
  final String token;
  final String url;
  final RoomModel? room;

  JoinRoomResponse({
    required this.token,
    required this.url,
    this.room,
  });

  factory JoinRoomResponse.fromJson(Map<String, dynamic> json) {
    return JoinRoomResponse(
      token: json['token'] ?? '',
      url: json['url'] ?? '',
      room: json['room'] != null ? RoomModel.fromJson(json['room']) : null,
    );
  }
}

