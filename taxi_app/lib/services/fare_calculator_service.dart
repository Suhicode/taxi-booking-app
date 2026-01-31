import 'dart:math' as math;
import '../constants/app_constants.dart';
import '../services/location_service.dart';
import '../models/location_model.dart';

class FareCalculator {
  static Map<String, dynamic> calculateFare({
    required String vehicleType,
    required double distanceKm,
    required double durationMin,
    double surgeMultiplier = 1.0,
  }) {
    // Get base fare and rates for vehicle type
    final baseFare = AppConstants.baseFares[vehicleType] ?? AppConstants.baseFares['Standard']!;
    final perKmRate = AppConstants.perKmRates[vehicleType] ?? AppConstants.perKmRates['Standard']!;
    final perMinuteRate = AppConstants.perMinuteRates[vehicleType] ?? AppConstants.perMinuteRates['Standard']!;

    // Calculate distance fare
    final distanceFare = distanceKm * perKmRate;

    // Calculate time fare (minimum 1 minute)
    final timeFare = math.max(durationMin, 1.0) * perMinuteRate;

    // Apply minimum fare
    final calculatedFare = math.max(baseFare + distanceFare + timeFare, AppConstants.minimumFare);

    // Apply surge pricing if applicable
    final finalFare = calculatedFare * surgeMultiplier;

    // Round to nearest integer
    final totalFare = finalFare.round();

    return {
      'baseFare': baseFare,
      'distanceFare': distanceFare,
      'timeFare': timeFare,
      'calculatedFare': calculatedFare,
      'surgeMultiplier': surgeMultiplier,
      'finalFare': finalFare,
      'total': totalFare,
      'distance': distanceKm,
      'duration': durationMin,
    };
  }

  static Map<String, dynamic> calculateFareForRoute({
    required String vehicleType,
    required LocationModel pickup,
    required LocationModel destination,
    double surgeMultiplier = 1.0,
  }) {
    // Calculate distance using LocationService
    final distance = LocationService.calculateDistance(pickup, destination);

    // Estimate duration (rough calculation: average speed of 30 km/h)
    final estimatedDuration = (distance / 30.0) * 60; // Convert to minutes

    return calculateFare(
      vehicleType: vehicleType,
      distanceKm: distance,
      durationMin: estimatedDuration,
      surgeMultiplier: surgeMultiplier,
    );
  }

  static double calculateDistance(LocationModel start, LocationModel end) {
    return LocationService.calculateDistance(start, end);
  }

  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  static bool isValidVehicleType(String vehicleType) {
    return AppConstants.vehicleTypes.contains(vehicleType);
  }

  static List<String> getAvailableVehicleTypes() {
    return List.from(AppConstants.vehicleTypes);
  }

  static double getMinimumFare(String vehicleType) {
    return AppConstants.baseFares[vehicleType] ?? AppConstants.baseFares['Standard']!;
  }

  static double getPerKmRate(String vehicleType) {
    return AppConstants.perKmRates[vehicleType] ?? AppConstants.perKmRates['Standard']!;
  }

  static double getPerMinuteRate(String vehicleType) {
    return AppConstants.perMinuteRates[vehicleType] ?? AppConstants.perMinuteRates['Standard']!;
  }
}
