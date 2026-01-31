import 'package:flutter/material.dart';

class InAppChatService {
  static final InAppChatService _instance = InAppChatService._internal();
  factory InAppChatService() => _instance;
  InAppChatService._internal();

  final List<ChatMessage> _messages = [];
  final List<VoidCallback> _listeners = [];

  /// Add chat listener
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove chat listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Send message
  void sendMessage({
    required String rideId,
    required String senderId,
    required String senderName,
    required String message,
  required String receiverId,
  required String receiverName,
  bool isDriver = false,
  }) {
    final chatMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.hashCode,
      rideId: rideId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      receiverId: receiverId,
      receiverName: receiverName,
      timestamp: DateTime.now(),
      isDriver: isDriver,
    );

    _messages.add(chatMessage);
    _notifyListeners();
  }

  /// Get all messages for a ride
  List<ChatMessage> getMessagesForRide(String rideId) {
    return _messages.where((msg) => msg.rideId == rideId).toList();
  }

  /// Get all messages
  List<ChatMessage> getAllMessages() {
    return List.from(_messages);
  }

  /// Clear messages for a ride
  void clearMessagesForRide(String rideId) {
    _messages.removeWhere((msg) => msg.rideId == rideId);
    _notifyListeners();
  }

  /// Clear all messages
  void clearAllMessages() {
    _messages.clear();
    _notifyListeners();
  }

  /// Mark message as read
  void markMessageAsRead(int messageId) {
    final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
    if (messageIndex != -1) {
      _messages[messageIndex] = _messages[messageIndex].copyWith(isRead: true);
      _notifyListeners();
    }
  }
}

class ChatMessage {
  final int id;
  final String rideId;
  final String senderId;
  final String senderName;
  final String message;
  final String receiverId;
  final String receiverName;
  final DateTime timestamp;
  final bool isRead;
  final bool isDriver;

  ChatMessage({
    required this.id,
    required this.rideId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.receiverId,
    required this.receiverName,
    required this.timestamp,
    this.isRead = false,
    this.isDriver = false,
  });

  ChatMessage copyWith({
    int? id,
    String? rideId,
    String? senderId,
    String? senderName,
    String? message,
    String? receiverId,
    String? receiverName,
    DateTime? timestamp,
    bool? isRead,
    bool? isDriver,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDriver: isDriver ?? this.isDriver,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rideId': rideId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isDriver': isDriver,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      rideId: json['rideId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      message: json['message'],
      receiverId: json['receiverId'],
      receiverName: json['receiverName'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      isDriver: json['isDriver'] ?? false,
    );
  }
}
