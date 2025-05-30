import 'package:equatable/equatable.dart';

/// Represents a category of products.
class Category extends Equatable {
  final String id;
  final String name;
  final String imageUrl; // Icon or image for the category

  const Category({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  Category copyWith({
    String? id,
    String? name,
    String? imageUrl,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object> get props => [id, name, imageUrl];
}