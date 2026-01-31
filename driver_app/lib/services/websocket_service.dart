import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class WebSocketService {
  static WebSocketChannel? _channel;
  static StreamSubscription? _subscription;
  static final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  static Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  
  static bool get isConnected => _channel != null;
  
  // Connect to WebSocket
  static Future<void> connect(String driverId) async {
    try {
      // Close existing connection if any
      await disconnect();
      
      // Connect to WebSocket
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:8000/ws/driver/$driverId'),
      );
      
      // Listen for messages
      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message) as Map<String, dynamic>;
            _messageController.add(data);
            
            if (kDebugMode) {
              print('📨 WebSocket received: $data');
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ Failed to parse WebSocket message: $e');
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('❌ WebSocket error: $error');
          }
          _messageController.add({
            'type': 'error',
            'message': 'Connection error: $error',
          });
        },
        onDone: () {
          if (kDebugMode) {
            print('🔌 WebSocket connection closed');
          }
          _messageController.add({
            'type': 'disconnected',
            'message': 'Connection closed',
          });
          _channel = null;
        },
      );
      
      // Send heartbeat every 30 seconds
      Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_channel != null) {
          sendHeartbeat();
        } else {
          timer.cancel();
        }
      });
      
      if (kDebugMode) {
        print('✅ WebSocket connected for driver: $driverId');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to connect WebSocket: $e');
      }
      _messageController.add({
        'type': 'error',
        'message': 'Failed to connect: $e',
      });
    }
  }
  
  // Disconnect WebSocket
  static Future<void> disconnect() async {
    try {
      _subscription?.cancel();
      _subscription = null;
      
      if (_channel != null) {
        await _channel!.sink.close();
        _channel = null;
      }
      
      if (kDebugMode) {
        print('🔌 WebSocket disconnected');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error disconnecting WebSocket: $e');
      }
    }
  }
  
  // Send message to server
  static void sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode(message));
        
        if (kDebugMode) {
          print('📤 WebSocket sent: $message');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to send WebSocket message: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('❌ Cannot send message - WebSocket not connected');
      }
    }
  }
  
  // Send location update
  static void sendLocationUpdate(double lat, double lng) {
    sendMessage({
      'type': 'location_update',
      'lat': lat,
      'lng': lng,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Send heartbeat
  static void sendHeartbeat() {
    sendMessage({
      'type': 'heartbeat',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Send ride acceptance
  static void acceptRide(int rideId) {
    sendMessage({
      'type': 'ride_accept',
      'ride_id': rideId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Send ride rejection
  static void rejectRide(int rideId) {
    sendMessage({
      'type': 'ride_reject',
      'ride_id': rideId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  // Clean up resources
  static void dispose() {
    disconnect();
    _messageController.close();
  }
}
