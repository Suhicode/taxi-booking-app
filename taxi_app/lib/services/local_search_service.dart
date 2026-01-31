import 'dart:math';
import 'package:latlong2/latlong.dart' as lat;
import '../models/location_model.dart';

class LocalSearchService {
  static Future<List<LocationModel>> searchLocations(String query) async {
    // Simulate local search with mock data
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Mock location data for demonstration
    final mockLocations = [
      LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        address: 'New Delhi, India',
        name: 'New Delhi',
      ),
      LocationModel(
        latitude: 19.0760,
        longitude: 72.8777,
        address: 'Mumbai, India',
        name: 'Mumbai',
      ),
      LocationModel(
        latitude: 12.9716,
        longitude: 77.5946,
        address: 'Bangalore, India',
        name: 'Bangalore',
      ),
      LocationModel(
        latitude: 17.3850,
        longitude: 78.4867,
        address: 'Hyderabad, India',
        name: 'Hyderabad',
      ),
      LocationModel(
        latitude: 13.0827,
        longitude: 80.2707,
        address: 'Chennai, India',
        name: 'Chennai',
      ),
    ];
    
    if (query.isEmpty) return mockLocations;
    
    return mockLocations.where((location) {
      final searchLower = query.toLowerCase();
      return location.name!.toLowerCase().contains(searchLower) ||
             location.address!.toLowerCase().contains(searchLower);
    }).toList();
  }
}

class LocalLocationSearchService {
  static Future<LocationModel?> getCurrentLocation() async {
    // Simulate getting current location
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return a mock current location (in real app, use geolocator)
    return LocationModel(
      latitude: 28.6139 + (Random().nextDouble() - 0.5) * 0.01,
      longitude: 77.2090 + (Random().nextDouble() - 0.5) * 0.01,
      address: 'Current Location',
      name: 'Current Location',
    );
  }
}