import 'package:equatable/equatable.dart';

/// Represents a product in the grocery store.
class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String unit; // e.g., "kg", "unidad", "litro"
  final String categoryId; // Link to Category

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.unit,
    required this.categoryId,
  });

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? unit,
    String? categoryId,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  List<Object> get props => [id, name, description, price, imageUrl, unit, categoryId];
}
