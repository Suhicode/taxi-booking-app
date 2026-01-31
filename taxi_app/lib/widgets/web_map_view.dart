// lib/widgets/web_map_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

typedef DestinationSelected = void Function(ll.LatLng dest);

class WebMapView extends StatefulWidget {
  final ll.LatLng initialLocation;
  final DestinationSelected onDestinationSelected;
  final List<ll.LatLng>? driverPositions;
  final ll.LatLng? pickup;
  final ll.LatLng? destination;

  const WebMapView({
    super.key,
    required this.initialLocation,
    required this.onDestinationSelected,
    this.driverPositions,
    this.pickup,
    this.destination,
  });

  @override
  State<WebMapView> createState() => _WebMapViewState();
}

class _WebMapViewState extends State<WebMapView> {
  final MapController _mapController = MapController();
  final double _zoom = 13.0;

  ll.LatLng _toLL(gmaps.LatLng p) => ll.LatLng(p.latitude, p.longitude);

  // Move map to show both points (fit bounds)
  void _fitBoundsIfNeeded() {
    if (widget.pickup != null && widget.destination != null) {
      final a = _toLL(widget.pickup!);
      final b = _toLL(widget.destination!);
      // compute best zoom and center: flutter_map has fitBounds via move + zoom
      // quick approach: center on midpoint and set zoom to 13-15 depending distance
      final centerLat = (a.latitude + b.latitude) / 2;
      final centerLng = (a.longitude + b.longitude) / 2;
      final latDiff = (a.latitude - b.latitude).abs();
      final lngDiff = (a.longitude - b.longitude).abs();
      double zoom = 15;
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
      if (maxDiff > 1.0) {
        zoom = 6;
      } else if (maxDiff > 0.5) zoom = 8;
      else if (maxDiff > 0.05) zoom = 12;
      else zoom = 14;
      _mapController.move(ll.LatLng(centerLat, centerLng), zoom);
    } else if (widget.pickup != null) {
      _mapController.move(_toLL(widget.pickup!), 15.0);
    } else if (widget.destination != null) {
      _mapController.move(_toLL(widget.destination!), 15.0);
    }
  }

  @override
  void didUpdateWidget(covariant WebMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only refit when pickup/destination changed
    if ((widget.pickup != null && oldWidget.pickup == null) ||
        (widget.destination != null && oldWidget.destination == null) ||
        (widget.pickup != null && oldWidget.pickup != null &&
            (widget.pickup!.latitude != oldWidget.pickup!.latitude ||
             widget.pickup!.longitude != oldWidget.pickup!.longitude)) ||
        (widget.destination != null && oldWidget.destination != null &&
            (widget.destination!.latitude != oldWidget.destination!.latitude ||
             widget.destination!.longitude != oldWidget.destination!.longitude))
    ) {
      // small delay to allow map controller to be ready
      Future.delayed(const Duration(milliseconds: 120), () {
        try {
          _fitBoundsIfNeeded();
        } catch (e) {
          // ignore fit errors
        }
      });
    }
  }

  Marker _mk(ll.LatLng point, Widget child) => Marker(
        width: 48,
        height: 48,
        point: point,
        builder: (_) => child,
        anchorPos: AnchorPos.align(AnchorAlign.top),
      );

  @override
  Widget build(BuildContext context) {
    final center = widget.pickup != null
        ? _toLL(widget.pickup!)
        : _toLL(widget.initialLocation);

    final markers = <Marker>[];

    if (widget.pickup != null) {
      markers.add(_mk(_toLL(widget.pickup!), const Icon(Icons.my_location, size: 44, color: Colors.blue)));
    }

    if (widget.destination != null) {
      markers.add(_mk(_toLL(widget.destination!), const Icon(Icons.place, size: 44, color: Colors.red)));
    }

    if (widget.driverPositions != null) {
      for (var p in widget.driverPositions!) {
        markers.add(_mk(_toLL(p), Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)]),
          child: const Center(child: Icon(Icons.drive_eta, size: 14, color: Colors.white)),
        )));
      }
    }

    // Polyline from pickup -> destination
    final polylines = <Polyline>[];
    if (widget.pickup != null && widget.destination != null) {
      polylines.add(Polyline(
        points: [_toLL(widget.pickup!), _toLL(widget.destination!)],
        strokeWidth: 4.0,
        color: Colors.black,
      ));
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: center,
        zoom: _zoom,
        interactiveFlags: InteractiveFlag.all,
        onTap: (tapPos, latlng) {
          final g = latlng;
          widget.onDestinationSelected(g);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.taxi_app',
        ),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
