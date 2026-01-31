import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as lat;

class FreePlace {
  final String name;
  final lat.LatLng location;

  const FreePlace({
    required this.name,
    required this.location,
  });
}

class FreePlacesService {
  static Future<List<FreePlace>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        
        final places = data
            .map((place) => FreePlace(
              name: place['display_name'] as String,
              location: lat.LatLng(
                double.parse(place['lat']),
                double.parse(place['lon']),
              ),
            ))
            .toList();
        
        return places;
      }
    } catch (e) {
      return [];
    }
    
    return [];
  }
}
