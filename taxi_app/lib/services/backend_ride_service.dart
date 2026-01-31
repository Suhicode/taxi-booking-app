import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'api_client.dart';
import '../models/ride_request_model.dart';
import 'socket_service.dart';

/// Backend-integrated ride booking service
class BackendRideService {
  final SocketService _socketService = SocketService();
  
  /// Create a new ride request
  Future<ApiResponse> createRideRequest({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required LatLng pickupLocation,
    required String pickupAddress,
    required LatLng destinationLocation,
    required String destinationAddress,
    required String vehicleType,
    double? estimatedFare,
    double? distance,
  }) async {
    try {
      final response = await ApiClient.post('/rides', {
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'pickupLat': pickupLocation.latitude,
        'pickupLon': pickupLocation.longitude,
        'pickupAddress': pickupAddress,
        'dropLat': destinationLocation.latitude,
        'dropLon': destinationLocation.longitude,
        'dropAddress': destinationAddress,
        'vehicleType': vehicleType.toLowerCase(),
        'estimatedFare': estimatedFare,
        'distanceKm': distance,
      });
      
      if (response.success && response.data != null) {
        // Subscribe to trip updates
        final rideId = response.data['rideId'].toString();
        _socketService.subscribeToTrip(rideId);
      }
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to create ride: ${e.toString()}');
    }
  }
  
  /// Get ride details
  Future<ApiResponse> getRideDetails(String rideId) async {
    try {
      return await ApiClient.get('/rides/$rideId');
    } catch (e) {
      return ApiResponse.error('Failed to get ride details: ${e.toString()}');
    }
  }
  
  /// Driver accepts a ride
  Future<ApiResponse> acceptRide(String rideId, String driverId, String driverName) async {
    try {
      final response = await ApiClient.put('/rides/$rideId/accept', {
        'driverId': driverId,
        'driverName': driverName,
      });
      
      if (response.success) {
        _socketService.acceptRideRequest(rideId, driverId, driverName);
      }
      
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to accept ride: ${e.toString()}');
    }
  }
  
  /// Driver starts the ride
  Future<ApiResponse> startRide(String rideId) async {
    try {
      return await ApiClient.put('/rides/$rideId/start', {});
    } catch (e) {
      return ApiResponse.error('Failed to start ride: ${e.toString()}');
    }
  }
  
  /// Complete a ride
  Future<ApiResponse> completeRide(
    String rideId, {
    double? actualFare,
    int? rating,
    String? feedback,
  }) async {
    try {
      return await ApiClient.put('/rides/$rideId/complete', {
        'actualFare': actualFare,
        'rating': rating,
        'feedback': feedback,
      });
    } catch (e) {
      return ApiResponse.error('Failed to complete ride: ${e.toString()}');
    }
  }
  
  /// Cancel a ride
  Future<ApiResponse> cancelRide(String rideId, {String? reason}) async {
    try {
      return await ApiClient.put('/rides/$rideId/cancel', {
        'reason': reason,
      });
    } catch (e) {
      return ApiResponse.error('Failed to cancel ride: ${e.toString()}');
    }
  }
  
  /// Estimate fare
  Future<ApiResponse> estimateFare({
    required LatLng pickup,
    required LatLng drop,
    required String vehicleType,
    bool usePickupZoneRates = true,
  }) async {
    try {
      return await ApiClient.post('/estimate-fare', {
        'pickup': {
          'lat': pickup.latitude,
          'lon': pickup.longitude,
        },
        'drop': {
          'lat': drop.latitude,
          'lon': drop.longitude,
        },
        'vehicleType': vehicleType.toLowerCase(),
        'usePickupZoneRates': usePickupZoneRates,
      });
    } catch (e) {
      return ApiResponse.error('Failed to estimate fare: ${e.toString()}');
    }
  }
  
  /// Get nearby drivers
  Future<ApiResponse> getNearbyDrivers(LatLng location, {double radius = 5.0}) async {
    try {
      return await ApiClient.get('/nearby-drivers', {
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'radius': radius.toString(),
      });
    } catch (e) {
      return ApiResponse.error('Failed to get nearby drivers: ${e.toString()}');
    }
  }
  
  /// Update driver location
  Future<ApiResponse> updateDriverLocation(String driverId, LatLng location) async {
    try {
      return await ApiClient.post('/driver-location', {
        'driverId': driverId,
        'lat': location.latitude,
        'lon': location.longitude,
      });
    } catch (e) {
      return ApiResponse.error('Failed to update driver location: ${e.toString()}');
    }
  }
  
  /// Subscribe to ride updates
  Stream<Map<String, dynamic>> subscribeToRideUpdates(String rideId) {
    _socketService.subscribeToTrip(rideId);
    return _socketService.tripLocationStream.where((data) => 
      data['tripId'] == rideId || data['rideId'] == rideId
    );
  }
  
  /// Get ride accepted stream
  Stream<Map<String, dynamic>> get rideAcceptedStream => _socketService.rideAcceptedStream;
  
  /// Get ride started stream
  Stream<Map<String, dynamic>> get rideStartedStream => _socketService.rideStartedStream;
  
  /// Get ride completed stream
  Stream<Map<String, dynamic>> get rideCompletedStream => _socketService.rideCompletedStream;
  
  /// Get ride cancelled stream
  Stream<Map<String, dynamic>> get rideCancelledStream => _socketService.rideCancelledStream;
  
  /// Get new ride request stream (for drivers)
  Stream<Map<String, dynamic>> get newRideRequestStream => _socketService.newRideRequestStream;
}
