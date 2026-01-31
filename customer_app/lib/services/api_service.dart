import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// API Configuration
class ApiConfig {
  static String get baseUrl {
    // Use 10.0.2.2 for Android emulator, localhost for web/desktop
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    } else {
      return 'http://10.0.2.2:8000/api';
    }
  }
  
  static String get wsUrl {
    // Use 10.0.2.2 for Android emulator, localhost for web/desktop
    if (kIsWeb) {
      return 'ws://localhost:8000/ws';
    } else {
      return 'ws://10.0.2.2:8000/ws';
    }
  }
  
  // Endpoints
  static String get authPassengerLogin => '$baseUrl/auth/passenger/login';
  static String get authPassengerRegister => '$baseUrl/auth/passenger/register';
  static String get passengerProfile => '$baseUrl/passengers/profile';
  static String get createRide => '$baseUrl/rides/request';
  static String get passengerRides => '$baseUrl/rides/passenger/history';
  static String get passengerActiveRides => '$baseUrl/passengers/active-rides';
}

// Storage for secure token management
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
  
  static Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }
}

// API Service
class ApiService {
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };
  
  // Add auth token to headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    if (token != null) {
      return {
        ..._headers,
        'Authorization': 'Bearer $token',
      };
    }
    return _headers;
  }
  
  // Passenger Login
  static Future<Map<String, dynamic>> passengerLogin(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authPassengerLogin),
        headers: _headers,
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await TokenStorage.saveToken(data['access_token']);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['detail']};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  // Passenger Registration
  static Future<Map<String, dynamic>> passengerRegister(Map<String, dynamic> passengerData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authPassengerRegister),
        headers: _headers,
        body: jsonEncode(passengerData),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await TokenStorage.saveToken(data['access_token']);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['detail']};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  // Get Passenger Profile
  static Future<Map<String, dynamic>> getPassengerProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.passengerProfile),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to load profile'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  // Create Ride Request
  static Future<Map<String, dynamic>> createRide({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropLat,
    required double dropLng,
    required String dropAddress,
    required String city,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.createRide),
        headers: headers,
        body: jsonEncode({
          'pickup_lat': pickupLat,
          'pickup_lng': pickupLng,
          'pickup_address': pickupAddress,
          'drop_lat': dropLat,
          'drop_lng': dropLng,
          'drop_address': dropAddress,
          'city': city,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['detail']};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  // Get Active Rides
  static Future<Map<String, dynamic>> getActiveRides() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.passengerActiveRides),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['active_rides']};
      } else {
        return {'success': false, 'error': 'Failed to load active rides'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  // Get Ride History
  static Future<Map<String, dynamic>> getRideHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.passengerRides),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['rides']};
      } else {
        return {'success': false, 'error': 'Failed to load ride history'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  // Logout
  static Future<void> logout() async {
    await TokenStorage.deleteToken();
  }
}
