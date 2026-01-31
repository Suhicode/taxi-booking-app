import 'package:flutter/material.dart';

class CashPaymentService {
  static const String _cashPaymentMethod = 'CASH';
  
  /// Process cash payment for completed ride
  static Future<bool> processCashPayment({
    required String rideId,
    required double amount,
    required String driverId,
    required String customerId,
  }) async {
    try {
      // Simulate cash payment confirmation
      // In real app, driver would confirm receiving cash
      await Future.delayed(const Duration(seconds: 1));
      
      // Log payment for record keeping
      final paymentRecord = {
        'rideId': rideId,
        'amount': amount,
        'paymentMethod': _cashPaymentMethod,
        'driverId': driverId,
        'customerId': customerId,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'PAID',
      };
      
      // Store payment record locally (you could save to SharedPreferences)
      debugPrint('Cash payment processed: $paymentRecord');
      
      return true;
    } catch (e) {
      debugPrint('Error processing cash payment: $e');
      return false;
    }
  }
  
  /// Get payment method display name
  static String getPaymentMethodName() {
    return 'Cash';
  }
  
  /// Get payment method description
  static String getPaymentMethodDescription() {
    return 'Pay cash directly to the driver after the ride';
  }
  
  /// Check if payment method is available
  static bool isPaymentMethodAvailable() {
    return true; // Cash is always available
  }
  
  /// Get cash payment instructions
  static List<String> getCashPaymentInstructions() {
    return [
      '1. Pay the exact fare amount to the driver',
      '2. Driver will confirm payment received',
      '3. You will receive payment confirmation',
      '4. Keep the receipt for your records',
    ];
  }
  
  /// Calculate cash payment breakdown
  static Map<String, dynamic> calculatePaymentBreakdown({
    required double baseFare,
    required double distanceFare,
    required double timeFare,
    required double? surgeMultiplier,
    required double platformFee,
  }) {
    final subtotal = baseFare + distanceFare + timeFare;
    final surgeAmount = surgeMultiplier != null && surgeMultiplier > 1.0 
        ? (subtotal * (surgeMultiplier - 1)) 
        : 0.0;
    final totalFare = (subtotal + surgeAmount) * (1 + platformFee / 100);
    
    return {
      'baseFare': baseFare,
      'distanceFare': distanceFare,
      'timeFare': timeFare,
      'surgeAmount': surgeAmount,
      'platformFee': totalFare * (platformFee / 100),
      'totalFare': totalFare.roundToDouble(),
      'paymentMethod': _cashPaymentMethod,
    };
  }
  
  /// Validate cash payment amount
  static bool validatePaymentAmount({
    required double requestedAmount,
    required double actualAmount,
  }) {
    // Allow small rounding differences
    final difference = (requestedAmount - actualAmount).abs();
    return difference <= 1.0; // Allow 1 rupee difference
  }
}
