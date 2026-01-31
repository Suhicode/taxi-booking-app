import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class FreeNotificationService {
  static final FreeNotificationService _instance = FreeNotificationService._internal();
  factory FreeNotificationService() => _instance;
  FreeNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher', // Use your app icon
    );

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('🔔 Free Notification Service initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');
    // Handle notification tap - navigate to appropriate screen
  }

  /// Show ride status notification
  Future<void> showRideStatusNotification({
    required String title,
    required String body,
    required String rideId,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ride_status_channel',
      'Ride Status Updates',
      channelDescription: 'Notifications for ride status changes',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Colors.blue,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.hashCode,
      title,
      body,
      platformDetails,
      payload: payload ?? 'ride_$rideId',
    );
  }

  /// Show driver assignment notification
  Future<void> showDriverAssignedNotification({
    required String driverName,
    required String vehicleNumber,
    required String rideId,
  }) async {
    await showRideStatusNotification(
      title: 'Driver Assigned! 🚗',
      body: '$driverName is on the way with $vehicleNumber',
      rideId: rideId,
      payload: 'driver_assigned_$rideId',
    );
  }

  /// Show ride started notification
  Future<void> showRideStartedNotification({
    required String rideId,
  }) async {
    await showRideStatusNotification(
      title: 'Ride Started! 🚀',
      body: 'Your ride has started. Enjoy your journey!',
      rideId: rideId,
      payload: 'ride_started_$rideId',
    );
  }

  /// Show ride completed notification
  Future<void> showRideCompletedNotification({
    required String rideId,
    required double fare,
  }) async {
    await showRideStatusNotification(
      title: 'Ride Completed! ✅',
      body: 'Your ride has ended. Fare: ₹${fare.toStringAsFixed(0)}',
      rideId: rideId,
      payload: 'ride_completed_$rideId',
    );
  }

  /// Show payment reminder notification
  Future<void> showPaymentReminderNotification({
    required String rideId,
    required double amount,
  }) async {
    await showRideStatusNotification(
      title: 'Payment Reminder 💰',
      body: 'Please pay ₹${amount.toStringAsFixed(0)} to your driver',
      rideId: rideId,
      payload: 'payment_reminder_$rideId',
    );
  }

  /// Show new ride request notification (for drivers)
  Future<void> showNewRideRequestNotification({
    required String customerName,
    required String pickupAddress,
    required double estimatedFare,
    required String rideId,
  }) async {
    await showRideStatusNotification(
      title: 'New Ride Request! 🎯',
      body: 'From $customerName: $pickupAddress (₹${estimatedFare.toStringAsFixed(0)})',
      rideId: rideId,
      payload: 'new_ride_$rideId',
    );
  }

  /// Show chat message notification
  Future<void> showChatMessageNotification({
    required String senderName,
    required String message,
    required String rideId,
  }) async {
    await showRideStatusNotification(
      title: 'New Message 💬',
      body: '$senderName: $message',
      rideId: rideId,
      payload: 'chat_$rideId',
    );
  }

  /// Schedule reminder notification
  Future<void> scheduleReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String notificationId,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Scheduled reminder notifications',
      importance: Importance.medium,
      priority: Priority.medium,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId.hashCode,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformDetails,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    
    return true; // Assume enabled on iOS
  }

  /// Show progress notification (for ride tracking)
  Future<void> showProgressNotification({
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
    required String rideId,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ride_progress_channel',
      'Ride Progress',
      channelDescription: 'Live ride progress updates',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      ongoing: true,
      autoCancel: false,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      rideId.hashCode,
      title,
      body,
      platformDetails,
      payload: 'progress_$rideId',
    );
  }

  /// Update progress notification
  Future<void> updateProgressNotification({
    required String title,
    required String body,
    required int progress,
    required String rideId,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ride_progress_channel',
      'Ride Progress',
      channelDescription: 'Live ride progress updates',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      ongoing: true,
      autoCancel: false,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      rideId.hashCode,
      title,
      body,
      platformDetails,
      payload: 'progress_$rideId',
    );
  }
}
