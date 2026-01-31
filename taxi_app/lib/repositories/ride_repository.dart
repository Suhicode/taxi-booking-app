import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart' as lat;
import '../models/ride_request_model.dart';
import '../services/location_service.dart';
import '../services/pricing_service.dart';
import '../services/ride_booking_service.dart';
import '../services/driver_service_mock.dart';

class RideRepository {
  final DriverService _driverService = DriverService();

  // Location Management
  Future<lat.LatLng?> getCurrentLocation() async {
    try {
      final granted = await LocationService.requestPermission();
      if (!granted) {
        throw LocationPermissionException('Location permission required');
      }

      final location = await LocationService.getCurrentLocation();
      if (location == null) {
        throw LocationException('Unable to get location');
      }

      return location.toLatLng();
    } catch (e) {
      throw RideRepositoryException('Failed to get current location: $e');
    }
  }

  // Distance Calculation
  double calculateDistance(lat.LatLng pickup, lat.LatLng destination) {
    const double earthRadius = 6371;
    
    final double lat1Rad = pickup.latitude * (math.pi / 180);
    final double lat2Rad = destination.latitude * (math.pi / 180);
    final double deltaLatRad = (destination.latitude - pickup.latitude) * (math.pi / 180);
    final double deltaLonRad = (destination.longitude - pickup.longitude) * (math.pi / 180);
    
    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLonRad / 2) * math.sin(deltaLonRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  // Pricing Calculation
  int calculateEstimatedPrice({
    required String vehicleType,
    required lat.LatLng pickup,
    required lat.LatLng destination,
  }) {
    final distance = calculateDistance(pickup, destination);
    final fare = PricingService.calculateFare(
      vehicleType: vehicleType,
      distanceKm: distance,
      durationMin: (distance * 3).toDouble(),
    );
    return fare['total'] as int;
  }

  // Driver Management
  Stream<List<DriverModel>> getAvailableDrivers() {
    return _driverService.getAvailableDrivers();
  }

  // Ride Booking
  Future<String> createRideRequest({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required lat.LatLng pickupLocation,
    required String pickupAddress,
    required lat.LatLng destinationLocation,
    required String destinationAddress,
    required String vehicleType,
    required double estimatedFare,
    required double distance,
  }) async {
    if (kIsWeb) {
      throw RideRepositoryException('Ride requests are disabled on web build');
    }

    try {
      final rideId = await RideBookingService.createRideRequest(
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
      );
      return rideId;
    } catch (e) {
      throw RideRepositoryException('Failed to create ride request: $e');
    }
  }

  // Ride Status Tracking
  RideRequestModel? getRideById(String rideId) {
    return RideBookingService.getRideById(rideId);
  }

  Stream<RideStatus?> rideStatusStream(String rideId) {
    return Stream.periodic(const Duration(seconds: 3), (_) {
      final ride = RideBookingService.getRideById(rideId);
      return ride?.status;
    }).where((status) => status != null);
  }
}

// Custom Exceptions
class RideRepositoryException implements Exception {
  final String message;
  RideRepositoryException(this.message);
  
  @override
  String toString() => 'RideRepositoryException: $message';
}

class LocationPermissionException extends RideRepositoryException {
  LocationPermissionException(super.message);
}

class LocationException extends RideRepositoryException {
  LocationException(super.message);
}
