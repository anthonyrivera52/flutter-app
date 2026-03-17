import 'package:equatable/equatable.dart';

enum ShopDeliveryStatus { active, waiting, closed }

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
  final bool isOpen;
  final String? statusText;
  final ShopDeliveryStatus? deliveryStatus;
  final ShopDeliveryStatus? pickupStatus;
  final String? organizationName;

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
    this.isOpen = false,
    this.statusText,
    this.deliveryStatus,
    this.pickupStatus,
    this.organizationName,
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
    bool? isOpen,
    String? statusText,
    ShopDeliveryStatus? deliveryStatus,
    ShopDeliveryStatus? pickupStatus,
    String? organizationName,
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
      isOpen: isOpen ?? this.isOpen,
      statusText: statusText ?? this.statusText,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      pickupStatus: pickupStatus ?? this.pickupStatus,
      organizationName: organizationName ?? this.organizationName,
    );
  }

  static ShopDeliveryStatus? parseDeliveryStatus(String? status) {
    if (status == null) return null;
    switch (status) {
      case 'active':
        return ShopDeliveryStatus.active;
      case 'waiting':
        return ShopDeliveryStatus.waiting;
      case 'closed':
        return ShopDeliveryStatus.closed;
      default:
        return null;
    }
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
    isOpen,
    statusText,
    deliveryStatus,
    pickupStatus,
    organizationName,
  ];
}

class ShopDistance extends Equatable {
  final Shop shop;
  final double distanceKm;

  const ShopDistance({required this.shop, required this.distanceKm});

  @override
  List<Object?> get props => [shop, distanceKm];
}
