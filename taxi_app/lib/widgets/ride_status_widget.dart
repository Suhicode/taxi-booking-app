import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';
import '../models/ride_state.dart';

class RideStatusWidget extends StatelessWidget {
  const RideStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, rideProvider, child) {
        final ride = rideProvider.currentRide;
        if (ride == null) {
          return const Center(
            child: Text(
              'No active ride',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Ride status header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getStatusColor(rideProvider.rideState),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(rideProvider.rideState),
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rideProvider.rideState.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Driver info (if accepted)
              if (ride.driverName != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Driver avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.blue.shade600,
                          size: 30,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Driver details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.driverName ?? 'Driver',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (ride.driverVehicleNumber != null)
                              Text(
                                '${ride.driverVehicleType} • ${ride.driverVehicleNumber}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            if (ride.driverPhone != null)
                              Text(
                                ride.driverPhone!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Call button
                      if (rideProvider.rideState == RideState.driverAccepted)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.call, color: Colors.white),
                            onPressed: () {
                              // In a real app, this would open the phone dialer
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Calling driver...'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
              
              // Ride details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ride Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildDetailRow(
                      'Pickup',
                      ride.pickupAddress,
                      Icons.location_on,
                      Colors.green,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    _buildDetailRow(
                      'Destination',
                      ride.destinationAddress,
                      Icons.flag,
                      Colors.red,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    _buildDetailRow(
                      'Fare',
                      '₹${ride.estimatedFare.toInt()}',
                      Icons.attach_money,
                      Colors.blue,
                    ),
                    
                    if (ride.distance > 0) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Distance',
                        '${ride.distance.toStringAsFixed(1)} km',
                        Icons.straighten,
                        Colors.grey,
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons based on state
              _buildActionButtons(context, rideProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, RideProvider rideProvider) {
    switch (rideProvider.rideState) {
      case RideState.driverAccepted:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showCancelDialog(context, rideProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cancel Ride'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => rideProvider.startRide(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Start Ride'),
              ),
            ),
          ],
        );
        
      case RideState.rideStarted:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => rideProvider.completeRide(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete Ride'),
          ),
        );
        
      case RideState.completed:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showRatingDialog(context, rideProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rate Driver'),
          ),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(RideState state) {
    switch (state) {
      case RideState.searching:
        return Colors.orange;
      case RideState.driverAccepted:
        return Colors.blue;
      case RideState.rideStarted:
        return Colors.green;
      case RideState.completed:
        return Colors.purple;
      case RideState.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(RideState state) {
    switch (state) {
      case RideState.searching:
        return Icons.search;
      case RideState.driverAccepted:
        return Icons.person;
      case RideState.rideStarted:
        return Icons.directions_car;
      case RideState.completed:
        return Icons.check_circle;
      case RideState.cancelled:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  void _showCancelDialog(BuildContext context, RideProvider rideProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text('Are you sure you want to cancel this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              rideProvider.cancelRide();
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, RideProvider rideProvider) {
    int rating = 0;
    String feedback = '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Rate Your Ride'),
            content: Column(
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await rideProvider.addRating(rating, feedback.isEmpty ? null : feedback);
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }
}
