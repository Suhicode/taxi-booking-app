import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomerMapScreen extends StatefulWidget {
  const CustomerMapScreen({super.key});

  @override
  State<CustomerMapScreen> createState() => _CustomerMapScreenState();
}

class _CustomerMapScreenState extends State<CustomerMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _destination;
  bool _isLoading = true;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _pickupLocation = _currentLocation;
        _addMarker('pickup', _currentLocation!, 'Pickup Location', BitmapDescriptor.hueGreen);
        _isLoading = false;
      });
      _moveToLocation(_currentLocation!);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addMarker(String id, LatLng position, String title, double colorHue) {
    _markers.removeWhere((m) => m.markerId.value == id);
    _markers.add(
      Marker(
        markerId: MarkerId(id),
        position: position,
        infoWindow: InfoWindow(title: title),
        icon: BitmapDescriptor.defaultMarkerWithHue(colorHue),
      ),
    );
  }

  void _moveToLocation(LatLng location) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 15),
      ),
    );
  }

  void _onDestinationSelected(LatLng latLng) {
    setState(() {
      _destination = latLng;
      _addMarker('destination', latLng, 'Destination', BitmapDescriptor.hueRed);
      _updateRoute();
    });
  }

  void _updateRoute() {
    if (_pickupLocation != null && _destination != null) {
      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [_pickupLocation!, _destination!],
            color: Colors.blue,
            width: 3,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation ?? const LatLng(0, 0),
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onTap: _onDestinationSelected,
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        children: [
                          TextField(
                            controller: _pickupController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              hintText: 'Pickup Location (Current)',
                              prefixIcon: Icon(Icons.my_location),
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(),
                          TextField(
                            controller: _destinationController,
                            decoration: const InputDecoration(
                              hintText: 'Enter Destination',
                              prefixIcon: Icon(Icons.location_on),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (value) async {
                              // TODO: Geocode destination name to LatLng
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
