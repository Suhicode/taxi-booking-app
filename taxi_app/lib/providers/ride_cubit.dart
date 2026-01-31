import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as lat;
import '../models/ride_booking_state.dart';
import '../models/ride_state.dart';
import '../models/ride_request_model.dart';
import '../services/location_service.dart';
import '../services/pricing_service.dart';
import '../services/ride_booking_service.dart';
import '../services/driver_service_mock.dart';

class RideCubit extends Cubit<RideBookingState> {
  RideCubit() : super(const RideBookingState());

  final DriverService _driverService = DriverService();
  StreamSubscription<List<DriverModel>>? _driverSub;
  Timer? _rideUpdateTimer;

  // Driver markers for map
  Set<Marker> get driverMarkers => _driverMarkers;
  Set<Marker> _driverMarkers = {};

  @override
  Future<void> close() {
    _driverSub?.cancel();
    _rideUpdateTimer?.cancel();
    return super.close();
  }

  // Location Management
  Future<void> initializeLocation() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final granted = await LocationService.requestPermission();
      if (!granted) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Location permission required',
        ));
        return;
      }

      final loc = await LocationService.getCurrentLocation();
      if (loc != null) {
        emit(state.copyWith(
          currentLocation: loc,
          pickupLocation: loc,
          pickupText: 'Current Location',
          isLoading: false,
        ));
        _subscribeToDrivers();
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to get location',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Location initialization failed: $e',
      ));
    }
  }

  Future<void> getCurrentLocation() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final granted = await LocationService.requestPermission();
      if (!granted) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Location permission is required',
        ));
        return;
      }

      final location = await LocationService.getCurrentLocation();
      if (location != null) {
        emit(state.copyWith(
          currentLocation: location,
          pickupLocation: location,
          pickupText: 'Current Location',
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to get current location',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Error getting location: $e',
      ));
    }
  }

  void moveToLocation(lat.LatLng location) {
    emit(state.copyWith(
      currentLocation: location,
      pickupLocation: location,
    ));
    _updateEstimatedPrice();
  }

  // Location Selection
  void onPickupSelected(String name, lat.LatLng loc) {
    emit(state.copyWith(
      pickupLocation: loc,
      currentLocation: loc,
      pickupText: name,
    ));
    moveToLocation(loc);
  }

  void onDestinationSelected(String name, lat.LatLng loc) {
    emit(state.copyWith(
      destination: loc,
      destinationText: name,
    ));
    moveToLocation(loc);
  }

  // Vehicle Selection
  void selectVehicle(String vehicleType) {
    emit(state.copyWith(selectedVehicle: vehicleType));
    _updateEstimatedPrice();
  }

  // Pricing
  void _updateEstimatedPrice() {
    if (state.pickupLocation != null && state.destination != null) {
      final distance = calculateDistance(
        state.pickupLocation!,
        state.destination!,
      );
      final fare = PricingService.calculateFare(
        vehicleType: state.selectedVehicle,
        distanceKm: distance,
        durationMin: (distance * 3).toDouble(),
      );
      emit(state.copyWith(estimatedPrice: fare['total'] as int));
    }
  }

  double calculateDistance(lat.LatLng pickup, lat.LatLng destination) {
    return _calculateDistance(pickup, destination);
  }

  double _calculateDistance(lat.LatLng pickup, lat.LatLng destination) {
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

  // Driver Management
  void _subscribeToDrivers() {
    _driverSub = _driverService.getAvailableDrivers().listen((drivers) {
      final newSet = drivers.map((d) => d.toMarker()).toSet();
      final changed = newSet.length != _driverMarkers.length ||
          !newSet.every((m) => _driverMarkers.contains(m));
      if (changed) {
        _driverMarkers = newSet;
      }
    });
  }

  // Ride Booking
  Future<void> requestRide() async {
    if (kIsWeb) {
      emit(state.copyWith(
        errorMessage: 'Ride requests are disabled on web build. Please run on Android/iOS.',
      ));
      return;
    }

    if (state.pickupLocation == null || state.destination == null) {
      emit(state.copyWith(
        errorMessage: 'Set pickup and destination',
      ));
      return;
    }

    try {
      emit(state.copyWith(
        rideState: RideState.searching,
        isLoading: false,
        clearError: true,
      ));

      final distance = _calculateDistance(
        state.pickupLocation!,
        state.destination!,
      );

      final latPickup = lat.LatLng(
        state.pickupLocation!.latitude,
        state.pickupLocation!.longitude,
      );
      final latDestination = lat.LatLng(
        state.destination!.latitude,
        state.destination!.longitude,
      );

      final rideId = await RideBookingService.createRideRequest(
        customerId: 'customer_demo_001',
        customerName: 'Demo Customer',
        customerPhone: '9876543210',
        pickupLocation: latPickup,
        pickupAddress: state.pickupText.isNotEmpty ? state.pickupText : 'Pickup',
        destinationLocation: latDestination,
        destinationAddress: state.destinationText.isNotEmpty ? state.destinationText : 'Destination',
        vehicleType: state.selectedVehicle,
        estimatedFare: state.estimatedPrice.toDouble(),
        distance: distance,
      );

      emit(state.copyWith(
        currentRideId: rideId,
        notificationTitle: 'Ride requested',
        notificationSubtitle: 'Waiting for drivers...',
        showNotification: true,
      ));

      _startRideStatusUpdates(rideId);
    } catch (e) {
      emit(state.copyWith(
        rideState: RideState.idle,
        errorMessage: 'Could not request ride: $e',
      ));
    }
  }

  void _startRideStatusUpdates(String rideId) {
    _rideUpdateTimer?.cancel();

    _rideUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }

      final ride = RideBookingService.getRideById(rideId);
      if (ride != null) {
        if (ride.status == RideStatus.accepted && ride.driverId != null) {
          _handleDriverAssigned(ride.driverName!);
        } else if (ride.status == RideStatus.completed) {
          _handleRideEnded(RideState.rideCompleted);
        } else if (ride.status == RideStatus.cancelled) {
          _handleRideEnded(RideState.cancelled);
        }
      }
    });
  }

  void _handleDriverAssigned(String driverName) {
    emit(state.copyWith(
      rideState: RideState.driverAccepted,
      notificationTitle: 'Driver assigned',
      notificationSubtitle: driverName,
      showNotification: true,
    ));
  }

  void _handleRideEnded(RideState endState) {
    emit(state.copyWith(
      rideState: endState,
      notificationTitle: endState == RideState.rideCompleted 
          ? 'Ride completed' 
          : 'Ride cancelled',
      notificationSubtitle: null,
      showNotification: true,
    ));
    _rideUpdateTimer?.cancel();
  }

  // Ride Actions
  void cancelRide() {
    _rideUpdateTimer?.cancel();
    emit(state.copyWith(
      rideState: RideState.cancelled,
      currentRideId: null,
      currentRide: null,
      notificationTitle: 'Ride cancelled',
      showNotification: true,
    ));
  }

  void resetRide() {
    _rideUpdateTimer?.cancel();
    emit(const RideBookingState());
  }

  void clearNotification() {
    emit(state.copyWith(clearNotification: true));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
