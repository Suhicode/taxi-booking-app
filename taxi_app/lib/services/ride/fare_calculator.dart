// lib/services/fare_calculator.dart
import 'dart:math' as math;

/// Vehicle types supported by the taxi service
enum VehicleType {
  bike,
  auto,
  scooty,
  standard,
  comfort,
  premium,
  xl,
}

/// Fare calculation result with all pricing details
class FareResult {
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double surgeMultiplier;
  final double totalFare;
  final double distance;
  final Duration estimatedDuration;
  final VehicleType vehicleType;
  final String currency;

  const FareResult({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.surgeMultiplier,
    required this.totalFare,
    required this.distance,
    required this.estimatedDuration,
    required this.vehicleType,
    this.currency = '₹',
  });

  /// Get fare breakdown as a formatted string
  String get fareBreakdown {
    return '''
Base Fare: ${currency}${baseFare.toStringAsFixed(2)}
Distance Fare: ${currency}${distanceFare.toStringAsFixed(2)}
Time Fare: ${currency}${timeFare.toStringAsFixed(2)}
Surge: ${surgeMultiplier > 1.0 ? '${(surgeMultiplier * 100).toStringAsFixed(0)}%' : 'None'}
Total: ${currency}${totalFare.toStringAsFixed(2)}
Distance: ${distance.toStringAsFixed(2)} km
Duration: ${estimatedDuration.inMinutes} min
Vehicle: ${vehicleType.name.toUpperCase()}
    ''';
  }
}

/// Pricing configuration for different vehicle types
class VehiclePricing {
  final double baseRate;
  final double perKmRate;
  final double perMinuteRate;
  final double minimumFare;
  final int capacity;

  const VehiclePricing({
    required this.baseRate,
    required this.perKmRate,
    required this.perMinuteRate,
    required this.minimumFare,
    required this.capacity,
  });
}

/// Surge pricing based on demand and time
class SurgePricing {
  final double peakHourMultiplier;
  final double nightMultiplier;
  final double weatherMultiplier;
  final double eventMultiplier;

  const SurgePricing({
    this.peakHourMultiplier = 1.5,
    this.nightMultiplier = 1.3,
    this.weatherMultiplier = 1.2,
    this.eventMultiplier = 2.0,
  });

/// Zone-based pricing for different areas
class ZonePricing {
  final String zoneId;
  final String zoneName;
  final double additionalCharge;

  const ZonePricing({
    required this.zoneId,
    required this.zoneName,
    required this.additionalCharge,
  });
}

/// Comprehensive fare calculator service
class FareCalculator {
  static const String _currency = '₹';
  
  // Vehicle pricing configuration
  static const Map<VehicleType, VehiclePricing> _vehiclePricing = {
    VehicleType.bike: VehiclePricing(
      baseRate: 15.0,
      perKmRate: 8.0,
      perMinuteRate: 1.0,
      minimumFare: 25.0,
      capacity: 1,
    ),
    VehicleType.auto: VehiclePricing(
      baseRate: 40.0,
      perKmRate: 12.0,
      perMinuteRate: 2.0,
      minimumFare: 60.0,
      capacity: 4,
    ),
    VehicleType.scooty: VehiclePricing(
      baseRate: 20.0,
      perKmRate: 10.0,
      perMinuteRate: 1.5,
      minimumFare: 35.0,
      capacity: 1,
    ),
    VehicleType.standard: VehiclePricing(
      baseRate: 50.0,
      perKmRate: 15.0,
      perMinuteRate: 2.5,
      minimumFare: 80.0,
      capacity: 4,
    ),
    VehicleType.comfort: VehiclePricing(
      baseRate: 75.0,
      perKmRate: 20.0,
      perMinuteRate: 3.5,
      minimumFare: 120.0,
      capacity: 4,
    ),
    VehicleType.premium: VehiclePricing(
      baseRate: 120.0,
      perKmRate: 25.0,
      perMinuteRate: 5.0,
      minimumFare: 180.0,
      capacity: 4,
    ),
    VehicleType.xl: VehiclePricing(
      baseRate: 150.0,
      perKmRate: 30.0,
      perMinuteRate: 6.0,
      minimumFare: 250.0,
      capacity: 6,
    ),
  };

  // Zone pricing for different areas
  static const List<ZonePricing> _zonePricing = [
    ZonePricing(zoneId: 'airport', zoneName: 'Airport Zone', additionalCharge: 50.0),
    ZonePricing(zoneId: 'downtown', zoneName: 'Downtown', additionalCharge: 20.0),
    ZonePricing(zoneId: 'highway', zoneName: 'Highway Zone', additionalCharge: 15.0),
    ZonePricing(zoneId: 'night', zoneName: 'Night Zone', additionalCharge: 25.0),
  ];

  /// Calculate fare based on distance and duration
  static FareResult calculateFare({
    required VehicleType vehicleType,
    required double distanceKm,
    required Duration duration,
    double surgeMultiplier = 1.0,
    String? zoneId,
    bool isPeakHour = false,
    bool isNightTime = false,
    bool isBadWeather = false,
    bool isSpecialEvent = false,
  }) {
    final pricing = _vehiclePricing[vehicleType]!;
    
    // Calculate base fare components
    final double distanceFare = distanceKm * pricing.perKmRate;
    final double timeFare = duration.inMinutes * pricing.perMinuteRate;
    final double baseFare = math.max(pricing.baseRate, math.max(distanceFare, timeFare));
    
    // Apply minimum fare
    final double calculatedFare = math.max(baseFare, pricing.minimumFare);
    
    // Add zone charges if applicable
    double zoneCharge = 0.0;
    if (zoneId != null) {
      final zone = _zonePricing.firstWhere(
        (zone) => zone.zoneId == zoneId,
      );
      zoneCharge = zone.additionalCharge;
    }
    
    // Calculate surge multiplier
    double finalSurgeMultiplier = surgeMultiplier;
    if (isPeakHour) finalSurgeMultiplier *= 1.5;
    if (isNightTime) finalSurgeMultiplier *= 1.3;
    if (isBadWeather) finalSurgeMultiplier *= 1.2;
    if (isSpecialEvent) finalSurgeMultiplier *= 2.0;
    
    // Apply surge to calculated fare
    final double totalFare = (calculatedFare + zoneCharge) * finalSurgeMultiplier;
    
    return FareResult(
      baseFare: baseFare,
      distanceFare: distanceFare,
      timeFare: timeFare,
      surgeMultiplier: finalSurgeMultiplier,
      totalFare: totalFare,
      distance: distanceKm,
      estimatedDuration: duration,
      vehicleType: vehicleType,
      currency: _currency,
    );
  }

  /// Calculate fare with automatic surge detection
  static FareResult calculateFareWithAutoSurge({
    required VehicleType vehicleType,
    required double distanceKm,
    required Duration duration,
    String? zoneId,
    DateTime? rideTime,
  }) {
    if (rideTime == null) {
      rideTime = DateTime.now();
    }
    
    // Detect peak hours (7-10 AM, 5-8 PM)
    final hour = rideTime.hour;
    final isPeakHour = (hour >= 7 && hour <= 10) || (hour >= 17 && hour <= 20);
    
    // Detect night time (9 PM - 6 AM)
    final isNightTime = hour >= 21 || hour <= 6;
    
    // Detect bad weather (simplified - would integrate with weather API)
    final isBadWeather = false; // Would check weather API in production
    
    return calculateFare(
      vehicleType: vehicleType,
      distanceKm: distanceKm,
      duration: duration,
      surgeMultiplier: 1.0,
      zoneId: zoneId,
      isPeakHour: isPeakHour,
      isNightTime: isNightTime,
      isBadWeather: isBadWeather,
    );
  }

  /// Calculate fare for multiple passengers
  static FareResult calculateFareForPassengers({
    required VehicleType vehicleType,
    required double distanceKm,
    required Duration duration,
    required int passengerCount,
    double surgeMultiplier = 1.0,
    String? zoneId,
  }) {
    final baseFare = calculateFare(
      vehicleType: vehicleType,
      distanceKm: distanceKm,
      duration: duration,
      surgeMultiplier: surgeMultiplier,
      zoneId: zoneId,
    );
    
    // Add passenger surcharge (₹10 per additional passenger after first)
    final passengerSurcharge = passengerCount > 1 ? (passengerCount - 1) * 10.0 : 0.0;
    
    return FareResult(
      baseFare: baseFare.baseFare,
      distanceFare: baseFare.distanceFare,
      timeFare: baseFare.timeFare,
      surgeMultiplier: baseFare.surgeMultiplier,
      totalFare: baseFare.totalFare + passengerSurcharge,
      distance: baseFare.distance,
      estimatedDuration: baseFare.estimatedDuration,
      vehicleType: baseFare.vehicleType,
      currency: baseFare.currency,
    );
  }

  /// Calculate fare for round trip
  static FareResult calculateRoundTripFare({
    required VehicleType vehicleType,
    required double distanceKm,
    required Duration duration,
    double surgeMultiplier = 1.0,
    String? zoneId,
  }) {
    final oneWayFare = calculateFare(
      vehicleType: vehicleType,
      distanceKm: distanceKm,
      duration: duration,
      surgeMultiplier: surgeMultiplier,
      zoneId: zoneId,
    );
    
    // Round trip discount (10% off)
    final discountedFare = oneWayFare.totalFare * 0.9;
    
    return FareResult(
      baseFare: oneWayFare.baseFare * 0.9,
      distanceFare: oneWayFare.distanceFare * 0.9,
      timeFare: oneWayFare.timeFare * 0.9,
      surgeMultiplier: oneWayFare.surgeMultiplier,
      totalFare: discountedFare,
      distance: oneWayFare.distance,
      estimatedDuration: oneWayFare.estimatedDuration,
      vehicleType: oneWayFare.vehicleType,
      currency: oneWayFare.currency,
    );
  }

  /// Get vehicle pricing information
  static VehiclePricing getVehiclePricing(VehicleType vehicleType) {
    return _vehiclePricing[vehicleType]!;
  }

  /// Get all supported vehicle types
  static List<VehicleType> getSupportedVehicleTypes() {
    return VehicleType.values;
  }

  /// Format currency amount
  static String formatCurrency(double amount) {
    return '$_currency${amount.toStringAsFixed(2)}';
  }

  /// Calculate estimated duration based on distance and traffic
  static Duration estimateDuration(double distanceKm, {double averageSpeedKmh = 30.0}) {
    final estimatedMinutes = (distanceKm / averageSpeedKmh) * 60;
    return Duration(minutes: estimatedMinutes.round());
  }

  /// Validate fare calculation inputs
  static bool isValidDistance(double distanceKm) {
    return distanceKm > 0 && distanceKm <= 500; // Max 500km
  }

  static bool isValidDuration(Duration duration) {
    return duration.inMinutes > 0 && duration.inMinutes <= 480; // Max 8 hours
  }

  /// Get fare estimate for different scenarios
  static Map<String, FareResult> getFareEstimates({
    required VehicleType vehicleType,
    required double distanceKm,
    required Duration duration,
  }) {
    return {
      'standard': calculateFare(vehicleType: vehicleType, distanceKm: distanceKm, duration: duration),
      'peak_hour': calculateFare(
        vehicleType: vehicleType,
        distanceKm: distanceKm,
        duration: duration,
        isPeakHour: true,
      ),
      'night': calculateFare(
        vehicleType: vehicleType,
        distanceKm: distanceKm,
        duration: duration,
        isNightTime: true,
      ),
      'round_trip': calculateRoundTripFare(
        vehicleType: vehicleType,
        distanceKm: distanceKm,
        duration: duration,
      ),
      'multiple_passengers': calculateFareForPassengers(
        vehicleType: vehicleType,
        distanceKm: distanceKm,
        duration: duration,
        passengerCount: 3,
      ),
    };
  }
}

/// Fare calculation exceptions
class FareCalculationException implements Exception {
  final String message;
  final String? code;
  
  const FareCalculationException(this.message, {this.code});
  
  @override
  String toString() => 'FareCalculationException: $message${code != null ? ' ($code)' : ''}';
}

/// Usage examples and documentation
class FareCalculatorExamples {
  /// Basic fare calculation example
  static void basicExample() {
    final fare = FareCalculator.calculateFare(
      vehicleType: VehicleType.standard,
      distanceKm: 12.5,
      duration: const Duration(minutes: 25),
    );
    
    print('Standard vehicle, 12.5 km, 25 min:');
    print(fare.fareBreakdown);
  }
  
  /// Peak hour surge example
  static void surgeExample() {
    final fare = FareCalculator.calculateFare(
      vehicleType: VehicleType.auto,
      distanceKm: 8.0,
      duration: const Duration(minutes: 20),
      isPeakHour: true,
      surgeMultiplier: 1.5,
    );
    
    print('Auto during peak hour with 1.5x surge:');
    print(fare.fareBreakdown);
  }
  
  /// Airport zone example
  static void zoneExample() {
    final fare = FareCalculator.calculateFare(
      vehicleType: VehicleType.premium,
      distanceKm: 25.0,
      duration: const Duration(minutes: 35),
      zoneId: 'airport',
    );
    
    print('Premium vehicle to airport with zone charge:');
    print(fare.fareBreakdown);
  }
  
  /// Multiple passengers example
  static void passengerExample() {
    final fare = FareCalculator.calculateFareForPassengers(
      vehicleType: VehicleType.xl,
      distanceKm: 15.0,
      duration: const Duration(minutes: 30),
      passengerCount: 4,
    );
    
    print('XL vehicle for 4 passengers:');
    print(fare.fareBreakdown);
  }
  
  /// Round trip discount example
  static void roundTripExample() {
    final fare = FareCalculator.calculateRoundTripFare(
      vehicleType: VehicleType.comfort,
      distanceKm: 20.0,
      duration: const Duration(minutes: 40),
    );
    
    print('Comfort vehicle round trip with 10% discount:');
    print(fare.fareBreakdown);
  }
}
