// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart' as lat;
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  /// Request runtime permission for location (foreground).
  static Future<bool> requestPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted) return true;

    final result = await Permission.location.request();
    return result.isGranted;
  }

  /// Get current position (throws if not available or denied)
  static Future<lat.LatLng?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    return lat.LatLng(pos.latitude, pos.longitude);
  }

  /// Geocode an address string → List of location suggestions
  static Future<List<lat.LatLng>?> locationFromAddress(String address) async {
    try {
      // Use Nominatim for better autocomplete
      final locations = await locationFromAddressNominatim(address);
      
      if (locations != null && locations.isNotEmpty) {
        return locations;
      }
      
      // Return empty list if Nominatim fails
      return [];
    } catch (e) {
      return null;
    }
  }

  /// Enhanced geocoding with Nominatim for better suggestions
  static Future<List<lat.LatLng>?> locationFromAddressNominatim(String address) async {
    try {
      const String nominatimUrl = 'https://nominatim.openstreetmap.org/search';
      final response = await http.get(
        Uri.parse('$nominatimUrl?q=${Uri.encodeComponent(address)}&format=json&limit=5'),
        headers: {'User-Agent': 'taxi_app'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          return lat.LatLng(
            double.parse(item['lat']),
            double.parse(item['lon']),
          );
        }).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
