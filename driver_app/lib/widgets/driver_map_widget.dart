import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';
import '../services/map_service.dart';

class DriverMapWidget extends StatefulWidget {
  const DriverMapWidget({super.key});

  @override
  State<DriverMapWidget> createState() => _DriverMapWidgetState();
}

class _DriverMapWidgetState extends State<DriverMapWidget> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _loadRouteIfActive();
  }

  void _loadRouteIfActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      if (driverProvider.currentRideRequest != null) {
        _loadRouteForRideRequest(driverProvider.currentRideRequest!);
      }
    });
  }

  Future<void> _loadRouteForRideRequest(Map<String, dynamic> rideRequest) async {
    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final pickup = LatLng(
        rideRequest['pickup_lat'] ?? 13.0827,
        rideRequest['pickup_lng'] ?? 80.2707,
      );
      
      final drop = LatLng(
        rideRequest['drop_lat'] ?? 13.0827,
        rideRequest['drop_lng'] ?? 80.2707,
      );

      final route = await MapService.getRoute(pickup, drop);
      
      if (mounted) {
        setState(() {
          _routePoints = route;
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, driverProvider, child) {
        final currentPosition = driverProvider.currentPosition;
        final rideRequest = driverProvider.currentRideRequest;
        final isOnline = driverProvider.isOnline;

        // Default to Chennai if no position
        final centerPosition = currentPosition != null
            ? LatLng(currentPosition.latitude, currentPosition.longitude)
            : const LatLng(13.0827, 80.2707); // Chennai

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centerPosition,
            initialZoom: 15.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // OpenStreetMap tiles (FREE)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ridenow.driver',
              maxZoom: 19,
            ),
            
            // Current location marker
            if (currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(currentPosition.latitude, currentPosition.longitude),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            
            // Ride request markers and route
            if (rideRequest != null) ...[
              // Pickup marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      rideRequest['pickup_lat'] ?? 13.0827,
                      rideRequest['pickup_lng'] ?? 80.2707,
                    ),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Drop marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      rideRequest['drop_lat'] ?? 13.0827,
                      rideRequest['drop_lng'] ?? 80.2707,
                    ),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.flag,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Route polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
            ],
            
            // Loading indicator for route
            if (_isLoadingRoute)
              const MarkerLayer(
                markers: [
                  // Empty markers layer for loading state
                ],
              ),
          ],
        );
      },
    );
  }
}

// Map control buttons widget
class MapControlsWidget extends StatelessWidget {
  final VoidCallback? onCenterLocation;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;

  const MapControlsWidget({
    super.key,
    this.onCenterLocation,
    this.onZoomIn,
    this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          // Center location button
          FloatingActionButton(
            heroTag: "center_location",
            onPressed: onCenterLocation,
            backgroundColor: Colors.white,
            mini: true,
            child: const Icon(
              Icons.my_location,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          
          // Zoom in button
          FloatingActionButton(
            heroTag: "zoom_in",
            onPressed: onZoomIn,
            backgroundColor: Colors.white,
            mini: true,
            child: const Icon(
              Icons.add,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          
          // Zoom out button
          FloatingActionButton(
            heroTag: "zoom_out",
            onPressed: onZoomOut,
            backgroundColor: Colors.white,
            mini: true,
            child: const Icon(
              Icons.remove,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// Map legend widget
class MapLegendWidget extends StatelessWidget {
  const MapLegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Legend',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            _buildLegendItem('Your Location', Colors.green, Icons.directions_car),
            const SizedBox(height: 4),
            _buildLegendItem('Pickup', Colors.green, Icons.location_on),
            const SizedBox(height: 4),
            _buildLegendItem('Destination', Colors.red, Icons.flag),
            const SizedBox(height: 4),
            _buildLegendItem('Route', Colors.blue, Icons.line_style),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 10,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
