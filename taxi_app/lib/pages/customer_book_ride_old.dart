// lib/pages/customer_book_ride.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/driver_service_mock.dart';
import '../services/location_service.dart';
import '../services/pricing_service.dart';
import '../services/ride_booking_service.dart';
import '../models/ride_request_model.dart';
import '../widgets/vehicle_tile.dart';
import '../widgets/web_map_view.dart';
import '../widgets/free_autocomplete_field.dart';
import '../widgets/booking_overlay.dart';
import '../widgets/ride_notification_banner.dart';

// Only import Google Maps on non-web platforms
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as lat;

class CustomerBookRidePage extends StatefulWidget {
  const CustomerBookRidePage({super.key});

  @override
  State<CustomerBookRidePage> createState() => _CustomerBookRidePageState();
}

class _CustomerBookRidePageState extends State<CustomerBookRidePage> {
  final Completer<GoogleMapController> _mapControllerCompleter = Completer();
  Set<Marker> _driverMarkers = {};
  LatLng? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _destination;
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  String _selectedVehicle = 'Standard';
  int _estimatedPrice = 0;
  bool _isLoading = true;
  bool _driverAssigned = false;
  final DriverService _driverService = DriverService();
  StreamSubscription<List<DriverModel>>? _driverSub;
  Timer? _rideUpdateTimer;
  DriverModel? _assignedDriver;
  String _pickupText = '';
  String _destinationText = '';
  List<DriverModel> _latestDrivers = [];
  String? _currentRideId;

  final List<String> _vehicleTypes = ['Bike', 'Scooty', 'Standard', 'Comfort', 'Premium', 'XL'];

  // Lightweight in-app notification state for ride status changes
  String? _rideNotificationTitle;
  String? _rideNotificationSubtitle;
  bool _showRideNotification = false;

  // Helper function to extract driver positions from markers
  List<LatLng> _driverPositionsFromMarkers() {
    return _driverMarkers.map((m) => m.position).toList();
  }

  @override
  void initState() {
    super.initState();
    // Run initialization after first frame so UI can show a loader fast.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
      _subscribeToDrivers();
    });
  }

  @override
  void dispose() {
    _driverSub?.cancel();
    _rideUpdateTimer?.cancel();
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    // Request permission first
    final granted = await LocationService.requestPermission();
    if (!granted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission required')));
      return;
    }

    final loc = await LocationService.getCurrentLocation();
    if (loc != null) {
      setState(() {
        _currentLocation = loc;
        _pickupLocation = loc;
        _pickupController.text = 'Current Location';
        _pickupText = 'Current Location';
        _isLoading = false;
      });
      if (!kIsWeb) {
        // wait for map to be created
        if (_mapControllerCompleter.isCompleted) {
          final c = await _mapControllerCompleter.future;
          c.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: loc, zoom: 15)));
        }
      }
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to get location')));
    }
  }

  void _subscribeToDrivers() {
    // Subscribe once and update markers only when changed
    _driverSub = _driverService.getAvailableDrivers().listen((drivers) {
      _latestDrivers = drivers;
      final newSet = drivers.map((d) => d.toMarker()).toSet();
      // Minimal UI update: only call setState when markers actually changed
      final changed = newSet.length != _driverMarkers.length ||
          !newSet.every((m) => _driverMarkers.contains(m));
      if (changed) {
        setState(() {
          _driverMarkers = newSet;
        });
      }
    });
  }

  void _moveToLocation(LatLng location) async {
    if (kIsWeb) {
      // For web we rely on WebMapView.didUpdateWidget to move the map
      setState(() {
        _currentLocation = location;
        // also set pickup as current if needed:
        _pickupLocation = location;
      });
      return;
    }
    // mobile (GoogleMap)
    if (_mapControllerCompleter.isCompleted) {
      final controller = await _mapControllerCompleter.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: location, zoom: 16)));
    }
  }

  void _updateEstimatedPrice() {
    if (_pickupLocation != null && _destination != null) {
      final distance = _calculateDistance(_pickupLocation!, _destination!);
      final fare = PricingService.calculateFare(
        vehicleType: _selectedVehicle,
        distanceKm: distance,
        durationMin: (distance * 3).toDouble(), // Rough estimate
      );
      setState(() {
        _estimatedPrice = fare['total'] as int;
      });
    }
  }

  double _calculateDistance(LatLng pickup, LatLng destination) {
    // Simple distance calculation using Haversine formula
    const double earthRadius = 6371; // kilometers
    
    final double lat1Rad = pickup.latitude * (math.pi / 180);
    final double lat2Rad = destination.latitude * (math.pi / 180);
    final double deltaLatRad = (destination.latitude - pickup.latitude) * (math.pi / 180);
    final double deltaLonRad = (destination.longitude - pickup.longitude) * (math.pi / 180);
    
    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLonRad / 2) * math.sin(deltaLonRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  // when user selects pickup from autocomplete
  void _onPickupSelected(String name, LatLng loc) {
    setState(() {
      _pickupLocation = loc;
      // set currentLocation to the pickup so the map centers on it
      _currentLocation = loc;
      _pickupController.text = name;
      _pickupText = name;
    });
    // update camera / map center and price
    _moveToLocation(loc);
    _updateEstimatedPrice();
  }

  // when user selects destination from autocomplete
  void _onDestinationSelected(String name, LatLng loc) {
    setState(() {
      _destination = loc;
      _destinationController.text = name;
      _destinationText = name;
    });
    // center map on destination as well (optional) — use same move
    _moveToLocation(loc);
    _updateEstimatedPrice();
  }

  Widget _buildMap() {
    final bool isWeb = kIsWeb;
    if (isWeb) {
      return WebMapView(
        initialLocation: _currentLocation ?? const LatLng(13.0827, 80.2707),
        pickup: _pickupLocation,
        destination: _destination,
        driverPositions: _driverPositionsFromMarkers(),
        onDestinationSelected: (LatLng destination) {
          setState(() {
            _destination = destination;
            _destinationController.text = 'Selected Destination';
          });
          _moveToLocation(destination);
          _updateEstimatedPrice();
        },
      );
    }

    if (_currentLocation == null) {
      return Container(
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _currentLocation!, zoom: 15),
      onMapCreated: (controller) {
        if (!_mapControllerCompleter.isCompleted) {
          _mapControllerCompleter.complete(controller);
        }
      },
      markers: _driverMarkers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false, // use custom button
      onTap: (LatLng dest) {
        setState(() {
          _destination = dest;
          _destinationController.text = 'Selected Destination';
        });
        _updateEstimatedPrice();
      },
    );
  }

  Future<void> _requestRide() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride requests are disabled on web build. Please run on Android/iOS.')),
      );
      return;
    }
    if (_pickupLocation == null || _destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Set pickup and destination')));
      return;
    }

    try {
      // Calculate distance for pricing
      final distance = _calculateDistance(_pickupLocation!, _destination!);
      
      // Convert Google Maps LatLng to latlong2 LatLng for the ride booking service
      final latPickup = lat.LatLng(_pickupLocation!.latitude, _pickupLocation!.longitude);
      final latDestination = lat.LatLng(_destination!.latitude, _destination!.longitude);
      
      // Create ride request using our mock service
      final rideId = await RideBookingService.createRideRequest(
        customerId: 'customer_demo_001',
        customerName: 'Demo Customer',
        customerPhone: '9876543210',
        pickupLocation: latPickup,
        pickupAddress: _pickupText.isNotEmpty ? _pickupText : _pickupController.text,
        destinationLocation: latDestination,
        destinationAddress: _destinationText.isNotEmpty ? _destinationText : _destinationController.text,
        vehicleType: _selectedVehicle,
        estimatedFare: _estimatedPrice.toDouble(),
        distance: distance,
      );
      
      _currentRideId = rideId;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride requested — waiting for drivers')));
      _startRideStatusUpdates(rideId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not request ride: $e')));
    }
  }

  void _startRideStatusUpdates(String rideId) {
    // Cancel existing timer (if any)
    _rideUpdateTimer?.cancel();

    // Start periodic updates to check ride status
    _rideUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final ride = RideBookingService.getRideById(rideId);
      if (ride != null) {
        if (ride.status == RideStatus.accepted && ride.driverId != null) {
          _handleDriverAssigned(ride.driverName!);
        } else if (ride.status == RideStatus.completed || ride.status == RideStatus.cancelled) {
          _handleRideEnded(ride.status);
        }
      }
    });
  }

  void _handleDriverAssigned(String driverName) {
    setState(() {
      _driverAssigned = true;
      _rideNotificationTitle = 'Driver assigned';
      _rideNotificationSubtitle = driverName;
      _showRideNotification = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Driver assigned: $driverName')),
    );
  }

  void _handleRideEnded(RideStatus status) {
    setState(() {
      _driverAssigned = false;
      _rideNotificationTitle = status == RideStatus.completed ? 'Ride completed' : 'Ride cancelled';
      _rideNotificationSubtitle = null;
      _showRideNotification = true;
    });
    _rideUpdateTimer?.cancel();
  }

  void _showLocationSelector({required bool isPickup}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: FreeAutocompleteField(
            hint: isPickup ? 'Enter pickup location' : 'Enter destination',
            controller: isPickup ? _pickupController : _destinationController,
            onSelected: (name, loc) {
              Navigator.of(context).pop();
              if (isPickup) {
                _onPickupSelected(name, loc);
              } else {
                _onDestinationSelected(name, loc);
              }
            },
          ),
        );
      },
    );
  }

  void _selectPickup() => _showLocationSelector(isPickup: true);

  void _selectDestination() => _showLocationSelector(isPickup: false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Map background
                _buildMap(),

                // Customer ride status notification banner
                if (_showRideNotification && _rideNotificationTitle != null)
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: RideNotificationBanner(
                      icon: Icons.local_taxi,
                      title: _rideNotificationTitle!,
                      subtitle: _rideNotificationSubtitle,
                      onTap: () {
                        if (_assignedDriver?.location != null) {
                          _moveToLocation(
                            LatLng(
                              _assignedDriver!.location.latitude,
                              _assignedDriver!.location.longitude,
                            ),
                          );
                        } else if (_pickupLocation != null) {
                          _moveToLocation(_pickupLocation!);
                        }
                        setState(() {
                          _showRideNotification = false;
                        });
                      },
                      onClose: () {
                        setState(() {
                          _showRideNotification = false;
                        });
                      },
                    ),
                  ),

                // Top gradient header + greeting card (Easy Ride style)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF6C200),
                          Color(0xFFFFE58A),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person, color: Colors.black87),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Good day 👋',
                                      style: theme.textTheme.bodySmall!.copyWith(
                                        color: Colors.black.withOpacity(0.7),
                                      ),
                                    ),
                                    Text(
                                      'Where are you going?',
                                      style: theme.textTheme.titleLarge!.copyWith(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Notifications coming soon')),
                                  );
                                },
                                icon: const Icon(Icons.notifications_none, color: Colors.black87),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Compact pickup/destination quick card overlaying map
                          Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: _selectPickup,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 26,
                                          width: 26,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.my_location, size: 16),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _pickupText.isNotEmpty ? _pickupText : 'Current location',
                                            style: theme.textTheme.bodyMedium!.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Divider(color: Colors.grey.shade200, height: 1),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _selectDestination,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          height: 26,
                                          width: 26,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFEE2E2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _destinationText.isNotEmpty
                                                ? _destinationText
                                                : 'Where to?',
                                            style: theme.textTheme.bodyMedium!.copyWith(
                                              color: _destinationText.isNotEmpty
                                                  ? theme.textTheme.bodyMedium!.color
                                                  : Colors.grey[600],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // VEHICLE SELECTOR - just above the main booking sheet
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 210,
                  child: SizedBox(
                    height: 120,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      scrollDirection: Axis.horizontal,
                      itemCount: _vehicleTypes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final vehicle = _vehicleTypes[index];
                        final fare = PricingService.calculateFare(
                          vehicleType: vehicle,
                          distanceKm: (_pickupLocation != null && _destination != null)
                              ? _calculateDistance(_pickupLocation!, _destination!)
                              : 5.0,
                          durationMin: 15,
                        );
                        return VehicleTile(
                          vehicleType: vehicle,
                          isSelected: _selectedVehicle == vehicle,
                          estimatedPrice: fare['total'] as int,
                          onTap: () {
                            setState(() {
                              _selectedVehicle = vehicle;
                            });
                            _updateEstimatedPrice();
                          },
                        );
                      },
                    ),
                  ),
                ),

                // Booking / in-trip bottom sheet
                if (!_driverAssigned)
                  BookingOverlay(
                    pickupText: _pickupText.isNotEmpty ? _pickupText : _pickupController.text,
                    destinationText: _destinationText.isNotEmpty ? _destinationText : _destinationController.text,
                    estimatedFare: '₹$_estimatedPrice',
                    onPickupTap: _selectPickup,
                    onDestinationTap: _selectDestination,
                    onBookTap: _requestRide,
                  )
                else if (_assignedDriver != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Material(
                      elevation: 24,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(40),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.directions_car, color: Colors.black87),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _assignedDriver!.name,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _assignedDriver!.vehicleType,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.call),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Calling driver...')),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Chat coming soon')),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 18, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Text(
                                      'ETA ~ 5 min',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '₹$_estimatedPrice',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _driverAssigned = false;
                                      _assignedDriver = null;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Booking cancelled')),
                                    );
                                  },
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      if (_assignedDriver?.location != null) {
                                        _moveToLocation(
                                          LatLng(
                                            _assignedDriver!.location.latitude,
                                            _assignedDriver!.location.longitude,
                                          ),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Centering on driver')),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Driver location not available')),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.navigation),
                                    label: const Text('Track driver'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (ctx) => SafeArea(
                                          child: Wrap(
                                            children: const [
                                              ListTile(
                                                leading: Icon(Icons.support_agent),
                                                title: Text('Contact support'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Help'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Live driver markers listener (non-web only)
                if (!kIsWeb)
                  StreamBuilder<List<DriverModel>>(
                    stream: _driverService.getAvailableDrivers(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _driverMarkers = {
                              for (var driver in snapshot.data!) driver.toMarker(),
                            };
                          });
                        });
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                // Custom locate-me FAB
                if (!kIsWeb)
                  Positioned(
                    right: 16,
                    bottom: 320,
                    child: FloatingActionButton(
                      heroTag: 'locFab',
                      mini: true,
                      onPressed: _getCurrentLocation,
                      child: const Icon(Icons.my_location),
                    ),
                  ),
              ],
            ),
          ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // Request permission and get current location
      final granted = await LocationService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final location = await LocationService.getCurrentLocation();
      if (location != null && mounted) {
        setState(() {
          _currentLocation = location;
          _pickupLocation = location;
          _pickupController.text = 'Current Location';
          _pickupText = 'Current Location';
          _isLoading = false;
        });

        // Move map to current location
        _moveToLocation(location);

        // Update estimated price
        _updateEstimatedPrice();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current location updated')),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not get current location')),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }
}
