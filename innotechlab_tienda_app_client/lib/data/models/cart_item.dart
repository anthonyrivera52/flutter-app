import 'dart:convert'; // Necesario para jsonEncode/jsonDecode

import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/data/models/product_model.dart'; // Asegúrate de importar ProductModel

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.product,
    required super.quantity,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      product: ProductModel.fromJson(json['product']),
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': (product as ProductModel).toJson(), // Asegúrate de castear a ProductModel
      'quantity': quantity,
    };
  }

  // Método para convertir entidad a modelo (útil si creas CartItem en dominio y luego lo necesitas como modelo)
  factory CartItemModel.fromEntity(CartItem entity) {
    return CartItemModel(
      product: ProductModel.fromEntity(entity.product),
      quantity: entity.quantity,
    );
  }
}

// Extensión para facilitar la conversión de lista de entidades a modelos y viceversa
extension CartItemModelListExtension on List<CartItem> {
  List<CartItemModel> toModels() {
    return map((item) => CartItemModel.fromEntity(item)).toList();
  }
}

extension CartItemListModelExtension on List<CartItemModel> {
  List<CartItem> toEntities() {
    return map((model) => CartItem(product: model.product, quantity: model.quantity)).toList();
  }
}