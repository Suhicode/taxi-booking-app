import 'package:flutter/material.dart';

class SimpleNotificationService {
  static final SimpleNotificationService _instance = SimpleNotificationService._internal();
  factory SimpleNotificationService() => _instance;
  SimpleNotificationService._internal();

  final List<NotificationMessage> _notifications = [];
  final List<VoidCallback> _listeners = [];

  /// Add notification listener
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove notification listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Show ride status notification
  void showRideStatusNotification({
    required String title,
    required String body,
    required String rideId,
  }) {
    final notification = NotificationMessage(
      id: DateTime.now().millisecondsSinceEpoch.hashCode,
      title: title,
      body: body,
      type: NotificationType.rideStatus,
      rideId: rideId,
      timestamp: DateTime.now(),
    );

    _notifications.add(notification);
    _notifyListeners();
    
    // Also show as snackbar for immediate feedback
    _showSnackBar(title, body);
  }

  /// Show driver assignment notification
  void showDriverAssignedNotification({
    required String driverName,
    required String vehicleNumber,
    required String rideId,
  }) {
    showRideStatusNotification(
      title: 'Driver Assigned! 🚗',
      body: '$driverName is on the way with $vehicleNumber',
      rideId: rideId,
    );
  }

  /// Show ride started notification
  void showRideStartedNotification({
    required String rideId,
  }) {
    showRideStatusNotification(
      title: 'Ride Started! 🚀',
      body: 'Your ride has started. Enjoy your journey!',
      rideId: rideId,
    );
  }

  /// Show ride completed notification
  void showRideCompletedNotification({
    required String rideId,
    required double fare,
  }) {
    showRideStatusNotification(
      title: 'Ride Completed! ✅',
      body: 'Your ride has ended. Fare: ₹${fare.toStringAsFixed(0)}',
      rideId: rideId,
    );
  }

  /// Show payment reminder notification
  void showPaymentReminderNotification({
    required String rideId,
    required double amount,
  }) {
    showRideStatusNotification(
      title: 'Payment Reminder 💰',
      body: 'Please pay ₹${amount.toStringAsFixed(0)} to your driver',
      rideId: rideId,
    );
  }

  /// Show new ride request notification (for drivers)
  void showNewRideRequestNotification({
    required String customerName,
    required String pickupAddress,
    required double estimatedFare,
    required String rideId,
  }) {
    showRideStatusNotification(
      title: 'New Ride Request! 🎯',
      body: 'From $customerName: $pickupAddress (₹${estimatedFare.toStringAsFixed(0)})',
      rideId: rideId,
    );
  }

  /// Show chat message notification
  void showChatMessageNotification({
    required String senderName,
    required String message,
    required String rideId,
  }) {
    showRideStatusNotification(
      title: 'New Message 💬',
      body: '$senderName: $message',
      rideId: rideId,
    );
  }

  /// Get all notifications
  List<NotificationMessage> get notifications => List.from(_notifications);

  /// Clear all notifications
  void clearNotifications() {
    _notifications.clear();
    _notifyListeners();
  }

  /// Clear specific notification
  void clearNotification(int notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _notifyListeners();
  }

  /// Show snackbar
  void _showSnackBar(String title, String message) {
    // This would need context to show snackbar
    // For now, just print to console
    debugPrint('🔔 $title: $message');
  }
}

enum NotificationType {
  rideStatus,
  chatMessage,
  payment,
  driverAssigned,
}

class NotificationMessage {
  final int id;
  final String title;
  final String body;
  final NotificationType type;
  final String? rideId;
  final DateTime timestamp;
  final bool isRead;

  NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.rideId,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationMessage copyWith({
    int? id,
    String? title,
    String? body,
    NotificationType? type,
    String? rideId,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      rideId: rideId ?? this.rideId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString(),
      'rideId': rideId,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NotificationType.rideStatus,
      ),
      rideId: json['rideId'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }
}
