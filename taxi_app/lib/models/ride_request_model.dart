import 'location_model.dart';

enum RideStatus {
  pending,
  accepted,
  started,
  completed,
  cancelled;

  bool get isActive => this == accepted || this == started;
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded
}

class RideRequestModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final LocationModel pickupLocation;
  final String pickupAddress;
  final LocationModel destinationLocation;
  final String destinationAddress;
  final String vehicleType;
  final double estimatedFare;
  final double distance;
  final RideStatus status;
  final DateTime createdAt;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final LocationModel? driverLocation;
  final String? driverVehicleType;
  final String? driverVehicleNumber;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final PaymentStatus paymentStatus;
  final String? paymentMethod;
  final int? rating;
  final String? feedback;

  const RideRequestModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.pickupLocation,
    required this.pickupAddress,
    required this.destinationLocation,
    required this.destinationAddress,
    required this.vehicleType,
    required this.estimatedFare,
    required this.distance,
    required this.status,
    required this.createdAt,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverLocation,
    this.driverVehicleType,
    this.driverVehicleNumber,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    required this.paymentStatus,
    this.paymentMethod,
    this.rating,
    this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'pickupLocation': pickupLocation.toMap(),
      'pickupAddress': pickupAddress,
      'destinationLocation': destinationLocation.toMap(),
      'destinationAddress': destinationAddress,
      'vehicleType': vehicleType,
      'estimatedFare': estimatedFare,
      'distance': distance,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverLocation': driverLocation?.toMap(),
      'driverVehicleType': driverVehicleType,
      'driverVehicleNumber': driverVehicleNumber,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'paymentStatus': paymentStatus.toString(),
      'paymentMethod': paymentMethod,
      'rating': rating,
      'feedback': feedback,
    };
  }

  factory RideRequestModel.fromMap(Map<String, dynamic> map) {
    return RideRequestModel(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      pickupLocation: LocationModel.fromMap(map['pickupLocation'] ?? {}),
      pickupAddress: map['pickupAddress'] ?? '',
      destinationLocation: LocationModel.fromMap(map['destinationLocation'] ?? {}),
      destinationAddress: map['destinationAddress'] ?? '',
      vehicleType: map['vehicleType'] ?? '',
      estimatedFare: (map['estimatedFare'] ?? 0).toDouble(),
      distance: (map['distance'] ?? 0).toDouble(),
      status: RideStatus.values.firstWhere(
        (status) => status.toString() == map['status'],
        orElse: () => RideStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      driverId: map['driverId'],
      driverName: map['driverName'],
      driverPhone: map['driverPhone'],
      driverLocation: map['driverLocation'] != null 
          ? LocationModel.fromMap(map['driverLocation']) 
          : null,
      driverVehicleType: map['driverVehicleType'],
      driverVehicleNumber: map['driverVehicleNumber'],
      acceptedAt: map['acceptedAt'] != null 
          ? DateTime.parse(map['acceptedAt']) 
          : null,
      startedAt: map['startedAt'] != null 
          ? DateTime.parse(map['startedAt']) 
          : null,
      completedAt: map['completedAt'] != null 
          ? DateTime.parse(map['completedAt']) 
          : null,
      cancelledAt: map['cancelledAt'] != null 
          ? DateTime.parse(map['cancelledAt']) 
          : null,
      paymentStatus: PaymentStatus.values.firstWhere(
        (status) => status.toString() == map['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentMethod: map['paymentMethod'],
      rating: map['rating']?.toInt(),
      feedback: map['feedback'],
    );
  }

  RideRequestModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    LocationModel? pickupLocation,
    String? pickupAddress,
    LocationModel? destinationLocation,
    String? destinationAddress,
    String? vehicleType,
    double? estimatedFare,
    double? distance,
    RideStatus? status,
    DateTime? createdAt,
    String? driverId,
    String? driverName,
    String? driverPhone,
    LocationModel? driverLocation,
    String? driverVehicleType,
    String? driverVehicleNumber,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    PaymentStatus? paymentStatus,
    String? paymentMethod,
    int? rating,
    String? feedback,
  }) {
    return RideRequestModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      vehicleType: vehicleType ?? this.vehicleType,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      distance: distance ?? this.distance,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverLocation: driverLocation ?? this.driverLocation,
      driverVehicleType: driverVehicleType ?? this.driverVehicleType,
      driverVehicleNumber: driverVehicleNumber ?? this.driverVehicleNumber,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RideRequestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RideRequestModel(id: $id, status: $status, customer: $customerName)';
  }
}
