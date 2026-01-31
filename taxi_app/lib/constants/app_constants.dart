class AppConstants {
  // App Info
  static const String appName = 'RideNow Taxi';
  static const String appVersion = '1.0.0';
  
  // API Keys (replace with actual keys)
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  // Vehicle Types
  static const List<String> vehicleTypes = [
    'Bike',
    'Scooty', 
    'Standard',
    'Comfort',
    'Premium',
    'XL'
  ];
  
  // Pricing Constants
  static const Map<String, double> baseFares = {
    'Bike': 15.0,
    'Scooty': 20.0,
    'Standard': 30.0,
    'Comfort': 45.0,
    'Premium': 60.0,
    'XL': 75.0,
  };
  
  static const Map<String, double> perKmRates = {
    'Bike': 8.0,
    'Scooty': 10.0,
    'Standard': 12.0,
    'Comfort': 15.0,
    'Premium': 20.0,
    'XL': 25.0,
  };
  
  static const Map<String, double> perMinuteRates = {
    'Bike': 1.0,
    'Scooty': 1.5,
    'Standard': 2.0,
    'Comfort': 2.5,
    'Premium': 3.0,
    'XL': 3.5,
  };
  
  static const double minimumFare = 25.0;
  static const double surgeMultiplier = 1.2;
  
  // Location
  static const double defaultLatitude = 28.6139;
  static const double defaultLongitude = 77.2090;
  static const double defaultZoom = 15.0;
  
  // Timeouts
  static const Duration locationTimeout = Duration(seconds: 10);
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration rideStatusCheckInterval = Duration(seconds: 3);
  
  // Error Messages
  static const String locationPermissionDenied = 'Location permission is required';
  static const String locationServiceDisabled = 'Location services are disabled';
  static const String networkError = 'Network error occurred';
  static const String serverError = 'Server error occurred';
  static const String invalidLocation = 'Invalid location selected';
  static const String noDriversAvailable = 'No drivers available nearby';
}
