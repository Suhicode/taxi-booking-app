import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import 'package:geolocator/geolocator.dart';

class PassengerProvider with ChangeNotifier {
  Map<String, dynamic>? _passenger;
  bool _isLoading = false;
  List<dynamic> _activeRides = [];
  List<dynamic> _rideHistory = [];
  String? _errorMessage;
  Position? _currentPosition;
  Map<String, dynamic>? _currentRide;
  bool _isCreatingRide = false;
  Map<String, dynamic>? _assignedDriver;
  StreamSubscription? _websocketSubscription;

  // Getters
  Map<String, dynamic>? get passenger => _passenger;
  bool get isLoading => _isLoading;
  List<dynamic> get activeRides => _activeRides;
  List<dynamic> get rideHistory => _rideHistory;
  String? get errorMessage => _errorMessage;
  Position? get currentPosition => _currentPosition;
  Map<String, dynamic>? get currentRide => _currentRide;
  bool get isCreatingRide => _isCreatingRide;
  Map<String, dynamic>? get assignedDriver => _assignedDriver;

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

  // Passenger Login
  Future<bool> login(String phone, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.passengerLogin(phone, password);
      
      if (result['success']) {
        _passenger = result['data']['user_data'];
        await loadPassengerProfile();
        
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
    if (_passenger != null) {
      await CustomerWebSocketService.connect(_passenger!['id'].toString());
      
      // Listen to WebSocket messages
      _websocketSubscription = CustomerWebSocketService.messageStream.listen((message) {
        _handleWebSocketMessage(message);
      });
    }
  }

  // Handle WebSocket messages
  void _handleWebSocketMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'driver_assigned':
        _handleDriverAssigned(message);
        break;
      case 'driver_location_update':
        _handleDriverLocationUpdate(message);
        break;
      case 'ride_completed':
        _handleRideCompleted(message);
        break;
      case 'ride_cancelled':
        _handleRideCancelled(message);
        break;
      case 'error':
        _setError(message['message'] ?? 'WebSocket error');
        break;
      case 'disconnected':
        _setError('Connection lost. Reconnecting...');
        // Attempt to reconnect after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (_passenger != null) {
            _connectWebSocket();
          }
        });
        break;
    }
  }

  // Handle driver assignment
  void _handleDriverAssigned(Map<String, dynamic> message) {
    if (_currentRide != null && _currentRide!['id'] == message['ride_id']) {
      _assignedDriver = message['driver'];
      _currentRide!['driver'] = message['driver'];
      _currentRide!['status'] = 'accepted';
      notifyListeners();
    }
  }

  // Handle driver location update
  void _handleDriverLocationUpdate(Map<String, dynamic> message) {
    if (_currentRide != null && _currentRide!['id'] == message['ride_id']) {
      if (_currentRide!['driver'] != null) {
        _currentRide!['driver']['current_lat'] = message['driver']['current_lat'];
        _currentRide!['driver']['current_lng'] = message['driver']['current_lng'];
      }
      if (_assignedDriver != null) {
        _assignedDriver!['current_lat'] = message['driver']['current_lat'];
        _assignedDriver!['current_lng'] = message['driver']['current_lng'];
      }
      notifyListeners();
    }
  }

  // Handle ride completion
  void _handleRideCompleted(Map<String, dynamic> message) {
    if (_currentRide != null && _currentRide!['id'] == message['ride_id']) {
      _currentRide!['status'] = 'completed';
      _currentRide!['actual_fare'] = message['final_fare'];
      _currentRide!['duration_minutes'] = message['duration_minutes'];
      notifyListeners();
      
      // Refresh ride history
      loadRideHistory();
    }
  }

  // Handle ride cancellation
  void _handleRideCancelled(Map<String, dynamic> message) {
    if (_currentRide != null && _currentRide!['id'] == message['ride_id']) {
      _currentRide!['status'] = 'cancelled';
      notifyListeners();
      
      // Clear current ride after delay
      Future.delayed(const Duration(seconds: 2), () {
        clearCurrentRide();
      });
    }
  }

  // Passenger Registration
  Future<bool> register(Map<String, dynamic> passengerData) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.passengerRegister(passengerData);
      
      if (result['success']) {
        _passenger = result['data']['user_data'];
        await loadPassengerProfile();
        
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

  // Load Passenger Profile
  Future<void> loadPassengerProfile() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.getPassengerProfile();
      
      if (result['success']) {
        _passenger = result['data'];
      } else {
        _setError(result['error']);
      }
    } catch (e) {
      _setError('Failed to load profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create Ride Request
  Future<bool> createRide({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
    required String city,
  }) async {
    _setLoading(true);
    _setError(null);
    _isCreatingRide = true;
    notifyListeners();

    try {
      final result = await ApiService.createRide(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        pickupAddress: pickupAddress,
        dropLat: dropLat,
        dropLng: dropLng,
        dropAddress: dropAddress,
        city: city,
      );
      
      if (result['success']) {
        _currentRide = result['data'];
        await loadActiveRides();
        return true;
      } else {
        _setError(result['error']);
        return false;
      }
    } catch (e) {
      _setError('Failed to create ride: $e');
      return false;
    } finally {
      _setLoading(false);
      _isCreatingRide = false;
      notifyListeners();
    }
  }

  // Load Active Rides
  Future<void> loadActiveRides() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.getActiveRides();
      
      if (result['success']) {
        _activeRides = result['data'];
        
        // Update current ride if there's an active ride
        if (_activeRides.isNotEmpty) {
          _currentRide = _activeRides.firstWhere(
            (ride) => ride['status'] != 'completed',
            orElse: () => _activeRides.first,
          );
          
          // Extract driver info if available
          if (_currentRide!['driver'] != null) {
            _assignedDriver = _currentRide!['driver'];
          }
        } else {
          _currentRide = null;
          _assignedDriver = null;
        }
      } else {
        _setError(result['error']);
      }
    } catch (e) {
      _setError('Failed to load active rides: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load Ride History
  Future<void> loadRideHistory() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await ApiService.getRideHistory();
      
      if (result['success']) {
        _rideHistory = result['data'];
      } else {
        _setError(result['error']);
      }
    } catch (e) {
      _setError('Failed to load ride history: $e');
    } finally {
      _setLoading(false);
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

      _currentPosition = position;
      notifyListeners();
    } catch (e) {
      _setError('Failed to get location: $e');
    }
  }

  // Update current ride status
  void updateRideStatus(Map<String, dynamic> rideUpdate) {
    if (_currentRide != null && _currentRide!['id'] == rideUpdate['id']) {
      _currentRide = {..._currentRide!, ...rideUpdate};
      notifyListeners();
    }
    
    // Update active rides list
    final rideIndex = _activeRides.indexWhere((ride) => ride['id'] == rideUpdate['id']);
    if (rideIndex != -1) {
      _activeRides[rideIndex] = {..._activeRides[rideIndex], ...rideUpdate};
      notifyListeners();
    }
  }

  // Clear current ride
  void clearCurrentRide() {
    _currentRide = null;
    _assignedDriver = null;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    try {
      // Disconnect WebSocket
      await CustomerWebSocketService.disconnect();
      _websocketSubscription?.cancel();
      
      // Logout from API
      await ApiService.logout();
      
      // Clear state
      _passenger = null;
      _activeRides = [];
      _rideHistory = [];
      _currentPosition = null;
      _currentRide = null;
      _assignedDriver = null;
      
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
    _websocketSubscription?.cancel();
    CustomerWebSocketService.dispose();
    super.dispose();
  }
}
