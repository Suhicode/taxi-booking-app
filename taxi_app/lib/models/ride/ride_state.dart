enum RideState {
  /// Initial state when user opens the booking screen
  idle,
  
  /// Actively searching for available drivers
  searching,
  
  /// Driver has accepted the ride request
  driverAccepted,
  
  /// Ride is in progress - driver has arrived and started trip
  rideStarted,
  
  /// Ride has been successfully completed
  rideCompleted,
  
  /// Ride was cancelled by user, driver, or system
  cancelled;

  bool get isIdle => this == RideState.idle;
  bool get isSearching => this == RideState.searching;
  bool get isDriverAccepted => this == RideState.driverAccepted;
  bool get isRideStarted => this == RideState.rideStarted;
  bool get isRideCompleted => this == RideState.rideCompleted;
  bool get isCancelled => this == RideState.cancelled;
  
  bool get isActive => isSearching || isDriverAccepted || isRideStarted;
  bool get isFinalState => isRideCompleted || isCancelled;
  
  String get displayName {
    switch (this) {
      case RideState.idle:
        return 'Book Your Ride';
      case RideState.searching:
        return 'Finding Drivers...';
      case RideState.driverAccepted:
        return 'Driver Assigned';
      case RideState.rideStarted:
        return 'Ride in Progress';
      case RideState.rideCompleted:
        return 'Ride Completed';
      case RideState.cancelled:
        return 'Ride Cancelled';
    }
  }
}
