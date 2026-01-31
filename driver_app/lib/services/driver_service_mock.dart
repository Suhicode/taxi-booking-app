// lib/services/driver_service_mock.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as lat;

class DriverModel {
  final String id;
  final String name;
  final String vehicleType;
  final String status;
  final lat.LatLng location;
  final DateTime lastSeen;

  DriverModel({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.status,
    required this.location,
    required this.lastSeen,
  });

  Marker toMarker() {
    final markerColor = _getMarkerColor(vehicleType);
    return Marker(
      point: location,
      width: 40.0,
      height: 40.0,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: markerColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.directions_car,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Color _getMarkerColor(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'bike':
        return Colors.green;
      case 'scooty':
        return Colors.orange;
      case 'standard':
        return Colors.blue;
      case 'comfort':
        return Colors.yellow;
      case 'premium':
        return Colors.red;
      case 'xl':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class DriverService {
  // Mock stream that emits a list of available drivers
  Stream<List<DriverModel>> getAvailableDrivers() async* {
    final rnd = Random();
    final base = lat.LatLng(13.0827, 80.2707);
    
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      final drivers = List.generate(5, (i) {
        final latitude = base.latitude + (rnd.nextDouble() - 0.5) * 0.05;
        final longitude = base.longitude + (rnd.nextDouble() - 0.5) * 0.05;
        return DriverModel(
          id: 'driver_${i + 1}',
          name: ['John Driver', 'Sarah Taxi', 'Mike Cab', 'Emma Ride', 'Alex Driver'][i % 5],
          vehicleType: ['Standard', 'Comfort', 'Premium', 'XL', 'Standard'][i % 4],
          status: 'available',
          location: lat.LatLng(latitude, longitude),
          lastSeen: DateTime.now().subtract(Duration(minutes: rnd.nextInt(10))),
        );
      });
      yield drivers;
    }
  }

  /// Get drivers within a specific radius (in km)
  Stream<List<DriverModel>> getDriversNearby(
    lat.LatLng center,
    double radiusKm,
  ) {
    return getAvailableDrivers().map((drivers) {
      return drivers.where((driver) {
        final distance = _calculateDistance(center, driver.location);
        return distance <= radiusKm;
      }).toList();
    });
  }

  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(lat.LatLng point1, lat.LatLng point2) {
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

  /// Mock update driver location (no-op for demo)
  Future<void> updateDriverLocation(
    String driverId,
    lat.LatLng location,
  ) async {
    // Mock implementation - would update Firebase in real app
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Mock update driver status (no-op for demo)
  Future<void> updateDriverStatus(String driverId, String status) async {
    // Mock implementation - would update Firebase in real app
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
