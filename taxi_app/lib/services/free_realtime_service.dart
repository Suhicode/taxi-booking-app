import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class FreeRealtimeService {
  static final FreeRealtimeService _instance = FreeRealtimeService._internal();
  factory FreeRealtimeService() => _instance;
  FreeRealtimeService._internal();

  HttpServer? _server;
  final List<WebSocket> _connections = [];
  final Map<String, WebSocket> _driverConnections = {};
  final Map<String, WebSocket> _customerConnections = {};
  bool _isRunning = false;

  /// Start free WebSocket server (no external services needed)
  Future<bool> startServer({int port = 8080}) async {
    try {
      if (_isRunning) return true;

      _server = await HttpServer.bind('localhost', port);
      _isRunning = true;

      await for (HttpRequest request in _server!) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          _handleWebSocketConnection(await WebSocketTransformer.upgrade(request));
        } else {
          request.response.statusCode = HttpStatus.forbidden;
          await request.response.close();
        }
      }

      debugPrint('🚀 Free Realtime Server started on port $port');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start server: $e');
      return false;
    }
  }

  void _handleWebSocketConnection(WebSocket webSocket) {
    _connections.add(webSocket);
    String? userId;
    String? userType;

    webSocket.listen(
      (data) {
        try {
          final message = jsonDecode(data);
          final type = message['type'] as String?;

          switch (type) {
            case 'auth':
              userId = message['userId'] as String?;
              userType = message['userType'] as String?;
              
              if (userId != null && userType != null) {
                if (userType == 'driver') {
                  _driverConnections[userId!] = webSocket;
                } else {
                  _customerConnections[userId!] = webSocket;
                }
                
                debugPrint('👤 $userType connected: $userId');
              }
              break;

            case 'driver_location':
              if (userType == 'driver' && userId != null) {
                _broadcastDriverLocation(userId!, message);
              }
              break;

            case 'ride_request':
              _broadcastToNearbyDrivers(message);
              break;

            case 'ride_status':
              _broadcastRideStatus(message);
              break;

            case 'chat_message':
              _broadcastChatMessage(message);
              break;
          }
        } catch (e) {
          debugPrint('❌ Error handling message: $e');
        }
      },
      onDone: () {
        _connections.remove(webSocket);
        if (userId != null) {
          _driverConnections.remove(userId);
          _customerConnections.remove(userId);
        }
        debugPrint('🔌 User disconnected: $userId');
      },
      onError: (error) {
        debugPrint('❌ WebSocket error: $error');
      },
    );
  }

  void _broadcastDriverLocation(String driverId, Map<String, dynamic> message) {
    final locationMessage = {
      'type': 'driver_location_update',
      'driverId': driverId,
      'latitude': message['latitude'],
      'longitude': message['longitude'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Send to all customers who might be tracking this driver
    for (final connection in _customerConnections.values) {
      connection.add(jsonEncode(locationMessage));
    }
  }

  void _broadcastToNearbyDrivers(Map<String, dynamic> message) {
    final rideRequest = {
      'type': 'new_ride_request',
      'rideId': message['rideId'],
      'customerId': message['customerId'],
      'pickupLatitude': message['pickupLatitude'],
      'pickupLongitude': message['pickupLongitude'],
      'destinationLatitude': message['destinationLatitude'],
      'destinationLongitude': message['destinationLongitude'],
      'vehicleType': message['vehicleType'],
      'estimatedFare': message['estimatedFare'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Broadcast to all nearby drivers
    for (final connection in _driverConnections.values) {
      connection.add(jsonEncode(rideRequest));
    }
  }

  void _broadcastRideStatus(Map<String, dynamic> message) {
    final statusMessage = {
      'type': 'ride_status_update',
      'rideId': message['rideId'],
      'status': message['status'],
      'driverId': message['driverId'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Send to specific customer
    final customerId = message['customerId'] as String?;
    if (customerId != null && _customerConnections.containsKey(customerId)) {
      _customerConnections[customerId]!.add(jsonEncode(statusMessage));
    }
  }

  void _broadcastChatMessage(Map<String, dynamic> message) {
    final chatMessage = {
      'type': 'chat_message',
      'rideId': message['rideId'],
      'senderId': message['senderId'],
      'senderName': message['senderName'],
      'message': message['message'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Send to both driver and customer in the ride
    final driverId = message['driverId'] as String?;
    final customerId = message['customerId'] as String?;

    if (driverId != null && _driverConnections.containsKey(driverId)) {
      _driverConnections[driverId]!.add(jsonEncode(chatMessage));
    }
    if (customerId != null && _customerConnections.containsKey(customerId)) {
      _customerConnections[customerId]!.add(jsonEncode(chatMessage));
    }
  }

  /// Stop the server
  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
    }
    _isRunning = false;
    debugPrint('🛑 Server stopped');
  }

  /// Get server status
  bool get isRunning => _isRunning;
  int get connectedClients => _connections.length;
  int get connectedDrivers => _driverConnections.length;
  int get connectedCustomers => _customerConnections.length;
}

/// Client-side service for connecting to the free realtime server
class RealtimeClient {
  WebSocket? _webSocket;
  final String serverUrl;
  final Function(Map<String, dynamic>) onMessage;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;

  RealtimeClient({
    required this.serverUrl,
    required this.onMessage,
    this.onConnected,
    this.onDisconnected,
  });

  Future<bool> connect() async {
    try {
      _webSocket = await WebSocket.connect(serverUrl);
      
      _webSocket!.listen(
        (data) {
          try {
            final message = jsonDecode(data);
            onMessage(message);
          } catch (e) {
            debugPrint('❌ Error parsing message: $e');
          }
        },
        onDone: () {
          debugPrint('🔌 Disconnected from server');
          onDisconnected?.call();
        },
        onError: (error) {
          debugPrint('❌ WebSocket error: $error');
        },
      );

      onConnected?.call();
      debugPrint('🔌 Connected to realtime server');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to connect: $e');
      return false;
    }
  }

  void authenticate(String userId, String userType) {
    _sendMessage({
      'type': 'auth',
      'userId': userId,
      'userType': userType,
    });
  }

  void updateDriverLocation(double latitude, double longitude) {
    _sendMessage({
      'type': 'driver_location',
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  void sendRideRequest({
    required String rideId,
    required String customerId,
    required double pickupLatitude,
    required double pickupLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    required String vehicleType,
    required double estimatedFare,
  }) {
    _sendMessage({
      'type': 'ride_request',
      'rideId': rideId,
      'customerId': customerId,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'vehicleType': vehicleType,
      'estimatedFare': estimatedFare,
    });
  }

  void updateRideStatus({
    required String rideId,
    required String status,
    required String customerId,
    String? driverId,
  }) {
    _sendMessage({
      'type': 'ride_status',
      'rideId': rideId,
      'status': status,
      'customerId': customerId,
      'driverId': driverId,
    });
  }

  void sendChatMessage({
    required String rideId,
    required String senderId,
    required String senderName,
    required String message,
    required String driverId,
    required String customerId,
  }) {
    _sendMessage({
      'type': 'chat_message',
      'rideId': rideId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'driverId': driverId,
      'customerId': customerId,
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
      _webSocket!.add(jsonEncode(message));
    }
  }

  void disconnect() {
    _webSocket?.close();
    _webSocket = null;
  }

  bool get isConnected => _webSocket?.readyState == WebSocket.open;
}
