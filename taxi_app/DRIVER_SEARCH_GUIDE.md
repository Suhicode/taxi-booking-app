# Driver Search Service Usage Guide

## Overview
The `DriverSearchService` provides comprehensive, real-time driver search and location tracking capabilities for your Flutter taxi application with Firebase integration.

## Key Features

### 🚗 **Real-Time Driver Search**
- **Location-based Search**: Find nearest drivers within specified radius
- **Vehicle Type Filtering**: Search by vehicle type (Bike, Auto, Standard, etc.)
- **Availability Filtering**: Only show available drivers
- **Distance Calculation**: Accurate Haversine formula for distance calculation
- **ETA Estimation**: Real-time estimated arrival times based on distance and traffic

### 📍 **Location Tracking**
- **Real-Time Updates**: Live driver location tracking with Firebase
- **Automatic Updates**: Periodic location updates every 5 seconds
- **Geofencing Integration**: Uses device GPS for accurate positioning
- **Location History**: Stores historical location data for analytics

### 🔥 **Driver Management**
- **Availability Control**: Drivers can set themselves as available/unavailable
- **Rating System**: Post-ride rating updates
- **Statistics Tracking**: Total rides, earnings, average ratings
- **Profile Management**: Driver profiles with vehicle and contact info

### 📊 **Search & Assignment Logic**
- **Proximity-Based**: Assign nearest available driver to ride requests
- **Timeout Handling**: Configurable search timeouts
- **Multiple Results**: Support for multiple driver options
- **Filter Options**: By rating, vehicle type, and availability status

### 🔥 **Firebase Integration**
- **Real-Time Database**: Firestore for driver data storage
- **Offline Support**: Local caching for poor connectivity
- **Data Synchronization**: Consistent state across all clients
- **Security**: Role-based access control for driver data

## Quick Usage Examples

### Basic Driver Search
```dart
import 'package:your_app/services/driver_search_service.dart';

// Search for nearby drivers
final results = await DriverSearchService.searchNearbyDrivers(
  center: pickupLocation,
  vehicleType: VehicleType.standard,
  radiusKm: 5.0,
);

// Display results
ListView.builder(
  itemCount: results.length,
  itemBuilder: (context, index) {
    final result = results[index];
    return DriverCard(
      driver: result.driver,
      distance: result.formattedDistance,
      time: result.formattedTime,
      onTap: () => assignDriver(result.driver),
    );
  },
)
```

### Real-Time Location Tracking
```dart
import 'package:your_app/services/driver_search_service.dart';

// Start tracking driver location
await DriverLocationTracker.startTracking(driverId);

// Listen to location updates
StreamBuilder(
  stream: DriverSearchService.getDriverLocationStream(),
  builder: (context, snapshot) {
    return DriverMapWidget(
      drivers: snapshot.data,
      currentDriverId: DriverLocationTracker.currentDriverId,
    );
  },
)
```

### Driver Assignment
```dart
// Get nearest available drivers for immediate assignment
final availableDrivers = await DriverSearchService.getNearbyAvailableDrivers(
  pickupLocation: rideRequest.pickupLocation,
  vehicleType: rideRequest.vehicleType,
);

// Assign closest driver
if (availableDrivers.isNotEmpty) {
  final closestDriver = availableDrivers.first;
  await assignDriverToRide(rideRequest.id, closestDriver.id);
}
```

### Driver Statistics
```dart
// Get driver performance metrics
final stats = await DriverSearchService.getDriverStatistics(driverId);

print('Total Rides: ${stats['totalRides']}');
print('Average Rating: ${stats['averageRating']}');
print('Total Earnings: ₹${stats['totalEarnings']}');
```

## Integration Steps

### 1. Update Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  cloud_firestore: ^4.17.5
  geolocator: ^10.1.0
```

### 2. Firebase Setup
1. Enable Firestore in Firebase Console
2. Configure security rules for driver data access
3. Set up indexes for performance optimization

### 3. Replace Driver Service
Update your existing driver service calls:

```dart
// Before
final drivers = await DriverServiceMock.getAvailableDrivers();

// After
final drivers = await DriverSearchService.searchNearbyDrivers(
  center: center,
  vehicleType: vehicleType,
);
```

### 4. Update UI Components
Replace static driver lists with real-time streams:

```dart
// Old approach
List<DriverModel> drivers = [];

// New approach
StreamBuilder(
  stream: DriverSearchService.getDriverLocationStream(),
  builder: (context, snapshot) {
    return DriverListView(drivers: snapshot.data);
  },
)
```

### 5. Add Location Tracking
Implement real-time driver location tracking:

```dart
class DriverTrackingWidget extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: DriverSearchService.getDriverLocationStream(),
      builder: (context, snapshot) {
        return GoogleMap(
          drivers: snapshot.data,
          showDriverLocations: true,
        );
      },
    );
  }
}
```

## Advanced Features

### WebSocket Integration (Production)
For production-scale real-time updates:

```dart
class RealTimeDriverService {
  static final WebSocketChannel _channel = WebSocketChannel.connect('ws://your-server.com/drivers');
  
  static Stream<List<DriverLocation>> getRealTimeLocations() {
    return _channel.stream.map((data) {
      return DriverLocation.fromJson(json.decode(data));
    });
  }
}
```

### Performance Optimization

### Caching Strategy
```dart
class DriverSearchCache {
  static final Map<String, List<DriverSearchResult>> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  static Future<List<DriverSearchResult>> getCachedResults(String key) async {
    if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheExpiry) {
        return cached.results;
      }
    }
    
    // Fetch fresh data
    final results = await DriverSearchService.searchNearbyDrivers(/*...*/);
    _cache[key] = CachedResults(results, DateTime.now());
    return results;
  }
}
```

### Error Handling

### Network Issues
```dart
try {
  final results = await DriverSearchService.searchNearbyDrivers(
    timeout: Duration(seconds: 10), // Shorter timeout for poor networks
  );
} on SocketException catch (e) {
  // Fallback to cached results
  return DriverSearchService.getCachedResults('fallback');
} on TimeoutException catch (e) {
  // Show user-friendly error message
  showErrorSnackBar('Search timed out. Using cached results.');
}
```

### Testing

### Unit Tests
```dart
void main() {
  test('Driver search functionality', () async {
    // Test distance calculation
    final distance = DriverSearchService._calculateDistance(0, 0, 40.7128, -73.9444);
    assert(distance > 0);
    
    // Test search functionality
    final results = await DriverSearchService.searchNearbyDrivers(
      center: lat.LatLng(40.7128, -73.9444),
      vehicleType: VehicleType.standard,
    );
    
    assert(results.isNotEmpty);
    assert(results.first.distanceKm > 0);
  });
}
```

### Monitoring

### Analytics Integration
```dart
class DriverSearchAnalytics {
  static void logSearch({
    required String query,
    required VehicleType vehicleType,
    required int resultCount,
    required Duration searchTime,
  }) {
    AnalyticsService.logEvent('driver_search', {
      'query': query,
      'vehicle_type': vehicleType.name,
      'result_count': resultCount,
      'search_time_ms': searchTime.inMilliseconds,
    });
  }
}
```

## Production Considerations

### Scalability
- **Database Indexing**: Add composite indexes for location queries
- **Load Balancing**: Implement driver load balancing for search requests
- **Caching Strategy**: Redis for frequently accessed driver data
- **Rate Limiting**: Implement API rate limiting for search requests

### Security
- **Data Validation**: Validate all location data before storage
- **Access Control**: Implement role-based access to driver information
- **Encryption**: Sensitive data (phone, location) should be encrypted

### Performance
- **Lazy Loading**: Load driver data on-demand rather than all at once
- **Pagination**: Implement pagination for large driver datasets
- **Background Processing**: Move heavy calculations to background isolates

## Troubleshooting

### Common Issues

**No Drivers Found:**
- Check Firebase security rules
- Verify location data exists in database
- Confirm search radius isn't too small

**Location Updates Not Working:**
- Check Firebase permissions
- Verify geolocator permissions
- Confirm WebSocket connection for real-time updates

**Performance Issues:**
- Monitor database query performance
- Check for N+1 queries that need optimization
- Implement proper indexing for location-based searches

**Memory Leaks:**
- Ensure stream subscriptions are properly disposed
- Check for unclosed database connections
- Monitor timer cancellations in location tracking

This comprehensive driver search system provides enterprise-grade real-time capabilities that will significantly enhance your taxi booking application with proper driver management, location tracking, and scalability for production deployment.
