import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import 'package:geolocator/geolocator.dart';

class DriverProvider with ChangeNotifier {
  Map<String, dynamic>? _driver;
  bool _isLoading = false;
  bool _isOnline = false;
  List<dynamic> _rides = [];
  Map<String, dynamic>? _earnings;
  String? _errorMessage;
  Position? _currentPosition;
  Map<String, dynamic>? _currentRideRequest;
  bool _isRideRequestActive = false;
  Timer? _locationUpdateTimer;
  StreamSubscription? _websocketSubscription;

  // Getters
  Map<String, dynamic>? get driver => _driver;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  List<dynamic> get rides => _rides;
  Map<String, dynamic>? get earnings => _earnings;
  String? get errorMessage => _errorMessage;
  Position? get currentPosition => _currentPosition;
  Map<String, dynamic>? get currentRideRequest => _currentRideRequest;
  bool get isRideRequestActive => _isRideRequestActive;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Driver Login
  Future<bool> login(String phone, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.driverLogin(phone, password);
      
      if (result['success']) {
        _driver = result['data']['user_data'];
        _isOnline = _driver!['is_online'] ?? false;
        await loadDriverProfile();
        
        // Connect WebSocket after successful login
        await _connectWebSocket();
        
        return true;
      } else {
        _setError(result['error']);
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Connect WebSocket
  Future<void> _connectWebSocket() async {
    if (_driver != null) {
      await WebSocketService.connect(_driver!['id'].toString());
      
      // Listen to WebSocket messages
      _websocketSubscription = WebSocketService.messageStream.listen((message) {
        _handleWebSocketMessage(message);
      });
    }
  }

  // Handle WebSocket messages
  void _handleWebSocketMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'ride_request':
        _showRideRequest(message);
        break;
      case 'ride_taken':
        if (_currentRideRequest != null && 
            _currentRideRequest!['ride_id'] == message['ride_id']) {
          _hideRideRequest();
          _setError('Ride was taken by another driver');
        }
        break;
      case 'error':
        _setError(message['message'] ?? 'WebSocket error');
        break;
      case 'disconnected':
        _setError('Connection lost. Reconnecting...');
        // Attempt to reconnect after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (_driver != null) {
            _connectWebSocket();
          }
        });
        break;
    }
  }

  // Show ride request
  void _showRideRequest(Map<String, dynamic> rideRequest) {
    _currentRideRequest = rideRequest;
    _isRideRequestActive = true;
    notifyListeners();
  }

  // Hide ride request
  void _hideRideRequest() {
    _currentRideRequest = null;
    _isRideRequestActive = false;
    notifyListeners();
  }

  // Accept ride request
  Future<bool> acceptRideRequest() async {
    if (_currentRideRequest == null) return false;

    try {
      // Send WebSocket message
      WebSocketService.acceptRide(_currentRideRequest!['ride_id']);
      
      // Also call REST API for confirmation
      final success = await acceptRide(_currentRideRequest!['ride_id']);
      
      if (success) {
        _hideRideRequest();
        return true;
      } else {
        _setError('Failed to accept ride');
        return false;
      }
    } catch (e) {
      _setError('Error accepting ride: $e');
      return false;
    }
  }

  // Reject ride request
  void rejectRideRequest() {
    if (_currentRideRequest == null) return;

    WebSocketService.rejectRide(_currentRideRequest!['ride_id']);
    _hideRideRequest();
  }

  // Ride request timeout
  void rideRequestTimeout() {
    _hideRideRequest();
    _setError('Ride request timed out');
  }

  // Driver Registration
  Future<bool> register(Map<String, dynamic> driverData) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.driverRegister(driverData);
      
      if (result['success']) {
        _driver = result['data']['user_data'];
        _isOnline = _driver!['is_online'] ?? false;
        await loadDriverProfile();
        
        // Connect WebSocket after successful registration
        await _connectWebSocket();
        
        return true;
      } else {
        _setError(result['error']);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load Driver Profile
  Future<void> loadDriverProfile() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.getDriverProfile();
      
      if (result['success']) {
        _driver = result['data'];
        _isOnline = _driver!['is_online'] ?? false;
      } else {
        _setError(result['error']);
      }
    } catch (e) {
      _setError('Failed to load profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle Online Status
  Future<bool> toggleOnlineStatus() async {
    _setError(null);

    try {
      final newStatus = !_isOnline;
      final result = await ApiService.updateStatus(newStatus);
      
      if (result['success']) {
        _isOnline = newStatus;
        if (_driver != null) {
          _driver!['is_online'] = newStatus;
        }
        
        // Start/stop location updates based on online status
        if (newStatus) {
          _startLocationUpdates();
        } else {
          _stopLocationUpdates();
        }
        
        notifyListeners();
        return true;
      } else {
        _setError(result['error']);
        return false;
      }
    } catch (e) {
      _setError('Failed to update status: $e');
      return false;
    }
  }

  // Start periodic location updates
  void _startLocationUpdates() {
    _stopLocationUpdates(); // Stop any existing timer
    
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentPosition != null) {
        updateLocation(_currentPosition!.latitude, _currentPosition!.longitude);
      }
    });
  }

  // Stop location updates
  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  // Update Location
  Future<void> updateLocation(double lat, double lng) async {
    try {
      final result = await ApiService.updateLocation(lat, lng);
      
      if (result['success']) {
        _currentPosition = Position(
          latitude: lat,
          longitude: lng,
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          timestamp: DateTime.now(),
        );
        
        // Send location via WebSocket if online
        if (_isOnline) {
          WebSocketService.sendLocationUpdate(lat, lng);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Location update failed: $e');
    }
  }

  // Get Current Location
  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await updateLocation(position.latitude, position.longitude);
    } catch (e) {
      _setError('Failed to get location: $e');
    }
  }

  // Load Rides
  Future<void> loadRides() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.getDriverRides();
      
      if (result['success']) {
        _rides = result['data'];
      } else {
        _setError(result['error']);
      }
    } catch (e) {
      _setError('Failed to load rides: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load Earnings
  Future<void> loadEarnings() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.getDriverEarnings();
      
      if (result['success']) {
        _earnings = result['data'];
      } else {
        _setError(result['error']);
      }
    } catch (e) {
      _setError('Failed to load earnings: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Accept Ride
  Future<bool> acceptRide(int rideId) async {
    _setError(null);

    try {
      final result = await ApiService.acceptRide(rideId);
      
      if (result['success']) {
        await loadRides(); // Refresh rides list
        return true;
      } else {
        _setError(result['error']);
        return false;
      }
    } catch (e) {
      _setError('Failed to accept ride: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Stop location updates
      _stopLocationUpdates();
      
      // Disconnect WebSocket
      await WebSocketService.disconnect();
      _websocketSubscription?.cancel();
      
      // Logout from API
      await ApiService.logout();
      
      // Clear state
      _driver = null;
      _isOnline = false;
      _rides = [];
      _earnings = null;
      _currentPosition = null;
      _currentRideRequest = null;
      _isRideRequestActive = false;
      
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: $e');
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    _websocketSubscription?.cancel();
    WebSocketService.dispose();
    super.dispose();
  }
}
