import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as lat;

class SimpleMap extends StatelessWidget {
  final lat.LatLng? center;
  final double zoom;
  final Set<Marker>? markers;
  final bool showCurrentLocation;
  final Function(lat.LatLng)? onTap;

  const SimpleMap({
    super.key,
    this.center,
    this.zoom = 15.0,
    this.markers,
    this.showCurrentLocation = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: center ?? lat.LatLng(37.7749, -122.4194),
        zoom: zoom,
        interactiveFlags: InteractiveFlag.all,
        onTap: (tapPosition, latLng) {
          if (onTap != null) {
            onTap!(latLng);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.yousu.taxiapp',
        ),
        if (markers != null) MarkerLayer(markers: markers!.toList()),
        if (showCurrentLocation && center != null)
          MarkerLayer(
            markers: [
              Marker(
                point: center!,
                width: 12.0,
                height: 12.0,
                builder: (context) => Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.0),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// Simple marker class
class CustomMarker {
  final lat.LatLng point;
  final double width;
  final double height;
  final Widget child;

  const CustomMarker({
    required this.point,
    this.width = 30.0,
    this.height = 30.0,
    required this.child,
  });
}
