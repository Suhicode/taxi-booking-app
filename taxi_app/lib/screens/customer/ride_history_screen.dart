import 'package:flutter/material.dart';
import '../../services/backend_ride_service.dart';
import '../../services/api_client.dart';
import '../../models/ride_request_model.dart';
import '../ride/ride_tracking_screen.dart';

/// Screen showing customer's ride history
class RideHistoryScreen extends StatefulWidget {
  final String customerId;
  
  const RideHistoryScreen({
    Key? key,
    required this.customerId,
  }) : super(key: key);
  
  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  final BackendRideService _rideService = BackendRideService();
  List<RideRequestModel> _rides = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadRideHistory();
  }
  
  Future<void> _loadRideHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Note: This endpoint needs to be implemented in backend
      // For now, using local storage or mock data
      final response = await ApiClient.get('/rides/customer/${widget.customerId}');
      
      if (response.success) {
        // Parse rides from response
        // This is a placeholder - adjust based on your API response format
        setState(() {
          _rides = []; // Parse from response.data
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History'),
        backgroundColor: Colors.amber,
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRideHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No ride history',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your completed rides will appear here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadRideHistory,
      child: ListView.builder(
        itemCount: _rides.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final ride = _rides[index];
          return _buildRideCard(ride);
        },
      ),
    );
  }
  
  Widget _buildRideCard(RideRequestModel ride) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(ride.status),
          child: Icon(
            _getStatusIcon(ride.status),
            color: Colors.white,
          ),
        ),
        title: Text(
          '${ride.pickupAddress} → ${ride.destinationAddress}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${ride.vehicleType} • ${_formatDate(ride.createdAt)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (ride.driverName != null)
              Text(
                'Driver: ${ride.driverName}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${ride.estimatedFare.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              _getStatusText(ride.status),
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(ride.status),
              ),
            ),
          ],
        ),
        onTap: () => _showRideDetails(ride),
      ),
    );
  }
  
  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.completed:
        return Colors.green;
      case RideStatus.cancelled:
        return Colors.red;
      case RideStatus.inProgress:
        return Colors.orange;
      case RideStatus.accepted:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getStatusIcon(RideStatus status) {
    switch (status) {
      case RideStatus.completed:
        return Icons.check_circle;
      case RideStatus.cancelled:
        return Icons.cancel;
      case RideStatus.inProgress:
        return Icons.directions_car;
      case RideStatus.accepted:
        return Icons.person;
      default:
        return Icons.pending;
    }
  }
  
  String _getStatusText(RideStatus status) {
    return status.name.toUpperCase();
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  void _showRideDetails(RideRequestModel ride) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ride Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Pickup', ride.pickupAddress),
            _buildDetailRow('Destination', ride.destinationAddress),
            _buildDetailRow('Vehicle', ride.vehicleType),
            _buildDetailRow('Fare', '₹${ride.estimatedFare.toStringAsFixed(2)}'),
            _buildDetailRow('Status', _getStatusText(ride.status)),
            _buildDetailRow('Date', _formatDate(ride.createdAt)),
            if (ride.driverName != null)
              _buildDetailRow('Driver', ride.driverName!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
