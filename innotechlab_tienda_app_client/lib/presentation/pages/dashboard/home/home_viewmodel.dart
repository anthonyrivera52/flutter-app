import 'package:equatable/equatable.dart';
import 'package:flutter_app/domain/entities/product.dart';
import 'package:flutter_app/domain/entities/shop.dart';

/// Represents the state of the Home screen.
/// It is immutable and used with the HomeNotifier.
class HomeState extends Equatable {
  final bool isLoading;
  final bool isLocationLoading;
  final String? errorMessage;
  final String? locationMessage;
  final List<Product> products;
  final List<ShopDistance> nearbyShops;
  final Shop? selectedShop;
  final double? userLatitude;
  final double? userLongitude;

  const HomeState({
    this.isLoading = false,
    this.isLocationLoading = false,
    this.errorMessage,
    this.locationMessage,
    this.products = const [],
    this.nearbyShops = const [],
    this.selectedShop,
    this.userLatitude,
    this.userLongitude,
  });

  /// Creates a new instance of HomeState with updated values.
  HomeState copyWith({
    bool? isLoading,
    bool? isLocationLoading,
    String? errorMessage,
    String? locationMessage,
    List<Product>? products,
    List<ShopDistance>? nearbyShops,
    Shop? selectedShop,
    double? userLatitude,
    double? userLongitude,
    bool clearError = false,
    bool clearLocationMessage = false,
    bool clearSelectedShop = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      isLocationLoading: isLocationLoading ?? this.isLocationLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      locationMessage: clearLocationMessage
          ? null
          : (locationMessage ?? this.locationMessage),
      products: products ?? this.products,
      nearbyShops: nearbyShops ?? this.nearbyShops,
      selectedShop: clearSelectedShop
          ? null
          : (selectedShop ?? this.selectedShop),
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isLocationLoading,
    errorMessage,
    locationMessage,
    products,
    nearbyShops,
    selectedShop,
    userLatitude,
    userLongitude,
  ];
}

class ShopDistance extends Equatable {
  final Shop shop;
  final double distanceKm;

  const ShopDistance({required this.shop, required this.distanceKm});

  @override
  List<Object?> get props => [shop, distanceKm];
}
