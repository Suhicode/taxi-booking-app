# FareCalculator Service Usage Guide

## Overview
The `FareCalculator` service provides comprehensive, backend-style fare calculation logic that can be reused across multiple screens in your Flutter taxi booking application.

## Key Features

### 🚗 **Vehicle Type Support**
- **Bike**: Base ₹15, ₹8/km, ₹1/min (Min ₹25)
- **Auto**: Base ₹40, ₹12/km, ₹2/min (Min ₹60)
- **Scooty**: Base ₹20, ₹10/km, ₹1.5/min (Min ₹35)
- **Standard**: Base ₹50, ₹15/km, ₹2.5/min (Min ₹80)
- **Comfort**: Base ₹75, ₹20/km, ₹3.5/min (Min ₹120)
- **Premium**: Base ₹120, ₹25/km, ₹5/min (Min ₹180)
- **XL**: Base ₹150, ₹30/km, ₹6/min (Min ₹250)

### 💰 **Dynamic Pricing Logic**
- **Base Fare**: Maximum of (distance rate × distance) or (time rate × duration)
- **Minimum Fare**: Always enforced regardless of calculation
- **Zone Pricing**: Additional charges for specific areas (airport, downtown, etc.)
- **Surge Pricing**: Multipliers for peak hours, night time, bad weather, special events
- **Passenger Pricing**: ₹10 surcharge per additional passenger after first

### 📍 **Zone-Based Pricing**
- **Airport Zone**: +₹50 additional charge
- **Downtown Zone**: +₹20 additional charge
- **Highway Zone**: +₹15 additional charge
- **Night Zone**: +₹25 additional charge

### ⚡ **Surge Pricing Scenarios**
- **Peak Hours**: 7-10 AM, 5-8 PM (1.5x multiplier)
- **Night Time**: 9 PM - 6 AM (1.3x multiplier)
- **Bad Weather**: 1.2x multiplier (integrate with weather API)
- **Special Events**: 2.0x multiplier (concerts, festivals, etc.)

### 🎯 **Special Features**
- **Round Trip Discount**: 10% off for round trips
- **Multiple Passengers**: Support for group bookings
- **Auto Surge Detection**: Time-based surge calculation
- **Fare Validation**: Input validation for distance and duration limits

## Quick Usage Examples

### Basic Fare Calculation
```dart
import 'package:your_app/services/fare_calculator.dart';

// Simple fare calculation
final fare = FareCalculator.calculateFare(
  vehicleType: VehicleType.standard,
  distanceKm: 12.5,
  duration: Duration(minutes: 25),
);

print('Total fare: ₹${fare.totalFare.toStringAsFixed(2)}');
```

### Peak Hour Surge Pricing
```dart
// During peak hours (7-10 AM, 5-8 PM)
final peakFare = FareCalculator.calculateFare(
  vehicleType: VehicleType.auto,
  distanceKm: 8.0,
  duration: Duration(minutes: 20),
  isPeakHour: true, // 1.5x surge
  surgeMultiplier: 1.5,
);

print('Peak hour fare: ₹${peakFare.totalFare.toStringAsFixed(2)}');
```

### Airport Zone Pricing
```dart
// Airport pickup with additional zone charge
final airportFare = FareCalculator.calculateFare(
  vehicleType: VehicleType.premium,
  distanceKm: 25.0,
  duration: Duration(minutes: 35),
  zoneId: 'airport', // +₹50 zone charge
);

print('Airport fare: ₹${airportFare.totalFare.toStringAsFixed(2)}');
```

### Multiple Passengers
```dart
// 4 passengers in XL vehicle
final groupFare = FareCalculator.calculateFareForPassengers(
  vehicleType: VehicleType.xl,
  distanceKm: 15.0,
  duration: Duration(minutes: 30),
  passengerCount: 4, // +₹30 for 3 extra passengers
);

print('Group fare: ₹${groupFare.totalFare.toStringAsFixed(2)}');
```

### Round Trip Discount
```dart
// 10% discount for round trips
final roundTripFare = FareCalculator.calculateRoundTripFare(
  vehicleType: VehicleType.comfort,
  distanceKm: 20.0,
  duration: Duration(minutes: 40),
);

print('Round trip fare: ₹${roundTripFare.totalFare.toStringAsFixed(2)} (10% off)');
```

### Auto Surge Detection
```dart
// Automatically detects peak hours and night time
final autoFare = FareCalculator.calculateFareWithAutoSurge(
  vehicleType: VehicleType.standard,
  distanceKm: 10.0,
  duration: Duration(minutes: 15),
  rideTime: DateTime.now(), // Current time
);

print('Auto-detected fare: ₹${autoFare.totalFare.toStringAsFixed(2)}');
```

## Integration Steps

### 1. Update Your Pricing Service
Replace your current pricing logic with `FareCalculator`:

```dart
// Before
import '../services/pricing_service.dart';

// After
import '../services/fare_calculator.dart';

// Replace pricing calculations
final fare = FareCalculator.calculateFare(
  vehicleType: VehicleType.standard,
  distanceKm: distance,
  duration: duration,
);
```

### 2. Update Vehicle Selection
Use the new `VehicleType` enum:

```dart
// Vehicle selection dropdown
List<VehicleType> vehicleTypes = FareCalculator.getSupportedVehicleTypes();

// Convert to string for display
String vehicleDisplayName = vehicleType.name.toUpperCase();
```

### 3. Update Ride Booking Logic
Enhance your ride booking with dynamic pricing:

```dart
class RideBookingService {
  Future<void> bookRide({
    required VehicleType vehicleType,
    required double distanceKm,
    required Duration estimatedDuration,
    String? zoneId,
    int passengerCount = 1,
  }) async {
    // Calculate fare with current conditions
    final fare = FareCalculator.calculateFareWithAutoSurge(
      vehicleType: vehicleType,
      distanceKm: distanceKm,
      duration: estimatedDuration,
      zoneId: zoneId,
      rideTime: DateTime.now(),
    );
    
    // Create booking with calculated fare
    final booking = RideBooking(
      fare: fare.totalFare,
      vehicleType: vehicleType,
      // ... other booking details
    );
    
    await saveBooking(booking);
  }
}
```

### 4. Update UI Components
Display detailed fare breakdowns to users:

```dart
// Fare breakdown display
Column(
  children: [
    Text('Total: ${fare.currency}${fare.totalFare.toStringAsFixed(2)}'),
    if (fare.surgeMultiplier > 1.0)
      Text('Surge: ${(fare.surgeMultiplier * 100).toStringAsFixed(0)}%'),
    Text('Distance: ${fare.distance.toStringAsFixed(2)} km'),
    Text('Duration: ${fare.estimatedDuration.inMinutes} min'),
  ],
)
```

## Advanced Features

### Custom Pricing Configuration
```dart
// Add custom vehicle pricing
final customPricing = VehiclePricing(
  baseRate: 60.0,
  perKmRate: 18.0,
  perMinuteRate: 4.0,
  minimumFare: 100.0,
  capacity: 4,
);

// Use in fare calculation
final customFare = FareCalculator.calculateFare(
  vehicleType: VehicleType.standard,
  distanceKm: 15.0,
  duration: Duration(minutes: 25),
  // Override default pricing
  // You would need to extend FareCalculator to support custom pricing
);
```

### Fare Validation
```dart
// Validate inputs before calculation
if (!FareCalculator.isValidDistance(distanceKm)) {
  throw FareCalculationException('Invalid distance: $distanceKm km');
}

if (!FareCalculator.isValidDuration(duration)) {
  throw FareCalculationException('Invalid duration: ${duration.inMinutes} minutes');
}
```

### Error Handling
```dart
try {
  final fare = FareCalculator.calculateFare(
    vehicleType: VehicleType.standard,
    distanceKm: distance,
    duration: duration,
  );
  
  // Use fare result
  totalCost = fare.totalFare;
} on FareCalculationException catch (e) {
  // Handle fare calculation errors
  showErrorDialog('Fare calculation failed: ${e.message}');
  
  // Fallback to default pricing
  return defaultFare;
}
```

## Production Considerations

### Performance
- Cache frequently used fare calculations
- Pre-calculate zone charges for common areas
- Use efficient algorithms for surge calculations
- Implement fare estimation for quick quotes

### Testing
```dart
// Test all vehicle types
for (final vehicleType in FareCalculator.getSupportedVehicleTypes()) {
  final fare = FareCalculator.calculateFare(
    vehicleType: vehicleType,
    distanceKm: 10.0,
    duration: Duration(minutes: 15),
  );
  
  print('${vehicleType.name}: ₹${fare.totalFare.toStringAsFixed(2)}');
}

// Test surge scenarios
final testFares = FareCalculator.getFareEstimates(
  vehicleType: VehicleType.standard,
  distanceKm: 10.0,
  duration: Duration(minutes: 20),
);

print('Standard: ₹${testFares['standard']!.totalFare}');
print('Peak Hour: ₹${testFares['peak_hour']!.totalFare}');
print('Night: ₹${testFares['night']!.totalFare}');
```

### Monitoring
```dart
// Log fare calculations for debugging
class FareLogger {
  static void logCalculation({
    required VehicleType vehicleType,
    required double distanceKm,
    required Duration duration,
    required double fare,
    double? surgeMultiplier,
    String? zoneId,
  }) {
    final logEntry = '''
Fare Calculation:
  Vehicle: ${vehicleType.name}
  Distance: ${distanceKm.toStringAsFixed(2)} km
  Duration: ${duration.inMinutes} min
  Base Fare: ₹${FareCalculator.getVehiclePricing(vehicleType).baseRate}
  Total Fare: ₹${fare.toStringAsFixed(2)}
  Surge: ${surgeMultiplier != null ? '${(surgeMultiplier! * 100).toStringAsFixed(0)}%' : 'None'}
  Zone: ${zoneId ?? 'None'}
  Timestamp: ${DateTime.now().toIso8601String()}
    ''';
    
    // Log to console, file, or analytics service
    print(logEntry);
    
    // Send to analytics
    AnalyticsService.logFareCalculation({
      'vehicle_type': vehicleType.name,
      'distance_km': distanceKm,
      'duration_minutes': duration.inMinutes,
      'fare_amount': fare,
      'surge_multiplier': surgeMultiplier,
      'zone_id': zoneId,
    });
  }
}
```

## Migration from Existing Pricing

### From PricingService
```dart
// Old approach
final fare = PricingService.calculateFare(
  vehicleType: 'Standard',
  distanceKm: distance,
  durationMin: duration.inMinutes,
);

// New approach
final fare = FareCalculator.calculateFare(
  vehicleType: VehicleType.standard,
  distanceKm: distance,
  duration: duration,
);
```

### Benefits of Migration

1. **Type Safety**: Compile-time checking of vehicle types
2. **Extensibility**: Easy to add new vehicle types and pricing rules
3. **Consistency**: Same pricing logic across all screens
4. **Testing**: Comprehensive test coverage with fare scenarios
5. **Maintenance**: Centralized pricing configuration

## Best Practices

### DO ✅
- Use `FareCalculator.calculateFareWithAutoSurge()` for automatic surge detection
- Validate inputs using `isValidDistance()` and `isValidDuration()`
- Handle `FareCalculationException` for proper error reporting
- Log fare calculations for debugging and analytics
- Cache fare results for performance

### DON'T ❌
- Don't hardcode pricing logic in UI components
- Don't ignore surge multipliers in calculations
- Don't skip input validation
- Don't mix up currency symbols (use the service constant)

## Troubleshooting

### Common Issues

**Incorrect fare amounts:**
- Check vehicle type enum values match pricing configuration
- Verify distance and duration units (km vs miles)
- Ensure surge multipliers are applied correctly

**Missing surge pricing:**
- Verify `isPeakHour`, `isNightTime` parameters
- Check current time zone for auto-detection
- Confirm surge multiplier is being applied

**Zone charges not applied:**
- Verify `zoneId` parameter is passed correctly
- Check zone configuration in `_zonePricing`
- Ensure zone lookup logic is working

**Performance issues:**
- Cache fare calculations for repeated routes
- Avoid complex calculations in UI thread
- Use efficient algorithms for surge detection

This comprehensive fare calculator service provides enterprise-grade pricing logic that's easy to integrate, test, and maintain across your Flutter taxi application.
