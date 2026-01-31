import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/passenger_provider.dart';

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
  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final passengerProvider = Provider.of<PassengerProvider>(context, listen: false);
    await passengerProvider.getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PassengerProvider>(
      builder: (context, passengerProvider, child) {
        final currentPosition = passengerProvider.currentPosition;
        
        return Stack(
          children: [
            // Map placeholder
            Container(
              color: Colors.grey.shade200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.map,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Map View',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Interactive map will be restored here',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    if (currentPosition != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Current Location:\n${currentPosition!.latitude.toStringAsFixed(6)}, ${currentPosition.longitude.toStringAsFixed(6)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Floating action buttons for demo
            Positioned(
              bottom: 100,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: "book_ride",
                    onPressed: () {
                      if (widget.onRideRequested != null) {
                        widget.onRideRequested!({
                          'pickup_lat': currentPosition?.latitude ?? 13.0827,
                          'pickup_lng': currentPosition?.longitude ?? 80.2707,
                          'drop_lat': 13.0827,
                          'drop_lng': 80.2807,
                          'pickup_address': 'Current Location',
                          'drop_address': 'Demo Destination',
                        });
                      }
                    },
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.directions_car),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: "center_location",
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Centering on current location')),
                      );
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }
}
