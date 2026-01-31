import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:latlong2/latlong.dart' as lat;

class MapboxMapWidget extends StatefulWidget {
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
  State<MapboxMapWidget> createState() => _MapboxMapWidgetState();
}

class _MapboxMapWidgetState extends State<MapboxMapWidget> {
  MapboxMapController? mapController;

  @override
  Widget build(BuildContext context) {
    return MapboxMap(
      accessToken: 'pk.eyJ1IjoidGVtYWlsIjoiY2FsaWRvIiwidSI6ImEifQ.eyJhcGkiOiJhIiwicmV2IjoxLjAsImFjY2VzcyIjpbInRscyJdfQ.5KjJ9', // Free public token
      initialCameraPosition: CameraPosition(
        target: widget.initialLocation ?? const lat.LatLng(37.7749, -122.4194),
        zoom: 15.0,
      ),
      onMapCreated: (controller) {
        mapController = controller;
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
      logoViewMargins: const EdgeInsets.only(top: 100, left: 10),
      attributionButtonMargins: EdgeInsets.zero,
      styleString: _mapStyle,
      markers: widget.markers?.map((marker) {
        return Marker(
          markerId: MarkerId(marker.toString()),
          position: lat.LatLng(marker.position.latitude, marker.position.longitude),
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

  void moveToLocation(lat.LatLng location) {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 16.0),
      ),
    );
  }

  void animateToLocation(lat.LatLng location) {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 15.0),
      ),
    );
  }
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

// Mock CameraPosition class for compatibility
class CameraPosition {
  final lat.LatLng target;
  final double zoom;

  CameraPosition({
    required this.target,
    required this.zoom,
  });
}

// Mock CameraUpdate class for compatibility
class CameraUpdate {
  static CameraUpdate newCameraPosition(CameraPosition position) {
    return CameraUpdate._(position);
  }

  CameraUpdate._(this.position);
  final CameraPosition position;
}

// Mock MapboxMapController for compatibility
class MapboxMapController {
  void animateCamera(CameraUpdate update) {
    // Implementation would go here
  }
}
