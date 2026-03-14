import 'package:equatable/equatable.dart';

class Shop extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String logoUrl;
  final String address;
  final String? schedule;
  final double latitude;
  final double longitude;
  final double? serviceRadiusKm;
  final List<String> productIds;
  final String? city;

  const Shop({
    required this.id,
    required this.name,
    required this.slug,
    required this.logoUrl,
    required this.address,
    this.schedule,
    required this.latitude,
    required this.longitude,
    this.serviceRadiusKm,
    required this.productIds,
    this.city,
  });

  Shop copyWith({
    String? id,
    String? name,
    String? slug,
    String? logoUrl,
    String? address,
    String? schedule,
    double? latitude,
    double? longitude,
    double? serviceRadiusKm,
    List<String>? productIds,
    String? city,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      schedule: schedule ?? this.schedule,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      productIds: productIds ?? this.productIds,
      city: city ?? this.city,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    logoUrl,
    address,
    schedule,
    latitude,
    longitude,
    serviceRadiusKm,
    productIds,
    city,
  ];
}
