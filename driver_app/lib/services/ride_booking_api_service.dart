import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class RideBookingApiService {
  static const String _baseUrl = 'http://localhost:3000/api'; // Update with your backend URL

  static Future<RideBookingResponse> bookRide(RideRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ride/request'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'pickupLat': request.pickupLat,
          'pickupLng': request.pickupLng,
          'pickupAddress': request.pickupAddress,
          'dropLat': request.dropLat,
          'dropLng': request.dropLng,
          'dropAddress': request.dropAddress,
          'userId': request.userId,
          'vehicleType': request.vehicleType,
          'estimatedFare': request.estimatedFare,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return RideBookingResponse.fromJson(data);
      } else {
        throw Exception('Failed to book ride: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ride booking error: $e');
    }
  }

  static Future<RideStatusResponse> checkRideStatus(String rideId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/ride/status/$rideId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RideStatusResponse.fromJson(data);
      } else {
        throw Exception('Failed to check ride status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ride status check error: $e');
    }
  }

  static Future<void> cancelRide(String rideId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ride/cancel/$rideId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel ride: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ride cancellation error: $e');
    }
  }

  // Polling service for ride status
  static Stream<RideStatusResponse> pollRideStatus(String rideId, {Duration interval = const Duration(seconds: 3)}) {
    return Stream.periodic(interval, (_) => rideId)
        .asyncMap((rideId) => checkRideStatus(rideId))
        .takeWhile((status) => status.status == 'searching' || status.status == 'pending');
  }
}

class RideRequest {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropLat;
  final double dropLng;
  final String dropAddress;
  final String userId;
  final String vehicleType;
  final double estimatedFare;

  RideRequest({
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropLat,
    required this.dropLng,
    required this.dropAddress,
    required this.userId,
    required this.vehicleType,
    required this.estimatedFare,
  });

  Map<String, dynamic> toJson() {
    return {
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'pickupAddress': pickupAddress,
      'dropLat': dropLat,
      'dropLng': dropLng,
      'dropAddress': dropAddress,
      'userId': userId,
      'vehicleType': vehicleType,
      'estimatedFare': estimatedFare,
    };
  }
}

class RideBookingResponse {
  final String rideId;
  final String status;
  final String? message;

  RideBookingResponse({
    required this.rideId,
    required this.status,
    this.message,
  });

  factory RideBookingResponse.fromJson(Map<String, dynamic> json) {
    return RideBookingResponse(
      rideId: json['rideId'] ?? '',
      status: json['status'] ?? 'unknown',
      message: json['message'],
    );
  }
}

class RideStatusResponse {
  final String rideId;
  final String status;
  final Driver? driver;
  final String? message;

  RideStatusResponse({
    required this.rideId,
    required this.status,
    this.driver,
    this.message,
  });

  factory RideStatusResponse.fromJson(Map<String, dynamic> json) {
    return RideStatusResponse(
      rideId: json['rideId'] ?? '',
      status: json['status'] ?? 'unknown',
      driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
      message: json['message'],
    );
  }
}

class Driver {
  final String id;
  final String name;
  final String phone;
  final String vehicleNumber;
  final String vehicleModel;
  final double rating;
  final String? profileImage;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleNumber,
    required this.vehicleModel,
    required this.rating,
    this.profileImage,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      vehicleModel: json['vehicleModel'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      profileImage: json['profileImage'],
    );
  }
}
