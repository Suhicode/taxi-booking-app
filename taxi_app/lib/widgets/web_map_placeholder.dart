import 'package:flutter/material.dart';

// Web-safe placeholder for Google Maps
class GoogleMap extends StatelessWidget {
  final CameraPosition initialCameraPosition;
  final Function(GoogleMapController)? onMapCreated;
  final Set<Marker>? markers;
  final bool? myLocationEnabled;
  final bool? myLocationButtonEnabled;

  const GoogleMap({
    super.key,
    required this.initialCameraPosition,
    this.onMapCreated,
    this.markers,
    this.myLocationEnabled,
    this.myLocationButtonEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Map View Not Available on Web',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please run on Android Emulator or Physical Phone',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              'Location: ${initialCameraPosition.target.latitude.toStringAsFixed(4)}, ${initialCameraPosition.target.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (markers != null)
              Text(
                'Available Drivers: ${markers!.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}

class CameraPosition {
  final LatLng target;
  final double zoom;

  const CameraPosition({
    required this.target,
    this.zoom = 15,
  });
}

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);
}

class Marker {
  final MarkerId markerId;
  final LatLng position;
  final InfoWindow? infoWindow;
  final BitmapDescriptor? icon;

  const Marker({
    required this.markerId,
    required this.position,
    this.infoWindow,
    this.icon,
  });
}

class MarkerId {
  final String value;

  const MarkerId(this.value);
}

class InfoWindow {
  final String? title;
  final String? snippet;

  const InfoWindow({this.title, this.snippet});
}

class BitmapDescriptor {
  static const double hueBlue = 200.0;
  static const double hueGreen = 120.0;
  static const double hueOrange = 30.0;
  static const double hueYellow = 60.0;
  static const double hueRed = 0.0;
  static const double hueViolet = 270.0;

  static BitmapDescriptor defaultMarkerWithHue(double hue) {
    return BitmapDescriptor._(hue);
  }

  final double hue;

  BitmapDescriptor._(this.hue);
}

class GoogleMapController {
  // Mock controller for web
}
