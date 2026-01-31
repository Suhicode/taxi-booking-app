import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../models/location_model.dart';

class LocationService {
  static Future<bool> requestPermission() async {
    if (kIsWeb) return true;
    
    final status = await Permission.locationWhenInUse.request();

    return status == PermissionStatus.granted;
  }

  static Future<bool> isLocationServiceEnabled() async {
    if (kIsWeb) return true;
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationModel?> getCurrentLocation() async {
    try {
      // Request permission first
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        throw Exception(AppConstants.locationPermissionDenied);
      }

      // Check if location service is enabled
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        throw Exception(AppConstants.locationServiceDisabled);
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: AppConstants.locationTimeout,
      );

      // Get address from coordinates
      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          address = placemarks.first.street ?? 
                   placemarks.first.subLocality ?? 
                   placemarks.first.locality ?? 
                   placemarks.first.name;
        }
      } catch (e) {
        // Address lookup failed, but we still have coordinates
      }

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        name: 'Current Location',
      );
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }

  static Future<LocationModel?> getLocationFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return LocationModel(
          latitude: location.latitude,
          longitude: location.longitude,
          address: address,
          name: address,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get location from address: $e');
    }
  }

  static Future<List<LocationModel>> searchLocations(String query) async {
    try {
      final locations = await locationFromAddress(query);
      return locations.map((location) => LocationModel(
        latitude: location.latitude,
        longitude: location.longitude,
        address: query,
        name: query,
      )).toList();
    } catch (e) {
      throw Exception('Failed to search locations: $e');
    }
  }

  static double calculateDistance(LocationModel start, LocationModel end) {
    const double earthRadius = 6371; // kilometers
    
    final double lat1Rad = start.latitude * math.pi / 180;
    final double lat2Rad = end.latitude * math.pi / 180;
    final double deltaLatRad = (end.latitude - start.latitude) * math.pi / 180;
    final double deltaLonRad = (end.longitude - start.longitude) * math.pi / 180;
    
    final double a = math.pow(deltaLatRad / 2, 2).toDouble() +
        math.pow(deltaLonRad / 2, 2).toDouble() *
        math.cos(lat1Rad) *
        math.cos(lat2Rad);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
}
