import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:latlong2/latlong.dart' as lat;

class MapboxMapWidget extends StatelessWidget {
  final lat.LatLng? initialLocation;
  final Set<Marker>? markers;
  final bool? myLocationEnabled;
  final Function(MapboxMapController)? onMapCreated;
  final Function(lat.LatLng)? onMapTap;

  const MapboxMapWidget({
    super.key,
    this.initialLocation,
    this.markers,
    this.myLocationEnabled,
    this.onMapCreated,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return MapboxMap(
      accessToken: 'pk.eyJ1IjoidGVtYWlsIjoiY2FsaWRvIiwidSI6ImEifQ.eyJhcGkiOiJhIiwicmV2IjoxLjAsImFjY2VzcyIjpbInRscyJdfQ.5KjJ9',
      initialCameraPosition: CameraPosition(
        target: LatLng(
          widget.initialLocation?.latitude ?? 37.7749,
          widget.initialLocation?.longitude ?? -122.4194,
        ),
        zoom: 15.0,
      ),
      onMapCreated: (controller) {
        widget.onMapCreated?.call(controller);
      },
      onMapClick: (point) {
        if (widget.onMapTap != null) {
          widget.onMapTap!(lat.LatLng(point.latitude, point.longitude));
        }
      },
      myLocationEnabled: widget.myLocationEnabled ?? true,
      myLocationTrackingMode: MyLocationTrackingMode.Tracking,
      myLocationRenderMode: MyLocationRenderMode.Normal,
      compassEnabled: true,
      logoViewMargins: const Point<double>(100, 10),
      attributionButtonMargins: const Point<double>(0, 0),
      styleString: _mapStyle,
      markers: widget.markers?.map((marker) {
        return Marker(
          markerId: MarkerId(marker.toString()),
          position: LatLng(
            marker.position.latitude,
            marker.position.longitude,
          ),
          infoWindow: InfoWindow(
            title: marker.infoWindowText?.title ?? '',
            snippet: marker.infoWindowText?.snippet ?? '',
          ),
        );
      }).toSet() ?? {},
    );
  }

  String get _mapStyle => '''
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#242f3e"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#746855"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#242f3e"
          }
        ]
      }
    ]
  ''';
}

// Mock Marker class for compatibility
class Marker {
  final String? markerId;
  final lat.LatLng position;
  final InfoWindow? infoWindowText;

  Marker({
    required this.markerId,
    required this.position,
    this.infoWindowText,
  });

  @override
  String toString() => markerId ?? '';
}

// Mock InfoWindow class for compatibility
class InfoWindow {
  final String? title;
  final String? snippet;

  InfoWindow({
    this.title,
    this.snippet,
  });
}
