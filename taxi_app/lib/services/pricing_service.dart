class PricingService {
  // Vehicle type pricing configuration
  static const Map<String, Map<String, double>> vehicleRates = {
    'Bike': {
      'baseFare': 20,
      'perKm': 10,
      'perMin': 1,
      'minFare': 30,
    },
    'Scooty': {
      'baseFare': 25,
      'perKm': 12,
      'perMin': 1.2,
      'minFare': 35,
    },
    'Standard': {
      'baseFare': 30,
      'perKm': 15,
      'perMin': 2,
      'minFare': 50,
    },
    'Comfort': {
      'baseFare': 40,
      'perKm': 18,
      'perMin': 2.5,
      'minFare': 60,
    },
    'Premium': {
      'baseFare': 60,
      'perKm': 25,
      'perMin': 3,
      'minFare': 80,
    },
    'XL': {
      'baseFare': 80,
      'perKm': 30,
      'perMin': 4,
      'minFare': 100,
    },
  };

  // Pricing configuration
  static const double platformCommission = 0.15; // 15%
  static const double taxRate = 0.05; // 5%
  static const double nightSurgeMultiplier = 1.25;
  static const int nightStartHour = 22;
  static const int nightEndHour = 6;
  static const double maxSurgeMultiplier = 3.0;
  static const int waitingFreeMins = 3;
  static const double waitingPerMin = 2;

  /// Calculate fare based on vehicle type, distance, duration, and optional surge.
  /// Returns a map with detailed breakdown and driver payout.
  static Map<String, dynamic> calculateFare({
    required String vehicleType,
    required double distanceKm,
    required double durationMin,
    double waitingMin = 0,
    double surgeMultiplier = 1.0,
    DateTime? now,
  }) {
    now ??= DateTime.now();

    final rates = vehicleRates[vehicleType] ?? vehicleRates['Standard']!;
    final baseFare = rates['baseFare']!;
    final perKm = rates['perKm']!;
    final perMin = rates['perMin']!;
    final minFare = rates['minFare']!;

    // Ensure non-negative values
    final distance = distanceKm.clamp(0, double.infinity);
    final duration = durationMin.clamp(0, double.infinity);
    final waiting = (waitingMin - waitingFreeMins).clamp(0, double.infinity);

    // Calculate waiting charge
    final waitingCharge = waiting * waitingPerMin;

    // Night surcharge
    double nightMultiplier = 1.0;
    final hour = now.hour;
    if (nightStartHour > nightEndHour) {
      // Night hours span midnight (e.g., 22:00 to 06:00)
      if (hour >= nightStartHour || hour < nightEndHour) {
        nightMultiplier = nightSurgeMultiplier;
      }
    } else {
      // Night hours don't span midnight
      if (hour >= nightStartHour && hour < nightEndHour) {
        nightMultiplier = nightSurgeMultiplier;
      }
    }

    // Clamp surge multiplier
    final clampedSurge = surgeMultiplier.clamp(1.0, maxSurgeMultiplier);

    // Calculate fare components
    final distanceFare = distance * perKm;
    final timeFare = duration * perMin;
    var subtotal = baseFare + distanceFare + timeFare + waitingCharge;
    subtotal = subtotal.clamp(minFare, double.infinity);

    // Apply multipliers
    final fareBeforeTax = subtotal * nightMultiplier * clampedSurge;

    // Round to nearest rupee
    final fareRounded = fareBeforeTax.round().toDouble();

    // Calculate commission and tax
    final commission = (fareRounded * platformCommission).round().toDouble();
    final tax = (fareRounded * taxRate).round().toDouble();
    final driverPayout = fareRounded - commission - tax;
    final total = fareRounded + tax;

    return {
      'vehicleType': vehicleType,
      'distanceKm': distance,
      'durationMin': duration,
      'waitingMin': waiting,
      'surgeMultiplier': clampedSurge,
      'nightMultiplier': nightMultiplier,
      'baseFare': baseFare,
      'perKm': perKm,
      'perMin': perMin,
      'waitingCharge': waitingCharge.round(),
      'minFare': minFare,
      'subtotal': fareRounded.toInt(),
      'commission': commission.toInt(),
      'tax': tax.toInt(),
      'total': total.toInt(),
      'driverPayout': driverPayout.toInt(),
      'breakdown': {
        'baseFare': baseFare,
        'distanceFare': (distanceFare).round(),
        'timeFare': (timeFare).round(),
        'waitingCharge': waitingCharge.round(),
        'nightMultiplier': nightMultiplier,
        'surgeMultiplier': clampedSurge,
        'subtotal': fareRounded.toInt(),
        'commission': commission.toInt(),
        'tax': tax.toInt(),
        'total': total.toInt(),
        'driverPayout': driverPayout.toInt(),
      }
    };
  }
}
