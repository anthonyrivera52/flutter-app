import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String unit; // Añadido: para la unidad del producto (ej. "kg", "unidad")
  final String categoryId; // CAMBIADO: Ahora usamos categoryId para el filtro
  final double? discountedPrice; // AÑADIDO: Para productos con descuento

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.unit, // Añadido
    required this.categoryId, // CAMBIADO
    this.discountedPrice, // AÑADIDO
  });

  // Método copyWith para facilitar la creación de nuevas instancias con cambios
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? unit,
    String? categoryId,
    double? discountedPrice,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      unit: unit ?? this.unit,
      categoryId: categoryId ?? this.categoryId,
      discountedPrice: discountedPrice, // Permite establecer null
    );
  }

  @override
  List<Object?> get props => [id, name, description, price, imageUrl, unit, categoryId, discountedPrice];
}
