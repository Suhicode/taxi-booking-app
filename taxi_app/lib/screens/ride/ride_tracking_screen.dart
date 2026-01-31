import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as lat;
import '../../services/backend_ride_service.dart';
import '../../services/socket_service.dart';
import '../../widgets/simple_map.dart';
import '../../models/ride_request_model.dart';

/// Screen for tracking an active ride
class RideTrackingScreen extends StatefulWidget {
  final String rideId;
  final RideRequestModel ride;
  
  const RideTrackingScreen({
    Key? key,
    required this.rideId,
    required this.ride,
  }) : super(key: key);
  
  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  final BackendRideService _rideService = BackendRideService();
  final SocketService _socketService = SocketService();
  
  lat.LatLng? _driverLocation;
  lat.LatLng? _customerLocation;
  String _rideStatus = 'accepted';
  StreamSubscription? _tripLocationSubscription;
  StreamSubscription? _rideStatusSubscription;
  Timer? _locationUpdateTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }
  
  Future<void> _initializeTracking() async {
    // Connect to socket if not connected
    if (!_socketService.isConnected) {
      await _socketService.connect();
    }
    
    // Subscribe to trip updates
    _socketService.subscribeToTrip(widget.rideId);
    
    // Listen to trip location updates
    _tripLocationSubscription = _socketService.tripLocationStream.listen((data) {
      if (mounted) {
        setState(() {
          _driverLocation = lat.LatLng(
            data['lat'] as double,
            data['lon'] as double,
          );
        });
      }
    });
    
    // Listen to ride status updates
    _rideStatusSubscription = _socketService.rideStartedStream.listen((data) {
      if (data['rideId'] == widget.rideId && mounted) {
        setState(() {
          _rideStatus = 'in_progress';
        });
      }
    });
    
    // Poll for ride status updates
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateRideStatus();
    });
    
    // Initial status fetch
    _updateRideStatus();
  }
  
  Future<void> _updateRideStatus() async {
    final response = await _rideService.getRideDetails(widget.rideId);
    if (response.success && response.data != null) {
      if (mounted) {
        setState(() {
          _rideStatus = response.data['status'] ?? 'accepted';
        });
      }
    }
  }
  
  @override
  void dispose() {
    _tripLocationSubscription?.cancel();
    _rideStatusSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Ride'),
        backgroundColor: Colors.amber,
      ),
      body: Stack(
        children: [
          // Map
          SimpleMap(
            initialLocation: widget.ride.pickupLocation.toLatLng(),
            markers: _buildMarkers(),
            onTap: null,
          ),
          
          // Status overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStatusCard(),
          ),
        ],
      ),
    );
  }
  
  Set<Marker> _buildMarkers() {
    final markers = <Marker>[];
    
    // Pickup marker
    markers.add(
      Marker(
        point: widget.ride.pickupLocation.toLatLng(),
        width: 40,
        height: 40,
        builder: (context) => const Icon(
          Icons.location_on,
          color: Colors.green,
          size: 40,
        ),
      ),
    );
    
    // Destination marker
    markers.add(
      Marker(
        point: widget.ride.destinationLocation.toLatLng(),
        width: 40,
        height: 40,
        builder: (context) => const Icon(
          Icons.location_on,
          color: Colors.red,
          size: 40,
        ),
      ),
    );
    
    // Driver marker (if location available)
    if (_driverLocation != null) {
      markers.add(
        Marker(
          point: _driverLocation!,
          width: 50,
          height: 50,
          builder: (context) => const Icon(
            Icons.directions_car,
            color: Colors.blue,
            size: 50,
          ),
        ),
      );
    }
    
    return markers;
  }
  
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '₹${widget.ride.estimatedFare.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Driver info
          if (widget.ride.driverName != null) ...[
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  widget.ride.driverName!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Pickup address
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.ride.pickupAddress,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Destination address
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.ride.destinationAddress,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          if (_rideStatus == 'accepted')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _cancelRide(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel Ride'),
              ),
            ),
        ],
      ),
    );
  }
  
  Color _getStatusColor() {
    switch (_rideStatus) {
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText() {
    switch (_rideStatus) {
      case 'accepted':
        return 'Driver Assigned';
      case 'in_progress':
        return 'Ride in Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }
  
  Future<void> _cancelRide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text('Are you sure you want to cancel this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final response = await _rideService.cancelRide(widget.rideId);
      if (response.success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride cancelled')),
        );
      }
    }
  }
}
