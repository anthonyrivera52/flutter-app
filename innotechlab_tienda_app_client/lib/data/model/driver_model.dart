import 'package:flutter_app/domain/entities/driver.dart';

class DriverModel extends Driver {
  const DriverModel({
    required super.id,
    required super.name,
    required super.phone,
    super.photoUrl,
    super.vehicleType,
    super.vehiclePlate,
    super.vehicleBrand,
    super.vehicleModel,
    super.currentLatitude,
    super.currentLongitude,
    super.status,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      photoUrl: json['photo_url'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
      vehicleBrand: json['vehicle_brand'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      currentLatitude: (json['current_latitude'] as num?)?.toDouble(),
      currentLongitude: (json['current_longitude'] as num?)?.toDouble(),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'photo_url': photoUrl,
      'vehicle_type': vehicleType,
      'vehicle_plate': vehiclePlate,
      'vehicle_brand': vehicleBrand,
      'vehicle_model': vehicleModel,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'status': status,
    };
  }
}
