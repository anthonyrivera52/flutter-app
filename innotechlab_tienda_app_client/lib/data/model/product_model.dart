import 'package:flutter_app/domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.imageUrl,
    required super.unit, // Añadido
    required super.categoryId, // CAMBIADO
    super.discountedPrice, // Añadido
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      unit: json['unit'] as String, // Añadido
      categoryId: json['category_id'] as String, // CAMBIADO: Leer de 'category_id'
      discountedPrice: (json['discounted_price'] as num?)?.toDouble(), // AÑADIDO: Leer de 'discounted_price'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'unit': unit, // Añadido
      'category_id': categoryId, // CAMBIADO: Escribir como 'category_id'
      'discounted_price': discountedPrice, // Añadido
    };
  }

  factory ProductModel.fromEntity(Product entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      price: entity.price,
      imageUrl: entity.imageUrl,
      unit: entity.unit, // Añadido
      categoryId: entity.categoryId, // CAMBIADO
      discountedPrice: entity.discountedPrice, // Añadido
    );
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      unit: unit, // Añadido
      categoryId: categoryId, // CAMBIADO
      discountedPrice: discountedPrice, // Añadido
    );
  }
}
