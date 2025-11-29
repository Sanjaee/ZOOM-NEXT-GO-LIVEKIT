class ChatMessageModel {
  final String id;
  final String roomId;
  final String userId;
  final String userName;
  final String userEmail;
  final String message;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? json['ID'] ?? '',
      roomId: json['room_id'] ?? json['RoomID'] ?? '',
      userId: json['user_id'] ?? json['UserID'] ?? '',
      userName: json['user_name'] ?? json['UserName'] ?? 'Unknown',
      userEmail: json['user_email'] ?? json['UserEmail'] ?? '',
      message: json['message'] ?? json['Message'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['CreatedAt'] != null
              ? DateTime.parse(json['CreatedAt'])
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

