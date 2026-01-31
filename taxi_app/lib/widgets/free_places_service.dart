import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as lat;

/// Geocode an address string → List of location suggestions
  static Future<List<FreePlace>?> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('$_nominatimUrl?q=${Uri.encodeComponent(query)}&format=json&limit=5'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['results'] != null) {
          final places = (data['results'] as List)
              .map((place) => FreePlace(
                name: place['display_name'] as String,
                location: lat.LatLng(
                  place['lat'] as double,
                  place['lon'] as double,
                ),
              ))
              .toList();
          
          return places;
        }
      }
    } catch (e) {
      return [];
    }
  }
}
