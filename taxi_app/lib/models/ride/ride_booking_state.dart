import 'package:latlong2/latlong.dart' as lat;
import 'ride_request_model.dart';
import 'ride_state.dart';

class RideBookingState {
  final RideState rideState;
  final lat.LatLng? currentLocation;
  final lat.LatLng? pickupLocation;
  final lat.LatLng? destination;
  final String pickupText;
  final String destinationText;
  final String selectedVehicle;
  final int estimatedPrice;
  final bool isLoading;
  final String? currentRideId;
  final RideRequestModel? currentRide;
  final String? errorMessage;
  final String? notificationTitle;
  final String? notificationSubtitle;
  final bool showNotification;

  const RideBookingState({
    this.rideState = RideState.idle,
    this.currentLocation,
    this.pickupLocation,
    this.destination,
    this.pickupText = '',
    this.destinationText = '',
    this.selectedVehicle = 'Standard',
    this.estimatedPrice = 0,
    this.isLoading = false,
    this.currentRideId,
    this.currentRide,
    this.errorMessage,
    this.notificationTitle,
    this.notificationSubtitle,
    this.showNotification = false,
  });

  RideBookingState copyWith({
    RideState? rideState,
    lat.LatLng? currentLocation,
    lat.LatLng? pickupLocation,
    lat.LatLng? destination,
    String? pickupText,
    String? destinationText,
    String? selectedVehicle,
    int? estimatedPrice,
    bool? isLoading,
    String? currentRideId,
    RideRequestModel? currentRide,
    String? errorMessage,
    String? notificationTitle,
    String? notificationSubtitle,
    bool? showNotification,
    bool clearError = false,
    bool clearNotification = false,
  }) {
    return RideBookingState(
      rideState: rideState ?? this.rideState,
      currentLocation: currentLocation ?? this.currentLocation,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destination: destination ?? this.destination,
      pickupText: pickupText ?? this.pickupText,
      destinationText: destinationText ?? this.destinationText,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      isLoading: isLoading ?? this.isLoading,
      currentRideId: currentRideId ?? this.currentRideId,
      currentRide: currentRide ?? this.currentRide,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      notificationTitle: clearNotification ? null : (notificationTitle ?? this.notificationTitle),
      notificationSubtitle: clearNotification ? null : (notificationSubtitle ?? this.notificationSubtitle),
      showNotification: clearNotification ? false : (showNotification ?? this.showNotification),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RideBookingState &&
        other.rideState == rideState &&
        other.currentLocation == currentLocation &&
        other.pickupLocation == pickupLocation &&
        other.destination == destination &&
        other.pickupText == pickupText &&
        other.destinationText == destinationText &&
        other.selectedVehicle == selectedVehicle &&
        other.estimatedPrice == estimatedPrice &&
        other.isLoading == isLoading &&
        other.currentRideId == currentRideId &&
        other.currentRide == currentRide &&
        other.errorMessage == errorMessage &&
        other.notificationTitle == notificationTitle &&
        other.notificationSubtitle == notificationSubtitle &&
        other.showNotification == showNotification;
  }

  @override
  int get hashCode {
    return Object.hash(
      rideState,
      currentLocation,
      pickupLocation,
      destination,
      pickupText,
      destinationText,
      selectedVehicle,
      estimatedPrice,
      isLoading,
      currentRideId,
      currentRide,
      errorMessage,
      notificationTitle,
      notificationSubtitle,
      showNotification,
    );
  }

  @override
  String toString() {
    return 'RideBookingState(rideState: $rideState, isLoading: $isLoading, estimatedPrice: $estimatedPrice)';
  }
}
