import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/nearby_drivers_widget.dart';
import '../services/nearby_drivers_service.dart';
import '../services/driver_service_mock.dart';
import '../services/location_service.dart';

class CustomerBookRideSimplePage extends StatefulWidget {
  const CustomerBookRideSimplePage({Key? key}) : super(key: key);

  @override
  State<CustomerBookRideSimplePage> createState() => _CustomerBookRideSimplePageState();
}

class _CustomerBookRideSimplePageState extends State<CustomerBookRideSimplePage> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  String _selectedVehicle = 'Standard';
  double _estimatedPrice = 15.50;
  int _estimatedTime = 12;
  LatLng? _customerLocation;
  bool _isLoadingLocation = false;

  final List<String> _vehicleTypes = ['Standard', 'Comfort', 'Premium', 'XL'];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final location = await LocationService.getCurrentLocation();
      if (location != null && mounted) {
        setState(() {
          _customerLocation = location;
          _isLoadingLocation = false;
        });
        
        // Set pickup location to current location
        _pickupController.text = 'Current Location';
      } else if (mounted) {
        setState(() {
          _customerLocation = const LatLng(13.0827, 80.2707); // Default to Chennai
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _customerLocation = const LatLng(13.0827, 80.2707); // Default to Chennai
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _calculateEstimate() {
    if (_pickupController.text.isNotEmpty && _destinationController.text.isNotEmpty) {
      setState(() {
        // Simulate price calculation based on vehicle type
        final basePrice = 15.50;
        switch (_selectedVehicle) {
          case 'Comfort':
            _estimatedPrice = basePrice * 1.3;
            break;
          case 'Premium':
            _estimatedPrice = basePrice * 1.6;
            break;
          case 'XL':
            _estimatedPrice = basePrice * 2.0;
            break;
          default:
            _estimatedPrice = basePrice;
        }
        _estimatedTime = 12 + (15 * (_vehicleTypes.indexOf(_selectedVehicle) ~/ 2));
      });
    }
  }

  void _bookRide() {
    if (_pickupController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter pickup and destination'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show booking confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${_pickupController.text}'),
            Text('To: ${_destinationController.text}'),
            Text('Vehicle: $_selectedVehicle'),
            Text('Estimated Price: \$${_estimatedPrice.toStringAsFixed(2)}'),
            Text('Estimated Time: $_estimatedTime mins'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ride booked successfully! Driver is on the way.'),
                  backgroundColor: Colors.green,
                ),
              );
              // Navigate to ride tracking page (could be implemented)
            },
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }

  void _onDriverSelected(DriverModel driver) {
    final nearbyDriversService = NearbyDriversService();
    final distance = nearbyDriversService.getDistanceToDriver(_customerLocation!, driver.location);
    final distanceText = nearbyDriversService.formatDistance(distance);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(driver.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle: ${driver.vehicleType}'),
            Text('Distance: $distanceText'),
            Text('Status: ${driver.status.toUpperCase()}'),
            const SizedBox(height: 8),
            const Text(
              'Would you like to book a ride with this driver?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${driver.name} assigned to your ride!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Book Driver'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Map View', style: TextStyle(color: Colors.grey)),
                        Text('Enter locations to see route', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (_isLoadingLocation)
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nearby Drivers Section
            if (_customerLocation != null)
              NearbyDriversWidget(
                customerLocation: _customerLocation!,
                selectedVehicleType: _selectedVehicle,
                onDriverSelected: _onDriverSelected,
              ),
            const SizedBox(height: 16),

            // Location Inputs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _pickupController,
                      label: 'Pickup Location',
                      hint: 'Enter pickup location',
                      prefixIcon: const Icon(Icons.location_on),
                      onChanged: (value) => _calculateEstimate(),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _destinationController,
                      label: 'Destination',
                      hint: 'Where to?',
                      prefixIcon: const Icon(Icons.flag),
                      onChanged: (value) => _calculateEstimate(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Vehicle Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Vehicle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._vehicleTypes.map((vehicle) {
                      return RadioListTile<String>(
                        title: Text(vehicle),
                        subtitle: Text(_getVehicleDescription(vehicle)),
                        secondary: Text('\$${_getVehiclePrice(vehicle).toStringAsFixed(2)}'),
                        value: vehicle,
                        groupValue: _selectedVehicle,
                        onChanged: (value) {
                          setState(() {
                            _selectedVehicle = value!;
                          });
                          _calculateEstimate();
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ride Estimate
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estimated Price',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${_estimatedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Estimated Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$_estimatedTime mins',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Book Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _bookRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Book Ride',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVehicleDescription(String vehicle) {
    switch (vehicle) {
      case 'Standard':
        return '4 seats, Affordable';
      case 'Comfort':
        return '4 seats, Comfortable';
      case 'Premium':
        return '4 seats, Luxury';
      case 'XL':
        return '6 seats, Spacious';
      default:
        return '';
    }
  }

  double _getVehiclePrice(String vehicle) {
    switch (vehicle) {
      case 'Standard':
        return 15.50;
      case 'Comfort':
        return 20.15;
      case 'Premium':
        return 24.80;
      case 'XL':
        return 31.00;
      default:
        return 15.50;
    }
  }
}
