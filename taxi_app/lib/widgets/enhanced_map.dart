// lib/widgets/enhanced_map.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as lat;
import 'package:http/http.dart' as http;

class EnhancedMap extends StatefulWidget {
  final lat.LatLng? center;
  final double zoom;
  final Set<Marker>? markers;
  final List<lat.LatLng>? routePoints;
  final Function(lat.LatLng)? onTap;
  final bool showCurrentLocation;
  final bool isLoading;
  final String? errorMessage;

  const EnhancedMap({
    Key? key,
    this.center,
    this.zoom = 15.0,
    this.markers,
    this.routePoints,
    this.onTap,
    this.showCurrentLocation = true,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<EnhancedMap> createState() => _EnhancedMapState();
}

class _EnhancedMapState extends State<EnhancedMap> {
  late MapController mapController;
  Timer? _debounceTimer;
  final int _mapLoadRetryCount = 0;
  static const int _maxMapLoadRetries = 3;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _loadMapWithRetry();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    mapController.dispose();
    super.dispose();
  }

  void _loadMapWithRetry() {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Debounce map loading to prevent flickering
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadMap();
    });
  }

  Future<void> _loadMap() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Simulate map loading with a small delay
      await Future.delayed(const Duration(milliseconds: 100));

      final bounds = _calculateBounds();
      
      if (bounds != null) {
        mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds!,
            padding: const EdgeInsets.all(50),
          ),
        );
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Map loading failed: ${e.toString()}';
      });
      
      // Retry logic for map loading failures
      if (_mapLoadRetryCount < _maxMapLoadRetries) {
        _loadMapWithRetry();
      }
    }
  }

  LatLngBounds? _calculateBounds() {
    if (widget.markers == null || widget.markers!.isEmpty) {
      return null;
    }

    double minLat = widget.markers!.first.point.latitude;
    double maxLat = widget.markers!.first.point.latitude;
    double minLng = widget.markers!.first.point.longitude;
    double maxLng = widget.markers!.first.point.longitude;

    // Include route points if available
    if (widget.routePoints != null && widget.routePoints!.isNotEmpty) {
      for (final point in widget.routePoints!) {
        minLat = math.min(minLat, point.latitude);
        maxLat = math.max(maxLat, point.latitude);
        minLng = math.min(minLng, point.longitude);
        maxLng = math.max(maxLng, point.longitude);
      }
    }

    // Add padding to bounds
    const double padding = 0.01; // ~1km padding

    return LatLngBounds(
      LatLng(maxLat - padding, minLng - padding),
      LatLng(maxLat + padding, maxLng + padding),
      LatLng(minLat - padding, maxLng - padding),
      LatLng(minLat + padding, minLng + padding),
    );
  }

  void _onMapReady() {
    if (widget.markers != null && widget.markers!.isNotEmpty) {
      final bounds = _calculateBounds();
      if (bounds != null) {
        mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds!,
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    }
  }

  void _showErrorSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          controller: mapController,
          options: MapOptions(
            center: widget.center ?? const lat.LatLng(37.7749, -122.4194),
            zoom: widget.zoom,
            interactiveFlags: InteractiveFlag.all,
            onTap: (tapPosition, latLng) {
              if (widget.onTap != null) {
                widget.onTap!(tapPosition, latLng);
              }
            },
          ),
          children: [
            // Enhanced tile layer with error handling
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.yousu.taxiapp',
              errorTileCallback: (tile, error, stackTrace) {
                if (error != null) {
                  _showErrorSnackBar('Map tile error: $error', context);
                }
                return true; // Continue loading other tiles
              },
            ),
            
            // Enhanced marker layer with custom icons
            if (widget.markers != null && widget.markers!.isNotEmpty)
              MarkerLayer(
                markers: widget.markers!.map((marker) {
                  final customMarker = marker as CustomMarker;
                  return customMarker.toMarker();
                }).toList(),
              ),
            
            // Current location marker
            if (widget.showCurrentLocation && widget.center != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.center!,
                    width: 40.0,
                    height: 40.0,
                    builder: (context) => Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 20,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'You',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            
            // Route polyline layer
            if (widget.routePoints != null && widget.routePoints!.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.routePoints!,
                    strokeWidth: 4.0,
                    color: Colors.blue,
                  ),
                ],
              ],
            ),
          ],
        ),
        
        // Loading indicator
        if (widget.isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3.0,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading map...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Error message
        if (widget.errorMessage != null)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.8),
              padding: const EdgeInsets.all(16),
              child: Card(
                color: Colors.red,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            errorMessage = null;
                          });
                          _loadMap();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        
        // Map controls
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Map Controls',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.zoom_in),
                              label: const Text('Zoom In'),
                              onPressed: () {
                                final currentZoom = mapController.camera.zoom;
                                mapController.move(
                                  mapController.camera.center,
                                  zoom: math.min(currentZoom + 1, 18.0),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.zoom_out),
                              label: const Text('Zoom Out'),
                              onPressed: () {
                                final currentZoom = mapController.camera.zoom;
                                mapController.move(
                                  mapController.camera.center,
                                  zoom: math.max(currentZoom - 1, 1.0),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icons.gps_fixed),
                              label: const Text('Recenter'),
                              onPressed: () {
                                if (widget.center != null) {
                                  mapController.move(widget.center, zoom: widget.zoom);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Enhanced marker class for better customization
class CustomMarker {
  final lat.LatLng point;
  final double width;
  final double height;
  final Widget icon;
  final Color color;

  const CustomMarker({
    required this.point,
    this.width = 30.0,
    this.height = 30.0,
    this.icon = Icons.location_on,
    this.color = Colors.green,
  });

  // Convert to flutter_map Marker
  Marker toMarker() {
    return Marker(
      point: point,
      width: width,
      height: height,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.0),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}

// Google Maps Directions API service
class GoogleMapsService {
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // Replace with actual API key
  
  static Future<List<lat.LatLng>> getDirections({
    required lat.LatLng origin,
    required lat.LatLng destination,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$_apiKey'
        '&mode=driving'
        '&alternatives=false',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final legs = route['legs'] as List<dynamic>;
          
          final points = <lat.LatLng>[];
          
          // Add origin
          points.add(origin);
          
          // Add intermediate points from each leg
          for (final leg in legs) {
            final steps = leg['steps'] as List<dynamic>;
            
            for (final step in steps) {
              if (step['start_location'] != null) {
                final startLoc = step['start_location'] as Map<String, dynamic>;
                points.add(lat.LatLng(
                  startLoc['lat'] as double,
                  startLoc['lng'] as double,
                ));
              }
              
              if (step['end_location'] != null) {
                final endLoc = step['end_location'] as Map<String, dynamic>;
                points.add(lat.LatLng(
                  endLoc['lat'] as double,
                  endLoc['lng'] as double,
                ));
              }
            }
          }
          
          // Add destination
          points.add(destination);
          
          return points;
        }
      }
      
      throw Exception('No route found');
    } catch (e) {
      throw Exception('Directions API error: $e');
    }
  }

  static Future<Map<String, dynamic>> getRouteInfo({
    required lat.LatLng origin,
    required lat.LatLng destination,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$_apiKey'
        '&mode=driving'
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final legs = route['legs'] as List<dynamic>;
          
          double totalDistance = 0;
          Duration totalDuration = Duration.zero;
          
          for (final leg in legs) {
            final distance = leg['distance']?.toDouble() ?? 0.0;
            final duration = Duration(
              seconds: leg['duration']?.toDouble() ?? 0.0,
            );
            
            totalDistance += distance;
            totalDuration += duration;
          }
          
          return {
            'distance': totalDistance.toStringAsFixed(2),
            'duration': totalDuration.inMinutes.toStringAsFixed(0),
            'steps': legs.length,
          };
        }
      }
      
      return {
        'distance': '0',
        'duration': '0',
        'steps': 0,
      };
    } catch (e) {
      throw Exception('Route info API error: $e');
    }
  }
}
