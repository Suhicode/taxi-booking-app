import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final String userType; // 'customer' or 'driver'
  final DateTime createdAt;
  final DateTime? lastActive;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? driverInfo; // Only for drivers
  final List<String>? paymentMethods;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    required this.userType,
    required this.createdAt,
    this.lastActive,
    this.preferences,
    this.driverInfo,
    this.paymentMethods,
  });

  // Convert User to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'userType': userType,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'preferences': preferences,
      'driverInfo': driverInfo,
      'paymentMethods': paymentMethods,
    };
  }

  // Create User from Map
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      photoURL: map['photoURL'] as String?,
      userType: map['userType'] as String? ?? 'customer',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastActive: map['lastActive'] != null 
          ? (map['lastActive'] as Timestamp).toDate() 
          : null,
      preferences: map['preferences'] as Map<String, dynamic>?,
      driverInfo: map['driverInfo'] as Map<String, dynamic>?,
      paymentMethods: map['paymentMethods'] != null 
          ? List<String>.from(map['paymentMethods'] as List) 
          : null,
    );
  }

  // Create User from Firebase User
  factory AppUser.fromFirebaseUser(User user, {String userType = 'customer'}) {
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      phoneNumber: user.phoneNumber,
      photoURL: user.photoURL,
      userType: userType,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastActive: user.metadata.lastSignInTime,
    );
  }

  // Copy with method for immutable updates
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    String? userType,
    DateTime? createdAt,
    DateTime? lastActive,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? driverInfo,
    List<String>? paymentMethods,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      preferences: preferences ?? this.preferences,
      driverInfo: driverInfo ?? this.driverInfo,
      paymentMethods: paymentMethods ?? this.paymentMethods,
    );
  }
}
