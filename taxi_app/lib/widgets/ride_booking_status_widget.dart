import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ride_booking_api_service.dart';

class RideStatusPoller {
  static StreamSubscription<RideStatusResponse>? _subscription;

  static void startPolling(
    String rideId, 
    {
    Duration interval = const Duration(seconds: 3),
    required Function(RideStatusResponse) onStatusUpdate,
    required Function(Driver) onDriverAccepted,
    required Function(String) onError,
  }) {
    _subscription?.cancel();
    
    _subscription = RideBookingApiService.pollRideStatus(rideId, interval: interval)
        .listen(
          (status) {
            onStatusUpdate(status);
            if (status.status == 'accepted' && status.driver != null) {
              onDriverAccepted(status.driver!);
              _subscription?.cancel();
            }
          },
          onError: (error) {
            onError(error.toString());
            _subscription?.cancel();
          },
        );
  }

  static void stopPolling() {
    _subscription?.cancel();
    _subscription = null;
  }
}

class RideStatusWidget extends StatefulWidget {
  final String rideId;
  final VoidCallback? onCancel;

  const RideStatusWidget({
    Key? key,
    required this.rideId,
    this.onCancel,
  }) : super(key: key);

  @override
  State<RideStatusWidget> createState() => _RideStatusWidgetState();
}

class _RideStatusWidgetState extends State<RideStatusWidget> {
  RideStatusResponse? _currentStatus;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    RideStatusPoller.stopPolling();
    super.dispose();
  }

  void _startPolling() {
    RideStatusPoller.startPolling(
      widget.rideId,
      onStatusUpdate: (status) {
        setState(() {
          _currentStatus = status;
          _isLoading = false;
          _error = null;
        });
      },
      onDriverAccepted: (driver) {
        setState(() {
          _currentStatus = RideStatusResponse(
            rideId: _currentStatus!.rideId,
            status: 'accepted',
            driver: driver,
            message: 'Driver accepted your ride',
          );
        });
      },
      onError: (error) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Searching for drivers...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Error', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(_error!),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _startPolling();
                    },
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 8),
                  if (widget.onCancel != null)
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_currentStatus == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No status information available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(_currentStatus!.status),
                  color: _getStatusColor(_currentStatus!.status),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(_currentStatus!.status),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_currentStatus!.status == 'searching' || _currentStatus!.status == 'pending')
              Column(
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('Finding nearby drivers...'),
                  const SizedBox(height: 12),
                  if (widget.onCancel != null)
                    OutlinedButton(
                      onPressed: widget.onCancel,
                      child: const Text('Cancel Ride'),
                    ),
                ],
              ),
            
            if (_currentStatus!.driver != null)
              DriverDetailsCard(driver: _currentStatus!.driver!),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'searching':
      case 'pending':
        return Icons.search;
      case 'accepted':
        return Icons.check_circle;
      case 'started':
        return Icons.directions_car;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'searching':
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'started':
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'searching':
        return 'Searching for drivers';
      case 'pending':
        return 'Waiting for driver acceptance';
      case 'accepted':
        return 'Driver accepted your ride';
      case 'started':
        return 'Ride in progress';
      case 'completed':
        return 'Ride completed';
      default:
        return 'Unknown status';
    }
  }
}

class DriverDetailsCard extends StatelessWidget {
  final Driver driver;

  const DriverDetailsCard({
    Key? key,
    required this.driver,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade300,
                child: driver.profileImage != null
                    ? null
                    : const Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < driver.rating.floor()
                                ? Icons.star
                                : index < driver.rating
                                    ? Icons.star_half
                                    : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          driver.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      // Call driver
                    },
                    icon: const Icon(Icons.phone, color: Colors.green),
                  ),
                  IconButton(
                    onPressed: () {
                      // Message driver
                    },
                    icon: const Icon(Icons.message, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.directions_car, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                '${driver.vehicleModel} • ${driver.vehicleNumber}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
