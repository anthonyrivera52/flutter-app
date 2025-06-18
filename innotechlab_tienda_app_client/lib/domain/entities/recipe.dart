import 'package:equatable/equatable.dart';

class Recipe extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int cookingTimeMinutes;
  final double price; // E.g., estimated cost of ingredients for the recipe

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.cookingTimeMinutes,
    required this.price,
  });

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    int? cookingTimeMinutes,
    double? price,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      cookingTimeMinutes: cookingTimeMinutes ?? this.cookingTimeMinutes,
      price: price ?? this.price,
    );
  }

  @override
  List<Object> get props => [id, title, description, imageUrl, cookingTimeMinutes, price];
}