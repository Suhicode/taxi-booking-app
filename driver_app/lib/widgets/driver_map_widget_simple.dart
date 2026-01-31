import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';

class DriverMapWidgetSimple extends StatefulWidget {
  const DriverMapWidgetSimple({super.key});

  @override
  State<DriverMapWidgetSimple> createState() => _DriverMapWidgetSimpleState();
}

class _DriverMapWidgetSimpleState extends State<DriverMapWidgetSimple> {
  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, driverProvider, child) {
        final currentPosition = driverProvider.currentPosition;
        final isOnline = driverProvider.isOnline;
        
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
                      'Driver Map View',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${isOnline ? "Online" : "Offline"}',
                      style: TextStyle(
                        fontSize: 16,
                        color: isOnline ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (currentPosition != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Current Location:\n${currentPosition.latitude.toStringAsFixed(6)}, ${currentPosition.longitude.toStringAsFixed(6)}',
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
            
            // Floating action buttons
            Positioned(
              bottom: 100,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton(
                    heroTag: "toggle_status",
                    onPressed: () {
                      driverProvider.toggleOnlineStatus();
                    },
                    backgroundColor: isOnline ? Colors.red : Colors.green,
                    child: Icon(isOnline ? Icons.offline_bolt : Icons.online_prediction),
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
