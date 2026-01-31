import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// API Configuration
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000/api';
  static const String wsUrl = 'ws://localhost:8000/ws';
  
  // Endpoints
  static const String authDriverLogin = '$baseUrl/auth/driver/login';
  static const String authDriverRegister = '$baseUrl/auth/driver/register';
  static const String driverProfile = '$baseUrl/drivers/profile';
  static const String driverLocation = '$baseUrl/drivers/location';
  static const String driverStatus = '$baseUrl/drivers/status';
  static const String driverRides = '$baseUrl/drivers/rides';
  static const String driverEarnings = '$baseUrl/drivers/earnings';
  static const String rideAccept = '$baseUrl/rides';
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
  
  // Driver Login
  static Future<Map<String, dynamic>> driverLogin(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authDriverLogin),
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
  
  // Driver Registration
  static Future<Map<String, dynamic>> driverRegister(Map<String, dynamic> driverData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authDriverRegister),
        headers: _headers,
        body: jsonEncode(driverData),
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
  
  // Get Driver Profile
  static Future<Map<String, dynamic>> getDriverProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.driverProfile),
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
  
  // Update Driver Location
  static Future<Map<String, dynamic>> updateLocation(double lat, double lng) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.driverLocation),
        headers: headers,
        body: jsonEncode({
          'lat': lat,
          'lng': lng,
        }),
      );
      
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Failed to update location'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  // Update Driver Status (Online/Offline)
  static Future<Map<String, dynamic>> updateStatus(bool isOnline) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.driverStatus),
        headers: headers,
        body: jsonEncode({
          'is_online': isOnline,
        }),
      );
      
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Failed to update status'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  // Get Driver Rides
  static Future<Map<String, dynamic>> getDriverRides() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.driverRides),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['rides']};
      } else {
        return {'success': false, 'error': 'Failed to load rides'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  // Get Driver Earnings
  static Future<Map<String, dynamic>> getDriverEarnings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.driverEarnings),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Failed to load earnings'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
  
  // Accept Ride
  static Future<Map<String, dynamic>> acceptRide(int rideId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.rideAccept}/$rideId/accept'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['detail']};
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
