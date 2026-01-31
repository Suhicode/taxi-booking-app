import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverModel {
  final String id;
  final String name;
  final String vehicleType;
  final String status;
  final LatLng location;
  final DateTime lastSeen;

  DriverModel({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.status,
    required this.location,
    required this.lastSeen,
  });

  factory DriverModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final geoPoint = data['location'] as GeoPoint?;
    
    return DriverModel(
      id: doc.id,
      name: data['name'] ?? 'Unknown Driver',
      vehicleType: data['vehicle_type'] ?? 'Standard',
      status: data['status'] ?? 'offline',
      location: geoPoint != null 
          ? LatLng(geoPoint.latitude, geoPoint.longitude)
          : const LatLng(13.0827, 80.2707),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Marker toMarker() {
    final markerColor = _getMarkerColor(vehicleType);
    return Marker(
      markerId: MarkerId(id),
      position: location,
      infoWindow: InfoWindow(
        title: name,
        snippet: '$vehicleType • ${status.toUpperCase()}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
    );
  }

  double _getMarkerColor(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'bike':
        return BitmapDescriptor.hueGreen;
      case 'scooty':
        return BitmapDescriptor.hueOrange;
      case 'standard':
        return BitmapDescriptor.hueBlue;
      case 'comfort':
        return BitmapDescriptor.hueYellow;
      case 'premium':
        return BitmapDescriptor.hueRed;
      case 'xl':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueBlue;
    }
  }
}

class DriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Listen to available drivers in real-time
  Stream<List<DriverModel>> getAvailableDrivers() {
    return _firestore
        .collection('drivers')
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => DriverModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get drivers within a specific radius (in km)
  Stream<List<DriverModel>> getDriversNearby(
    LatLng center,
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

  /// Update driver location
  Future<void> updateDriverLocation(
    String driverId,
    LatLng location,
  ) async {
    await _firestore.collection('drivers').doc(driverId).update({
      'location': GeoPoint(location.latitude, location.longitude),
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  /// Update driver status
  Future<void> updateDriverStatus(String driverId, String status) async {
    await _firestore.collection('drivers').doc(driverId).update({
      'status': status,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}
