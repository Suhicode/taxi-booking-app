import 'dart:async';
import '../models/driver_profile_model.dart';

class DriverAuthService {
  // Mock database - in production, use Firebase or other backend
  static Map<String, DriverProfileModel> _driverDatabase = {};

  /// Register a new driver
  static Future<String> registerDriver(DriverProfileModel driver) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Check if email already exists
    final existingDriver = _driverDatabase.values
        .where((d) => d.email == driver.email)
        .firstOrNull;
    
    if (existingDriver != null) {
      throw Exception('Email already registered');
    }
    
    // Check if phone number already exists
    final existingPhone = _driverDatabase.values
        .where((d) => d.phoneNumber == driver.phoneNumber)
        .firstOrNull;
    
    if (existingPhone != null) {
      throw Exception('Phone number already registered');
    }
    
    // Generate unique ID
    final driverId = 'driver_${DateTime.now().millisecondsSinceEpoch}';
    final newDriver = driver.copyWith(id: driverId);
    
    // Store in database
    _driverDatabase[driverId] = newDriver;
    
    return driverId;
  }

  /// Login driver with email and password (using phone as password for demo)
  static Future<DriverProfileModel> loginDriver(String email, String phoneNumber) async {
    // Initialize sample data if database is empty
    initializeSampleData();
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Find driver by email
    final driver = _driverDatabase.values
        .where((d) => d.email == email && d.phoneNumber == phoneNumber)
        .firstOrNull;
    
    if (driver == null) {
      throw Exception('Invalid email or phone number');
    }
    
    // Update last login
    final updatedDriver = driver.copyWith(lastLogin: DateTime.now());
    _driverDatabase[driver.id] = updatedDriver;
    
    // Save session
    await _saveSession(updatedDriver);
    
    return updatedDriver;
  }

  /// Get current logged-in driver
  static Future<DriverProfileModel?> getCurrentDriver() async {
    try {
      final sessionData = await _getSession();
      if (sessionData != null) {
        return DriverProfileModel.fromMap(sessionData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Logout driver
  static Future<void> logoutDriver() async {
    await _clearSession();
  }

  /// Check if driver is logged in
  static Future<bool> isDriverLoggedIn() async {
    final driver = await getCurrentDriver();
    return driver != null;
  }

  /// Update driver profile
  static Future<void> updateDriverProfile(DriverProfileModel driver) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _driverDatabase[driver.id] = driver;
    
    // Update session if this is current driver
    final currentDriver = await getCurrentDriver();
    if (currentDriver?.id == driver.id) {
      await _saveSession(driver);
    }
  }

  /// Get all drivers (for admin)
  static Future<List<DriverProfileModel>> getAllDrivers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _driverDatabase.values.toList();
  }

  /// Get driver by ID
  static Future<DriverProfileModel?> getDriverById(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _driverDatabase[driverId];
  }

  /// Verify driver (for admin)
  static Future<void> verifyDriver(String driverId, bool isVerified) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final driver = _driverDatabase[driverId];
    if (driver != null) {
      final updatedDriver = driver.copyWith(
        isVerified: isVerified,
        status: isVerified ? 'verified' : 'rejected',
      );
      _driverDatabase[driverId] = updatedDriver;
    }
  }

  // Session management methods (using SharedPreferences simulation)
  static Map<String, dynamic>? _sessionCache;

  static Future<void> _saveSession(DriverProfileModel driver) async {
    // In production, use SharedPreferences
    _sessionCache = driver.toMap();
  }

  static Future<Map<String, dynamic>?> _getSession() async {
    // In production, use SharedPreferences
    return _sessionCache;
  }

  static Future<void> _clearSession() async {
    // In production, use SharedPreferences
    _sessionCache = null;
  }

  /// Validate driver data
  static String? validateDriverData({
    required String name,
    required String email,
    required String phoneNumber,
    required int age,
    required String profileImageUrl,
    required String aadharCardImageUrl,
    required String licenseImageUrl,
  }) {
    // Name validation
    if (name.trim().isEmpty) {
      return 'Name is required';
    }
    if (name.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }

    // Email validation
    if (email.trim().isEmpty) {
      return 'Email is required';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Please enter a valid email';
    }

    // Phone validation
    if (phoneNumber.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (phoneNumber.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    // Age validation
    if (age < 18 || age > 70) {
      return 'Age must be between 18 and 70';
    }

    // Image validation
    if (profileImageUrl.isEmpty) {
      return 'Profile picture is required';
    }
    if (aadharCardImageUrl.isEmpty) {
      return 'Aadhar card image is required';
    }
    if (licenseImageUrl.isEmpty) {
      return 'License image is required';
    }

    return null; // No validation errors
  }

  /// Initialize with sample data for testing
  static void initializeSampleData() {
    if (_driverDatabase.isEmpty) {
      final sampleDriver = DriverProfileModel(
        id: 'driver_sample_001',
        name: 'John Driver',
        email: 'john@driver.com',
        phoneNumber: '9876543210',
        age: 30,
        profileImageUrl: 'assets/images/default_profile.png',
        aadharCardImageUrl: 'assets/images/default_aadhar.png',
        licenseImageUrl: 'assets/images/default_license.png',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
        isVerified: true,
        status: 'active',
        vehicleType: 'Standard',
        vehicleNumber: 'TN-01-AB-1234',
        rating: 4.5,
      );
      _driverDatabase['driver_sample_001'] = sampleDriver;
    }
  }
}
