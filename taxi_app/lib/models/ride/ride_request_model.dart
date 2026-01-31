import 'package:latlong2/latlong.dart';

enum RideStatus {
  pending,
  accepted,
  driverArrived,
  inProgress,
  completed,
  cancelled,
}

enum PaymentStatus {
  pending,
  paid,
  refunded,
}

class RideRequestModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? driverId;
  final String? driverName;
  final LatLng pickupLocation;
  final String pickupAddress;
  final LatLng destinationLocation;
  final String destinationAddress;
  final String vehicleType;
  final double estimatedFare;
  final double distance;
  final RideStatus status;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final LatLng? currentCustomerLocation;
  final LatLng? currentDriverLocation;
  final int? estimatedArrivalMinutes;
  final double? actualFare;
  final String? paymentMethod;

  RideRequestModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.driverId,
    this.driverName,
    required this.pickupLocation,
    required this.pickupAddress,
    required this.destinationLocation,
    required this.destinationAddress,
    required this.vehicleType,
    required this.estimatedFare,
    required this.distance,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.currentCustomerLocation,
    this.currentDriverLocation,
    this.estimatedArrivalMinutes,
    this.actualFare,
    this.paymentMethod,
  });

  factory RideRequestModel.fromMap(Map<String, dynamic> map) {
    return RideRequestModel(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      driverId: map['driverId'],
      driverName: map['driverName'],
      pickupLocation: LatLng(
        map['pickupLatitude'] ?? 0.0,
        map['pickupLongitude'] ?? 0.0,
      ),
      pickupAddress: map['pickupAddress'] ?? '',
      destinationLocation: LatLng(
        map['destinationLatitude'] ?? 0.0,
        map['destinationLongitude'] ?? 0.0,
      ),
      destinationAddress: map['destinationAddress'] ?? '',
      vehicleType: map['vehicleType'] ?? '',
      estimatedFare: (map['estimatedFare'] ?? 0.0).toDouble(),
      distance: (map['distance'] ?? 0.0).toDouble(),
      status: _parseRideStatus(map['status']),
      paymentStatus: _parsePaymentStatus(map['paymentStatus']),
      createdAt: DateTime.parse(map['createdAt']),
      acceptedAt: map['acceptedAt'] != null ? DateTime.parse(map['acceptedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      currentCustomerLocation: map['currentCustomerLatitude'] != null && map['currentCustomerLongitude'] != null
          ? LatLng(map['currentCustomerLatitude'], map['currentCustomerLongitude'])
          : null,
      currentDriverLocation: map['currentDriverLatitude'] != null && map['currentDriverLongitude'] != null
          ? LatLng(map['currentDriverLatitude'], map['currentDriverLongitude'])
          : null,
      estimatedArrivalMinutes: map['estimatedArrivalMinutes'],
      actualFare: map['actualFare']?.toDouble(),
      paymentMethod: map['paymentMethod'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'driverId': driverId,
      'driverName': driverName,
      'pickupLatitude': pickupLocation.latitude,
      'pickupLongitude': pickupLocation.longitude,
      'pickupAddress': pickupAddress,
      'destinationLatitude': destinationLocation.latitude,
      'destinationLongitude': destinationLocation.longitude,
      'destinationAddress': destinationAddress,
      'vehicleType': vehicleType,
      'estimatedFare': estimatedFare,
      'distance': distance,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'currentCustomerLatitude': currentCustomerLocation?.latitude,
      'currentCustomerLongitude': currentCustomerLocation?.longitude,
      'currentDriverLatitude': currentDriverLocation?.latitude,
      'currentDriverLongitude': currentDriverLocation?.longitude,
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
      'actualFare': actualFare,
      'paymentMethod': paymentMethod,
    };
  }

  RideRequestModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? driverId,
    String? driverName,
    LatLng? pickupLocation,
    String? pickupAddress,
    LatLng? destinationLocation,
    String? destinationAddress,
    String? vehicleType,
    double? estimatedFare,
    double? distance,
    RideStatus? status,
    PaymentStatus? paymentStatus,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    LatLng? currentCustomerLocation,
    LatLng? currentDriverLocation,
    int? estimatedArrivalMinutes,
    double? actualFare,
    String? paymentMethod,
  }) {
    return RideRequestModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      vehicleType: vehicleType ?? this.vehicleType,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      distance: distance ?? this.distance,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      currentCustomerLocation: currentCustomerLocation ?? this.currentCustomerLocation,
      currentDriverLocation: currentDriverLocation ?? this.currentDriverLocation,
      estimatedArrivalMinutes: estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      actualFare: actualFare ?? this.actualFare,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  static RideStatus _parseRideStatus(String? status) {
    switch (status) {
      case 'pending':
        return RideStatus.pending;
      case 'accepted':
        return RideStatus.accepted;
      case 'driverArrived':
        return RideStatus.driverArrived;
      case 'inProgress':
        return RideStatus.inProgress;
      case 'completed':
        return RideStatus.completed;
      case 'cancelled':
        return RideStatus.cancelled;
      default:
        return RideStatus.pending;
    }
  }

  static PaymentStatus _parsePaymentStatus(String? status) {
    switch (status) {
      case 'pending':
        return PaymentStatus.pending;
      case 'paid':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  String get statusDisplay {
    switch (status) {
      case RideStatus.pending:
        return 'Waiting for driver';
      case RideStatus.accepted:
        return 'Driver on the way';
      case RideStatus.driverArrived:
        return 'Driver has arrived';
      case RideStatus.inProgress:
        return 'Ride in progress';
      case RideStatus.completed:
        return 'Ride completed';
      case RideStatus.cancelled:
        return 'Ride cancelled';
    }
  }

  bool get isActive => status == RideStatus.accepted || 
                      status == RideStatus.driverArrived || 
                      status == RideStatus.inProgress;
}
