import 'package:flutter/foundation.dart';
import '../models/ride_request_model.dart';
import '../models/location_model.dart';

class SimpleRideProvider extends ChangeNotifier {
  final List<RideRequestModel> _rides = [];
  RideRequestModel? _currentRide;
  bool _isLoading = false;
  String? _error;

  List<RideRequestModel> getAllRides() => List.from(_rides);
  RideRequestModel? get currentRide => _currentRide;

  Future<String?> createRideRequest({
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
        id: DateTime.now().millisecondsSinceEpoch.toString(),
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
        paymentStatus: PaymentStatus.pending,
      );

      _rides.add(rideRequest);
      notifyListeners();
      return rideRequest.id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateRideStatus(String rideId, RideStatus newStatus) async {
    try {
      final rideIndex = _rides.indexWhere((ride) => ride.id == rideId);
      if (rideIndex != -1) {
        final ride = _rides[rideIndex];
        final updatedRide = ride.copyWith(status: newStatus);
        
        DateTime? acceptedAt, startedAt, completedAt, cancelledAt;
        switch (newStatus) {
          case RideStatus.pending:
            break;
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
        }
        
        _rides[rideIndex] = updatedRide.copyWith(
          acceptedAt: acceptedAt,
          startedAt: startedAt,
          completedAt: completedAt,
          cancelledAt: cancelledAt,
        );
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDriverLocation(String rideId, LocationModel location) async {
    try {
      final rideIndex = _rides.indexWhere((ride) => ride.id == rideId);
      if (rideIndex != -1) {
        final ride = _rides[rideIndex];
        final updatedRide = ride.copyWith(driverLocation: location);
        _rides[rideIndex] = updatedRide;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addRating(String rideId, int rating, String? feedback) async {
    try {
      final rideIndex = _rides.indexWhere((ride) => ride.id == rideId);
      if (rideIndex != -1) {
        final ride = _rides[rideIndex];
        final updatedRide = ride.copyWith(rating: rating, feedback: feedback);
        _rides[rideIndex] = updatedRide;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String? get error => _error;
  bool get isLoading => _isLoading;
}
