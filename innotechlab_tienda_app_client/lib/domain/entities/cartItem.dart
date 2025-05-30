import 'package:equatable/equatable.dart';

/// Represents an item in the user's shopping cart.
class CartItem extends Equatable {
  final String productId; // ID of the product
  final String name; // Product name (denormalized for convenience)
  final String imageUrl; // Product image (denormalized for convenience)
  final double price; // Product price (denormalized for convenience)
  final String unit; // Product unit (denormalized for convenience)
  final int quantity;

  const CartItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.unit,
    required this.quantity,
  });

  CartItem copyWith({
    String? productId,
    String? name,
    String? imageUrl,
    double? price,
    String? unit,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object> get props => [productId, name, imageUrl, price, unit, quantity];
}