import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../providers/passenger_provider.dart';
import '../services/map_service.dart';

class CustomerMapWidget extends StatefulWidget {
  final Map<String, dynamic>? currentRide;
  final Function(Map<String, dynamic>)? onRideRequested;

  const CustomerMapWidget({
    super.key,
    this.currentRide,
    this.onRideRequested,
  });

  @override
  State<CustomerMapWidget> createState() => _CustomerMapWidgetState();
}

class _CustomerMapWidgetState extends State<CustomerMapWidget> {
  final MapController _mapController = MapController();
  LatLng? _pickupLocation;
  LatLng? _dropLocation;
  String _pickupAddress = '';
  String _dropAddress = '';
  bool _isSelectingDrop = false;
  bool _isLoading = false;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final passengerProvider = Provider.of<PassengerProvider>(context, listen: false);
    await passengerProvider.getCurrentLocation();
    
    if (passengerProvider.currentPosition != null) {
      final position = passengerProvider.currentPosition!;
      final userLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _pickupLocation = userLocation;
      });
      
      _mapController.move(userLocation, 15.0);
      _reverseGeocodePickup(userLocation);
    }
  }

  Future<void> _reverseGeocodePickup(LatLng location) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final address = await MapService.reverseGeocode(location);
      if (address != null) {
        setState(() {
          _pickupAddress = address;
        });
      }
    } catch (e) {
      print('Error geocoding pickup: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _reverseGeocodeDrop(LatLng location) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final address = await MapService.reverseGeocode(location);
      if (address != null) {
        setState(() {
          _dropAddress = address;
        });
      }
    } catch (e) {
      print('Error geocoding drop: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRoute() async {
    if (_pickupLocation == null || _dropLocation == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final route = await MapService.getRoute(_pickupLocation!, _dropLocation!);
      setState(() {
        _routePoints = route;
      });
    } catch (e) {
      print('Error loading route: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (widget.currentRide != null) return; // Don't allow selection during active ride

    if (!_isSelectingDrop) {
      // Select pickup location
      setState(() {
        _pickupLocation = point;
        _dropLocation = null;
        _dropAddress = '';
        _routePoints = [];
      });
      _reverseGeocodePickup(point);
    } else {
      // Select drop location
      setState(() {
        _dropLocation = point;
        _routePoints = [];
      });
      _reverseGeocodeDrop(point);
      _loadRoute();
    }
  }

  void _startDropSelection() {
    setState(() {
      _isSelectingDrop = true;
    });
  }

  void _resetSelection() {
    setState(() {
      _pickupLocation = null;
      _dropLocation = null;
      _pickupAddress = '';
      _dropAddress = '';
      _isSelectingDrop = false;
      _routePoints = [];
    });
    
    // Reload user location
    _loadUserLocation();
  }

  Future<void> _bookRide() async {
    if (_pickupLocation == null || _dropLocation == null) return;

    final rideData = {
      'pickup_lat': _pickupLocation!.latitude,
      'pickup_lng': _pickupLocation!.longitude,
      'pickup_address': _pickupAddress.isEmpty ? 'Selected Location' : _pickupAddress,
      'drop_lat': _dropLocation!.latitude,
      'drop_lng': _dropLocation!.longitude,
      'drop_address': _dropAddress.isEmpty ? 'Selected Location' : _dropAddress,
      'city': 'Chennai', // Default city
    };

    if (widget.onRideRequested != null) {
      widget.onRideRequested!(rideData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PassengerProvider>(
      builder: (context, passengerProvider, child) {
        final currentPosition = passengerProvider.currentPosition;
        final currentRide = widget.currentRide;

        // Default to user location or Chennai
        final centerPosition = currentPosition != null
            ? LatLng(currentPosition.latitude, currentPosition.longitude)
            : const LatLng(13.0827, 80.2707);

        return Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: centerPosition,
                initialZoom: 15.0,
                minZoom: 3.0,
                maxZoom: 18.0,
                onTap: currentRide == null ? _onMapTap : null,
              ),
              children: [
                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ridenow.customer',
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
                            color: Colors.blue,
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
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                
                // Pickup marker
                if (_pickupLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _pickupLocation!,
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
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                
                // Drop marker
                if (_dropLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _dropLocation!,
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
                          child: const Icon(
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
                
                // Driver location (if active ride)
                if (currentRide != null && currentRide['driver'] != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          currentRide['driver']['current_lat'] ?? 13.0827,
                          currentRide['driver']['current_lng'] ?? 80.2707,
                        ),
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange,
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
                          child: const Icon(
                            Icons.directions_car,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            
            // Map controls
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  // Center location button
                  FloatingActionButton(
                    heroTag: "center_location",
                    onPressed: () {
                      if (currentPosition != null) {
                        _mapController.move(
                          LatLng(currentPosition.latitude, currentPosition.longitude),
                          15.0,
                        );
                      }
                    },
                    backgroundColor: Colors.white,
                    mini: true,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Zoom controls
                  FloatingActionButton(
                    heroTag: "zoom_in",
                    onPressed: () {
                      final currentZoom = _mapController.zoom ?? 15.0;
                      _mapController.move(_pickupLocation ?? const LatLng(13.0827, 80.2707), currentZoom + 1);
                    },
                    backgroundColor: Colors.white,
                    mini: true,
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  
                  FloatingActionButton(
                    heroTag: "zoom_out",
                    onPressed: () {
                      final currentZoom = _mapController.zoom ?? 15.0;
                      _mapController.move(_pickupLocation ?? const LatLng(13.0827, 80.2707), currentZoom - 1);
                    },
                    backgroundColor: Colors.white,
                    mini: true,
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
            
            // Loading indicator
            if (_isLoading)
              const Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            
            // Bottom sheet for ride booking
            if (currentRide == null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: RideBookingBottomSheet(
                  pickupLocation: _pickupLocation,
                  dropLocation: _dropLocation,
                  pickupAddress: _pickupAddress,
                  dropAddress: _dropAddress,
                  isSelectingDrop: _isSelectingDrop,
                  routePoints: _routePoints,
                  onStartDropSelection: _startDropSelection,
                  onReset: _resetSelection,
                  onBookRide: _bookRide,
                ),
              ),
          ],
        );
      },
    );
  }
}

class RideBookingBottomSheet extends StatelessWidget {
  final LatLng? pickupLocation;
  final LatLng? dropLocation;
  final String pickupAddress;
  final String dropAddress;
  final bool isSelectingDrop;
  final List<LatLng> routePoints;
  final VoidCallback onStartDropSelection;
  final VoidCallback onReset;
  final VoidCallback onBookRide;

  const RideBookingBottomSheet({
    super.key,
    required this.pickupLocation,
    required this.dropLocation,
    required this.pickupAddress,
    required this.dropAddress,
    required this.isSelectingDrop,
    required this.routePoints,
    required this.onStartDropSelection,
    required this.onReset,
    required this.onBookRide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              isSelectingDrop ? 'Select Drop Location' : 'Select Pickup Location',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Pickup location
            _buildLocationRow(
              'Pickup',
              pickupAddress.isEmpty ? 'Tap on map to select' : pickupAddress,
              Icons.location_on,
              Colors.green,
              pickupLocation != null,
            ),
            
            const SizedBox(height: 12),
            
            // Drop location
            _buildLocationRow(
              'Drop',
              dropAddress.isEmpty ? 
                (isSelectingDrop ? 'Tap on map to select' : 'Select pickup first') 
                : dropAddress,
              Icons.flag,
              Colors.red,
              dropLocation != null,
            ),
            
            // Route info
            if (routePoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Route calculated successfully',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Action buttons
            if (pickupLocation != null && dropLocation != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onBookRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Book Ride',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else if (pickupLocation != null && !isSelectingDrop)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onStartDropSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Select Drop Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else if (pickupLocation != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Reset Selection',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap on the map to select your pickup location',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(
    String label,
    String address,
    IconData icon,
    Color color,
    bool isSelected,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.black87 : Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle, color: color, size: 20),
        ],
      ),
    );
  }
}
