import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/ride_provider.dart';
import '../models/location_model.dart';
import '../models/ride_state.dart';
import '../constants/app_constants.dart';
import '../widgets/location_search_widget.dart';
import '../widgets/vehicle_selection_widget.dart';
import '../widgets/fare_summary_widget.dart';
import '../widgets/ride_status_widget.dart';

class CustomerBookRideScreen extends StatefulWidget {
  const CustomerBookRideScreen({Key? key}) : super(key: key);

  @override
  State<CustomerBookRideScreen> createState() => _CustomerBookRideScreenState();
}

class _CustomerBookRideScreenState extends State<CustomerBookRideScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  Future<void> _initializeLocation() async {
    final rideProvider = Provider.of<RideProvider>(context, listen: false);
    await rideProvider.getCurrentLocation();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _pickupFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, rideProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              rideProvider.hasActiveRide ? 'Your Ride' : 'Book a Ride',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Stack(
            children: [
              // Map or ride status
              _buildMainContent(rideProvider),
              
              // Loading overlay
              if (rideProvider.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Error message
              if (rideProvider.errorMessage != null)
                Positioned(
                  top: 100,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rideProvider.errorMessage!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            rideProvider.clearError();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: rideProvider.hasActiveRide
              ? _buildActiveRideBottomBar(rideProvider)
              : _buildBookingBottomBar(rideProvider),
        );
      },
    );
  }

  Widget _buildMainContent(RideProvider rideProvider) {
    if (rideProvider.hasActiveRide) {
      return RideStatusWidget();
    } else {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: rideProvider.pickupLocation?.toLatLng() ?? 
                  const LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
          zoom: AppConstants.defaultZoom,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapType: MapType.normal,
        onMapCreated: (GoogleMapController controller) {
          // Map controller ready
        },
      );
    }
  }

  Widget _buildBookingBottomBar(RideProvider rideProvider) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
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
      child: Column(
        children: [
          // Location inputs
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Pickup location
                  LocationSearchWidget(
                    controller: _pickupController,
                    focusNode: _pickupFocusNode,
                    hintText: 'Enter pickup location',
                    icon: Icons.my_location,
                    onLocationSelected: (location) {
                      rideProvider.setPickupLocation(location);
                      _pickupController.text = location.address ?? location.name ?? '';
                    },
                    onClear: () {
                      rideProvider.setPickupLocation(null);
                      _pickupController.clear();
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Destination location
                  LocationSearchWidget(
                    controller: _destinationController,
                    focusNode: _destinationFocusNode,
                    hintText: 'Where to?',
                    icon: Icons.location_on,
                    onLocationSelected: (location) {
                      rideProvider.setDestinationLocation(location);
                      _destinationController.text = location.address ?? location.name ?? '';
                    },
                    onClear: () {
                      rideProvider.setDestinationLocation(null);
                      _destinationController.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Vehicle selection and fare
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Vehicle selection
                  Expanded(
                    flex: 1,
                    child: VehicleSelectionWidget(
                      selectedVehicleType: rideProvider.selectedVehicleType,
                      onVehicleSelected: (vehicleType) {
                        rideProvider.setSelectedVehicleType(vehicleType);
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Fare summary
                  Expanded(
                    flex: 1,
                    child: FareSummaryWidget(
                      fareData: rideProvider.calculateFare(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Book button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: rideProvider.canBookRide && !rideProvider.isLoading
                    ? () => _bookRide(rideProvider)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: rideProvider.canBookRide 
                      ? Colors.blue 
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  rideProvider.isLoading ? 'Booking...' : 'Book Ride',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRideBottomBar(RideProvider rideProvider) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    rideProvider.rideState.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (rideProvider.currentRide?.driverName != null)
                    Text(
                      'Driver: ${rideProvider.currentRide!.driverName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            if (rideProvider.rideState == RideState.driverAccepted)
              ElevatedButton(
                onPressed: () => rideProvider.startRide(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Start Ride'),
              ),
            if (rideProvider.rideState == RideState.rideStarted)
              ElevatedButton(
                onPressed: () => rideProvider.completeRide(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Complete Ride'),
              ),
            if (rideProvider.rideState == RideState.completed)
              ElevatedButton(
                onPressed: () => _showRatingDialog(rideProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Rate Ride'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _bookRide(RideProvider rideProvider) async {
    final success = await rideProvider.bookRide(
      customerId: 'customer_123',
      customerName: 'John Doe',
      customerPhone: '+1234567890',
    );
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to book ride. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRatingDialog(RideProvider rideProvider) async {
    int rating = 0;
    String feedback = '';
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Your Ride'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How was your ride?'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Leave feedback (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    feedback = value;
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await rideProvider.addRating(rating, feedback.isEmpty ? null : feedback);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
