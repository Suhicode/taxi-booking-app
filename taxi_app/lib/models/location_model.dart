import 'package:latlong2/latlong.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;
  final String? name;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
  });

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'name': name,
    };
  }

  factory LocationModel.fromLatLng(LatLng latLng, {String? address, String? name}) {
    return LocationModel(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      address: address,
      name: name,
    );
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'],
      name: map['name'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() {
    return 'LocationModel(lat: $latitude, lng: $longitude, address: $address, name: $name)';
  }
}
