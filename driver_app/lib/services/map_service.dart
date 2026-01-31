import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class MapService {
  static const String _osrmBaseUrl = 'http://router.project-osrm.org';
  
  // Get route between two points using OSRM (FREE)
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    try {
      final url = '$_osrmBaseUrl/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          
          return coordinates.map((coord) {
            return LatLng(coord[1], coord[0]); // OSRM returns [lng, lat]
          }).toList();
        }
      }
      
      return []; // Return empty list if no route found
    } catch (e) {
      print('Error getting route: $e');
      return [];
    }
  }
  
  // Get distance and duration between two points
  static Future<Map<String, double>> getDistanceAndDuration(LatLng start, LatLng end) async {
    try {
      final url = '$_osrmBaseUrl/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final distance = (route['distance'] ?? 0) / 1000.0; // Convert to km
          final duration = (route['duration'] ?? 0) / 60.0; // Convert to minutes
          
          return {
            'distance_km': distance,
            'duration_minutes': duration,
          };
        }
      }
      
      return {
        'distance_km': 0.0,
        'duration_minutes': 0.0,
      };
    } catch (e) {
      print('Error getting distance/duration: $e');
      return {
        'distance_km': 0.0,
        'duration_minutes': 0.0,
      };
    }
  }
  
  // Geocode address to coordinates (using Nominatim - FREE)
  static Future<LatLng?> geocodeAddress(String address) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/search?'
          'q=${Uri.encodeComponent(address)}&'
          'format=json&limit=1';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'RideNow Driver App',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data.isNotEmpty) {
          final result = data[0];
          final lat = double.parse(result['lat']);
          final lng = double.parse(result['lon']);
          
          return LatLng(lat, lng);
        }
      }
      
      return null;
    } catch (e) {
      print('Error geocoding address: $e');
      return null;
    }
  }
  
  // Reverse geocode coordinates to address
  static Future<String?> reverseGeocode(LatLng position) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?'
          'format=json&lat=${position.latitude}&lon=${position.longitude}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'RideNow Driver App',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['display_name'] != null) {
          return data['display_name'] as String;
        }
      }
      
      return null;
    } catch (e) {
      print('Error reverse geocoding: $e');
      return null;
    }
  }
  
  // Calculate straight-line distance between two points
  static double calculateStraightLineDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // meters
    
    final double lat1Rad = start.latitude * (pi / 180);
    final double lat2Rad = end.latitude * (pi / 180);
    final double deltaLatRad = (end.latitude - start.latitude) * (pi / 180);
    final double deltaLngRad = (end.longitude - start.longitude) * (pi / 180);
    
    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c; // meters
  }
  
  // Find nearby points within radius
  static List<LatLng> findNearbyPoints(LatLng center, List<LatLng> points, double radiusKm) {
    final List<LatLng> nearby = [];
    
    for (final point in points) {
      final distance = calculateStraightLineDistance(center, point) / 1000; // Convert to km
      
      if (distance <= radiusKm) {
        nearby.add(point);
      }
    }
    
    return nearby;
  }
}
