class DriverProfileModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final int age;
  final String profileImageUrl;
  final String aadharCardImageUrl;
  final String licenseImageUrl;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isVerified;
  final String status; // 'pending', 'verified', 'rejected', 'active'
  final String? vehicleType;
  final String? vehicleNumber;
  final double? rating;

  DriverProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.age,
    required this.profileImageUrl,
    required this.aadharCardImageUrl,
    required this.licenseImageUrl,
    required this.createdAt,
    required this.lastLogin,
    required this.isVerified,
    required this.status,
    this.vehicleType,
    this.vehicleNumber,
    this.rating,
  });

  // Factory constructor for creating from database/map
  factory DriverProfileModel.fromMap(Map<String, dynamic> map) {
    return DriverProfileModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      age: map['age'] ?? 0,
      profileImageUrl: map['profileImageUrl'] ?? '',
      aadharCardImageUrl: map['aadharCardImageUrl'] ?? '',
      licenseImageUrl: map['licenseImageUrl'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLogin: DateTime.parse(map['lastLogin'] ?? DateTime.now().toIso8601String()),
      isVerified: map['isVerified'] ?? false,
      status: map['status'] ?? 'pending',
      vehicleType: map['vehicleType'],
      vehicleNumber: map['vehicleNumber'],
      rating: map['rating']?.toDouble(),
    );
  }

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'age': age,
      'profileImageUrl': profileImageUrl,
      'aadharCardImageUrl': aadharCardImageUrl,
      'licenseImageUrl': licenseImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'isVerified': isVerified,
      'status': status,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'rating': rating,
    };
  }

  // Create copy with updated fields
  DriverProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    int? age,
    String? profileImageUrl,
    String? aadharCardImageUrl,
    String? licenseImageUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isVerified,
    String? status,
    String? vehicleType,
    String? vehicleNumber,
    double? rating,
  }) {
    return DriverProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      age: age ?? this.age,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      aadharCardImageUrl: aadharCardImageUrl ?? this.aadharCardImageUrl,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      rating: rating ?? this.rating,
    );
  }
}
