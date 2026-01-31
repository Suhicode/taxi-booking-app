import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/ride_request_model.dart';
import '../models/location_model.dart';
import '../constants/app_constants.dart';

class RideBookingService {
  static final List<RideRequestModel> _rides = [];

  static Future<String> createRideRequest({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required LocationModel pickupLocation,
    required String pickupAddress,
    required LocationModel destinationLocation,
    required String destinationAddress,
    required String vehicleType,
    required double estimatedFare,
    required double distance,
  }) async {
    try {
      final rideRequest = RideRequestModel(
        id: Uuid().v4(),
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
        createdAt: DateTime.now(),
        driverId: null,
        driverName: null,
        driverPhone: null,
        driverLocation: null,
        driverVehicleType: null,
        driverVehicleNumber: null,
        acceptedAt: null,
        startedAt: null,
        completedAt: null,
        cancelledAt: null,
        paymentStatus: PaymentStatus.pending,
        paymentMethod: null,
        rating: null,
        feedback: null,
      );

      _rides.add(rideRequest);
      
      // Simulate driver assignment after 5 seconds
      _simulateDriverAssignment(rideRequest.id);
      
      return rideRequest.id;
    } catch (e) {
      throw Exception('Failed to create ride request: $e');
    }
  }

  static void _simulateDriverAssignment(String rideId) {
    Future.delayed(const Duration(seconds: 5), () {
      final rideIndex = _rides.indexWhere((r) => r.id == rideId);
      if (rideIndex != -1) {
        final ride = _rides[rideIndex];
        if (ride.status == RideStatus.pending) {
          _rides[rideIndex] = ride.copyWith(
            status: RideStatus.accepted,
            driverId: 'driver_${DateTime.now().millisecondsSinceEpoch}',
            driverName: 'John Driver',
            driverPhone: '+1234567890',
            driverLocation: LocationModel(
              latitude: ride.pickupLocation.latitude + 0.001,
              longitude: ride.pickupLocation.longitude + 0.001,
            ),
            driverVehicleType: ride.vehicleType,
            driverVehicleNumber: 'ABC-1234',
            acceptedAt: DateTime.now(),
          );
        }
      }
    });
  }

  static RideRequestModel? getRideById(String rideId) {
    try {
      return _rides.firstWhere((ride) => ride.id == rideId);
    } catch (e) {
      return null;
    }
  }

  static List<RideRequestModel> getRidesByCustomerId(String customerId) {
    return _rides.where((ride) => ride.customerId == customerId).toList();
  }

  static List<RideRequestModel> getRidesByDriverId(String driverId) {
    return _rides.where((ride) => ride.driverId == driverId).toList();
  }

  static List<RideRequestModel> getActiveRides() {
    return _rides.where((ride) => 
      ride.status == RideStatus.accepted || 
      ride.status == RideStatus.started
    ).toList();
  }

  static Future<bool> updateRideStatus(String rideId, RideStatus newStatus) async {
    try {
      final rideIndex = _rides.indexWhere((r) => r.id == rideId);
      if (rideIndex != -1) {
        final ride = _rides[rideIndex];
        
        // Update timestamps
        DateTime? acceptedAt, startedAt, completedAt, cancelledAt;
        switch (newStatus) {
          case RideStatus.accepted:
            acceptedAt = DateTime.now();
            break;
          case RideStatus.started:
            startedAt = DateTime.now();
            break;
          case RideStatus.completed:
            completedAt = DateTime.now();
            break;
          case RideStatus.cancelled:
            cancelledAt = DateTime.now();
            break;
          case RideStatus.pending:
            break;
        }
        
        _rides[rideIndex] = ride.copyWith(
          status: newStatus,
          acceptedAt: acceptedAt,
          startedAt: startedAt,
          completedAt: completedAt,
          cancelledAt: cancelledAt,
        );
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateDriverLocation(String rideId, LocationModel location) async {
    try {
      final rideIndex = _rides.indexWhere((r) => r.id == rideId);
      if (rideIndex != -1) {
        final ride = _rides[rideIndex];
        _rides[rideIndex] = ride.copyWith(driverLocation: location);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updatePaymentStatus(String rideId, PaymentStatus status) async {
    try {
      final rideIndex = _rides.indexWhere((r) => r.id == rideId);
      if (rideIndex != -1) {
        final ride = _rides[rideIndex];
        _rides[rideIndex] = ride.copyWith(paymentStatus: status);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> addRating(String rideId, int rating, String? feedback) async {
    try {
      final rideIndex = _rides.indexWhere((r) => r.id == rideId);
      if (rideIndex != -1) {
        final ride = _rides[rideIndex];
        _rides[rideIndex] = ride.copyWith(
          rating: rating,
          feedback: feedback,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static List<RideRequestModel> getAllRides() {
    return List.from(_rides);
  }

  static void clearAllRides() {
    _rides.clear();
  }
}
