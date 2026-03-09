import 'package:equatable/equatable.dart';

class Shop extends Equatable {
  final String id;
  final String name;
  final String logoUrl;
  final String address;
  final String schedule;
  final double latitude;
  final double longitude;
  final double serviceRadiusKm;
  final List<String> productIds;

  const Shop({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.address,
    required this.schedule,
    required this.latitude,
    required this.longitude,
    required this.serviceRadiusKm,
    required this.productIds,
  });

  Shop copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? address,
    String? schedule,
    double? latitude,
    double? longitude,
    double? serviceRadiusKm,
    List<String>? productIds,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      schedule: schedule ?? this.schedule,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      productIds: productIds ?? this.productIds,
    );
  }

  @override
  List<Object> get props => [
        id,
        name,
        logoUrl,
        address,
        schedule,
        latitude,
        longitude,
        serviceRadiusKm,
        productIds,
      ];
}
