import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as lat;
import '../services/location_service.dart';

class DynamicPricingService {
  // Dynamic pricing configuration similar to Rapido/Ola
  static const Map<String, Map<String, double>> baseRates = {
    'Bike': {'baseFare': 15.0, 'perKm': 8.0, 'minFare': 25.0},
    'Scooty': {'baseFare': 20.0, 'perKm': 10.0, 'minFare': 35.0},
    'Standard': {'baseFare': 25.0, 'perKm': 12.0, 'minFare': 40.0},
    'Comfort': {'baseFare': 35.0, 'perKm': 15.0, 'minFare': 50.0},
    'Premium': {'baseFare': 50.0, 'perKm': 20.0, 'minFare': 70.0},
    'XL': {'baseFare': 70.0, 'perKm': 25.0, 'minFare': 90.0},
  };

  // Surge pricing multipliers
  static const double peakHourSurge = 1.5;
  static const double nightSurge = 1.25;
  static const double rainSurge = 1.2;
  static const double maxSurge = 3.0;

  static Map<String, dynamic> calculateDynamicFare({
    required String vehicleType,
    required double distanceKm,
    required double durationMin,
    DateTime? rideTime,
    double waitingMin = 0,
  }) {
    final now = rideTime ?? DateTime.now();
    final rates = baseRates[vehicleType] ?? baseRates['Standard']!;
    
    // Calculate base fare
    double baseFare = rates['baseFare']!;
    double perKmRate = rates['perKm']!;
    double minFare = rates['minFare']!;

    // Distance-based fare calculation
    double distanceFare = distanceKm * perKmRate;
    
    // Time-based fare (minimum charge)
    double timeFare = (durationMin * perKmRate * 0.5); // 50% of distance fare per minute
    
    // Calculate subtotal
    double subtotal = baseFare + distanceFare + timeFare;
    
    // Apply minimum fare
    subtotal = subtotal > minFare ? subtotal : minFare;

    // Apply surge pricing based on conditions
    double surgeMultiplier = 1.0;
    
    // Peak hours (7-10 AM, 5-8 PM)
    final hour = now.hour;
    if ((hour >= 7 && hour <= 10) || (hour >= 17 && hour <= 20)) {
      surgeMultiplier = peakHourSurge;
    }
    
    // Night hours (10 PM - 6 AM)
    if (hour >= 22 || hour < 6) {
      surgeMultiplier = nightSurge;
    }
    
    // Limit surge multiplier
    surgeMultiplier = surgeMultiplier.clamp(1.0, maxSurge);

    // Apply surge
    final fareBeforeTax = subtotal * surgeMultiplier;

    // Add waiting charges
    double waitingCharge = (waitingMin > 3) ? (waitingMin - 3) * 2.0 : 0.0;

    final totalFare = fareBeforeTax + waitingCharge;

    // Calculate commission and tax (same as before)
    final commission = (totalFare * 0.15).round().toDouble();
    final tax = (totalFare * 0.05).round().toDouble();
    final driverPayout = totalFare - commission - tax;

    return {
      'vehicleType': vehicleType,
      'distanceKm': distanceKm,
      'durationMin': durationMin,
      'waitingMin': waitingMin,
      'surgeMultiplier': surgeMultiplier,
      'baseFare': baseFare,
      'distanceFare': distanceFare.round(),
      'timeFare': timeFare.round(),
      'waitingCharge': waitingCharge.round(),
      'minFare': minFare,
      'subtotal': totalFare.round().toInt(),
      'commission': commission.toInt(),
      'tax': tax.toInt(),
      'total': totalFare.round().toInt(),
      'driverPayout': driverPayout.toInt(),
      'isSurgeActive': surgeMultiplier > 1.0,
      'surgeReason': _getSurgeReason(surgeMultiplier, hour),
      'breakdown': {
        'base': baseFare.round(),
        'distance': distanceFare.round(),
        'time': timeFare.round(),
        'surge': ((totalFare * surgeMultiplier) - totalFare).round(),
        'waiting': waitingCharge.round(),
      }
    };
  }

  static String _getSurgeReason(double multiplier, int hour) {
    if (multiplier == peakHourSurge) {
      return 'Peak hours';
    } else if (multiplier == nightSurge) {
      return 'Night hours';
    } else if (multiplier == rainSurge) {
      return 'Rainy weather';
    }
    return 'Normal pricing';
  }

  // Get estimated fare for display
  static Map<String, dynamic> getEstimatedFare({
    required String vehicleType,
    required double distanceKm,
    required double durationMin,
  }) {
    final fare = calculateDynamicFare(
      vehicleType: vehicleType,
      distanceKm: distanceKm,
      durationMin: durationMin,
      rideTime: DateTime.now(),
    );

    return {
      'estimatedFare': fare['total'],
      'estimatedDuration': (durationMin * 1.2).round(), // Add buffer time
      'distance': distanceKm,
      'vehicleType': vehicleType,
    };
  }
}
