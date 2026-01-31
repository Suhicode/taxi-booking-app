import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_model.dart';

class OpenStreetMapSearchService {
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org/search';
  static const bool kIsWeb = identical(0, 0);

  /// Request location permission (using device permissions)
  static Future<bool> requestPermission() async {
    if (OpenStreetMapSearchService.kIsWeb) return true;
    
    // Request location permission
    var status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check if location service is enabled
  static Future<bool> isLocationServiceEnabled() async {
    if (OpenStreetMapSearchService.kIsWeb) return true;
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current location (real implementation)
  static Future<LocationModel?> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) print('Location services are disabled.');
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) print('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) print('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        address: 'Current Location',
        name: 'Current Location',
      );
    } catch (e) {
      if (kDebugMode) print('Error getting location: $e');
      return null;
    }
  }

  /// Search locations using OpenStreetMap Nominatim API
  static Future<List<LocationModel>> searchLocations(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final uri = Uri.parse('$_nominatimBaseUrl')
          .replace(queryParameters: {
        'q': query,
        'format': 'json',
        'limit': '10',
        'addressdetails': '1',
      });

      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => LocationModel(
          latitude: double.parse(item['lat']),
          longitude: double.parse(item['lon']),
          address: item['display_name'],
          name: item['display_name'].split(',')[0],
        )).toList();
      }
    } catch (e) {
      if (kDebugMode) print('Search error: $e');
    }
    
    return [];
  }
}
