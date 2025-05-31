// En flutter_app/domain/entities/category.dart (o donde la tengas definida)
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid(); // Para generar IDs si es necesario dentro de la entidad

class Category {
  final String id;
  final String name;
  final String imageUrl;
  final List<Category>? subcategories; // Campo para las subcategorías
  final String? parentId; // Opcional: si también quieres mantener una referencia al padre

  Category({
    String? id, // Permitir que el ID sea opcional si se genera aquí
    required this.name,
    required this.imageUrl,
    this.subcategories,
    this.parentId,
  }) : id = id ?? _uuid.v4(); // Genera un ID si no se proporciona

  // Método copyWith para facilitar la actualización de instancias (opcional pero útil)
  Category copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<Category>? subcategories,
    String? parentId,
    bool clearSubcategories = false, // Para explícitamente poner subcategories a null
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      subcategories: clearSubcategories ? null : (subcategories ?? this.subcategories),
      parentId: parentId ?? this.parentId,
    );
  }

  // Para facilitar la serialización/deserialización si usas JSON (opcional)
  // Map<String, dynamic> toJson() => {
  //   'id': id,
  //   'name': name,
  //   'imageUrl': imageUrl,
  //   'subcategories': subcategories?.map((sub) => sub.toJson()).toList(),
  //   'parentId': parentId,
  // };

  // factory Category.fromJson(Map<String, dynamic> json) => Category(
  //   id: json['id'],
  //   name: json['name'],
  //   imageUrl: json['imageUrl'],
  //   subcategories: (json['subcategories'] as List<dynamic>?)
  //       ?.map((subJson) => Category.fromJson(subJson as Map<String, dynamic>))
  //       .toList(),
  //   parentId: json['parentId'],
  // );
}