// lib/pages/customer_book_ride_improved.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as lat;
import 'package:provider/provider.dart';

import '../services/driver_service_mock.dart';
import '../services/location_service.dart';
import '../services/pricing_service.dart';
import '../services/ride_booking_service.dart';
import '../models/ride_request_model.dart';
import '../widgets/vehicle_tile.dart';
import '../widgets/simple_map.dart';
import '../widgets/free_autocomplete_field.dart';
import '../widgets/booking_overlay.dart';
import '../widgets/ride_notification_banner.dart';

// State management class
class RideBookingState {
  lat.LatLng? currentLocation;
  lat.LatLng? pickupLocation;
  lat.LatLng? destination;
  String selectedVehicle = 'Standard';
  int estimatedPrice = 0;
  bool isLoading = true;
  bool driverAssigned = false;
  DriverModel? assignedDriver;
  String pickupText = '';
  String destinationText = '';
  String? currentRideId;
  String? rideNotificationTitle;
  String? rideNotificationSubtitle;
  bool showRideNotification = false;
  Set<Marker> driverMarkers = {};
  List<String> vehicleTypes = ['Bike', 'Scooty', 'Standard', 'Comfort', 'Premium', 'XL'];

  RideBookingState() {
    _initializeState();
  }

  void _initializeState() {
    // Initialize with safe defaults
    isLoading = true;
    driverAssigned = false;
    showRideNotification = false;
    selectedVehicle = 'Standard';
    estimatedPrice = 0;
    pickupText = '';
    destinationText = '';
  }

  RideBookingState copyWith({
    lat.LatLng? currentLocation,
    lat.LatLng? pickupLocation,
    lat.LatLng? destination,
    String? selectedVehicle,
    int? estimatedPrice,
    bool? isLoading,
    bool? driverAssigned,
    DriverModel? assignedDriver,
    String? pickupText,
    String? destinationText,
    String? currentRideId,
    String? rideNotificationTitle,
    String? rideNotificationSubtitle,
    bool? showRideNotification,
    Set<Marker>? driverMarkers,
  }) {
    final newState = RideBookingState();
    newState.currentLocation = currentLocation ?? this.currentLocation;
    newState.pickupLocation = pickupLocation ?? this.pickupLocation;
    newState.destination = destination ?? this.destination;
    newState.selectedVehicle = selectedVehicle ?? this.selectedVehicle;
    newState.estimatedPrice = estimatedPrice ?? this.estimatedPrice;
    newState.isLoading = isLoading ?? this.isLoading;
    newState.driverAssigned = driverAssigned ?? this.driverAssigned;
    newState.assignedDriver = assignedDriver ?? this.assignedDriver;
    newState.pickupText = pickupText ?? this.pickupText;
    newState.destinationText = destinationText ?? this.destinationText;
    newState.currentRideId = currentRideId ?? this.currentRideId;
    newState.rideNotificationTitle = rideNotificationTitle ?? this.rideNotificationTitle;
    newState.rideNotificationSubtitle = rideNotificationSubtitle ?? this.rideNotificationSubtitle;
    newState.showRideNotification = showRideNotification ?? this.showRideNotification;
    newState.driverMarkers = driverMarkers ?? this.driverMarkers;
    return newState;
  }

  void updateLocation(lat.LatLng location) {
    currentLocation = location;
    pickupLocation = location;
    pickupText = 'Current Location';
  }

  void updatePickup(String name, lat.LatLng loc) {
    pickupLocation = loc;
    currentLocation = loc;
    pickupText = name;
  }

  void updateDestination(String name, lat.LatLng loc) {
    destination = loc;
    destinationText = name;
  }

  void updateVehicle(String vehicle) {
    selectedVehicle = vehicle;
  }

  void updatePrice() {
    if (pickupLocation != null && destination != null) {
      final distance = _calculateDistance(pickupLocation!, destination!);
      final fare = PricingService.calculateFare(
        vehicleType: selectedVehicle,
        distanceKm: distance,
        durationMin: (distance * 3).toDouble(),
      );
      estimatedPrice = fare['total'] as int;
    }
  }

  void setLoading(bool loading) {
    isLoading = loading;
  }

  void setDriverAssigned(DriverModel driver) {
    driverAssigned = true;
    assignedDriver = driver;
    rideNotificationTitle = 'Driver assigned';
    rideNotificationSubtitle = driver.name;
    showRideNotification = true;
  }

  void setRideEnded(RideStatus status) {
    driverAssigned = false;
    assignedDriver = null;
    rideNotificationTitle = status == RideStatus.completed ? 'Ride completed' : 'Ride cancelled';
    rideNotificationSubtitle = null;
    showRideNotification = true;
  }

  void clearRideNotification() {
    showRideNotification = false;
    rideNotificationTitle = null;
    rideNotificationSubtitle = null;
  }

  double _calculateDistance(lat.LatLng pickup, lat.LatLng destination) {
    const double earthRadius = 6371;
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
}

// State management provider
class RideBookingProvider extends ChangeNotifier {
  RideBookingState _state = RideBookingState();

  RideBookingState get state => _state;

  void updateState(RideBookingState newState) {
    _state = newState;
    notifyListeners();
  }

  void updateLocation(lat.LatLng location) {
    updateState(_state.copyWith(currentLocation: location));
  }

  void updatePickup(String name, lat.LatLng loc) {
    updateState(_state.copyWith(
      pickupLocation: loc,
      pickupText: name,
    ));
  }

  void updateDestination(String name, lat.LatLng loc) {
    updateState(_state.copyWith(
      destination: loc,
      destinationText: name,
    ));
  }

  void updateVehicle(String vehicle) {
    updateState(_state.copyWith(selectedVehicle: vehicle));
    _updatePrice();
  }

  void updatePrice() {
    final newState = _state.copyWith();
    newState.updatePrice();
    updateState(newState);
  }

  void setLoading(bool loading) {
    updateState(_state.copyWith(isLoading: loading));
  }

  void setDriverAssigned(DriverModel driver) {
    final newState = _state.copyWith();
    newState.setDriverAssigned(driver);
    updateState(newState);
  }

  void setRideEnded(RideStatus status) {
    final newState = _state.copyWith();
    newState.setRideEnded(status);
    updateState(newState);
  }

  void clearRideNotification() {
    updateState(_state.copyWith(
      showRideNotification: false,
      rideNotificationTitle: null,
      rideNotificationSubtitle: null,
    ));
  }

  void updateDriverMarkers(Set<Marker> markers) {
    updateState(_state.copyWith(driverMarkers: markers));
  }
}

class CustomerBookRideImprovedPage extends StatefulWidget {
  const CustomerBookRideImprovedPage({super.key});

  @override
  State<CustomerBookRideImprovedPage> createState() => _CustomerBookRideImprovedPageState();
}

class _CustomerBookRideImprovedPageState extends State<CustomerBookRideImprovedPage> {
  late final DriverService _driverService;
  StreamSubscription<List<DriverModel>>? _driverSub;
  Timer? _rideUpdateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
      _subscribeToDrivers();
    });
  }

  @override
  void dispose() {
    _driverSub?.cancel();
    _rideUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    final provider = Provider.of<RideBookingProvider>(context, listen: false);
    
    try {
      final granted = await LocationService.requestPermission();
      if (!granted) {
        provider.setLoading(false);
        _showErrorSnackBar('Location permission required');
        return;
      }

      final loc = await LocationService.getCurrentLocation();
      if (loc != null) {
        provider.updateLocation(loc);
        provider.updatePrice();
      } else {
        provider.setLoading(false);
        _showErrorSnackBar('Unable to get location');
      }
    } catch (e) {
      provider.setLoading(false);
      _showErrorSnackBar('Error getting location: $e');
    }
  }

  void _subscribeToDrivers() {
    final provider = Provider.of<RideBookingProvider>(context, listen: false);
    
    _driverSub = _driverService.getAvailableDrivers().listen((drivers) {
      final newSet = drivers.map((d) => d.toMarker()).toSet();
      provider.updateDriverMarkers(newSet);
    });
  }

  void _moveToLocation(lat.LatLng location) {
    final provider = Provider.of<RideBookingProvider>(context, listen: false);
    provider.updateLocation(location);
    provider.updatePrice();
  }

  void _onPickupSelected(String name, lat.LatLng loc) {
    final provider = Provider.of<RideBookingProvider>(context, listen: false);
    provider.updatePickup(name, loc);
    _moveToLocation(loc);
  }

  void _onDestinationSelected(String name, lat.LatLng loc) {
    final provider = Provider.of<RideBookingProvider>(context, listen: false);
    provider.updateDestination(name, loc);
    _moveToLocation(loc);
  }

  void _onVehicleSelected(String vehicle) {
    final provider = Provider.of<RideBookingProvider>(context, listen: false);
    provider.updateVehicle(vehicle);
  }

  Future<void> _requestRide() async {
    final provider = Provider.of<RideBookingProvider>(context, listen: false);
    
    if (kIsWeb) {
      _showErrorSnackBar('Ride requests are disabled on web build. Please run on Android/iOS.');
      return;
    }

    if (provider.state.pickupLocation == null || provider.state.destination == null) {
      _showErrorSnackBar('Set pickup and destination');
      return;
    }

    try {
      provider.setLoading(true);

      final distance = provider.state._calculateDistance(
        provider.state.pickupLocation!,
        provider.state.destination!,
      );
      
      final latPickup = lat.LatLng(
        provider.state.pickupLocation!.latitude,
        provider.state.pickupLocation!.longitude,
      );
      final latDestination = lat.LatLng(
        provider.state.destination!.latitude,
        provider.state.destination!.longitude,
      );
      
      final rideId = await RideBookingService.createRideRequest(
        customerId: 'customer_demo_001',
        customerName: 'Demo Customer',
        customerPhone: '9876543210',
        pickupLocation: latPickup,
        pickupAddress: provider.state.pickupText.isNotEmpty 
            ? provider.state.pickupText 
            : 'Selected location',
        destinationLocation: latDestination,
        destinationAddress: provider.state.destinationText.isNotEmpty 
            ? provider.state.destinationText 
            : 'Selected destination',
        vehicleType: provider.state.selectedVehicle,
        estimatedFare: provider.state.estimatedPrice.toDouble(),
        distance: distance,
      );

      // Update state with ride ID
      final newState = provider.state.copyWith(currentRideId: rideId);
      provider.updateState(newState);

      _showSuccessSnackBar('Ride requested — waiting for drivers');
      _startRideStatusUpdates(rideId);
    } catch (e) {
      provider.setLoading(false);
      _showErrorSnackBar('Could not request ride: $e');
    }
  }

  void _startRideStatusUpdates(String rideId) {
    _rideUpdateTimer?.cancel();

    _rideUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final ride = RideBookingService.getRideById(rideId);
      if (ride != null) {
        final provider = Provider.of<RideBookingProvider>(context, listen: false);
        
        if (ride.status == RideStatus.accepted && ride.driverId != null) {
          provider.setDriverAssigned(DriverModel(
            id: ride.driverId!,



  void _showLocationSelector({required bool isPickup}) {
    final provider = Provider.of<RideBookingProvider>(context, listen: false);
    
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
            controller: TextEditingController(
              text: isPickup ? provider.state.pickupText : provider.state.destinationText,
            ),
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

  Widget _buildMap(RideBookingState state) {
    if (state.currentLocation == null) {
      return Container(
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final Set<Marker> allMarkers = {};
    allMarkers.addAll(state.driverMarkers);

    if (state.pickupLocation != null) {
      allMarkers.add(Marker(
        point: state.pickupLocation!,
        width: 30.0,
        height: 30.0,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.0),
          ),
          child: const Icon(Icons.my_location, size: 16, color: Colors.white),
        ),
      ));
    }

    if (state.destination != null) {
      allMarkers.add(Marker(
        point: state.destination!,
        width: 30.0,
        height: 30.0,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.0),
          ),
          child: const Icon(Icons.location_on, size: 16, color: Colors.white),
        ),
      ));
    }

    return SimpleMap(
      center: state.currentLocation ?? lat.LatLng(37.7749, -122.4194),
      zoom: 15.0,
      markers: allMarkers,
      onTap: (dest) {
        _onDestinationSelected('Selected Destination', dest);
      },
    );
  }

  Widget _buildNotificationBanner(RideBookingState state) {
    if (!state.showRideNotification || state.rideNotificationTitle == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 8,
      left: 0,
      right: 0,
      child: RideNotificationBanner(
        icon: Icons.local_taxi,
        title: state.rideNotificationTitle!,
        subtitle: state.rideNotificationSubtitle,
        onTap: () {
          if (state.assignedDriver?.location != null) {
            _moveToLocation(
              lat.LatLng(
                state.assignedDriver!.location.latitude,
                state.assignedDriver!.location.longitude,
              ),
            );
          } else if (state.pickupLocation != null) {
            _moveToLocation(state.pickupLocation!);
          }
          final provider = Provider.of<RideBookingProvider>(context, listen: false);
          provider.clearRideNotification();
        },
        onClose: () {
          final provider = Provider.of<RideBookingProvider>(context, listen: false);
          provider.clearRideNotification();
        },
      ),
    );
  }

  Widget _buildLocationSelectors(RideBookingState state) {
    return Material(
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
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.my_location, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.pickupText.isNotEmpty ? state.pickupText : 'Current location',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      state.destinationText.isNotEmpty 
                          ? state.destinationText 
                          : 'Where to?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: state.destinationText.isNotEmpty 
                            ? Theme.of(context).textTheme.bodyMedium?.color
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
    );
  }

  Widget _buildVehicleSelector(RideBookingState state) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 210,
      child: SizedBox(
        height: 120,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          scrollDirection: Axis.horizontal,
          itemCount: state.vehicleTypes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final vehicle = state.vehicleTypes[index];
            final fare = PricingService.calculateFare(
              vehicleType: vehicle,
              distanceKm: (state.pickupLocation != null && state.destination != null)
                  ? state._calculateDistance(state.pickupLocation!, state.destination!)
                  : 5.0,
              durationMin: 15,
            );
            return VehicleTile(
              vehicleType: vehicle,
              isSelected: state.selectedVehicle == vehicle,
              estimatedPrice: fare['total'] as int,
              onTap: () => _onVehicleSelected(vehicle),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingOverlay(RideBookingState state) {
    if (state.driverAssigned) {
      return Positioned(
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
                            state.assignedDriver!.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            state.assignedDriver!.vehicleType,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.call),
                      onPressed: () => _showSuccessSnackBar('Calling driver...'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      onPressed: () => _showSuccessSnackBar('Chat coming soon'),
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
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '₹${state.estimatedPrice}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        final provider = Provider.of<RideBookingProvider>(context, listen: false);
                        provider.setDriverAssigned(null);
                        provider.assignedDriver = null;
                        _showSuccessSnackBar('Booking cancelled');
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
                          if (state.assignedDriver?.location != null) {
                            _moveToLocation(
                              lat.LatLng(
                                state.assignedDriver!.location.latitude,
                                state.assignedDriver!.location.longitude,
                              ),
                            );
                            _showSuccessSnackBar('Centering on driver');
                          } else {
                            _showErrorSnackBar('Driver location not available');
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
      );
    }

    return BookingOverlay(
      pickupText: state.pickupText.isNotEmpty ? state.pickupText : 'Current location',
      destinationText: state.destinationText.isNotEmpty ? state.destinationText : 'Where to?',
      estimatedFare: '₹${state.estimatedPrice}',
      onPickupTap: _selectPickup,
      onDestinationTap: _selectDestination,
      onBookTap: _requestRide,
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      right: 16,
      bottom: 320,
      child: FloatingActionButton(
        heroTag: 'locFab',
        mini: true,
        onPressed: _initializeLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RideBookingProvider(),
      child: Consumer<RideBookingProvider>(
        builder: (context, provider, _) {
          final state = provider.state;
          
          return Scaffold(
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      _buildMap(state),
                      _buildNotificationBanner(state),
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
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.black.withOpacity(0.7),
                                            ),
                                          ),
                                          Text(
                                            'Where are you going?',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _showSuccessSnackBar('Notifications coming soon'),
                                      icon: const Icon(Icons.notifications_none, color: Colors.black87),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildLocationSelectors(state),
                                const SizedBox(height: 16),
                                _buildVehicleSelector(state),
                                _buildBookingOverlay(state),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!kIsWeb) _buildFloatingActionButton(),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
