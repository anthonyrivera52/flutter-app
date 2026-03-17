import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final String unit;
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

  double get subtotal => price * quantity;

  @override
  List<Object?> get props =>
      [productId, name, imageUrl, price, unit, quantity];
}
