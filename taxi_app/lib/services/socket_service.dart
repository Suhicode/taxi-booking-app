import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Socket.IO service for real-time communication
class SocketService {
  static SocketService? _instance;
  IO.Socket? _socket;
  bool _isConnected = false;
  
  // Stream controllers for different events
  final _rideAcceptedController = StreamController<Map<String, dynamic>>.broadcast();
  final _rideStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final _rideCompletedController = StreamController<Map<String, dynamic>>.broadcast();
  final _rideCancelledController = StreamController<Map<String, dynamic>>.broadcast();
  final _tripLocationController = StreamController<Map<String, dynamic>>.broadcast();
  final _newRideRequestController = StreamController<Map<String, dynamic>>.broadcast();
  final _nearbyDriversController = StreamController<List<dynamic>>.broadcast();
  
  SocketService._();
  
  factory SocketService() {
    _instance ??= SocketService._();
    return _instance!;
  }
  
  /// Connect to Socket.IO server
  Future<void> connect({String? serverUrl}) async {
    if (_isConnected && _socket?.connected == true) {
      return;
    }
    
    final url = serverUrl ?? 'http://localhost:3000';
    // For Android emulator: 'http://10.0.2.2:3000'
    // For physical device: 'http://YOUR_COMPUTER_IP:3000'
    
    try {
      _socket = IO.io(
        url,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build(),
      );
      
      _socket!.onConnect((_) {
        _isConnected = true;
        print('Socket.IO connected');
      });
      
      _socket!.onDisconnect((_) {
        _isConnected = false;
        print('Socket.IO disconnected');
      });
      
      _socket!.onError((error) {
        print('Socket.IO error: $error');
      });
      
      // Listen to ride events
      _setupEventListeners();
      
    } catch (e) {
      print('Error connecting to Socket.IO: $e');
      _isConnected = false;
    }
  }
  
  /// Setup event listeners
  void _setupEventListeners() {
    _socket!.on('ride-accepted', (data) {
      _rideAcceptedController.add(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('ride-started', (data) {
      _rideStartedController.add(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('ride-completed', (data) {
      _rideCompletedController.add(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('ride-cancelled', (data) {
      _rideCancelledController.add(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('trip-location', (data) {
      _tripLocationController.add(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('new-ride-request', (data) {
      _newRideRequestController.add(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('nearby-drivers-update', (data) {
      if (data is List) {
        _nearbyDriversController.add(data);
      }
    });
  }
  
  /// Subscribe to trip updates
  void subscribeToTrip(String tripId) {
    _socket?.emit('subscribe-trip', tripId);
  }
  
  /// Driver goes online
  void driverOnline(String driverId, {double? lat, double? lon}) {
    _socket?.emit('driver-online', {
      'driverId': driverId,
      'lat': lat,
      'lon': lon,
    });
  }
  
  /// Driver goes offline
  void driverOffline(String driverId) {
    _socket?.emit('driver-offline', {'driverId': driverId});
  }
  
  /// Update driver location
  void updateDriverLocation(String driverId, double lat, double lon) {
    _socket?.emit('driver-location-update', {
      'driverId': driverId,
      'lat': lat,
      'lon': lon,
    });
  }
  
  /// Update trip location (during ride)
  void updateTripLocation(String tripId, double lat, double lon) {
    _socket?.emit('trip-location-update', {
      'tripId': tripId,
      'lat': lat,
      'lon': lon,
    });
  }
  
  /// Accept ride request (driver)
  void acceptRideRequest(String rideId, String driverId, String driverName) {
    _socket?.emit('accept-ride-request', {
      'rideId': rideId,
      'driverId': driverId,
      'driverName': driverName,
    });
  }
  
  // Stream getters
  Stream<Map<String, dynamic>> get rideAcceptedStream => _rideAcceptedController.stream;
  Stream<Map<String, dynamic>> get rideStartedStream => _rideStartedController.stream;
  Stream<Map<String, dynamic>> get rideCompletedStream => _rideCompletedController.stream;
  Stream<Map<String, dynamic>> get rideCancelledStream => _rideCancelledController.stream;
  Stream<Map<String, dynamic>> get tripLocationStream => _tripLocationController.stream;
  Stream<Map<String, dynamic>> get newRideRequestStream => _newRideRequestController.stream;
  Stream<List<dynamic>> get nearbyDriversStream => _nearbyDriversController.stream;
  
  /// Check if connected
  bool get isConnected => _isConnected && (_socket?.connected ?? false);
  
  /// Disconnect
  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
  }
  
  /// Dispose
  void dispose() {
    disconnect();
    _rideAcceptedController.close();
    _rideStartedController.close();
    _rideCompletedController.close();
    _rideCancelledController.close();
    _tripLocationController.close();
    _newRideRequestController.close();
    _nearbyDriversController.close();
  }
}
