import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_app/services/pricing_service.dart';

void main() {
  group('PricingService', () {
    test('calculateFare returns correct structure', () {
      final result = PricingService.calculateFare(
        vehicleType: 'Standard',
        distanceKm: 5,
        durationMin: 15,
      );

      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('vehicleType'), true);
      expect(result.containsKey('total'), true);
      expect(result.containsKey('driverPayout'), true);
      expect(result.containsKey('breakdown'), true);
    });

    test('calculateFare applies minimum fare correctly', () {
      final result = PricingService.calculateFare(
        vehicleType: 'Standard',
        distanceKm: 0.5,
        durationMin: 1,
      );

      // Standard minimum fare is 50
      expect(result['subtotal'], greaterThanOrEqualTo(50));
    });

    test('calculateFare calculates long trip correctly', () {
      final result = PricingService.calculateFare(
        vehicleType: 'Standard',
        distanceKm: 10,
        durationMin: 30,
      );

      // Base fare (30) + distance (10*15=150) + time (30*2=60) = 240
      expect(result['subtotal'], greaterThan(100));
    });

    test('calculateFare applies surge pricing', () {
      final normalFare = PricingService.calculateFare(
        vehicleType: 'Standard',
        distanceKm: 5,
        durationMin: 15,
        surgeMultiplier: 1.0,
      );

      final surgeFare = PricingService.calculateFare(
        vehicleType: 'Standard',
        distanceKm: 5,
        durationMin: 15,
        surgeMultiplier: 2.0,
      );

      expect(surgeFare['subtotal'], greaterThan(normalFare['subtotal']));
    });

    test('calculateFare applies night surcharge', () {
      final dayTime = DateTime(2024, 1, 1, 12, 0); // Noon
      final nightTime = DateTime(2024, 1, 1, 23, 0); // 11 PM

      final dayFare = PricingService.calculateFare(
        vehicleType: 'Standard',
        distanceKm: 5,
        durationMin: 15,
        now: dayTime,
      );

      final nightFare = PricingService.calculateFare(
        vehicleType: 'Standard',
        distanceKm: 5,
        durationMin: 15,
        now: nightTime,
      );

      expect(nightFare['subtotal'], greaterThan(dayFare['subtotal']));
    });

    test('calculateFare calculates waiting charges correctly', () {
      final noWaiting = PricingService.calculateFare(
        vehicleType: 'Standard',
        distanceKm: 5,
        durationMin: 15,
        waitingMin: 0,
      );

      final withWaiting = PricingService.calculateFare(
        vehicleType: 'Standard',
        distanceKm: 5,
        durationMin: 15,
        waitingMin: 10, // 10 minutes waiting, 3 free + 7 paid
      );

      expect(withWaiting['subtotal'], greaterThan(noWaiting['subtotal']));
    });

    test('calculateFare calculates different vehicle types correctly', () {
      final bikeFare = PricingService.calculateFare(
        vehicleType: 'Bike',
        distanceKm: 5,
        durationMin: 15,
      );

      final premiumFare = PricingService.calculateFare(
        vehicleType: 'Premium',
        distanceKm: 5,
        durationMin: 15,
      );

      expect(premiumFare['subtotal'], greaterThan(bikeFare['subtotal']));
    });

    test('calculateFare includes tax and commission in total', () {
      final result = PricingService.calculateFare(
        vehicleType: 'Standard',
        distanceKm: 5,
        durationMin: 15,
      );

      final expectedTotal = result['subtotal'] + result['tax'];
      expect(result['total'], equals(expectedTotal));
    });

    test('calculateFare calculates driver payout correctly', () {
      final result = PricingService.calculateFare(
        vehicleType: 'Standard',
        distanceKm: 5,
        durationMin: 15,
      );

      final expectedPayout = result['subtotal'] - result['commission'] - result['tax'];
      expect(result['driverPayout'], equals(expectedPayout));
    });

    test('calculateFare clamps surge multiplier to max', () {
      final result = PricingService.calculateFare(
        vehicleType: 'Standard',
        distanceKm: 5,
        durationMin: 15,
        surgeMultiplier: 5.0, // Exceeds max of 3.0
      );

      expect(result['surgeMultiplier'], lessThanOrEqualTo(3.0));
    });

    test('calculateFare returns values as integers for currency', () {
      final result = PricingService.calculateFare(
        vehicleType: 'Standard',
        distanceKm: 5,
        durationMin: 15,
      );

      expect(result['subtotal'], isA<int>());
      expect(result['total'], isA<int>());
      expect(result['driverPayout'], isA<int>());
      expect(result['commission'], isA<int>());
      expect(result['tax'], isA<int>());
    });
  });
}
