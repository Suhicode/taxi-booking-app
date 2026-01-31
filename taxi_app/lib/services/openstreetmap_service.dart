import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as lat;

class OpenStreetMapService {
  static Future<List<LocationSuggestion>> searchLocation(String query) async {
    if (query.isEmpty) return [];
    
    final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5"
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'TaxiApp/1.0'}
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => LocationSuggestion(
          displayName: item['display_name'] ?? '',
          latitude: double.parse(item['lat'] ?? '0'),
          longitude: double.parse(item['lon'] ?? '0'),
          name: item['display_name']?.split(',')[0] ?? '',
        )).toList();
      }
    } catch (e) {
      print('Location search error: $e');
    }
    
    return [];
  }

  static Future<List<lat.LatLng>> getRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng
  ) async {
    final url = Uri.parse(
      "https://router.project-osrm.org/route/v1/driving/"
      "$startLng,$startLat;$endLng,$endLat"
      "?overview=full&geometries=geojson"
    );

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'];
          return coords.map<lat.LatLng>((c) => lat.LatLng(c[1], c[0])).toList();
        }
      }
    } catch (e) {
      print('Route error: $e');
    }
    
    return [];
  }
}

class LocationSuggestion {
  final String displayName;
  final String name;
  final double latitude;
  final double longitude;

  LocationSuggestion({
    required this.displayName,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  lat.LatLng toLatLng() => lat.LatLng(latitude, longitude);
}
