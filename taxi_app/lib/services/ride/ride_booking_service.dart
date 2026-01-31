import 'dart:async';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/ride_request_model.dart';
import '../models/driver_profile_model.dart';
import 'driver_auth_service.dart';

class RideBookingService {
  static Map<String, RideRequestModel> _rideDatabase = {};
  static Map<String, List<String>> _driverRideNotifications = {}; // driverId -> list of rideIds
  
  /// Create a new ride request
  static Future<String> createRideRequest({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required LatLng pickupLocation,
    required String pickupAddress,
    required LatLng destinationLocation,
    required String destinationAddress,
    required String vehicleType,
    required double estimatedFare,
    required double distance,
  }) async {
    // Generate unique ride ID
    final rideId = 'ride_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    
    final rideRequest = RideRequestModel(
      id: rideId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      pickupLocation: pickupLocation,
      pickupAddress: pickupAddress,
      destinationLocation: destinationLocation,
      destinationAddress: destinationAddress,
      vehicleType: vehicleType,
      estimatedFare: estimatedFare,
      distance: distance,
      status: RideStatus.pending,
      paymentStatus: PaymentStatus.pending,
      createdAt: DateTime.now(),
      currentCustomerLocation: pickupLocation,
      paymentMethod: 'cash',
    );

    // Store in database
    _rideDatabase[rideId] = rideRequest;

    // Find nearby drivers and notify them
    await _notifyNearbyDrivers(rideRequest);

    return rideId;
  }

  /// Find nearby drivers and send them ride notifications
  static Future<void> _notifyNearbyDrivers(RideRequestModel rideRequest) async {
    try {
      // Get all available drivers
      final allDrivers = await DriverAuthService.getAllDrivers();
      final availableDrivers = allDrivers.where((driver) => 
        driver.isVerified && 
        driver.status.toLowerCase() == 'active'
      ).toList();

      // Find drivers within 5km radius
      final nearbyDrivers = <DriverProfileModel>[];
      const searchRadiusKm = 5.0;

      for (final driver in availableDrivers) {
        // For demo, assign random locations to drivers if they don't have one
        final driverLocation = _getDriverLocation(driver);
        final distance = _calculateDistance(rideRequest.pickupLocation, driverLocation);
        
        if (distance <= searchRadiusKm) {
          nearbyDrivers.add(driver);
        }
      }

      // Sort by distance (closest first)
      nearbyDrivers.sort((a, b) {
        final distanceA = _calculateDistance(rideRequest.pickupLocation, _getDriverLocation(a));
        final distanceB = _calculateDistance(rideRequest.pickupLocation, _getDriverLocation(b));
        return distanceA.compareTo(distanceB);
      });

      // Notify top 3 nearest drivers
      final maxNotifications = min(3, nearbyDrivers.length);
      for (int i = 0; i < maxNotifications; i++) {
        final driver = nearbyDrivers[i];
        _addRideNotificationForDriver(driver.id, rideRequest.id);
      }

      print('Notified ${maxNotifications} nearby drivers about ride ${rideRequest.id}');
    } catch (e) {
      print('Error notifying nearby drivers: $e');
    }
  }

  /// Get driver's current location (for demo purposes)
  static LatLng _getDriverLocation(DriverProfileModel driver) {
    // In a real app, this would come from GPS tracking
    // For demo, assign random locations around Chennai
    final random = Random(driver.id.hashCode);
    final baseLat = 13.0827; // Chennai
    final baseLng = 80.2707;
    
    return LatLng(
      baseLat + (random.nextDouble() - 0.5) * 0.1, // ±0.05 degrees
      baseLng + (random.nextDouble() - 0.5) * 0.1,
    );
  }

  /// Calculate distance between two points in kilometers
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  /// Add ride notification for a specific driver
  static void _addRideNotificationForDriver(String driverId, String rideId) {
    if (!_driverRideNotifications.containsKey(driverId)) {
      _driverRideNotifications[driverId] = [];
    }
    _driverRideNotifications[driverId]!.add(rideId);
  }

  /// Get pending ride requests for a driver
  static List<RideRequestModel> getPendingRidesForDriver(String driverId) {
    final rideIds = _driverRideNotifications[driverId] ?? [];
    return rideIds
        .map((id) => _rideDatabase[id])
        .where((ride) => ride != null && ride.status == RideStatus.pending)
        .cast<RideRequestModel>()
        .toList();
  }

  /// Accept a ride request
  static Future<bool> acceptRide(String rideId, String driverId, String driverName) async {
    try {
      final ride = _rideDatabase[rideId];
      if (ride == null || ride.status != RideStatus.pending) {
        return false;
      }

      // Update ride status
      final updatedRide = ride.copyWith(
        driverId: driverId,
        driverName: driverName,
        status: RideStatus.accepted,
        acceptedAt: DateTime.now(),
        estimatedArrivalMinutes: _calculateEstimatedArrival(ride),
      );

      _rideDatabase[rideId] = updatedRide;

      // Remove notifications for other drivers
      _removeRideNotificationsForOtherDrivers(rideId, driverId);

      print('Ride $rideId accepted by driver $driverId');
      return true;
    } catch (e) {
      print('Error accepting ride: $e');
      return false;
    }
  }

  /// Remove ride notifications for drivers other than the accepting driver
  static void _removeRideNotificationsForOtherDrivers(String rideId, String acceptingDriverId) {
    for (final driverId in _driverRideNotifications.keys) {
      if (driverId != acceptingDriverId) {
        _driverRideNotifications[driverId]?.remove(rideId);
      }
    }
  }

  /// Calculate estimated arrival time in minutes
  static int _calculateEstimatedArrival(RideRequestModel ride) {
    // Simple calculation: 2 minutes per km + 5 minutes base time
    final distance = ride.distance;
    return (5 + (distance * 2)).round();
  }

  /// Reject a ride request
  static Future<bool> rejectRide(String rideId, String driverId) async {
    try {
      // Remove notification for this driver
      _driverRideNotifications[driverId]?.remove(rideId);
      
      print('Ride $rideId rejected by driver $driverId');
      return true;
    } catch (e) {
      print('Error rejecting ride: $e');
      return false;
    }
  }

  /// Update customer's live location
  static Future<void> updateCustomerLocation(String rideId, LatLng newLocation) async {
    final ride = _rideDatabase[rideId];
    if (ride != null && ride.isActive) {
      final updatedRide = ride.copyWith(
        currentCustomerLocation: newLocation,
      );
      _rideDatabase[rideId] = updatedRide;
    }
  }

  /// Update driver's live location
  static Future<void> updateDriverLocation(String rideId, LatLng newLocation) async {
    final ride = _rideDatabase[rideId];
    if (ride != null && ride.isActive) {
      final updatedRide = ride.copyWith(
        currentDriverLocation: newLocation,
      );
      _rideDatabase[rideId] = updatedRide;
    }
  }

  /// Get ride details by ID
  static RideRequestModel? getRideById(String rideId) {
    return _rideDatabase[rideId];
  }

  /// Get all rides for a customer
  static List<RideRequestModel> getRidesForCustomer(String customerId) {
    return _rideDatabase.values
        .where((ride) => ride.customerId == customerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Most recent first
  }

  /// Get all rides for a driver
  static List<RideRequestModel> getRidesForDriver(String driverId) {
    return _rideDatabase.values
        .where((ride) => ride.driverId == driverId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Most recent first
  }

  /// Update ride status
  static Future<bool> updateRideStatus(String rideId, RideStatus newStatus) async {
    try {
      final ride = _rideDatabase[rideId];
      if (ride == null) {
        return false;
      }

      final updatedRide = ride.copyWith(
        status: newStatus,
        completedAt: newStatus == RideStatus.completed ? DateTime.now() : null,
      );

      _rideDatabase[rideId] = updatedRide;
      print('Ride $rideId status updated to ${newStatus.name}');
      return true;
    } catch (e) {
      print('Error updating ride status: $e');
      return false;
    }
  }

  /// Get active ride for a driver
  static RideRequestModel? getActiveRideForDriver(String driverId) {
    return _rideDatabase.values
        .where((ride) => ride.driverId == driverId && ride.isActive)
        .firstOrNull;
  }

  /// Get active ride for a customer
  static RideRequestModel? getActiveRideForCustomer(String customerId) {
    return _rideDatabase.values
        .where((ride) => ride.customerId == customerId && ride.isActive)
        .firstOrNull;
  }

  /// Cancel a ride request
  static Future<bool> cancelRide(String rideId) async {
    try {
      final ride = _rideDatabase[rideId];
      if (ride == null) {
        return false;
      }

      final updatedRide = ride.copyWith(
        status: RideStatus.cancelled,
      );

      _rideDatabase[rideId] = updatedRide;

      // Remove all notifications
      for (final driverId in _driverRideNotifications.keys) {
        _driverRideNotifications[driverId]?.remove(rideId);
      }

      print('Ride $rideId cancelled');
      return true;
    } catch (e) {
      print('Error cancelling ride: $e');
      return false;
    }
  }

  /// Complete a ride and update payment
  static Future<bool> completeRide(String rideId, double actualFare) async {
    try {
      final ride = _rideDatabase[rideId];
      if (ride == null || ride.status != RideStatus.inProgress) {
        return false;
      }

      final updatedRide = ride.copyWith(
        status: RideStatus.completed,
        completedAt: DateTime.now(),
        actualFare: actualFare,
        paymentStatus: PaymentStatus.paid,
      );

      _rideDatabase[rideId] = updatedRide;
      print('Ride $rideId completed with fare $actualFare');
      return true;
    } catch (e) {
      print('Error completing ride: $e');
      return false;
    }
  }

  /// Clear all data (for testing)
  static void clearAllData() {
    _rideDatabase.clear();
    _driverRideNotifications.clear();
  }
}
