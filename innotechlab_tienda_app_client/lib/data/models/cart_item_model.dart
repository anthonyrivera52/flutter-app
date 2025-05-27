import 'dart:convert';
import 'package:mi_tienda/domain/entities/cart_item.dart';
import 'package:mi_tienda/data/models/product_model.dart';

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
      'product': (product as ProductModel).toJson(),
      'quantity': quantity,
    };
  }

  factory CartItemModel.fromEntity(CartItem entity) {
    return CartItemModel(
      product: ProductModel.fromEntity(entity.product),
      quantity: entity.quantity,
    );
  }
}

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
