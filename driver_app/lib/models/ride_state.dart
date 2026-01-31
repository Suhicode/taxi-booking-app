enum RideState {
  idle,
  searching,
  driverAccepted,
  rideStarted,
  completed,
  cancelled
}

extension RideStateExtension on RideState {
  String get displayName {
    switch (this) {
      case RideState.idle:
        return 'Idle';
      case RideState.searching:
        return 'Searching for driver...';
      case RideState.driverAccepted:
        return 'Driver assigned';
      case RideState.rideStarted:
        return 'Ride in progress';
      case RideState.completed:
        return 'Ride completed';
      case RideState.cancelled:
        return 'Ride cancelled';
    }
  }

  bool get isActive {
    return this == RideState.searching || 
           this == RideState.driverAccepted || 
           this == RideState.rideStarted;
  }

  bool get isCompleted {
    return this == RideState.completed || this == RideState.cancelled;
  }
}
