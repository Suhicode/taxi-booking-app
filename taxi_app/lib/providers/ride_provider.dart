import 'package:flutter/foundation.dart';
import '../models/ride_state.dart';
import '../models/ride_request_model.dart';
import '../models/location_model.dart';
import '../services/ride_booking_service.dart';
import '../services/location_service.dart';
import '../services/fare_calculator_service.dart';
import '../constants/app_constants.dart';

class RideProvider extends ChangeNotifier {
  RideState _rideState = RideState.idle;
  RideRequestModel? _currentRide;
  LocationModel? _pickupLocation;
  LocationModel? _destinationLocation;
  String _selectedVehicleType = 'Standard';
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  RideState get rideState => _rideState;
  RideRequestModel? get currentRide => _currentRide;
  LocationModel? get pickupLocation => _pickupLocation;
  LocationModel? get destinationLocation => _destinationLocation;
  String get selectedVehicleType => _selectedVehicleType;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasActiveRide => _currentRide != null && _currentRide!.status.isActive;
  bool get canBookRide => _pickupLocation != null && _destinationLocation != null;

  // Setters
  void setPickupLocation(LocationModel? location) {
    _pickupLocation = location;
    notifyListeners();
  }

  void setDestinationLocation(LocationModel? location) {
    _destinationLocation = location;
    notifyListeners();
  }

  void setSelectedVehicleType(String vehicleType) {
    _selectedVehicleType = vehicleType;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setRideState(RideState state) {
    _rideState = state;
    notifyListeners();
  }

  void _setCurrentRide(RideRequestModel? ride) {
    _currentRide = ride;
    notifyListeners();
  }

  // Location methods
  Future<void> getCurrentLocation() async {
    try {
      _setLoading(true);
      _setError(null);
      
      final location = await LocationService.getCurrentLocation();
      if (location != null) {
        setPickupLocation(location);
      } else {
        _setError('Could not get current location');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<List<LocationModel>> searchLocations(String query) async {
    try {
      if (query.isEmpty) return [];
      return await LocationService.searchLocations(query);
    } catch (e) {
      _setError('Failed to search locations: $e');
      return [];
    }
  }

  // Fare calculation
  Map<String, dynamic>? calculateFare() {
    if (_pickupLocation == null || _destinationLocation == null) {
      return null;
    }

    try {
      return FareCalculator.calculateFareForRoute(
        vehicleType: _selectedVehicleType,
        pickup: _pickupLocation!,
        destination: _destinationLocation!,
        surgeMultiplier: AppConstants.surgeMultiplier,
      );
    } catch (e) {
      _setError('Failed to calculate fare: $e');
      return null;
    }
  }

  // Ride booking
  Future<bool> bookRide({
    required String customerId,
    required String customerName,
    required String customerPhone,
  }) async {
    if (_pickupLocation == null || _destinationLocation == null) {
      _setError('Please select pickup and destination locations');
      return false;
    }

    try {
      _setLoading(true);
      _setError(null);

      final fareData = calculateFare();
      if (fareData == null) {
        _setError('Could not calculate fare');
        return false;
      }

      final rideId = await RideBookingService.createRideRequest(
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        pickupLocation: _pickupLocation!,
        pickupAddress: _pickupLocation!.address ?? _pickupLocation!.name ?? 'Pickup',
        destinationLocation: _destinationLocation!,
        destinationAddress: _destinationLocation!.address ?? _destinationLocation!.name ?? 'Destination',
        vehicleType: _selectedVehicleType,
        estimatedFare: fareData['finalFare'],
        distance: fareData['distance'],
      );

      // Get the created ride
      final ride = RideBookingService.getRideById(rideId);
      if (ride != null) {
        _setCurrentRide(ride);
        _setRideState(RideState.searching);
        
        // Start monitoring ride status
        _monitorRideStatus();
        
        return true;
      } else {
        _setError('Failed to create ride request');
        return false;
      }
    } catch (e) {
      _setError('Failed to book ride: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _monitorRideStatus() {
    if (_currentRide == null) return;

    // Simulate periodic status checks
    Future.delayed(AppConstants.rideStatusCheckInterval, () {
      if (_currentRide != null) {
        _updateRideFromService();
      }
    });
  }

  void _updateRideFromService() {
    if (_currentRide == null) return;

    final updatedRide = RideBookingService.getRideById(_currentRide!.id);
    if (updatedRide != null) {
      _setCurrentRide(updatedRide);
      
      // Update ride state based on status
      switch (updatedRide.status) {
        case RideStatus.pending:
          _setRideState(RideState.searching);
          break;
        case RideStatus.accepted:
          _setRideState(RideState.driverAccepted);
          break;
        case RideStatus.started:
          _setRideState(RideState.rideStarted);
          break;
        case RideStatus.completed:
          _setRideState(RideState.completed);
          break;
        case RideStatus.cancelled:
          _setRideState(RideState.cancelled);
          break;
      }
      
      // Continue monitoring if ride is active
      if (updatedRide.status.isActive) {
        _monitorRideStatus();
      }
    }
  }

  Future<bool> cancelRide() async {
    if (_currentRide == null) return false;

    try {
      _setLoading(true);
      final success = await RideBookingService.updateRideStatus(
        _currentRide!.id, 
        RideStatus.cancelled
      );
      
      if (success) {
        _updateRideFromService();
        return true;
      } else {
        _setError('Failed to cancel ride');
        return false;
      }
    } catch (e) {
      _setError('Failed to cancel ride: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> startRide() async {
    if (_currentRide == null) return false;

    try {
      _setLoading(true);
      final success = await RideBookingService.updateRideStatus(
        _currentRide!.id, 
        RideStatus.started
      );
      
      if (success) {
        _updateRideFromService();
        return true;
      } else {
        _setError('Failed to start ride');
        return false;
      }
    } catch (e) {
      _setError('Failed to start ride: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> completeRide() async {
    if (_currentRide == null) return false;

    try {
      _setLoading(true);
      final success = await RideBookingService.updateRideStatus(
        _currentRide!.id, 
        RideStatus.completed
      );
      
      if (success) {
        _updateRideFromService();
        return true;
      } else {
        _setError('Failed to complete ride');
        return false;
      }
    } catch (e) {
      _setError('Failed to complete ride: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addRating(int rating, String? feedback) async {
    if (_currentRide == null) return false;

    try {
      _setLoading(true);
      final success = await RideBookingService.addRating(
        _currentRide!.id, 
        rating, 
        feedback
      );
      
      if (success) {
        _updateRideFromService();
        return true;
      } else {
        _setError('Failed to submit rating');
        return false;
      }
    } catch (e) {
      _setError('Failed to submit rating: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearRide() {
    _setCurrentRide(null);
    _setRideState(RideState.idle);
    setPickupLocation(null);
    setDestinationLocation(null);
    _setError(null);
  }

  void clearError() {
    _setError(null);
  }
}
