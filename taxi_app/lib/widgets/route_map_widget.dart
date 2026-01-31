import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as lat;
import '../services/openstreetmap_service.dart';

class RouteMapWidget extends StatefulWidget {
  final lat.LatLng pickupLocation;
  final lat.LatLng dropLocation;
  final List<lat.LatLng>? routePoints;

  const RouteMapWidget({
    Key? key,
    required this.pickupLocation,
    required this.dropLocation,
    this.routePoints,
  }) : super(key: key);

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  List<lat.LatLng> _routePoints = [];
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    if (widget.routePoints != null) {
      _routePoints = widget.routePoints!;
    } else {
      _loadRoute();
    }
  }

  Future<void> _loadRoute() async {
    setState(() => _isLoadingRoute = true);
    
    try {
      final route = await OpenStreetMapService.getRoute(
        widget.pickupLocation.latitude,
        widget.pickupLocation.longitude,
        widget.dropLocation.latitude,
        widget.dropLocation.longitude,
      );
      
      if (mounted) {
        setState(() {
          _routePoints = route;
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load route: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: lat.LatLng(
          (widget.pickupLocation.latitude + widget.dropLocation.latitude) / 2,
          (widget.pickupLocation.longitude + widget.dropLocation.longitude) / 2,
        ),
        zoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.taxi_app',
        ),
        
        // Route polyline
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 5.0,
                color: Colors.blue,
              ),
            ],
          ),
        
        // Pickup marker
        MarkerLayer(
          markers: [
            Marker(
              point: widget.pickupLocation,
              builder: (context) => const Icon(
                Icons.location_on,
                color: Colors.green,
                size: 40,
              ),
            ),
            Marker(
              point: widget.dropLocation,
              builder: (context) => const Icon(
                Icons.flag,
                color: Colors.red,
                size: 40,
              ),
            ),
          ],
        ),
        
        // Loading indicator
        if (_isLoadingRoute)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}

class MapWithRoute extends StatelessWidget {
  final lat.LatLng pickupLocation;
  final lat.LatLng dropLocation;

  const MapWithRoute({
    Key? key,
    required this.pickupLocation,
    required this.dropLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: RouteMapWidget(
        pickupLocation: pickupLocation,
        dropLocation: dropLocation,
      ),
    );
  }
}
