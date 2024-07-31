import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId; 
  final String message;
  final DateTime timestamp;
  final List<String> participants;
  final bool isGroup;
  final String? groupId;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    required this.participants,
    this.isGroup = false,
    this.groupId,
    this.isRead = false, 
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'],
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      message: data['message'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      participants: List<String>.from(data['participants']),
      isGroup: data['isGroup'] ?? false,
      groupId: data['groupId'],
      isRead: data['isRead'] ?? false, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'participants': participants,
      'isGroup': isGroup,
      'groupId': groupId,
      'isRead': isRead,
    };
  }
}

class ChatPreview {
  final String chatId;
  final String name;
  final String lastMessage;
  final String lastMessageTime;
  final bool isGroup;
  final String? userId;
  final String? groupPhotoUrl;

  ChatPreview({
    required this.chatId,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isGroup,
    this.userId,
    this.groupPhotoUrl,
  });
}
