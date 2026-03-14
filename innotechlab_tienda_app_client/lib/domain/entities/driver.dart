import 'package:equatable/equatable.dart';

class Driver extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  final String? vehicleType;
  final String? vehiclePlate;
  final String? vehicleBrand;
  final String? vehicleModel;
  final double? currentLatitude;
  final double? currentLongitude;
  final String? status;

  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
    this.vehicleType,
    this.vehiclePlate,
    this.vehicleBrand,
    this.vehicleModel,
    this.currentLatitude,
    this.currentLongitude,
    this.status,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    photoUrl,
    vehicleType,
    vehiclePlate,
    vehicleBrand,
    vehicleModel,
    currentLatitude,
    currentLongitude,
    status,
  ];
}
