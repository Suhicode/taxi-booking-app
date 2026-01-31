// lib/services/driver_search_service.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as lat;
import 'package:location_service.dart';

import '../models/driver_model.dart';
import '../models/ride_request_model.dart';

/// Driver search result with distance and availability
class DriverSearchResult {
  final DriverModel driver;
  final double distanceKm;
  final Duration estimatedTime;
  final bool isAvailable;
  final double? rating;

  const DriverSearchResult({
    required this.driver,
    required this.distanceKm,
    required this.estimatedTime,
    required this.isAvailable,
    this.rating,
  });

  /// Get formatted distance string
  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  /// Get formatted time string
  String get formattedTime {
    final minutes = estimatedTime.inMinutes;
    if (minutes < 60) {
      return '${minutes} min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }
}

/// Driver search service with real-time capabilities
class DriverSearchService {
  static const Duration _searchTimeout = Duration(seconds: 30);
  static const Duration _locationUpdateInterval = Duration(seconds: 5);
  static const double _maxSearchRadiusKm = 10.0;
  static const int _maxSearchResults = 10;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamSubscription<Position>? _positionSubscription;

  /// Search for available drivers near a location
  static Future<List<DriverSearchResult>> searchNearbyDrivers({
    required lat.LatLng center,
    required VehicleType vehicleType,
    double radiusKm = _maxSearchRadiusKm,
    int maxResults = _maxSearchResults,
    Duration? timeout,
  }) async {
    try {
      // Get current location for distance calculations
      final currentPosition = await Geolocator.getCurrentPosition();
      if (currentPosition == null) {
        throw Exception('Unable to get current location');
      }

      final centerLat = center.latitude;
      final centerLng = center.longitude;

      // Query Firestore for available drivers
      final driversSnapshot = await _firestore
          .collection('drivers')
          .where('isAvailable', isEqualTo: true)
          .where('vehicleType', isEqualTo: vehicleType.name)
          .limit(maxResults)
          .get()
          .timeout(timeout ?? _searchTimeout);

      final List<DriverSearchResult> results = [];

      for (final doc in driversSnapshot.docs) {
        final driverData = doc.data() as Map<String, dynamic>;
        
        // Parse driver location
        final driverLat = driverData['location']['latitude'] as double;
        final driverLng = driverData['location']['longitude'] as double;
        final driverLocation = lat.LatLng(driverLat, driverLng);

        // Calculate distance from center
        final distance = _calculateDistance(
          centerLat, centerLng,
          driverLat, driverLng,
        );

        // Calculate estimated time
        final estimatedTime = Duration(
          seconds: (distance / 30.0) * 3600, // Assume 30 km/h average
        );

        // Check if driver is within radius
        final isWithinRadius = distance <= radiusKm;

        // Create search result
        final result = DriverSearchResult(
          driver: DriverModel(
            id: driverData['id'] as String,
            name: driverData['name'] as String,
            vehicleType: driverData['vehicleType'] as String,
            location: driverLocation,
            lastSeen: (driverData['lastSeen'] as Timestamp).toDate(),
            rating: (driverData['rating'] as num?)?.toDouble(),
            phone: driverData['phone'] as String,
          ),
          distanceKm: distance,
          estimatedTime: estimatedTime,
          isAvailable: driverData['isAvailable'] as bool && isWithinRadius,
        );

        if (isWithinRadius) {
          results.add(result);
        }
      }

      // Sort by distance (closest first)
      results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      return results;
    } catch (e) {
      throw Exception('Driver search failed: $e');
    }
  }

  /// Calculate distance between two points using Haversine formula
  static double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat1)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Start real-time driver location tracking
  static Stream<List<DriverSearchResult>> trackDriverLocations() {
    return _firestore
        .collection('drivers')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.data() as Map<String, dynamic>)
        .map((data) {
          final driverData = data;
          final driverLat = driverData['location']['latitude'] as double;
          final driverLng = driverData['location']['longitude'] as double;
          final driverLocation = lat.LatLng(driverLat, driverLng);
          
          return DriverSearchResult(
            driver: DriverModel(
              id: driverData['id'] as String,
              name: driverData['name'] as String,
              vehicleType: driverData['vehicleType'] as String,
              location: driverLocation,
              lastSeen: (driverData['lastSeen'] as Timestamp).toDate(),
              rating: (driverData['rating'] as num?)?.toDouble(),
              phone: driverData['phone'] as String,
            ),
            distanceKm: 0.0, // Will be calculated per client
            estimatedTime: Duration.zero,
            isAvailable: driverData['isAvailable'] as bool,
          );
        });
  }

  /// Update driver location in real-time
  static Future<void> updateDriverLocation({
    required String driverId,
    required lat.LatLng newLocation,
    required double? newRating,
  }) async {
    try {
      await _firestore.collection('drivers').doc(driverId).update({
        'location': {
          'latitude': newLocation.latitude,
          'longitude': newLocation.longitude,
          'timestamp': Timestamp.now(),
        },
        'lastSeen': Timestamp.now(),
        if (newRating != null) {
          'rating': newRating,
        },
        'isAvailable': true,
      });
    } catch (e) {
      throw Exception('Failed to update driver location: $e');
    }
  }

  /// Set driver availability status
  static Future<void> setDriverAvailability({
    required String driverId,
    required bool isAvailable,
  }) async {
    try {
      await _firestore.collection('drivers').doc(driverId).update({
        'isAvailable': isAvailable,
        'lastSeen': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update driver availability: $e');
    }
  }

  /// Get driver by ID
  static Future<DriverModel?> getDriverById(String driverId) async {
    try {
      final doc = await _firestore.collection('drivers').doc(driverId).get();
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final driverData = data['location'] as Map<String, dynamic>;
      
      return DriverModel(
        id: driverId,
        name: data['name'] as String,
        vehicleType: data['vehicleType'] as String,
        location: lat.LatLng(
          driverData['latitude'] as double,
          driverData['longitude'] as double,
        ),
        lastSeen: (data['lastSeen'] as Timestamp).toDate(),
        rating: (data['rating'] as num?)?.toDouble(),
        phone: data['phone'] as String,
      );
    } catch (e) {
      throw Exception('Failed to get driver: $e');
    }
  }

  /// Search drivers by vehicle type and availability
  static Future<List<DriverSearchResult>> searchDriversByTypeAndAvailability({
    required VehicleType vehicleType,
    required bool isAvailable,
    int limit = 20,
  }) async {
    try {
      final query = _firestore
          .collection('drivers')
          .where('vehicleType', isEqualTo: vehicleType.name)
          .where('isAvailable', isEqualTo: isAvailable)
          .limit(limit);

      final snapshot = await query.get();
      
      final List<DriverSearchResult> results = [];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final driverData = data['location'] as Map<String, dynamic>;
        
        results.add(DriverSearchResult(
          driver: DriverModel(
            id: doc.id,
            name: data['name'] as String,
            vehicleType: data['vehicleType'] as String,
            location: lat.LatLng(
              driverData['latitude'] as double,
              driverData['longitude'] as double,
            ),
            lastSeen: (data['lastSeen'] as Timestamp).toDate(),
            rating: (data['rating'] as num?)?.toDouble(),
            phone: data['phone'] as String,
          ),
          distanceKm: 0.0,
          estimatedTime: Duration.zero,
          isAvailable: data['isAvailable'] as bool,
        ));
      }

      return results;
    } catch (e) {
      throw Exception('Driver search failed: $e');
    }
  }

  /// Get driver statistics
  static Future<Map<String, dynamic>> getDriverStatistics(String driverId) async {
    try {
      final driverDoc = await _firestore.collection('drivers').doc(driverId).get();
      if (!driverDoc.exists) {
        return {};
      }

      final driverData = driverDoc.data() as Map<String, dynamic>;
      final ridesCollection = await _firestore
          .collection('rides')
          .where('driverId', isEqualTo: driverId)
          .get();

      final ridesSnapshot = ridesCollection as QuerySnapshot;
      
      int totalRides = ridesSnapshot.docs.length;
      int completedRides = 0;
      double totalRating = 0.0;
      int totalEarnings = 0;

      for (final rideDoc in ridesSnapshot.docs) {
        final rideData = rideDoc.data() as Map<String, dynamic>;
        if (rideData['status'] == 'completed') {
          completedRides++;
          totalRating += (rideData['rating'] as num?)?.toDouble() ?? 0.0;
          totalEarnings += (rideData['fare'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return {
        'totalRides': totalRides,
        'completedRides': completedRides,
        'averageRating': totalRides > 0 ? totalRating / completedRides : 0.0,
        'totalEarnings': totalEarnings,
        'lastActive': driverData['lastSeen'],
        'currentRating': driverData['rating']?.toDouble() ?? 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get driver statistics: $e');
    }
  }

  /// Update driver rating after ride completion
  static Future<void> updateDriverRating({
    required String driverId,
    required double rating,
    required String rideId,
  }) async {
    try {
      // Update driver's overall rating
      final driverDoc = await _firestore.collection('drivers').doc(driverId).get();
      if (driverDoc.exists) {
        final driverData = driverDoc.data() as Map<String, dynamic>;
        final currentRating = (driverData['rating'] as num?)?.toDouble() ?? 0.0;
        final totalRides = (driverData['totalRides'] as int?) ?? 0;
        
        // Calculate new average rating
        final newAverageRating = ((currentRating * totalRides) + rating) / (totalRides + 1);
        
        await _firestore.collection('drivers').doc(driverId).update({
          'rating': newAverageRating,
          'totalRides': totalRides + 1,
        });
      }

      // Update ride with rating
      await _firestore.collection('rides').doc(rideId).update({
        'rating': rating,
        'ratedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update driver rating: $e');
    }
  }

  /// Start location tracking for a driver
  static Future<void> startLocationTracking(String driverId) async {
    try {
      // Subscribe to location updates (would use WebSocket in production)
      _positionSubscription = Geolocator.getPositionStream().listen((Position position) {
        if (position != null) {
          // Update driver location in Firestore
          await updateDriverLocation(
            driverId: driverId,
            newLocation: lat.LatLng(position.latitude, position.longitude),
          );
        }
      });

      // Set driver as active
      await setDriverAvailability(driverId, true);
    } catch (e) {
      throw Exception('Failed to start location tracking: $e');
    }
  }

  /// Stop location tracking for a driver
  static Future<void> stopLocationTracking(String driverId) async {
    try {
      // Cancel location subscription
      await _positionSubscription?.cancel();
      
      // Set driver as inactive
      await setDriverAvailability(driverId, false);
    } catch (e) {
      throw Exception('Failed to stop location tracking: $e');
    }
  }

  /// Get nearby drivers for ride assignment
  static Future<List<DriverSearchResult>> getNearbyAvailableDrivers({
    required lat.LatLng pickupLocation,
    required VehicleType vehicleType,
    double radiusKm = 5.0, // Smaller radius for immediate assignment
    int maxResults = 5,
  }) async {
    return searchNearbyDrivers(
      center: pickupLocation,
      vehicleType: vehicleType,
      radiusKm: radiusKm,
      maxResults: maxResults,
    );
  }

  /// Real-time driver location stream
  static Stream<List<DriverSearchResult>> getDriverLocationStream() {
    return trackDriverLocations();
  }

  /// Clean up old location data
  static Future<void> cleanupOldLocationData() async {
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      
      final oldLocations = await _firestore
          .collection('driver_locations')
          .where('timestamp', isLessThan: cutoff)
          .get();

      for (final doc in oldLocations.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to cleanup old location data: $e');
    }
  }
}

/// Real-time driver location tracking service
class DriverLocationTracker {
  static final DriverSearchService _searchService = DriverSearchService();
  static StreamSubscription<Position>? _positionSubscription;
  static String? _currentDriverId;
  static Timer? _locationUpdateTimer;

  /// Start tracking a specific driver
  static Future<void> startTracking(String driverId) async {
    try {
      _currentDriverId = driverId;
      await _searchService.startLocationTracking(driverId);
      
      // Start periodic location updates
      _locationUpdateTimer?.cancel();
      _locationUpdateTimer = Timer.periodic(
        DriverSearchService._locationUpdateInterval,
        (timer) async {
          final currentPosition = await Geolocator.getCurrentPosition();
          if (currentPosition != null && _currentDriverId != null) {
            await _searchService.updateDriverLocation(
              driverId: _currentDriverId!,
              newLocation: lat.LatLng(
                currentPosition.latitude,
                currentPosition.longitude,
              ),
            );
          }
        },
      );
    } catch (e) {
      print('Location tracking error: $e');
    }
  }

  /// Stop tracking
  static Future<void> stopTracking() async {
    try {
      _locationUpdateTimer?.cancel();
      _positionSubscription?.cancel();
      
      if (_currentDriverId != null) {
        await _searchService.stopLocationTracking(_currentDriverId!);
      }
      
      _currentDriverId = null;
    } catch (e) {
      print('Stop tracking error: $e');
    }
  }

  /// Get current tracking status
  static bool get isTracking => _currentDriverId != null;
  static String? get currentDriverId => _currentDriverId;
}
