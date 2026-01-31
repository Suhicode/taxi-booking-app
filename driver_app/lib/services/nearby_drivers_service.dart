import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'driver_service_mock.dart';

class NearbyDriversService {
  static const double _defaultSearchRadiusKm = 5.0; // 5 km default radius
  final DriverService _driverService = DriverService();

  /// Get stream of nearby drivers for a given location
  Stream<List<DriverModel>> getNearbyDriversStream(
    LatLng customerLocation, {
    double radiusKm = _defaultSearchRadiusKm,
  }) {
    return _driverService.getDriversNearby(customerLocation, radiusKm);
  }

  /// Get one-time list of nearby drivers
  Future<List<DriverModel>> getNearbyDriversOnce(
    LatLng customerLocation, {
    double radiusKm = _defaultSearchRadiusKm,
  }) async {
    final drivers = await _driverService.getAvailableDrivers().first;
    return drivers.where((driver) {
      final distance = _calculateDistance(customerLocation, driver.location);
      return distance <= radiusKm;
    }).toList();
  }

  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const R = 6371; // Earth's radius in km
    final dLat = (point2.latitude - point1.latitude) * pi / 180;
    final dLon = (point2.longitude - point1.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(point1.latitude * pi / 180) *
            cos(point2.latitude * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Get distance to a specific driver
  double getDistanceToDriver(LatLng customerLocation, LatLng driverLocation) {
    return _calculateDistance(customerLocation, driverLocation);
  }

  /// Format distance for display
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m away';
    } else {
      return '${distanceKm.toStringAsFixed(1)}km away';
    }
  }

  /// Get estimated arrival time based on distance
  String getEstimatedArrivalTime(double distanceKm) {
    // Assuming average speed of 30 km/h in city
    final averageSpeedKmPerMin = 0.5; // 30 km/h = 0.5 km/min
    final minutes = (distanceKm / averageSpeedKmPerMin).round();
    
    if (minutes < 1) {
      return 'Less than 1 min';
    } else if (minutes < 60) {
      return '$minutes min${minutes > 1 ? 's' : ''}';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours hour${hours > 1 ? 's' : ''} ${remainingMinutes > 0 ? '$remainingMinutes min${remainingMinutes > 1 ? 's' : ''}' : ''}';
    }
  }

  /// Filter drivers by vehicle type
  List<DriverModel> filterByVehicleType(
    List<DriverModel> drivers,
    String vehicleType,
  ) {
    return drivers.where((driver) => 
      driver.vehicleType.toLowerCase() == vehicleType.toLowerCase()
    ).toList();
  }

  /// Sort drivers by distance (closest first)
  List<DriverModel> sortByDistance(
    List<DriverModel> drivers,
    LatLng customerLocation,
  ) {
    final sortedDrivers = List<DriverModel>.from(drivers);
    sortedDrivers.sort((a, b) {
      final distanceA = _calculateDistance(customerLocation, a.location);
      final distanceB = _calculateDistance(customerLocation, b.location);
      return distanceA.compareTo(distanceB);
    });
    return sortedDrivers;
  }

  /// Generate mock nearby drivers for testing (when Firebase is not available)
  List<DriverModel> generateMockNearbyDrivers(LatLng customerLocation) {
    final mockDrivers = <DriverModel>[];
    final random = Random();
    final vehicleTypes = ['Standard', 'Comfort', 'Premium', 'XL'];
    final names = ['John Driver', 'Sarah Taxi', 'Mike Cab', 'Emma Ride', 'Alex Driver'];
    
    // Generate 3-6 random nearby drivers
    final driverCount = random.nextInt(4) + 3;
    
    for (int i = 0; i < driverCount; i++) {
      // Generate random location within 5km
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * 5.0; // 0-5 km
      
      final latOffset = (distance * cos(angle)) / 111.32; // Approximate km to degrees
      final lngOffset = (distance * sin(angle)) / (111.32 * cos(customerLocation.latitude * pi / 180));
      
      final driverLocation = LatLng(
        customerLocation.latitude + latOffset,
        customerLocation.longitude + lngOffset,
      );
      
      mockDrivers.add(DriverModel(
        id: 'driver_${i + 1}',
        name: names[i % names.length],
        vehicleType: vehicleTypes[random.nextInt(vehicleTypes.length)],
        status: 'available',
        location: driverLocation,
        lastSeen: DateTime.now().subtract(Duration(minutes: random.nextInt(10))),
      ));
    }
    
    return sortByDistance(mockDrivers, customerLocation);
  }
}
