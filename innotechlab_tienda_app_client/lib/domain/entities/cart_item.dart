import 'package:equatable/equatable.dart';
import 'package:mi_tienda/domain/entities/product.dart'; // Importa la entidad Product

class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  // Método para crear un nuevo CartItem con una cantidad diferente
  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object> get props => [product, quantity];
}